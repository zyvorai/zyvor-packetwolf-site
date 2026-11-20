# PacketWolf MCP server (read-only)

PacketWolf exposes a [Model Context Protocol](https://modelcontextprotocol.io) server so AI agents
(Claude Code, Claude Desktop, and other MCP clients) can query your cluster's network intelligence.

**Read-only by design.** This version ships 18 tools and every one of them is a read. There is no
tool that creates, changes, deletes, applies, or executes anything, and there is no flag that turns
one on.

- Endpoint: `POST /api/mcp` (MCP Streamable HTTP transport, JSON-RPC 2.0, spec revision 2025-03-26;
  2024-11-05 and 2025-06-18 clients are also accepted).
- `GET` and `DELETE` on the endpoint return `405` (no SSE stream, no sessions).
- Methods: `initialize`, `notifications/initialized`, `ping`, `tools/list`, `tools/call`. Anything
  else returns JSON-RPC `-32601`. JSON-RPC batches (up to 20 messages) are accepted.

## Enable it

MCP is **off by default** (the endpoint answers `404`). Turn it on for the API process:

```bash
PACKETWOLF_MCP_ENABLED=true
```

Optional: `PACKETWOLF_MCP_MAX_OUTPUT_BYTES` (default 65536, clamped to 4096..1048576) sets the cap on
the text returned by one tool call.

## Authenticate

MCP uses the existing API credentials; there is no separate MCP login.

| Credential | Header | Resulting role |
|---|---|---|
| Admin API key | `Authorization: Bearer <key>` or `x-api-key: <key>` | `admin` |
| Partner API key | same | `partner` (view only) |
| User JWT from `/api/v1/auth/login` | `Authorization: Bearer <jwt>` | the user's role and namespaces |

Rules specific to MCP, stricter than the REST API:

- A request must carry one of the credentials above. The credential-less "cluster network trust"
  shortcut (loopback / pod-network callers) and `AUTH_DISABLED=true` do **not** grant MCP access.
- Embed tokens (`x-embed-token`) are refused.
- Missing or bad credential: HTTP `401`. A role RBAC does not know: HTTP `403`.
- The normal middleware stack still applies: CSRF origin check, request validation, 256 KB body
  limit, and rate limiting (the `/api/mcp` path uses the 20 req/s per-IP "heavy" tier).

## Add it to Claude Code

```bash
claude mcp add --transport http packetwolf http://localhost:9191/api/mcp \
  --header "Authorization: Bearer $PACKETWOLF_API_KEY"
```

Replace the URL with your API address (use `https://` outside local development). Verify with
`claude mcp list`, then ask, for example: "Using packetwolf, which namespaces have dropped traffic
right now and why?"

For Claude Desktop or other clients that take a JSON config, use the HTTP/streamable-http server
form with the same URL and `Authorization` header.

## Tools

All tools are annotated `readOnlyHint: true`. "Admin" tools are listed to, and callable by, the
`admin` role only. "Cluster-wide" tools return data that the underlying API cannot filter by
namespace, so they are hidden from and refused to namespace-scoped credentials.

| Tool | Arguments | Access | Backing API |
|---|---|---|---|
| `packetwolf_cluster_health` | none | cluster-wide | `/api/v1/cluster/health` |
| `packetwolf_network_overview` | `namespace?` | namespaced | `/api/v1/network/overview` |
| `packetwolf_service_map` | `namespace?` | namespaced | `/api/v1/network/service-map` |
| `packetwolf_flows_query` | `namespace?`, `verdict?`, `limit?`, `offset?` | namespaced | `/api/v1/flows` |
| `packetwolf_flow_stats` | none | cluster-wide | `/api/v1/flows/stats` |
| `packetwolf_drop_explanations` | `namespace?` | namespaced | `/api/v1/network/drop-decoder` |
| `packetwolf_network_policies_list` | `limit?`, `offset?` | namespaced | `/api/v1/policies` |
| `packetwolf_anomalies_list` | `namespace?`, `limit?`, `offset?` | namespaced | `/api/v1/anomalies` |
| `packetwolf_incidents_list` | `limit?`, `offset?` | cluster-wide | `/api/v1/incidents` |
| `packetwolf_events_list` | `limit?`, `offset?` | namespaced | `/api/v1/events` |
| `packetwolf_endpoints_list` | `limit?`, `offset?` | namespaced | `/api/v1/endpoints` |
| `packetwolf_nodes_list` | none | cluster-wide | `/api/v1/nodes` |
| `packetwolf_ebpf_dataplane_status` | none | admin | `/api/v1/ebpf/dataplane` |
| `packetwolf_ebpf_drop_stats` | `limit?`, `offset?` | admin | `/api/v1/ebpf/drops` |
| `packetwolf_compliance_frameworks` | none | cluster-wide | `/api/v1/compliance/frameworks` |
| `packetwolf_security_posture` | none | admin | `/api/v1/security/posture` |
| `packetwolf_metrics_seconds` | `window` (1-900 s) | viewer | `/api/v1/metrics/seconds` |
| `packetwolf_node_isolation_shadow_runs` | `limit?` (capped at 50) | viewer | `/api/v1/nodes/isolation/shadow` |

Argument bounds: `limit` 1..200 (default 50), `offset` 0..100000, `namespace` an RFC 1123 name of at
most 253 characters, `verdict` one of FORWARDED, DROPPED, ERROR, AUDIT, REDIRECTED, TRACED,
TRANSLATED. `tools/list` returns the full JSON Schema for each tool.

## Safety model

1. **Read-only registry.** Tools map to GET-equivalent handlers only. Adding a mutating tool would
   require a code change and a new access level; there is no runtime switch.
2. **Same authorisation as REST, plus gates.** Each call runs the handler in-process with the
   caller's own claims, so namespace RBAC inside the handler applies exactly as over REST. On top
   of that: the `View` capability is required, admin-only tools check the admin role, and
   cluster-wide tools are refused to namespace-scoped credentials. Denials are JSON-RPC error
   `-32001` and are logged with the caller and tool name.
3. **Untrusted arguments.** Arguments must be an object; unknown fields, wrong types, out-of-range
   numbers, bad names, and more than 16 keys are rejected with `-32602` before any handler runs.
4. **Redaction.** Every result passes through a redaction pass before it leaves the server. Fields
   whose names indicate secrets (password, secret, token, api key, private key, kubeconfig,
   credential, authorization, cookie, and similar) are replaced with `[REDACTED]`, as are the
   `data`/`stringData` of Kubernetes `Secret` objects and any value that looks like a bearer
   token, JWT, or PEM private key. Redaction is name- and pattern-based and best effort; it is a
   safety net, not a replacement for the handlers not returning secrets.
5. **Size cap.** Output is cut at the cap (default 64 KiB) and ends with a line starting
   `[TRUNCATED: ...]` stating the original size. Narrow with `namespace`, `limit`, `offset`.
6. **Resource limits.** 25 s per tool call, at most 8 concurrent tool calls (`-32002` when busy),
   plus the API's per-IP rate limit.
7. **Audit.** Each call logs `sub`, `role`, tool name, and argument names (not values).

Tool *execution* failures (for example a handler returning 403 or a backend being unreachable)
come back as a normal result with `isError: true` and a short message, so the agent can react.

## Walkthrough with curl

```bash
export PW=http://127.0.0.1:9191 KEY=...   # admin or partner API key, or a user JWT
H=(-H 'Content-Type: application/json' -H 'Accept: application/json, text/event-stream' -H "Authorization: Bearer $KEY")

curl -s -X POST $PW/api/mcp "${H[@]}" -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"curl","version":"1"}}}'
curl -s -X POST $PW/api/mcp "${H[@]}" -d '{"jsonrpc":"2.0","method":"notifications/initialized"}'      # 202, empty body
curl -s -X POST $PW/api/mcp "${H[@]}" -d '{"jsonrpc":"2.0","id":2,"method":"tools/list"}'
curl -s -X POST $PW/api/mcp "${H[@]}" -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"packetwolf_flows_query","arguments":{"namespace":"default","verdict":"dropped","limit":20}}}'
```

## Not in this version

Mutating tools (policy apply, containment, remediation), MCP resources and prompts, server-sent
events / resumable streams, and per-user MCP tokens. Agents should use a dedicated least-privilege
credential (a viewer-role user, or the partner key) rather than the admin key.

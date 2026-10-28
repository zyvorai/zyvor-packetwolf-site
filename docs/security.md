# Security summary

How PacketWolf decides who can see and do what. This page describes the current PacketWolf build; the published container image is updated at each release, so check the [release notes](https://github.com/zyvorai/zyvor-packetwolf-site/releases) for the tag that carries a feature. The [feature guide (PDF)](../downloads/PacketWolf-Feature-Guide.pdf) has the full detail.

PacketWolf is **deny by default**: every request needs a credential, and what a credential may see or do is decided on the server, never only in the browser.

## Roles and capabilities

| Role | Can |
|---|---|
| `viewer`, `partner` | Read |
| `operator` | Read, simulate, apply low-impact containment |
| `approver` | Read, approve or reject |
| `security-admin` | Simulate, contain, approve, break-glass |
| `platform-admin` | Simulate, configure integrations |
| `admin` | Everything (unless limited to namespaces, see below) |

| Action | Needs |
|---|---|
| Read flows, policies, maps | Any role, within the account's namespaces |
| Simulate; submit a policy for approval | Simulate capability |
| Approve or reject a submitted policy | Approve capability, and the approval's namespace in scope |
| Apply a policy directly, release, roll back | Unscoped `admin` |
| Users, SSO settings, node maintenance, `/metrics` | Unscoped `admin` |

Embed tokens and partner keys are view-only. They can be confined to namespaces so that a leaked embed URL cannot read the whole cluster.

## Namespace-scoped accounts

An account can be limited to a list of namespaces. The API enforces it on every route:

- Flow-derived views show a flow when its source **or** destination is in scope. An object outside the scope reads as not found; naming a namespace outside it is refused (403).
- Cluster-level data that cannot be split by namespace (nodes, Cilium internals, SLOs, alert channels, multi-cluster, replay and similar) is refused for a scoped account.
- An account with several namespaces works in one at a time (the console has a namespace switcher); with one, it is applied automatically.
- **The namespace list wins over the role.** An `admin` limited to namespaces is a scoped caller, not a platform admin.
- Role and scope changes reach tokens already issued: for local and SSO-provisioned accounts the next request uses the account's current role and scope, and open live streams are closed. LDAP identities keep the role they had at sign-in until the token expires.

## Approvals

One person submits a `CiliumNetworkPolicy` (Simulate capability); another reviews the diff and approves or rejects it (Approve capability). The policy must be a single, valid `CiliumNetworkPolicy` whose namespace matches the approval's, within size limits and without YAML anchors, aliases or tags, and it is checked again before it is applied. Each approval records who submitted it, who reviewed it, and its namespace.

## Audit

State-changing actions are logged with time, actor, action, target and outcome, and kept for 30 days. Policy submit, approve, reject and direct apply are audited. Actions that PacketWolf records but does not perform (packet capture, traffic mirror, chaos and replay entries in the console) are marked `recorded`. Reading the audit log writes no entries.

## Sessions

- **Sign-out is server-side.** The token is revoked and that session's open streams are closed. With Redis configured the revocation reaches every API replica; without it, each replica keeps its own list.
- Sessions have an absolute lifetime (7 days by default) and cannot be extended by refreshing.
- Five failed sign-ins for the same address and username start a lockout that doubles up to 15 minutes. A separate per-username limit stops guessing that rotates addresses.
- Interactive shells (pod, container, VM console) are audited, capped (3 per user, 20 in total by default), idle-limited, and need a real admin credential.

## Requests, webhooks and defaults

- Nothing ships with a default password or key. The Helm chart generates a random admin password and API key on first install.
- Trusting callers inside the cluster as admin is **off** by default.
- Every `kubectl` call the API makes passes one argument guard, and a request value that starts with `-` is refused, so it cannot become a `kubectl` option.
- Errors from Kubernetes are sanitised before they reach a client.
- Outbound webhooks and SSO fetches refuse private, loopback and cloud-metadata addresses unless an administrator allows them.
- `X-Forwarded-For` is honoured only from proxies you list. Without that list, everyone behind an ingress shares one lockout and rate-limit bucket.
- Containers run as non-root with a read-only root filesystem and all capabilities dropped. Node maintenance (cordon, drain) is off unless enabled at install.

## What is not claimed

- Node cordon, drain and uncordon, and the Tetragon views, have been tested against mocks and fixtures, not against a live cluster.
- Packet capture, traffic mirroring, chaos and replay entries in the console are records only; the healer records an acknowledgement and does not apply a fix.
- Live-cluster verification of the admission webhook, WebSocket scoping and shell limits under load is still outstanding.
- Lockout and rate-limit counters are per API replica.
- Cross-replica effects such as a logout on another replica rely on Redis.

Questions: [info@zyvor.dev](mailto:info@zyvor.dev).

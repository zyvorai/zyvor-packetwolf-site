# Pages

Every page in the PacketWolf console, grouped by area. Routes are the paths in the web console.

> Illustrative descriptions of what each page is for; availability of live data depends on your cluster and on Cilium and Hubble being present.


## Overview

| Page | Route | Purpose |
|---|---|---|
| Network | `/embed/overview` | Primary Network overview — health, shortcuts, and summary cards for the PacketWolf console. |
| Cluster Health | `/clusterhealth` | Cluster health pulse for Cilium, Hubble, and PacketWolf components. |
| Events | `/events` | Platform and network event stream. |
| Kubernetes | `/kubernetes` | Kubernetes inventory context for network intelligence. |
| Nodes | `/nodes` | Node inventory with network/agent relevance. |
| Endpoints | `/endpoints` | Cilium / workload endpoint inventory. |
| Host Info | `/host` | Host information for the PacketWolf control plane node. |
| Cilium Status | `/cilium-status` | Live Cilium agent status and feature readiness. |
| Containers | `/containers` | Container inventory including non-Kubernetes runtimes surfaced by the node agent. |

## Observability

| Page | Route | Purpose |
|---|---|---|
| Flow Monitor | `/flows` | Live Hubble flow monitor with verdicts, drops, and L7 context. |
| Topology History | `/topology` | Topology history — how the service graph evolved over time. |
| Service Map | `/servicemap` | Live service map of who talks to whom. |
| Heatmap | `/heatmap` | Traffic or risk heatmap across workloads. |
| Dependencies | `/dependencies` | Workload dependency graph from observed flows. |
| Latency | `/latency` | Latency distribution and path timing insights. |
| Flow Export | `/flow-export` | Export flows for SIEM, forensics, or offline analysis. |
| SLOs | `/slo` | Network SLO definitions and burn/error budgets. |
| DNS Monitor | `/dns` | DNS monitor — queries, failures, and DNS Wolf signals. |
| Bandwidth | `/bandwidth` | Bandwidth usage by workload or interface. |
| Interfaces | `/interfaces` | Host and node network interfaces. |
| Network changes | `/netlink-changes` | Which link, address, route or neighbor changed on this node, and when — with findings such as default route removed or uplink down. |
| Per-second metrics | `/metrics-seconds` | One-second resolution rates for flows, API requests, 5xx responses and node network counters over the last 15 minutes. Shows unavailable, never invented numbers, when a source cannot be read. |
| Metrics | `/system-metrics` | System and PacketWolf metrics dashboard. |

## Security

| Page | Route | Purpose |
|---|---|---|
| Policies | `/policies` | The list of network policies in your cluster (Cilium and Kubernetes), with create, edit, simulate and delete for admins. |
| Policy Approvals | `/policy-approvals` | Review the diff of a submitted network policy and approve or reject it; approving applies it. Needs the Approve capability and the approval's namespace in scope. |
| Egress Security | `/egress-security` | Egress security posture — external destinations and least-privilege egress controls. |
| Templates | `/templates` | Policy and response templates library. |
| Policy Editor | `/policy-editor` | Edit Cilium/network policies as text or structured forms. |
| Visual Policy Editor | `/policy-visual` | Visual policy editor for CiliumNetworkPolicy objects. |
| Rule Builder | `/rule-builder` | Guided rule builder for least-privilege network rules. |
| Ingress Security | `/ingress-security` | Ingress security posture and controls. |
| Pod Security | `/pod-security` | Pod-level network security overview. |
| User accounts | `/user-accounts` | Accounts, roles and namespace scopes for the PacketWolf console and API; disable an account to end its sessions. |
| Anomalies | `/anomalies` | Behavioral anomaly detections for unusual network patterns. |
| Containment | `/containment` | Workload containment — simulate, apply, and roll back quarantine profiles. |
| VM Guard | `/vm-guard` | VM Guard — PacketWolf containment and flow view for KubeVirt VMs. |
| Pod Guard | `/pod-guard` | Pod Guard — contain and inspect pod network posture. |
| Security | `/security` | Security overview combining threats, posture, and recommended actions. |
| Runtime Security | `/tetragon` | Runtime security (Tetragon) events and enforcement visibility. |
| Encryption | `/encryption` | Encryption / WireGuard-related network encryption status. |
| WireGuard | `/wireguard` | WireGuard tunnel and peer status. |
| Mutual Auth | `/mutual-auth` | Cilium native mTLS (SPIFFE/SPIRE) enforcement coverage — which policy rules require it, and whether SPIRE is present. |
| Identities | `/identities` | Cilium identity inventory. |
| RBAC | `/rbac` | RBAC visibility for who can change network policy. |
| Compliance | `/compliance` | Network compliance checks and evidence. |
| Policy Baselines | `/policy-baselines` | Default allow/deny posture per namespace, tenant, or the whole cluster, with guided least-privilege RuleSets layered on top. |
| Audit Log | `/audit` | Audit log of policy and containment actions. |
| Alerts | `/alerts` | Alerting for threats, drops, and policy events. |
| Incidents | `/incidents` | Incident tracking with network context. |
| Change Log | `/changelog` | Change log of network and policy mutations. |
| Remote Access | `/vm-access` | Remote access helpers related to VM Guard / console exposure. |

## Intelligence

| Page | Route | Purpose |
|---|---|---|
| Diagnostics | `/diagnostics` | Diagnostics and suggested fixes for connectivity and policy issues. |
| AI Hub | `/ai/hub` | AI Hub — Zeus copilot entry and AI-assisted network workflows. |
| Kernel Intel | `/kernel` | Kernel intelligence — process-to-socket attribution and TCP lifecycle. |
| War Room | `/war-room` | War Room collaborative incident surface. |
| Zeus Catalog | `/ai/catalog` | Zeus / AI playbook and capability catalog. |
| Graph Explorer | `/graph-explorer` | Explore the live risk/attack/dependency graph. |
| CRD Manager | `/crds` | PacketWolf CRD manager (FlowPolicy, AutoPolicy, Containment, and more). |
| AutoPolicy | `/autopolicy-engine` | AutoPolicy Engine — ML-scored least-privilege CiliumNetworkPolicy from real Hubble traffic, persistent learn/suggest/enforce jobs, and one-click namespace isolation (Open/Default-Deny/Zero-Trust). |
| Healer | `/healer` | Network healer: proposed fixes for network faults. A fix is recorded as handled; PacketWolf does not apply it. |
| Root Cause | `/rootcause` | Root-cause analysis correlating drops, policy, DNS, and kernel signals. |
| Internet Test | `/internet-test` | Internet reachability / egress path testing. |
| Troubleshoot | `/troubleshoot` | Guided network troubleshooting workflows. |
| Forecasting | `/forecast` | Traffic and capacity forecasting. |

## Operations

| Page | Route | Purpose |
|---|---|---|
| eBPF Hub | `/ebpf-hub` | eBPF hub landing page for map readers, probes, and dataplane status. |
| eBPF Data Plane | `/ebpf-dataplane` | Honest eBPF dataplane status — which probe phases attached, failed, or remain userspace. |
| BPF Attachments | `/ebpf-inventory` | Which PacketWolf and Cilium eBPF hooks should be attached, which are, and where they have drifted. |
| Node isolation (shadow) | `/node-isolation-shadow` | A dry run of isolating a node: which pods would be evicted, which services would lose endpoints, and the blast radius. Changes nothing in the cluster. |
| Chaos | `/chaos` | Chaos experiment log. Entries are records only; no fault is injected. |
| Canary | `/canary` | Canary traffic shifting for network/deploy validation. |
| Replay | `/replay` | Replay recordings: labelled time windows with the hubble observe command that replays them. |
| Capture | `/capture` | Packet capture session records. The API runs no capture itself. |
| Mirroring | `/mirror` | Traffic mirror rule records. The API does not program mirroring. |
| MultiCluster | `/multicluster` | Multi-cluster network visibility. |
| Cluster Mesh | `/clustermesh` | Cilium Cluster Mesh topology and status. |
| BGP Peering | `/bgp` | BGP peering status and routes. |
| Node Drain | `/node-drain` | Node drain with network-aware checks. |
| eBPF | `/ebpf` | Decoded Cilium eBPF maps overview. |

## eBPF Data

| Page | Route | Purpose |
|---|---|---|
| Conntrack Table | `/conntrack` | Conntrack table decoded from Cilium maps with K8s enrichment. |
| Policy Map | `/policy-map` | Policy map entries decoded from the kernel. |
| IP Cache | `/ipcache` | IP cache (identity ↔ IP) from Cilium maps. |
| LB Map | `/lb-map` | Load-balancer map backends and services. |
| Drop Analytics | `/drops` | Drop analytics by reason with trends. |

## Networking

| Page | Route | Purpose |
|---|---|---|
| Load Balancer | `/loadbalancer` | Load balancer service overview. |
| Ingress | `/ingress` | Ingress resources and network exposure. |
| Egress GW | `/egress` | Egress gateway configuration and status. |
| Service Mesh | `/service-mesh` | Service mesh visibility (mTLS, L7) where available. |
| KPR | `/kpr` | Kube-proxy replacement (KPR) status under Cilium. |
| IPAM | `/ipam` | IPAM pools and allocation status. |
| Cost Analytics | `/costs` | Network cost analytics (egress/cross-AZ style signals). |

## System

| Page | Route | Purpose |
|---|---|---|
| Settings | `/settings` | PacketWolf settings — appearance, auth-related preferences, and system options. |

## Embeds (Zeus OS / CloudOS panels)

| Page | Route | Purpose |
|---|---|---|
| overview | `/embed/overview` | Primary Network overview — health, shortcuts, and summary cards for the PacketWolf console. |
| workloads | `/embed/workloads` | Workload-centric embed panel. |
| service map | `/embed/service-map` | Embeddable service map. |
| flows | `/embed/flows` | Embeddable live flows panel. |
| threats | `/embed/threats` | Threat detections embed panel. |
| policy wizard | `/embed/policy-wizard` | Policy creation wizard embed. |
| war room | `/embed/war-room` | War Room embed. |
| runtime security | `/embed/runtime-security` | Runtime security embed (Tetragon). |
| external traffic | `/embed/external-traffic` | External / internet traffic embed. |
| copilot | `/embed/copilot` | Ask Zyra / copilot embed chat. |
| ai | `/embed/ai` | AI surfaces embed landing. |
| zeus catalog | `/embed/zeus-catalog` | Zeus catalog embed. |
| playbooks | `/embed/playbooks` | Response playbooks embed. |
| incident | `/embed/incident` | Incident embed panel. |
| risk graph | `/embed/risk-graph` | Risk graph embed. |
| process lens | `/embed/process-lens` | Process-to-network lens embed. |
| flow baselines | `/embed/flow-baselines` | Flow baseline learning embed. |
| forensics | `/embed/forensics` | Network forensics embed. |
| geo threat | `/embed/geo-threat` | Geo threat map embed. |
| healer auto | `/embed/healer-auto` | Healer automation embed. |
| threat threads | `/embed/threat-threads` | Correlated threat story threads. |
| attack graph | `/embed/attack-graph` | Attack graph embed. |
| zero trust pilot | `/embed/zero-trust-pilot` | Zero-trust observe → simulate → approve pilot. |
| dns wolf | `/embed/dns-wolf` | DNS Wolf intelligence embed. |
| runtime guard | `/embed/runtime-guard` | Runtime Guard embed. |
| compliance lens | `/embed/compliance-lens` | Compliance lens embed. |
| autopolicy pilot | `/embed/autopolicy-pilot` | AutoPolicy pilot embed. |
| policy recommendation | `/embed/policy-recommendation` | Policy recommendation embed. |
| approvals | `/embed/approvals` | Policy/response approvals embed. |
| dependencies export | `/embed/dependencies/export` | Dependency export embed. |
| unreachable debugger | `/embed/unreachable-debugger` | Unreachable endpoint debugger. |
| policy drift | `/embed/policy-drift` | Policy drift detection embed. |
| l7 insights | `/embed/l7-insights` | L7 protocol insights embed. |
| cluster health ai | `/embed/cluster-health-ai` | AI cluster-health embed. |
| digital twin | `/embed/digital-twin` | Network digital twin embed. |
| top talkers | `/embed/top-talkers` | Top talkers embed. |
| mtls visibility | `/embed/mtls-visibility` | mTLS visibility embed. |
| blast radius | `/embed/blast-radius` | Blast-radius simulator embed. |
| network score | `/embed/network-score` | Network health score embed. |
| service mesh | `/embed/service-mesh` | Service mesh embed panel. |
| cost aware | `/embed/cost-aware` | Cost-aware networking embed. |
| bgp topology | `/embed/bgp-topology` | BGP topology embed. |
| cloud hybrid | `/embed/cloud-hybrid` | Cloud/hybrid networking embed. |
| cve posture | `/embed/cve-posture` | CVE posture related to network exposure. |
| network siem | `/embed/network-siem` | Network SIEM integration embed. |
| incident coach | `/embed/incident-coach` | Incident coach AI embed. |
| connectivity wizard | `/embed/connectivity-wizard` | Connectivity troubleshooting wizard. |
| rbac ai | `/embed/rbac-ai` | RBAC AI assistant embed. |
| tenant ai | `/embed/tenant-ai` | Multi-tenant AI assist embed. |
| enterprise audit | `/embed/enterprise-audit` | Enterprise audit embed. |
| compliance automation | `/embed/compliance-automation` | Compliance automation embed. |
| disaster recovery | `/embed/disaster-recovery` | DR networking embed. |
| dns | `/embed/dns` | DNS embed panel. |
| timeline | `/embed/timeline` | Network timeline embed. |
| capture | `/embed/capture` | Capture embed panel. |
| reports | `/embed/reports` | Reports embed. |
| multicluster | `/embed/multicluster` | Multi-cluster embed. |
| federation | `/embed/federation` | Federation embed. |
| vm guard | `/embed/vm-guard` | VM Guard embed for Zeus OS. |
| pod guard | `/embed/pod-guard` | Pod Guard embed. |

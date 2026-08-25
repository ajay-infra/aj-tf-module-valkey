# CLAUDE.md — aj-tf-module-valkey

> Local context file for Claude. Not pushed to GitHub.

---

## What This Module Does

Provisions an ElastiCache Valkey replication group in the data VPC. Shared across both blue and green EKS clusters — the data layer is never duplicated. Both clusters connect to the same Valkey instance via data VPC peering.

Valkey is the BSD-licensed open-source fork of Redis (API-compatible). AWS made Valkey the primary ElastiCache focus after the Redis BSL license change (March 2024).

---

## Module Structure

```
modules/
  secrets/          → random auth_token + Secrets Manager secret (shell only)
  valkey-cluster/   → security group + subnet group + parameter group + replication group

root:
  main.tf           → orchestrates both submodules + writes full connection bundle to secret
  locals.tf         → name_prefix, cluster_mode_enabled, automatic_failover_enabled, allowed_cidr_blocks
  variables.tf      → all input variables with validation + EOT descriptions
  outputs.tf        → primary_endpoint, reader_endpoint, port, security_group_id, secret_arn
  providers.tf      → Terraform = 1.10.5, AWS = 5.100.0, random = 3.6.3
```

---

## Key Design Decisions

- **Valkey not Redis** — BSD open-source fork, identical API, AWS primary focus post Redis BSL
- **Shared across blue + green** — data layer is NOT duplicated per EKS color; both clusters hit same instance via data VPC peering; security group dynamically adds green VPC CIDR when `green_enabled = true`
- **az_count slices subnet list** — same pattern as eks + vpc modules; pass all data subnets, module uses only az_count of them
- **Cluster mode driven by num_shards** — `num_shards = 1` → cluster mode disabled (dev/staging); `num_shards > 1` → cluster mode enabled (prod); no separate toggle needed
- **Automatic failover from replicas** — `automatic_failover_enabled` is derived from `replicas_per_shard >= 1`; no manual toggle
- **Auth token in Secrets Manager** — random 64-char alphanumeric token; full connection bundle (auth_token + endpoints + port + tls) written to Secrets Manager after cluster is up; ESO ExternalSecret in k8s-manifests pulls this into K8s Secrets
- **TLS always on** — `transit_encryption_enabled = true` unconditional; no variable to disable it
- **At-rest encryption always on** — `at_rest_encryption_enabled = true` default; variable exposed for auditability
- **Graviton ARM nodes** — `cache.r7g.*` by default; ~20% cheaper vs x86 equivalent for same memory/throughput
- **lazyfree parameters** — `lazyfree-lazy-eviction`, `lazyfree-lazy-expire`, `lazyfree-lazy-server-del` all enabled; reduces latency spikes under memory pressure by deferring cleanup to background threads
- **engine_version ignored in lifecycle** — allows AWS to apply minor patches without Terraform drift
- **Kong rate-limiting backend** — Kong `rate-limiting-advanced` plugin uses this Valkey instance for distributed counters across replicas; in cluster mode (`num_shards > 1`), Kong must use `redis_cluster` strategy

---

## Variables to Know

- `num_shards` — 1 (dev/staging = cluster mode disabled), 3 (prod = cluster mode enabled)
- `replicas_per_shard` — 0 (no failover, not recommended), 1 (default — automatic failover)
- `multi_az_enabled` — false for dev, true for prod (primary + replica in different AZs)
- `green_enabled` — flip to true during blue/green upgrade window to allow green VPC CIDR into SG
- `az_count` — 2 (dev/staging), 3 (prod); controls subnet group membership
- `node_type` — `cache.r7g.large` (dev), `cache.r7g.xlarge` (prod)
- `snapshot_retention_days` — 1 (dev), 7 (prod)
- `secret_recovery_window_days` — 0 (dev, immediate delete), 7 (staging/prod)
- `apply_immediately` — true (dev), false (prod — changes go through maintenance window)

---

## Outputs Used by Downstream Modules

`aj-infra-release` consumes these as `-var` flags or remote state:
- `secret_arn` → ESO `ExternalSecret` in k8s-manifests (fetches auth_token + endpoints)
- `security_group_id` → optionally added to EKS node group SG rules
- `primary_endpoint` → can be passed to Kong Helm values for rate-limiting plugin config
- `cluster_mode_enabled` → determines whether Kong uses `redis` or `redis_cluster` strategy

---

## Blue/Green Notes

Valkey is NOT part of the blue/green swap — it's shared data infrastructure.

| Phase | Action |
|---|---|
| Normal | `green_enabled = false`; only blue VPC CIDR in SG |
| Green cluster live | `green_enabled = true`; green VPC CIDR added to SG via `terraform apply` |
| Traffic on green | Both blue + green can reach Valkey — no cache invalidation needed |
| Blue torn down | `green_enabled = false`; blue CIDR removed from SG |

---

## Running Locally (Podman container)

```bash
# from aj-infra-context/local-testing/ (formerly My-Infra/ — repo renamed;
# this Podman workflow currently has no Makefile/Dockerfile, see that repo's
# local-testing/README.md for the known gap)
make shell
cd /workspaces/aj-tf-module-valkey
terraform init -backend=false
terraform plan -var-file=example.tfvars
```

Dummy AWS creds (`test`/`test`) + `skip_credentials_validation = true` in providers.tf — plan works without real AWS.

---

## Known TODOs

- [ ] Add auth_token rotation — Lambda-backed Secrets Manager rotation; Valkey supports `AUTH` token rotation with zero downtime via `auth_token_update_strategy = ROTATE`
- [ ] CloudWatch alarms — `EngineCPUUtilization`, `DatabaseMemoryUsagePercentage`, `CurrConnections` per shard
- [ ] Evaluate `cache.r8g` (newer Graviton gen) when available in us-east-1
- [ ] Valkey parameter tuning for Kong rate-limiting workloads — review `maxmemory-policy`, `hz`

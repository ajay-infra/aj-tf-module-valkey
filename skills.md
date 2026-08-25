# skills.md — aj-tf-module-valkey

## Purpose
Provisions a Valkey (Redis-compatible) ElastiCache cluster with blue/green VPC support, encryption in transit and at rest, and parameter group management.

## Type
`tf-module`

## Stable ref
```
source = "github.com/ajay-infra/aj-tf-module-valkey?ref=v1.0.0"
```

## Key inputs
| Variable | Description |
|---|---|
| `cluster_name` | ElastiCache cluster name |
| `environment` | dev \| staging \| uat \| prod |
| `data_vpc_id` | VPC for the cache cluster |
| `data_subnet_ids` | Data tier subnet IDs |
| `green_enabled` | Enable green VPC variant |

## AWS tags applied
`Project`, `ManagedBy`, `Repository` (from `common_tags`), plus `Environment`, `Team`,
`CostCenter`, `ClusterName`, `AZCount` (set in `locals.full_tags`), plus whatever's in
`var.tags`. No `Env`, `Model`, or `Customer` tag exists in this module.

## Depends on
`aj-tf-module-vpc` — requires data_vpc_id and data_subnet_ids

## Branching convention
- `main` — active development
- semver tags (`v1.0.0`, ...) — stable pinned releases, per `README.md` usage examples

## CI checks
fmt, validate, plan (dry-run), tfsec/checkov

## Agentic capabilities
- Detect Valkey engine version drift
- Validate encryption-in-transit is enabled
- Flag missing auth token in prod
- Generate PR for parameter group tuning

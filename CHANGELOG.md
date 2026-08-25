# Changelog

All notable changes to this module are documented here. Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Fixed
- `README.md`'s "Requirements" table and `CLAUDE.md`'s module structure line both said Terraform `= 1.7.5` — `providers.tf` actually pins `= 1.10.5`, matching the platform-wide Terraform 1.10.5 / S3-native-locking migration already reflected everywhere else. Same stale-version pattern already found and fixed in `aj-tf-module-vpc`, `aj-tf-module-eks`, and `aj-tf-module-aurora`.
- `skills.md`'s "Stable ref" pointed at `github.com/ajaylakma/aj-tf-module-valkey?ref=valkey-01` — wrong org (real org is `ajay-infra`) and a branch that doesn't exist (only `main` exists — confirmed via `git branch -a`; no tags existed either, despite `README.md`'s own Usage example already correctly referencing `?ref=v1.0.0`). Same pattern found 4+ times this project now. Fixed the ref to match `README.md` and cut the `v1.0.0` tag (module was fully implemented with no prior release).
- `skills.md`'s "AWS tags applied" listed `Env`, `Team`, `ManagedBy`, `CostCenter`, `Model`, `Customer` — checked `locals.tf`: the real tag set is `Project`/`ManagedBy`/`Repository` (from `common_tags`) plus `Environment`/`Team`/`CostCenter`/`ClusterName`/`AZCount` (from `locals.full_tags`). No `Env`, `Model`, or `Customer` tag exists anywhere in this module. Same pattern already found in `aj-tf-module-eks` and `aj-tf-module-aurora`.
- `CLAUDE.md`'s "Running Locally" section still pointed at `My-Infra/` — repo renamed to `aj-infra-context` in Session 2; that Podman workflow currently has no `Makefile`/`Dockerfile` (documented gap, not fixed here). Updated the reference and noted the gap inline, matching the fix already applied in `aj-tf-module-eks`.

## [v1.0.0] - 2026-08-24

Initial release — ElastiCache Valkey replication group, blue/green SG toggle, cluster-mode-via-num_shards, Secrets Manager auth token bundle, Graviton (`cache.r7g.*`) nodes. Module was already fully implemented; this tag just formalizes the first stable release so `skills.md` has something real to pin to (`README.md`'s Usage example already referenced this tag before it existed).

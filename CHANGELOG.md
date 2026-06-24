# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the module
follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Releases are cut automatically by `release-please` on merge to `main`,
driven by Conventional Commit prefixes (`feat:` → minor, `fix:`/`docs:`/`chore:` → patch,
`feat!:` or `BREAKING CHANGE:` footer → major).

## 0.1.0 (2026-06-24)


### Features

* native AWS Secrets Manager module (fintech-hardened) ([02d4386](https://github.com/devotica-labs/terraform-aws-secretsmanager/commit/02d43867ce2952c4607b1868537cb4da87ce8178))


### Bug Fixes

* avoid coalesce(null,null) for Terraform 1.9 compatibility ([1095d33](https://github.com/devotica-labs/terraform-aws-secretsmanager/commit/1095d33aee577df99cfb060902499d6f0dac37c7))
* null-safe recovery_window validation (Terraform || does not short-circuit) ([e17cad9](https://github.com/devotica-labs/terraform-aws-secretsmanager/commit/e17cad97988b46d41e9eb7f7c3cf206bfe7d445c))

## [Unreleased]

### Added
- Initial module — a native (no external module dependencies) AWS Secrets
  Manager module that manages a `for_each` map of secrets, each with:
  - KMS encryption (module-level default + per-secret override).
  - A configurable deletion-recovery window (default 30 days).
  - An optional resource policy with public access blocked by default.
  - Optional Lambda-based rotation.
  - Optional cross-region replicas.
  - An opt-in bootstrap value supplied via a separate, sensitive
    `secret_values` map (driven by a non-sensitive `set_initial_value` flag so
    `for_each` never touches sensitive data).
- Native naming/tagging composed from `namespace`/`environment`/`stage`/`name`;
  each secret is named `<prefix>/<map-key>` (or a `name_override`).
- `examples/basic` + `examples/complete`, and unit/contract/integration
  `terraform test` suites.

### Deferred to later versions
- AWS-managed rotation (without a custom Lambda).
- An SSM Parameter Store companion module.

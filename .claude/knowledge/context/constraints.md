---
name: constraints
description: Hard constraints the agent must respect. Read before any non-trivial change.
last_verified: 2026-04-15
verified_against: TODO
decay_risk: low
---

# Constraints

> Non-obvious limits the agent cannot infer from the code alone:
> performance budgets, compliance requirements, external contracts,
> deployment limits.

<!-- TEMPLATE: fill in with your project's real constraints. Each
     constraint should explain WHAT the limit is and WHY it exists. -->

## Performance

TODO: Latency targets, memory limits, throughput requirements, and
what happens if they are breached.

## Compliance

TODO: GDPR, HIPAA, SOC 2, PCI, regional data residency, or similar
legal requirements, and which modules are affected.

## External contracts

TODO: Public API versions that must remain backwards-compatible,
webhook payloads consumed by external systems, contract tests with
partner services.

## Deployment

TODO: Supported platforms, runtime versions, database versions,
browser matrix, minimum dependency versions.

## Backwards compatibility

TODO: What breaking changes require what process? Major version
bumps? Deprecation windows? Migration scripts?

---
docId: GOV-PLAN-59
title: "[CODE] fix(onboard): bump pinned shared-tooling ref to gft-bootstrap-v1.0.2"
version: 1.0.0
authors:
  - Claude
creation_date: '2026-08-07'
last_updated_date: '2026-08-07'
language: en
summary: Planning context for issue #59 — advance the release pin so users receive the entrypoint-resolution fix
status: in_progress
issue-id: GenCr-ft/gencr-ft.github.io#59
metadata:
  lifecycle-stage: draft
  scope: project-aethel
  domain: engineering
  doc-type: specification
  security-classification: l2_confidential
  keywords:
    - planning
    - bump-plt-ref-v1-0-2
---

# [CODE] fix(onboard): bump pinned shared-tooling ref to gft-bootstrap-v1.0.2

## Why

`plt_ref()` is the sole trust anchor between this shim and the shared tooling.
Until it advances, users keep cloning v1.0.1 — the release that reports success
and leaves `gft` unable to resolve its entrypoint when poetry has a cached
virtualenv (`gcs-plt-tools#782`, PR #783).

## Ordering is the risk, not the diff

`bootstrap_shared_tooling` pins one tag across three repos and dies on any
missing clone, so all three were tagged and verified **before** this edit:

| Repo | tag -> commit |
|------|---------------|
| `gcs-plt-tools` | `dde9608c` |
| `gcs-plt-gemop` | `cb5123ef` |
| `gcs-core-governance` | `35d37d27` |

Then the shim's clone was rehearsed verbatim for each repo, and the cloned
`onboard.sh` confirmed to carry `resolve_service_entrypoint`, the
`GFT_ENTRYPOINT` write and the python3.12 preference, `bash -n` clean, wrapper
free of poetry in code. Suites at that commit: 38/38 onboarding, 53/53 scripts.

## The rehearsal gap that v1.0.1 taught us

The v1.0.1 rehearsal cloned into **empty** temp directories, which only
exercises the fresh-machine branch. The `ref?: unbound variable` abort lived in
the returning-user update branch — the one a pin bump forces every existing
developer through. That is now rehearsed explicitly: shared tooling
pre-populated at an older tag, fast path failing, update branch entered, no
abort, and the branch proven reached rather than skipped.

## No new test, deliberately

`scripts/test_onboard.sh` already asserts the invariants that matter — pinned
`gft-bootstrap-v*`, not a moving branch, still overridable — and they are
pattern-based, so they validate this bump without an edit. The ASCII-only guard
from #57 also stays green through it. A value-based assertion would need
changing every release, turning a safety net into churn.

## Rollback

Revert the single line to v1.0.1. That tag remains published and resolvable, so
behaviour returns exactly to its previous state. Machines already onboarded under
v1.0.2 keep working.

## Relations

Parent: #59 · ships gcs-plt-tools#782 (PR #783) · previous bump #51 · ASCII
guard #57 · keystone gcs-project-management#535 · ADR ENG-ADR-088.

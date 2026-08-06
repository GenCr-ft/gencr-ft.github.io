---
docId: GOV-PLAN-51
title: "[CODE] fix(onboard): bump pinned shared-tooling ref to gft-bootstrap-v1.0.1"
version: 1.0.0
authors:
  - Claude
creation_date: '2026-08-06'
last_updated_date: '2026-08-06'
language: en
summary: Planning context for issue #51 — advance the release pin so users receive the poetry auto-install fix
status: in_progress
issue-id: GenCr-ft/gencr-ft.github.io#51
metadata:
  lifecycle-stage: draft
  scope: project-aethel
  domain: engineering
  doc-type: specification
  security-classification: l2_confidential
  keywords:
    - planning
    - bump-plt-ref-v1-0-1
---

# [CODE] fix(onboard): bump pinned shared-tooling ref to gft-bootstrap-v1.0.1

## Why

`plt_ref()` is the sole trust anchor between this public shim and the shared
tooling. Until it advances, the poetry auto-install fix
(`gcs-plt-tools#776`, PR #780) reaches **nobody** — onboarding keeps cloning
`v1.0.0`, which hard-exits when poetry is absent. That is the exact macOS failure
this whole initiative exists to remove (keystone `gcs-project-management#535`).

## Ordering is the risk, not the diff

The change is one token. What carries risk is sequence: `bootstrap_shared_tooling`
pins **one** tag name across three repos and `die`s on any missing clone, so a
half-tagged release breaks onboarding for everyone.

Therefore all three tags were created and verified **before** this edit:

| Repo | tag → commit |
|------|--------------|
| `gcs-plt-tools` | `52b8db1b` |
| `gcs-plt-gemop` | `f2ec25c7` |
| `gcs-core-governance` | `35d37d27` |

Then the shim's clone was rehearsed verbatim
(`gh repo clone … --branch gft-bootstrap-v1.0.1 --depth 1`) for each repo, and the
resulting `gcs-plt-tools/onboard.sh` confirmed to contain `ensure_poetry`,
`poetry==$POETRY_VERSION`, `POETRY_VERSION="2.1.3"` and the `GFT_ONBOARD_LIB`
guard, with `bash -n` clean and no `poetry not found` gate. Both suites pass at
that commit: 28/28 onboarding, 53/53 scripts.

## No new test, deliberately

`scripts/test_onboard.sh` already asserts the invariants that matter — the default
ref must match `gft-bootstrap-v*`, must not be a moving branch, and must remain
overridable by `GFT_PLT_REF`. Those are **pattern-based**, so they validate this
bump without an edit. A value-based assertion would need changing every release,
turning a safety net into churn.

## Rollback

Revert the single line to `v1.0.0`. That tag is untouched and still resolves, so
behaviour returns exactly to its previous state. Machines already onboarded under
v1.0.1 keep working.

## Known remaining gaps (not this WI)

A newcomer still needs Homebrew and a >= 3.12 python on macOS
(`gcd-onboarding-scripts#259`), and Docker/Node/wasm-pack before the walking
skeleton runs (`gcs-plt-tools#658`/`#659`).

## Relations

Parent: #51 · Design: #52 · Impl: #53 · keystone gcs-project-management#535 ·
ships gcs-plt-tools#776 · ADR ENG-ADR-088 §Pinned-Tag Governance.

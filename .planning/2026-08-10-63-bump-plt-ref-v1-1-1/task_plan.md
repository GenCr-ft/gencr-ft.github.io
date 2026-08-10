---
docId: GOV-PLAN-63
title: "[CODE] fix(onboard): bump pinned shared-tooling ref to gft-bootstrap-v1.1.1"
version: 1.0.0
authors:
  - Claude
creation_date: '2026-08-10'
last_updated_date: '2026-08-10'
language: en
summary: Planning context for issue #63 — advance plt_ref to v1.1.1 so operators receive the portable-template fix
status: in_progress
issue-id: GenCr-ft/gencr-ft.github.io#63
metadata:
  lifecycle-stage: draft
  scope: project-aethel
  domain: engineering
  doc-type: specification
  security-classification: l2_confidential
  keywords:
    - planning
    - onboarding
    - pinned-tag
---

# [CODE] fix(onboard): bump pinned shared-tooling ref to gft-bootstrap-v1.1.1

## Problem

v1.1.0 shipped workspace context deployment (gcs-plt-tools#789) while
`AGENTS.md.template` still carried 4 hard-coded `/home/lgan` paths. That was accepted
deliberately — context with four wrong paths beats no context — but it means every operator
onboarding against v1.1.0 receives a file telling them to `cd` into someone else's home
directory, and on macOS into a path that cannot exist. The fix is merged
(gcs-plt-gemop#415) but reaches nobody until the pin advances.

## Pre-flight — done BEFORE the bump

| Repo | tag -> commit | == remote main |
|---|---|---|
| gcs-plt-tools | gft-bootstrap-v1.1.1 -> 7fa6c61b | yes (unchanged since v1.1.0) |
| gcs-plt-gemop | gft-bootstrap-v1.1.1 -> ba8c7330 | yes |
| gcs-core-governance | gft-bootstrap-v1.1.1 -> aa8a2aa8 | yes |

Verified from each remote via `git ls-remote refs/tags/...^{}`, then proven by
`git clone --depth 1 --branch gft-bootstrap-v1.1.1`.

**And the payload was verified at the tag**, not just its resolvability: zero `/home/lgan`
in the cloned `AGENTS.md.template`, guard module present, `gcs-plt-tools/onboard.sh` present.
A tag that resolves is not the same as a tag that contains the fix.

## Verification gap

`scripts/test_onboard.sh:42` asserts only the `gft-bootstrap-v*` pattern — it would pass
against a tag that exists nowhere. The pre-flight is the only real guard here.

## Traceability

- Issue: GenCr-ft/gencr-ft.github.io#63
- Ships: GenCr-ft/gcs-plt-gemop#395 (PR #415, merged ba8c733)
- Previous bump: #61 -> v1.1.0
- Deployment mechanism: GenCr-ft/gcs-plt-tools#789
- Keystone: GenCr-ft/gcs-project-management#535

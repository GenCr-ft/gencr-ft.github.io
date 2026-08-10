---
docId: GOV-PLAN-61
title: "[CODE] fix(onboard): bump pinned shared-tooling ref to gft-bootstrap-v1.1.0"
version: 1.0.0
authors:
  - Claude
creation_date: '2026-08-09'
last_updated_date: '2026-08-09'
language: en
summary: Planning context for issue #61 — advance plt_ref to gft-bootstrap-v1.1.0 so users receive workspace context deployment
status: in_progress
issue-id: GenCr-ft/gencr-ft.github.io#61
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

# [CODE] fix(onboard): bump pinned shared-tooling ref to gft-bootstrap-v1.1.0

## Problem

`plt_ref()` still returns `gft-bootstrap-v1.0.2`. It is the sole trust anchor between this
public shim and the shared tooling (ENG-ADR-088, Pinned-Tag Governance), so onboarding keeps
cloning v1.0.2 — the release in which a freshly onboarded workspace has **no** root
`CLAUDE.md`/`AGENTS.md`, and assistants therefore start with none of the studio's routing,
gates or conventions. Without the bump, gcs-plt-tools#789 reaches nobody.

## Why MINOR, not patch

v1.0.1 and v1.0.2 were fixes. v1.1.0 adds user-visible behaviour (`gft onboard` writes two
files it never wrote before, and moves a divergent pre-existing one aside), changes existing
behaviour (`gft drift scan` resolves a different canonical source, so "drift" means something
different), carries an accepted regression (`--no-claude` with an invalid relative
`GFT_STUDIO_HOME` went from exit 0 to exit 1), and gemop adds a new skill.

## Pre-flight — completed BEFORE the bump

`bootstrap_shared_tooling` dies on any missing clone, so a half-tagged release breaks
onboarding outright. Order was: tag all three → verify on the remotes → prove by cloning →
only then edit `plt_ref()`.

| Repo | tag -> commit | == remote main |
|---|---|---|
| gcs-plt-tools | gft-bootstrap-v1.1.0 -> 7fa6c61b | yes |
| gcs-plt-gemop | gft-bootstrap-v1.1.0 -> 02f9a9bb | yes |
| gcs-core-governance | gft-bootstrap-v1.1.0 -> 206036ce | yes |

Verified by reading `refs/tags/gft-bootstrap-v1.1.0^{}` from each **remote** via
`git ls-remote` — not the local tag database, which can hold an unpushed tag — and then by
`git clone --depth 1 --branch gft-bootstrap-v1.1.0` of each repo, confirming
`gcs-plt-tools/onboard.sh` and both gemop templates are present in the cloned trees.

## Verification gap worth naming

`scripts/test_onboard.sh:42` asserts only that the default ref matches `gft-bootstrap-v*`.
It would pass just as happily against a tag that does not exist anywhere. No automated check
in this repo can catch a bad pin; the pre-flight above is the only real guard, which is why
it is recorded rather than summarised.

## Activated by this release

`gcs-plt-gemop/templates/AGENTS.md.template` carries 4 hard-coded `/home/lgan` paths. Inert
until now because nothing deployed the template; this release starts fanning them out to
every onboarded workspace on every machine, including macOS where the path cannot exist.
Tracked as GenCr-ft/gcs-plt-gemop#395 and recommended as the immediate next action.

## Traceability

- Issue: GenCr-ft/gencr-ft.github.io#61
- Ships: GenCr-ft/gcs-plt-tools#789 (PR #798, merged 7fa6c61)
- Previous bump: #59 -> v1.0.2
- Activates: GenCr-ft/gcs-plt-gemop#395
- Keystone: GenCr-ft/gcs-project-management#535
- ENG-ADR-088 Pinned-Tag Governance

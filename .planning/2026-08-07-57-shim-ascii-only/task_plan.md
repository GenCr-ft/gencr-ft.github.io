---
docId: GOV-PLAN-57
title: "[CODE] fix(onboard): make the public shim ASCII-only (hotfix)"
version: 1.0.0
authors:
  - Claude
creation_date: '2026-08-07'
last_updated_date: '2026-08-07'
language: en
summary: Planning context for issue #57 — shim aborts with "ref?: unbound variable" on macOS for returning users
status: in_progress
issue-id: GenCr-ft/gencr-ft.github.io#57
metadata:
  lifecycle-stage: draft
  scope: project-aethel
  domain: engineering
  doc-type: specification
  security-classification: l2_confidential
  keywords:
    - planning
    - shim-ascii-only
---

# [CODE] fix(onboard): make the public shim ASCII-only (hotfix)

## Problem

The live one-liner aborts on macOS for anyone who has onboarded before:

```text
bash: line 149: ref?: unbound variable
```

Line 149, at byte level, is:

```text
log "Updating $repo to $ref\342\200\246"
```

`$ref` is immediately followed by the UTF-8 bytes of U+2026. Bash decides where a
variable name ends using `isalnum()`, which is **locale-dependent**. Under a
locale where high bytes classify as alphanumeric, bash absorbs the ellipsis into
the name, looks up `ref`+ellipsis, finds it unset, and `set -euo pipefail` kills
the run. The terminal renders the mangled bytes as `?`, which is why the reported
name appears nowhere in the source.

Audit of the three scripts the one-liner executes: **line 149 is the only
instance**. `gcs-plt-tools/onboard.sh` and `scripts/gft-wrapper.sh` at
`gft-bootstrap-v1.0.1` are clean. Line 152 also ends in an ellipsis but reads
`$ref)`, and the `)` terminates the name, so it is safe — which is why the abort
is at 149 and not 152.

## Why it surfaced now, and why the release rehearsal missed it

Line 149 lives in a branch that runs **only** when the shared-tooling directory
already exists but is not at the pinned tag:

```sh
if [ -e "$dest" ]; then
  log "Updating $repo to $ref..."   # line 149
  rm -rf "$dest" || die ...
fi
```

- Fresh machine: `$dest` absent, line skipped, never reached.
- Returning user pinned at v1.0.0: `$dest` exists, HEAD != v1.0.1, fast path
  fails, **line 149 executes**.

The defect predates this work (WI-387a shim rewrite) but was latent. Bumping the
pin in #51 is precisely what forces returning users down that branch.

The pre-release clone rehearsal cloned into **empty temp directories** — the
fresh-machine path — so it could not have caught this. Check 13 in
`scripts/test_onboard.sh` now exercises the returning-user path directly.

## Approach

Bracing `${ref}` would fix the symptom only. The shim carried **19 non-ASCII
characters across 16 lines** (10x U+2014, 6x U+2026, 3x U+00A7), any of which
could land next to a variable in a future edit. A public bootstrap piped from
curl into bash 3.2 under an unknown locale should be pure ASCII.

So: convert all 19, and add two byte-level guards plus a returning-user
reproduction so it cannot regress.

## Honest limit of the test

A glibc runner cannot reproduce the macOS locale classification (glibc `isalnum`
is ASCII-only in the C locale), so check 13 proves the update branch is reached
and survives under `set -u`; it does **not** demonstrate the original failure.
Check 12 (ASCII-only, and no variable adjacent to a high byte) is what actually
prevents recurrence, and it is mutation-verified.

## Relations

Parent: #57 · activated by pin bump #51 (PR #54) · defect introduced with the
WI-387a shim rewrite · keystone gcs-project-management#535.

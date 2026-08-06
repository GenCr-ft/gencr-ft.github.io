---
docId: GOV-PLAN-49
title: "[CODE] fix(site): correct dead launcher, macOS Godot, failure recovery"
version: 1.0.0
authors:
  - Claude
creation_date: '2026-08-06'
last_updated_date: '2026-08-06'
language: en
summary: Planning context for issue #49 — homepage publishes a renamed launcher and Linux-only Godot instructions
status: in_progress
issue-id: GenCr-ft/gencr-ft.github.io#49
metadata:
  lifecycle-stage: draft
  scope: project-aethel
  domain: engineering
  doc-type: specification
  security-classification: l2_confidential
  keywords:
    - planning
    - homepage-corrections
---

# [CODE] fix(site): correct dead launcher, macOS Godot, failure recovery

## Problem

The public onboarding homepage documents at least one command that cannot work,
and gives no guidance for the failure newcomers actually hit.

1. **Dead launcher command.** The walking-skeleton section instructs
   `./run-walking-skeleton.sh`. That script was renamed to `start_aethel.sh` by
   WI-250 (`gcd-onboarding-scripts` d27c5e8). Verified absent before changing.
2. **Undeclared prerequisites.** `start_aethel.sh` requires Docker + compose,
   Node.js 20+, `openssl` and `wasm-pack`. **None** are installed by onboarding
   today (tracked: `gcs-plt-tools#658`/`#659`), yet the page implies the
   one-liner covered everything.
3. **Godot instructions are Linux-only.** The page tells users to run
   `../Godot_v4.5-stable_linux.x86_64` while advertising macOS as first-class in
   its own Quickstart.
4. **No failure recovery.** The page claims re-running is safe but offers no
   recovery path. A macOS newcomer hit a hard stop installing the `gft` CLI
   (keystone `gcs-project-management#535`, RC1) with nothing to fall back on.

## Approach

Correct the launcher name, state the real prerequisites plainly rather than
implying they are handled, make the Godot step platform-aware via `GODOT_BIN`,
list the service ports so a port clash is self-diagnosable, and add an "If
Something Goes Wrong" section mapping each failure phase to a concrete remedy.

Every published command is executed before merge — the defect being fixed is
precisely a command that was published without being run.

## Verification

`./test.sh` — HTML structural validity, the one-liner onboarding contract, the
four canonical workspace ids, and the `onboard.sh` bootstrap unit tests.

## Relations

Parent: #49 · keystone gcs-project-management#535 · WI-250 (launcher rename) ·
prerequisites gap gcs-plt-tools#658/#659.

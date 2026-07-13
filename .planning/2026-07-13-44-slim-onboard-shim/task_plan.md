---
docId: GOV-PLAN-44
title: "[CODE] WI-387a slim public onboard.sh — shared-tooling bootstrap + exec gft onboard"
issue-id: GenCr-ft/gencr-ft.github.io#44
status: in-progress
---

# [CODE] WI-387a — slim public onboard.sh (ENG-ADR-088 §4)

## Scope

Slim the public curl|bash shim: keep prereqs + gh device-auth; ADD bootstrap of the 3
shared-tooling repos (gcs-plt-tools/gcs-plt-gemop/gcs-core-governance) into ~/.gft-studio
at a pinned release tag (gft-bootstrap-v1.0.0) + install gft via gcs-plt-tools/onboard.sh;
then `exec gft onboard --workspace <id>`. REMOVE the gcd-onboarding-scripts orchestrator
clone, gft-onboarding.sh delegation, fixed ~/gft_studio, and all workspace-clone logic.
gft-onboarding.sh retained as the full role-tool path (deprecation = follow-up).

## Changes

- onboard.sh: rewrite (studio_home/plt_ref/bootstrap_shared_tooling; exec gft onboard).
- scripts/test_onboard.sh: rewrite contract tests (plt_ref tag, no-orchestrator, bootstrap idempotency + PATH-die, full main() exec handoff).
- scripts/verify-contracts.sh: drop gcd-onboarding-scripts requirement; assert §4 flow.
- index.html + README.md: two-phase model (user-facing one-liner unchanged).

## Gates

- Design #45: diane R1 dispositioned (C-1 parity → #653, now merged).
- Release pin: gft-bootstrap-v1.0.0 cut on the 3 shared repos at #653-inclusive commits.
- Verify: ./test.sh green; real tag-clone + full-run e2e; impl-adversary (diane).
- LIVE cutover of the public entrypoint — merge only after e2e passes.

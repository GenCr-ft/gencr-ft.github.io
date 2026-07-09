---
docId: GOV-PLAN-26
title: "[CODE] Public onboard.sh bootstrap — device-auth, pinned clone, handoff (ENG-ADR-087)"
status: approved
issue-id: GenCr-ft/gencr-ft-github-io#26
---

## [CODE] Public onboarding bootstrap (keystone)

Parent Initiative: GenCr-ft/gcs-project-management#377. Decision: ENG-ADR-087. DESIGN: #32.

### TDD Cycles

- [x] Cycle 1 — RED: scripts/test_onboard.sh (canonical ids, arg parse, pinned ref, pkg-mgr detect, handoff cmd, no-secrets)
- [ ] Cycle 1 — GREEN: onboard.sh thin bootstrap (lib-guarded) — detect_pkg_mgr/ensure_cmd/parse_args/is_canonical_workspace/onboarding_ref/ensure_gh_auth/clone_orchestrator/build_handoff_cmd/main
- [ ] Cycle 2 — RED/GREEN: verify-contracts.sh newcomer contract → require curl one-liner + 4 canonical ids; forbid private tarball URL; index.html fixed

### Invariants (ENG-ADR-087)

No secrets; least-privilege device-flow; pinned ref (GFT_ONBOARDING_REF, default main); idempotent; delegate gft install to orchestrator; safe non-interactive default (base set + usage, exit 0).

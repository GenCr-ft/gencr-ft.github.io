---
docId: GOV-PLAN-38
title: "[CODE] onboard.sh reclone-on-ref-mismatch (upgrade re-run fix)"
status: approved
issue-id: GenCr-ft/gencr-ft.github.io#38
---

## [CODE] clone_orchestrator: fast-path or re-clone

Parent gcs-project-management#377; regression of #26/#37.

- [x] Fix: fast-path if HEAD == pinned tag commit; else rm -rf + fresh clone at the tag (fixes shallow `git fetch <tag>` pitfall)
- [x] Regression test (check #9) — existing clone at wrong ref → re-clone
- [x] Verified END-TO-END against the real v1.0.0 clone → re-cloned to v1.0.1 (591e7a8)

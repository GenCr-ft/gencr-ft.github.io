---
docId: GOV-PLAN-36
title: "[CODE] Fix onboard.sh cd crash (log→stdout), workspace prompt, and UX"
status: approved
issue-id: GenCr-ft/gencr-ft.github.io#36
---

## [CODE] onboard.sh P0 fix (regression of #26)

Parent Initiative gcs-project-management#377. ENG-ADR-087.

### TDD Cycles

- [x] RED: test_onboard.sh checks 7/8 — log/warn must not write stdout; clone_orchestrator stdout is a clean path
- [ ] GREEN: log()/warn() → stderr; select_workspace prompts on readable+writable /dev/tty (not [ -t 1 ]); suppress detached-HEAD advice; friendly completion summary (gft location, gft doctor, repos path, restart shell)

### Notes

Root cause: `log()` wrote to stdout; `dest="$(clone_orchestrator)"` captured the log line → `cd` failed. Discovered by a real `curl | bash` run — unit tests + shellcheck missed it because they never exercised the capture path.

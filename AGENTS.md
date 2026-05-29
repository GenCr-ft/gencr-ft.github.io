---
docId: DEV-AGNT-002
title: AGENTS.md - gencr-ft.github.io
version: 1.0.0
authors:
- GenCr@ft Studio
creation_date: '2026-05-25'
last_updated_date: 2026-05-29
language: en
summary: Authoritative onboarding and workspace contract pointers for AI agents in gencr-ft.github.io.
metadata:
  lifecycle-stage: approved
  scope: studio-wide
  domain: engineering
  doc-type: onboarding-guide
  security-classification: l2_confidential
---
# AGENTS.md — gencr-ft.github.io

> **Read this file first.** This is the authoritative onboarding guide for any contributor — human or AI — starting work in this website repository. It points directly to computable active contracts.

---

## 1. Project Overview & Active State

Public GitHub Pages landing site for GenCr@ft Studio, served at `https://gencr-ft.github.io`.
- **Stack**: Static Jekyll (tactile theme).
- **Status**: Active development.
- **Unified Contract**: [project-state.json](project-state.json)
- **Active Validator**: [scripts/verify-contracts.sh](scripts/verify-contracts.sh)

---

## 2. Developer Operations & Key Commands

- **Onboarding**: `bash ./onboard.sh`
- **Testing & Verification**: `bash ./test.sh`
- **Local Preview**:
  ```bash
  python3 -m http.server 8080
  # Open http://localhost:8080
  ```

---

## 3. Architecture & Key Directories

```
gencr-ft.github.io/
  index.html            — landing page (English, main content updates)
  _config.yml           — Jekyll theme config
  project-state.json    — Unified Active Contract metadata
  scripts/
    validate_html.py    — Python-based HTML parser validator
    verify-contracts.sh — Programmatic contract validator
```

---

## 4. Governance & Constraints

- **Language**: English only across all files. No other language comments (e.g. no French in configuration comments).
- **CI/CD Integration**: Strict linter gates (`continue-on-error: false`) run on every PR/push.
- **Commit & PR Conventions**: Enforced by commitlint. Branches must conform strictly to `feat/issue-ID-slug` and `fix/issue-ID-slug`.
- **Gap Protocol Reference**: All issues must be logged immediately and added to Project #16.
- **Co-author trailer**: Strictly prohibited in this workspace due to administrative blocks. Do NOT write or push commits containing the `Co-Authored-By` trailer.

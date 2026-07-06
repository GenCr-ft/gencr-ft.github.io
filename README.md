---
docId: DEV-READ-002
title: gencr-ft.github.io
version: 0.1.0
authors:
- GenCr@ft Studio
reviewers:
- GenCr@ft Studio
creation_date: '2026-04-28'
language: en
summary: Public GitHub Pages site for GenCr@ft Studio, serving as the external web
  presence at https://gencr-ft.github.io.
last_updated_date: '2026-07-06'
metadata:
  lifecycle-stage: draft
  keywords:
  - gencraft-studio
  - aethel
  - voxel-rpg
  - indie-game
  - game-development
  - github-pages
  scope: studio
  domain: devops
  doc-type: readme
  intended-audience:
  - contributors
  - ai-agents
  - governance-team
  - project-leads
  security-classification: l2_confidential
knowledgeGuardian: "Édouard (GCT-DVO-DVSST-001)"
---
# gencr-ft.github.io

> Public GitHub Pages site for GenCr@ft Studio, accessible at [https://gencr-ft.github.io](https://gencr-ft.github.io).

## Start Here

`AGENTS.md` is the repo-local authority and the first read for agents.

`index.html` is the main content surface. `project-state.json` is the unified
contract metadata. Use the validators in `scripts/` to check site contracts and
HTML before proposing changes.

## Surface Map

| Surface | Role | Notes |
| --- | --- | --- |
| `AGENTS.md` | Repo authority | First read for any contributor or agent |
| `README.md` | Human-facing summary | Quick orientation only |
| `index.html` | Main site content | The public landing page |
| `_config.yml` | Jekyll config | Theme and site settings |
| `project-state.json` | Active contract metadata | Unified site contract source |
| `scripts/verify-contracts.sh` | Contract validator | Programmatic validator |
| `scripts/validate_html.py` | HTML validator | Checks site HTML structure |

## Command Matrix

| Task | Command | Result |
| --- | --- | --- |
| Public studio onboarding (newcomers) | `curl -fsSL https://gencr-ft.github.io/onboard.sh \| bash` | One-line studio bootstrap: prerequisites, `gh` device-login, clones the pinned onboarding orchestrator, sets up your workspace (ENG-ADR-087). Served from this repo's `onboard.sh`. |
| Local dev setup (this repo's contributors) | `pre-commit install --install-hooks` | Installs this repo's pre-commit hooks. |
| Test | `bash ./test.sh` | Runs the repo test suite |
| Preview locally | `python3 -m http.server 8080` | Serves the site for browser preview |
| Validate contracts | `bash scripts/verify-contracts.sh` | Runs the active contract validator |
| Validate HTML | `python3 scripts/validate_html.py` | Checks the site HTML |

## Generated / No-Edit Surfaces

- `project-state.json` is contract metadata; update it through the approved flow.
- Generated or compiled site artifacts should not be edited directly.
- Keep the README as navigation, and edit `index.html` for actual site content.

## Overview

This repository hosts the external-facing website for GenCr@ft Studio. It is a static site served via GitHub Pages, currently presenting a placeholder landing page while the studio is in early development.

## Index of Contents

### Files

- `index.html`: The main landing page (English).
- `_config.yml`: Jekyll configuration (no theme; `index.html` uses `layout: null`).
- `README.md`: This document.

## Getting Started

This is a static HTML site with no build step required. To preview locally:

```sh
git clone https://github.com/GenCr-ft/gencr-ft.github.io.git
cd gencr-ft.github.io
# Open index.html directly in a browser, or serve with any static file server:
python3 -m http.server 8080
```

## Contributing

All changes are proposed via Pull Requests. See the organization-wide [CONTRIBUTING.md](https://github.com/GenCr-ft/.github/blob/main/CONTRIBUTING.md) for standards.

## AI Instructions

**Purpose for AI Agents:**

- Use the `docId` (`DEV-READ-002`) for direct reference and in all traceability records.
- This repository contains a single HTML page served publicly as the studio's external web presence.
- When updating site content, edit `index.html`. The site language must be English.

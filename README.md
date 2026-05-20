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
last_updated_date: '2026-05-20'
metadata:
  lifecycle-stage: draft
  keywords:
  - tag1
  - tag2
  - project
  scope: studio
  domain: devops
  doc-type: readme
  intended-audience:
  - contributors
  - ai-agents
  - governance-team
  - project-leads
  security-classification: l2_confidential
knowledgeGuardian:
- "\xC9douard (GCT-DVO-DVSST-001)"
---
# gencr-ft.github.io

> Public GitHub Pages site for GenCr@ft Studio, accessible at [https://gencr-ft.github.io](https://gencr-ft.github.io).

## Overview

This repository hosts the external-facing website for GenCr@ft Studio. It is a static site served via GitHub Pages, currently presenting a placeholder landing page while the studio is in early development.

## Index of Contents

### Files

- `index.html`: The main landing page (English).
- `_config.yml`: Jekyll configuration (theme: tactile).
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

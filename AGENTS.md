# AGENTS.md — gencr-ft.github.io

## Project Overview

Public GitHub Pages landing site for GenCr@ft Studio, served at `https://gencr-ft.github.io`. Static HTML (Jekyll theme: tactile) presenting the studio's external web presence. Contains a single landing page describing Aethel and linking to the GitHub org. No build step required.

## Setup

```bash
git clone https://github.com/GenCr-ft/gencr-ft.github.io.git
cd gencr-ft.github.io
# Preview locally (no build needed):
python3 -m http.server 8080
# Then open http://localhost:8080
```

## Development

Edit `index.html` directly for content changes. The Jekyll `_config.yml` sets `theme: tactile` and is used by GitHub Pages automatically — no local Jekyll install needed for simple edits.

## Build

No build step. GitHub Pages deploys directly from the `main` branch on push.

## Linting & Formatting

Pre-commit hooks run markdownlint and yamllint on Markdown/YAML files. Commitlint enforces Conventional Commits:
```bash
npx commitlint --from HEAD~1
```

## Architecture & Key Directories

```
gencr-ft.github.io/
  index.html      — landing page (English, edit here for content updates)
  _config.yml     — Jekyll theme config (tactile)
  README.md       — repo documentation
```

## CI/CD & Required Checks

SSoT compliance workflow validates frontmatter on Markdown files on push/PR.

## Commit & PR Conventions

- Conventional Commits v1.0.0 — enforced by commitlint.
- Branch naming: `feat/`, `fix/`, `docs/`, `chore/`.
- Every PR requires a linked GitHub Issue.
- AI commits: `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>`

## Notes for Agents

- Site language must be **English only**.
- Keep content consistent with the studio's public messaging — no internal roadmap, financial, or confidential information in `index.html`.
- All Markdown files must carry valid SSoT YAML frontmatter.
- Do not add build tooling (webpack, npm scripts, etc.) without an ADR or explicit instruction.

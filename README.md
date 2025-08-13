# Deploy Wars

A complete end-to-end **DevOps demo project** that showcases automation, scripting, logging, and CI/CD — wrapped in a fun, turn-based **Bash battle game** where **DevOps** fights **Developer**.

## Features

- Pure **Bash** implementation; no external runtimes.
- Two players with **unique attack sets** stored in arrays.
- **Random attack** and **random damage (10–25)** each turn.
- Alternating turns until someone’s **HP reaches 0**.
- **Color-coded** terminal output (falls back gracefully when colors unsupported).
- **Battle logs** saved with timestamps to `logs/` (unique filename per run).
- Robust **error handling** + comments.
- **GitHub Actions** workflow that runs the game on every push to `main` and **commits generated logs back** to the repo.

## Quick Start

```bash
git clone <your-fork-url>.git
cd deploy-wars
chmod +x deploy_wars.sh
./deploy_wars.sh         # interactive
# or
./deploy_wars.sh --no-prompt  # non-interactive
```

A log file will be created in `logs/` like `battle_YYYYMMDD_HHMMSS_PID.log`.

## GitHub Actions CI

This repository includes `.github/workflows/deploy-wars.yml` which:

1. Triggers on pushes to `main`.
2. Runs the game non-interactively.
3. Commits **new** log files back to the repo.

### Important

- The workflow sets `permissions: contents: write` so it can push using the `GITHUB_TOKEN`.
- The job is skipped if the commit message contains **`[skip ci]`** to avoid endless loops. The workflow itself commits with `[skip ci]`.
- `actions/checkout@v4` uses `fetch-depth: 0` so pushes back succeed.

## Project Structure

```
deploy-wars/
├── deploy_wars.sh                 # Main Bash game (executable)
├── logs/                          # Auto-generated battle logs
├── .github/
│   └── workflows/
│       └── deploy-wars.yml        # CI to run the game and commit logs
├── .gitignore
└── README.md
```

## Troubleshooting

- **shuf: command not found** (macOS): The script auto-falls back to `jot` (available on macOS). If neither exists, it uses `$RANDOM` as a last resort.
- **Workflow cannot push**: Ensure your repo allows `GITHUB_TOKEN` to write. In the repo settings, make sure Actions are enabled and the default workflow permissions include **Read and write** (or keep `permissions: contents: write` in the workflow).
- **Color output looks odd**: Set `FORCE_COLOR=0` to disable colors or run in a terminal that supports ANSI colors.

## DevOps Concepts Demonstrated

- **Automation & Scripting**: Entire game in Bash with modular functions and defensive scripting (`set -Eeuo pipefail`, `trap`).
- **Observability**: Structured logs with timestamps per action.
- **CI/CD**: Workflow that runs on push and persists artifacts (logs) to the repo.
- **Idempotency**: Safe re-runs; logs are uniquely named; CI avoids infinite loops via `[skip ci]`.

## License

MIT (or your choice)

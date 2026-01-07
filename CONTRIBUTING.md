# Contributing

Thanks for considering contributing.

## Workflow

1) Create a feature branch.
2) Make changes with clear, focused commits.
3) Ensure checks pass locally.
4) Open a PR with context and testing notes.

## Local Checks

```bash
make fmt
make validate
make lint
make security
make docs
make test
```

## Pre-commit

Install pre-commit and hooks:

```bash
pre-commit install
```

## Style

- Prefer small, composable modules.
- Keep variables and outputs explicit with validations.
- Document decisions and security implications.

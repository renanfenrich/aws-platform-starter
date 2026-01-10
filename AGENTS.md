# AGENTS.md

This file is the “README for agents”. Codex (and other coding agents) must read this before making changes. Keep instructions concrete, repo-specific, and runnable.

## Project intent (human tone)
This repository is my AWS infrastructure portfolio project. It is intentionally small in scope, but strict about correctness, security defaults, and operational clarity. Every change must preserve:
- Clear module boundaries and readable Terraform
- Safe-by-default security posture
- Reproducible workflows (no “click in the AWS console” steps unless explicitly documented as unavoidable)
- Documentation that sounds like an engineer explaining real trade-offs

## Agent operating rules
1) Prefer minimal diffs. Don’t refactor unless required.
2) No invented features. Implement only what the task requests.
3) No console hand-waving. If AWS prerequisites exist, create a Terraform bootstrap stack or document why it must remain manual.
4) Don’t commit secrets, state files, or local configs.
5) Run checks before concluding. If you can’t run something, say exactly what you didn’t run and why.

Codex reads the closest AGENTS.md relative to files it changes. If you add sub-project rules, place nested AGENTS.md files inside that subdirectory.

## Repo structure (expected)
- `bootstrap/`   : One-time or per-account/per-region prerequisites (state bucket with native locking, KMS, SNS topic, etc.)
- `environments/`: `dev/` and `prod/` root stacks wiring modules together
- `modules/`     : Focused Terraform modules (networking, compute, data, observability, etc.)
- `docs/`        : Architecture, decisions, runbook, Well-Architected mapping
- `tests/`       : Plan-based assertions or terraform test / terratest (minimal but real)
- `.github/`     : CI workflow and any repo instruction files

## Canonical commands
Use these commands exactly (don’t guess other tooling).
- Format:
  - `make fmt`
- Validate:
  - `make validate`
- Lint / security:
  - `make lint`
- Docs generation/check:
  - `make docs`
  - `make docs-check`
- Cost estimate:
  - `make cost`
- Tests:
  - `make test`
- Plan/apply:
  - `make plan ENV=dev platform=ecs`
  - `make apply ENV=dev platform=ecs`
If Makefile targets differ, update this section to match the repo. Do not introduce new command conventions without updating docs.

### Terraform validation in CI
CI should validate without requiring a real backend. Use `terraform init -backend=false` where necessary. Keep local and CI behavior aligned.

## Terraform conventions
- Terraform: pin to the repo’s minimum supported version (do not silently raise it).
- Providers: pinned versions with explicit constraints.
- Modules:
  - One module = one responsibility.
  - Inputs validated (type + validation blocks).
  - Outputs intentionally designed (no “dump everything” outputs).
  - Avoid “god modules” and avoid deeply nested abstractions.
- Naming:
  - Use existing `name_prefix`/`tags`/`locals` conventions.
  - Every AWS resource must be tagged consistently.
- Safety:
  - Prod safeguards are opt-in by environment defaults (e.g., deletion protection, prevent_destroy where appropriate).
  - Avoid destructive changes unless the task explicitly requests them.

## Security baseline (non-negotiable)
- No public SSH. Prefer SSM if access is needed; keep it opt-in.
- Enforce encryption where relevant (RDS, S3 state, SNS topic if created).
- IAM is least privilege; prefer scoped ARNs over `*`.
- Secrets are stored in AWS Secrets Manager or SSM Parameter Store (encrypted), never in git.

## Platform selectors and “modes”
When adding “choose between options” functionality:
- Use a single validated selector variable with clear allowed values.
- Keep stable outputs across modes so environment wiring doesn’t fork.
- Document operational differences in `docs/runbook.md` and trade-offs in `docs/decisions.md`.

## Documentation standards (sound like me)
Docs must be:
- Direct, technical, and specific
- Honest about trade-offs and limitations
- Free of marketing filler unless backed by concrete details
Update docs alongside code changes, not afterwards.

## Bootstrap policy (avoid AWS console)
If any setup is currently manual, prefer a Terraform `bootstrap/` stack. Common bootstrap items:
- Terraform state S3 bucket (native locking) + KMS key
- SNS topic for alarm notifications
- Optional: ECR repo for demo app
Keep bootstrap safe:
- Require explicit variables for anything high-impact.
- Document destroy risks (state bucket especially).

## Tests policy
- Tests should be minimal but meaningful:
  - Plan-based assertions are acceptable if apply is too heavy.
  - Cover selectors/modes so regressions are caught.
- If adding new modules or modes, update tests in the same PR.

## PR/commit hygiene
- Use Conventional Commits.
- Milestone commits over micro-commits.
- Every commit must keep the repo in a buildable/validatable state when feasible.

## Context management (to avoid giant chats)
When starting a new Codex run or a new chat:
- Provide only the task, constraints, and the relevant paths.
- Point Codex to this file and the exact commands to run.
- Close irrelevant files in the editor and keep only the needed files open.

## If you’re unsure
Do not ask questions unless you truly cannot proceed. Instead:
- Make the safest assumption
- Document it in `docs/decisions.md`
- Keep the change small and reversible

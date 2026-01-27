# Testing Scaffolding (Examples)

This folder is a lightweight guide for adding new tests. It does not run anything by itself.

## Terraform native tests (preferred)

Use `terraform test` for most module and stack checks because it runs without AWS credentials when you use mock providers.

Where to add tests:
- Module tests: `modules/<name>/*.tftest.hcl`
- Stack tests: `tests/terraform/*.tftest.hcl`

Minimal test shape:

```hcl
run "plan" {
  command = plan

  variables = {
    # set only what you need for the assertion
  }

  assert {
    condition     = true
    error_message = "replace with a real assertion"
  }
}
```

After adding tests, ensure they are covered by `make test` (the Makefile explicitly lists module test directories).

## Terratest (optional, for real AWS integration)

Use Terratest only when you need to validate real AWS API behavior or runtime properties.

Suggested layout (not created here):
- `tests/terratest/` with a small Go module
- Environment setup/teardown in `*_test.go`

Guidelines:
- Keep tests focused on one behavior.
- Clean up resources reliably (defer destroy).
- Use low-cost instance types and short timeouts.

## Kitchen-style integration (rare)

Only use full environment tests when you need to validate a complete deployment path. These are slower and require careful cleanup and cost controls.

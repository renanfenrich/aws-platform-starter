#!/usr/bin/env bash
set -euo pipefail

report_path="${1:-infracost-report.json}"
dev_tfvars="${2:-environments/dev/terraform.tfvars}"
prod_tfvars="${3:-environments/prod/terraform.tfvars}"

if [[ ! -f "$report_path" ]]; then
  echo "Infracost report not found at $report_path" >&2
  exit 1
fi

read_tfvar() {
  local file="$1"
  local key="$2"

  awk -F '=' -v key="$key" '
    $1 ~ "^[[:space:]]*"key"[[:space:]]*$" {
      gsub(/[[:space:]]/, "", $2)
      print $2
      exit
    }
  ' "$file"
}

project_cost() {
  local project="$1"

  jq -r --arg name "$project" '
    .projects[]
    | select(.name == $name)
    | (.summary.totalMonthlyCost // .summary.total_monthly_cost // .summary.total_monthly_cost // "0")
  ' "$report_path"
}

dev_cost="$(project_cost dev)"
prod_cost="$(project_cost prod)"

dev_budget_limit="$(read_tfvar "$dev_tfvars" "budget_limit_usd")"
dev_budget_warn="$(read_tfvar "$dev_tfvars" "budget_warning_threshold_percent")"
dev_budget_hard="$(read_tfvar "$dev_tfvars" "budget_hard_limit_percent")"

prod_budget_limit="$(read_tfvar "$prod_tfvars" "budget_limit_usd")"
prod_budget_warn="$(read_tfvar "$prod_tfvars" "budget_warning_threshold_percent")"
prod_budget_hard="$(read_tfvar "$prod_tfvars" "budget_hard_limit_percent")"

dev_hard_limit_usd="$(awk -v limit="$dev_budget_limit" -v pct="$dev_budget_hard" 'BEGIN { printf "%.2f", limit * pct / 100 }')"
prod_hard_limit_usd="$(awk -v limit="$prod_budget_limit" -v pct="$prod_budget_hard" 'BEGIN { printf "%.2f", limit * pct / 100 }')"

summary_header="| Environment | Est. Monthly Cost (USD) | Budget Limit (USD) | Warn % | Hard % | Hard Limit (USD) | Status |\n| --- | --- | --- | --- | --- | --- | --- |"
dev_status="ok"
prod_status="ok"
failure_messages=()

if awk -v cost="$dev_cost" -v hard="$dev_hard_limit_usd" 'BEGIN { exit !(cost > hard) }'; then
  dev_status="exceeds hard limit"
  failure_messages+=("dev estimate ${dev_cost} exceeds hard limit ${dev_hard_limit_usd}")
fi

if awk -v cost="$prod_cost" -v hard="$prod_hard_limit_usd" 'BEGIN { exit !(cost > hard) }'; then
  prod_status="exceeds hard limit"
  failure_messages+=("prod estimate ${prod_cost} exceeds hard limit ${prod_hard_limit_usd}")
fi

summary_rows="| dev | ${dev_cost} | ${dev_budget_limit} | ${dev_budget_warn}% | ${dev_budget_hard}% | ${dev_hard_limit_usd} | ${dev_status} |\n| prod | ${prod_cost} | ${prod_budget_limit} | ${prod_budget_warn}% | ${prod_budget_hard}% | ${prod_hard_limit_usd} | ${prod_status} |"

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "## FinOps Cost Summary"
    echo ""
    echo -e "$summary_header"
    echo -e "$summary_rows"
  } >> "$GITHUB_STEP_SUMMARY"
fi

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "dev_estimated_monthly_cost=${dev_cost}"
    echo "prod_estimated_monthly_cost=${prod_cost}"
    echo "dev_budget_limit_usd=${dev_budget_limit}"
    echo "prod_budget_limit_usd=${prod_budget_limit}"
  } >> "$GITHUB_OUTPUT"
fi

if (( ${#failure_messages[@]} > 0 )); then
  printf "Cost enforcement failed: %s\n" "${failure_messages[@]}" >&2
  exit 1
fi

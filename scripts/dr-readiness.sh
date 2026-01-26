#!/usr/bin/env bash
set -euo pipefail

primary_dir="${1:-environments/prod}"
dr_dir="${2:-environments/dr}"

read_tfvar() {
  local file="$1"
  local key="$2"

  awk -F '=' -v key="$key" '
    $1 ~ "^[[:space:]]*"key"[[:space:]]*$" {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
      gsub(/^"|"$/, "", $2)
      print $2
      exit
    }
  ' "$file"
}

primary_tfvars="$primary_dir/terraform.tfvars"
dr_tfvars="$dr_dir/terraform.tfvars"

if [[ ! -f "$primary_tfvars" ]]; then
  echo "Missing tfvars: $primary_tfvars" >&2
  exit 1
fi

if [[ ! -f "$dr_tfvars" ]]; then
  echo "Missing tfvars: $dr_tfvars" >&2
  exit 1
fi

primary_region="$(read_tfvar "$primary_tfvars" "aws_region")"
dr_region="$(read_tfvar "$dr_tfvars" "aws_region")"
project_name="$(read_tfvar "$primary_tfvars" "project_name")"
primary_env="$(read_tfvar "$primary_tfvars" "environment")"
service_name="$(read_tfvar "$primary_tfvars" "service_name")"

ecr_repo_name="${project_name}-${primary_env}-${service_name}"
rds_instance_id="${project_name}-${primary_env}-db"

if [[ -z "$primary_region" || -z "$dr_region" ]]; then
  echo "aws_region must be set in both $primary_tfvars and $dr_tfvars" >&2
  exit 1
fi

if ! command -v aws >/dev/null 2>&1; then
  echo "AWS CLI is required for DR readiness checks." >&2
  exit 1
fi

status=0

printf "DR readiness checks (primary=%s, dr=%s)\n" "$primary_region" "$dr_region"

# ECR replication configuration
replication_json="$(aws ecr describe-replication-configuration --region "$primary_region" 2>/dev/null || echo '{}')"
python3 - <<PY
import json, sys
config = json.loads('''$replication_json''')
replication = config.get('replicationConfiguration', {}).get('rules', [])
regions = {d.get('region') for r in replication for d in r.get('destinations', [])}
filters = [f.get('filter') for r in replication for f in r.get('repositoryFilters', [])]
repo = "$ecr_repo_name"
dr_region = "$dr_region"
missing = []
if dr_region not in regions:
    missing.append(f"missing replication destination {dr_region}")
if filters and repo not in filters:
    missing.append(f"missing repository filter {repo}")
if missing:
    print("ECR replication: FAIL - " + ", ".join(missing))
    sys.exit(1)
print("ECR replication: OK")
PY
if [[ $? -ne 0 ]]; then
  status=1
fi

# ECR images present in DR region
if aws ecr describe-repositories --region "$dr_region" --repository-names "$ecr_repo_name" >/dev/null 2>&1; then
  images_json="$(aws ecr describe-images --region "$dr_region" --repository-name "$ecr_repo_name" 2>/dev/null || echo '{}')"
  python3 - <<PY
import json, sys
images = json.loads('''$images_json''').get('imageDetails', [])
if len(images) == 0:
    print("ECR images in DR: WARN - repository exists but no images replicated")
    sys.exit(2)
print("ECR images in DR: OK")
PY
  rc=$?
  if [[ $rc -eq 2 ]]; then
    status=1
  elif [[ $rc -ne 0 ]]; then
    status=1
  fi
else
  echo "ECR images in DR: FAIL - repository $ecr_repo_name not found in $dr_region"
  status=1
fi

# RDS automated snapshots in primary
snapshots_json="$(aws rds describe-db-snapshots --region "$primary_region" --db-instance-identifier "$rds_instance_id" --snapshot-type automated --max-records 20 2>/dev/null || echo '{}')"
python3 - <<PY
import json, sys
snaps = json.loads('''$snapshots_json''').get('DBSnapshots', [])
if len(snaps) == 0:
    print("RDS backups in primary: FAIL - no automated snapshots found")
    sys.exit(1)
print("RDS backups in primary: OK")
PY
if [[ $? -ne 0 ]]; then
  status=1
fi

# AWS Backup copy check (if configured)
backup_enabled="$(read_tfvar "$primary_tfvars" "enable_rds_backup")"
backup_copy_vault_arn="$(read_tfvar "$primary_tfvars" "rds_backup_copy_destination_vault_arn")"

if [[ "${backup_enabled}" == "true" && -n "${backup_copy_vault_arn}" ]]; then
  backup_vault_name="${backup_copy_vault_arn##*:}"
  recovery_json="$(aws backup list-recovery-points-by-backup-vault --region "$dr_region" --backup-vault-name "$backup_vault_name" 2>/dev/null || echo '{}')"
  python3 - <<PY
import json, sys
recovery = json.loads('''$recovery_json''').get('RecoveryPoints', [])
if len(recovery) == 0:
    print("RDS backups in DR vault: FAIL - no recovery points found")
    sys.exit(1)
print("RDS backups in DR vault: OK")
PY
  if [[ $? -ne 0 ]]; then
    status=1
  fi
else
  echo "RDS backups in DR vault: SKIP - enable_rds_backup=false or no destination vault ARN set"
fi

if [[ $status -ne 0 ]]; then
  echo "DR readiness checks failed." >&2
  exit 1
fi

echo "DR readiness checks passed."

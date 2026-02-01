#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
POLICY_DIR="$ROOT_DIR/policy/kubernetes/rego"
POLICY_TEST_DIR="$ROOT_DIR/policy/kubernetes/tests"
YAMLLINT_CONFIG="$ROOT_DIR/scripts/kubernetes/yamllint.yaml"
MODE="${1:-all}"
K8S_VERSION="${K8S_VERSION:-1.29.2}"

cd "$ROOT_DIR"

require_tool() {
  local tool="$1"
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing required tool: $tool" >&2
    return 1
  fi
}

kustomize_build() {
  local dir="$1"
  if command -v kustomize >/dev/null 2>&1; then
    kustomize build "$dir"
    return
  fi

  if command -v kubectl >/dev/null 2>&1; then
    kubectl kustomize "$dir"
    return
  fi

  echo "Missing required tool: kustomize or kubectl" >&2
  return 1
}

unique_dirs() {
  awk '!seen[$0]++'
}

rg_files() {
  local pattern="$1"
  if command -v rg >/dev/null 2>&1; then
    rg --files \
      -g "$pattern" \
      -g '!**/.terraform/**' \
      -g '!**/node_modules/**' \
      -g '!**/vendor/**' \
      -g '!**/dist/**' \
      -g '!**/build/**'
  else
    find . \
      -path './.terraform' -prune -o \
      -path './node_modules' -prune -o \
      -path './vendor' -prune -o \
      -path './dist' -prune -o \
      -path './build' -prune -o \
      -name "$pattern" -print
  fi
}

discover_kustomize_dirs() {
  local files=()
  while IFS= read -r file; do
    files+=("$file")
  done < <(rg_files 'kustomization.yaml' ; rg_files 'kustomization.yml')

  if [ ${#files[@]} -eq 0 ]; then
    return 0
  fi

  for file in "${files[@]}"; do
    dirname "$file"
  done | unique_dirs
}

discover_helm_dirs() {
  local files=()
  while IFS= read -r file; do
    files+=("$file")
  done < <(rg_files 'Chart.yaml')

  if [ ${#files[@]} -eq 0 ]; then
    return 0
  fi

  for file in "${files[@]}"; do
    dirname "$file"
  done | unique_dirs
}

select_kustomize_targets() {
  local overlays=()
  local clusters=()

  for dir in "$@"; do
    if [[ "$dir" == *"/clusters/"* ]]; then
      clusters+=("$dir")
    elif [[ "$dir" == *"/overlays/"* ]]; then
      overlays+=("$dir")
    fi
  done

  if [ ${#clusters[@]} -gt 0 ]; then
    printf '%s\n' "${clusters[@]}"
    if [ ${#overlays[@]} -gt 0 ]; then
      printf '%s\n' "${overlays[@]}"
    fi
    return
  fi

  if [ ${#overlays[@]} -gt 0 ]; then
    printf '%s\n' "${overlays[@]}"
  else
    printf '%s\n' "$@"
  fi
}

collect_yaml_files() {
  local dirs=("$@")
  local files=()

  for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
      while IFS= read -r -d '' file; do
        files+=("$file")
      done < <(find "$dir" -type f \( -name '*.yaml' -o -name '*.yml' \) -print0)
    fi
  done

  if [ ${#files[@]} -eq 0 ]; then
    return 0
  fi

  printf '%s\n' "${files[@]}" | unique_dirs
}

run_fmt() {
  require_tool yamllint

  local files=()
  while IFS= read -r file; do
    files+=("$file")
  done < <(collect_yaml_files "${KUSTOMIZE_DIRS[@]}" "${HELM_DIRS[@]}")

  if [ ${#files[@]} -eq 0 ]; then
    echo "No YAML files found for k8s-fmt."
    return 0
  fi

  yamllint -c "$YAMLLINT_CONFIG" "${files[@]}"
}

run_lint() {
  require_tool yamllint

  local files=()
  while IFS= read -r file; do
    files+=("$file")
  done < <(collect_yaml_files "${KUSTOMIZE_DIRS[@]}" "${HELM_DIRS[@]}")

  if [ ${#files[@]} -eq 0 ]; then
    echo "No YAML files found for k8s-lint."
    return 0
  fi

  yamllint -c "$YAMLLINT_CONFIG" "${files[@]}"

  if [ ${#HELM_DIRS[@]} -gt 0 ]; then
    require_tool helm
    for dir in "${HELM_DIRS[@]}"; do
      helm lint "$dir"
    done
  fi
}

run_validate() {
  require_tool kubeconform

  if [ ${#KUSTOMIZE_TARGETS[@]} -gt 0 ]; then
    for dir in "${KUSTOMIZE_TARGETS[@]}"; do
      echo "Validating Kustomize: $dir"
      kustomize_build "$dir" | kubeconform \
        -summary \
        -strict \
        -ignore-missing-schemas \
        -kubernetes-version "$K8S_VERSION"
    done
  fi

  if [ ${#HELM_DIRS[@]} -gt 0 ]; then
    require_tool helm
    for dir in "${HELM_DIRS[@]}"; do
      echo "Validating Helm chart: $dir"
      helm template "$dir" | kubeconform \
        -summary \
        -strict \
        -ignore-missing-schemas \
        -kubernetes-version "$K8S_VERSION"
    done
  fi
}

run_policy() {
  require_tool conftest

  if [ ${#KUSTOMIZE_TARGETS[@]} -gt 0 ]; then
    for dir in "${KUSTOMIZE_TARGETS[@]}"; do
      echo "Policy check (kustomize): $dir"
      kustomize_build "$dir" | conftest test -p "$POLICY_DIR" --namespace kubernetes.policy -
    done
  fi

  if [ ${#HELM_DIRS[@]} -gt 0 ]; then
    require_tool helm
    for dir in "${HELM_DIRS[@]}"; do
      echo "Policy check (helm): $dir"
      helm template "$dir" | conftest test -p "$POLICY_DIR" --namespace kubernetes.policy -
    done
  fi

  echo "Policy unit tests: $POLICY_TEST_DIR"
  conftest verify -p "$POLICY_DIR" -p "$POLICY_TEST_DIR"
}

run_sec() {
  require_tool conftest

  if [ ${#KUSTOMIZE_TARGETS[@]} -gt 0 ]; then
    for dir in "${KUSTOMIZE_TARGETS[@]}"; do
      echo "Security check (kustomize): $dir"
      kustomize_build "$dir" | conftest test -p "$POLICY_DIR" --namespace kubernetes.security -
    done
  fi

  if [ ${#HELM_DIRS[@]} -gt 0 ]; then
    require_tool helm
    for dir in "${HELM_DIRS[@]}"; do
      echo "Security check (helm): $dir"
      helm template "$dir" | conftest test -p "$POLICY_DIR" --namespace kubernetes.security -
    done
  fi
}

mapfile -t KUSTOMIZE_DIRS < <(discover_kustomize_dirs)
mapfile -t HELM_DIRS < <(discover_helm_dirs)

mapfile -t KUSTOMIZE_TARGETS < <(select_kustomize_targets "${KUSTOMIZE_DIRS[@]}")

if [ ${#KUSTOMIZE_DIRS[@]} -eq 0 ] && [ ${#HELM_DIRS[@]} -eq 0 ]; then
  echo "No Kubernetes manifest roots found."
  exit 0
fi

case "$MODE" in
  fmt)
    run_fmt
    ;;
  lint)
    run_lint
    ;;
  validate)
    run_validate
    ;;
  policy)
    run_policy
    ;;
  sec)
    run_sec
    ;;
  all)
    run_fmt
    run_validate
    run_lint
    run_policy
    run_sec
    ;;
  *)
    echo "Usage: $0 [fmt|validate|lint|policy|sec|all]" >&2
    exit 1
    ;;
esac

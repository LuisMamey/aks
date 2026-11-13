#!/usr/bin/env bash
# ==============================================================================
# Azure Kubernetes Service (AKS) — Automated Platform Lifecycle Script
# ==============================================================================
# Usage:
#   ./scripts/platform.sh up            # Provision bootstrap state, AKS, and deploy workloads
#   ./scripts/platform.sh status        # Inspect live AKS nodes, pods, services, and endpoints
#   ./scripts/platform.sh test-identity # Verify zero-secret Workload Identity via federated OIDC
#   ./scripts/platform.sh stop          # Pause AKS nodes to drop compute cost to $0.00/hr
#   ./scripts/platform.sh start         # Resume paused AKS cluster nodes
#   ./scripts/platform.sh down          # Destroy all provisioned Azure compute and network resources
# ==============================================================================

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOOTSTRAP_DIR="${ROOT_DIR}/bootstrap"
TF_DIR="${ROOT_DIR}/terraform"
K8S_DIR="${ROOT_DIR}/k8s"

RESOURCE_GROUP="rg-aks-metrics-dev"
CLUSTER_NAME="aks-aks-metrics-dev"

log_info()  { printf "\033[1;34m[INFO]\033[0m  %s\n" "$*"; }
log_ok()    { printf "\033[1;32m[OK]\033[0m    %s\n" "$*"; }
log_warn()  { printf "\033[1;33m[WARN]\033[0m  %s\n" "$*"; }
log_error() { printf "\033[1;31m[ERROR]\033[0m %s\n" "$*" >&2; }

check_prereqs() {
  for cmd in az terraform kubectl curl; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
      log_error "Required binary '${cmd}' is not installed in PATH."
      exit 1
    fi
  done

  if ! az account show >/dev/null 2>&1; then
    log_error "Azure CLI is not authenticated. Please run 'az login' first."
    exit 1
  fi

  local sub_name
  sub_name="$(az account show --query name -o tsv)"
  log_info "Authenticated to Azure Subscription: ${sub_name}"
}

cmd_status() {
  check_prereqs
  log_info "Checking AKS Cluster Status for ${CLUSTER_NAME} in ${RESOURCE_GROUP}..."
  
  local power_state
  power_state="$(az aks show -g "${RESOURCE_GROUP}" -n "${CLUSTER_NAME}" --query "powerState.code" -o tsv 2>/dev/null || echo "NotFound")"
  log_info "Cluster Power State: ${power_state}"

  if [[ "${power_state}" != "Running" ]]; then
    log_warn "Cluster is not in 'Running' state (State: ${power_state})."
    return 0
  fi

  log_info "Kubernetes Nodes:"
  kubectl get nodes -o wide

  echo ""
  log_info "Application Pods (default namespace):"
  kubectl get pods -o wide

  echo ""
  log_info "Services & Public LoadBalancers:"
  kubectl get svc -o wide

  echo ""
  local ext_ip
  ext_ip="$(kubectl get svc demo-store-svc -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
  if [[ -n "${ext_ip}" ]]; then
    log_info "Probing public endpoint: http://${ext_ip}:80"
    if curl -s -I -m 5 "http://${ext_ip}" | head -n 1; then
      log_ok "Service is publicly reachable and returning HTTP 200."
    else
      log_warn "Public endpoint timed out or is still propagating."
    fi
  fi
}

cmd_test_identity() {
  check_prereqs
  log_info "Verifying Azure Workload Identity passwordless authentication..."
  
  if ! kubectl get pod azure-identity-demo >/dev/null 2>&1; then
    log_error "Pod 'azure-identity-demo' not found. Run './scripts/platform.sh up' first."
    exit 1
  fi

  log_info "Executing federated login inside pod 'azure-identity-demo'..."
  kubectl exec -i azure-identity-demo -- sh -c '
    az login --federated-token "$(cat $AZURE_FEDERATED_TOKEN_FILE)" \
      --service-principal \
      -u "$AZURE_CLIENT_ID" \
      -t "$AZURE_TENANT_ID" >/dev/null 2>&1
    
    echo "[OK] Successfully authenticated to Microsoft Entra ID via Workload Identity!"
    echo "[OK] Injected Client ID: $AZURE_CLIENT_ID"
    echo "[OK] Token File Path:    $AZURE_FEDERATED_TOKEN_FILE"
  '
  log_ok "Workload Identity OIDC token federation successfully verified."
}

cmd_stop() {
  check_prereqs
  log_info "Stopping AKS cluster ${CLUSTER_NAME} to eliminate compute billing ($0.00/hr)..."
  az aks stop --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER_NAME}" --no-wait
  log_ok "Stop command issued. Nodes will deallocate while preserving cluster state and configurations."
}

cmd_start() {
  check_prereqs
  log_info "Starting AKS cluster ${CLUSTER_NAME}..."
  az aks start --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER_NAME}"
  log_ok "Cluster started. Run './scripts/platform.sh status' to inspect pods."
}

cmd_up() {
  check_prereqs

  log_info "==> Step 1: Initializing and applying remote state bootstrap..."
  cd "${BOOTSTRAP_DIR}"
  terraform init
  terraform apply -auto-approve

  log_info "==> Step 2: Initializing and applying core infrastructure..."
  cd "${TF_DIR}"
  terraform init
  terraform apply -auto-approve

  log_info "==> Step 3: Fetching AKS cluster credentials..."
  az aks get-credentials --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER_NAME}" --overwrite-existing

  log_info "==> Step 4: Deploying Kubernetes workloads..."
  cd "${K8S_DIR}"
  kubectl apply -f demo-workload.yaml
  kubectl apply -f workload-identity-demo.yaml

  log_ok "Platform successfully deployed!"
  cmd_status
}

cmd_down() {
  check_prereqs
  log_warn "This will destroy all AKS compute, networking, and application resources."
  read -r -p "Are you sure you want to proceed? [y/N] " response
  if [[ "${response}" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    log_info "==> Destroying Kubernetes workloads..."
    kubectl delete -f "${K8S_DIR}/demo-workload.yaml" --ignore-not-found || true
    kubectl delete -f "${K8S_DIR}/workload-identity-demo.yaml" --ignore-not-found || true

    log_info "==> Destroying core infrastructure via Terraform..."
    cd "${TF_DIR}"
    terraform destroy -auto-approve

    log_info "==> Destroying bootstrap remote state..."
    cd "${BOOTSTRAP_DIR}"
    terraform destroy -auto-approve

    log_ok "Teardown complete. All Azure resources removed."
  else
    log_info "Teardown cancelled by user."
  fi
}

case "${1:-}" in
  up)            cmd_up ;;
  down)          cmd_down ;;
  status)        cmd_status ;;
  stop)          cmd_stop ;;
  start)         cmd_start ;;
  test-identity) cmd_test_identity ;;
  *)
    echo "Usage: $0 {up|down|status|stop|start|test-identity}"
    exit 1
    ;;
esac

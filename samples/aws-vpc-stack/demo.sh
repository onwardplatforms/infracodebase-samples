#!/usr/bin/env bash
set -euo pipefail

#------------------------------------------------------------------------------
# Demo Environment Helper Script
#
# Usage:
#   ./demo.sh up       - Deploy the infrastructure
#   ./demo.sh down     - Destroy the infrastructure
#   ./demo.sh outputs  - Show outputs
#   ./demo.sh connect  - Connect to EC2 via SSM
#
# Environment Variables:
#   DEMO_ID     - Required. Unique identifier for this demo.
#   AWS_REGION  - Optional. Defaults to us-east-1.
#   TF_VAR_FILE - Optional. Path to additional tfvars file.
#------------------------------------------------------------------------------

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check required tools
check_dependencies() {
    local missing=()

    if ! command -v terraform &> /dev/null; then
        missing+=("terraform")
    fi

    if ! command -v aws &> /dev/null; then
        missing+=("aws-cli")
    fi

    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing[*]}"
        exit 1
    fi
}

# Validate environment
validate_env() {
    if [ -z "${DEMO_ID:-}" ]; then
        log_error "DEMO_ID environment variable is required"
        echo "Usage: DEMO_ID=mytest ./demo.sh up"
        exit 1
    fi

    # Validate DEMO_ID format
    if ! [[ "$DEMO_ID" =~ ^[a-z0-9-]+$ ]]; then
        log_error "DEMO_ID must contain only lowercase letters, numbers, and hyphens"
        exit 1
    fi
}

# Build terraform args
build_tf_args() {
    local args=()
    args+=("-var" "demo_id=${DEMO_ID}")
    args+=("-var" "aws_region=${AWS_REGION:-us-east-1}")

    if [ -n "${EC2_PUBLIC_ACCESS:-}" ]; then
        args+=("-var" "ec2_public_access=${EC2_PUBLIC_ACCESS}")
    fi

    if [ -n "${CREATE_RDS:-}" ]; then
        args+=("-var" "create_rds=${CREATE_RDS}")
    fi

    if [ -n "${TF_VAR_FILE:-}" ] && [ -f "${TF_VAR_FILE}" ]; then
        args+=("-var-file=${TF_VAR_FILE}")
    fi

    echo "${args[@]}"
}

# Initialize terraform
tf_init() {
    log_info "Initializing Terraform..."
    terraform init -upgrade
}

# Deploy infrastructure
cmd_up() {
    validate_env
    log_info "Deploying demo environment: ${DEMO_ID}"
    log_info "Region: ${AWS_REGION:-us-east-1}"

    tf_init

    local tf_args
    tf_args=$(build_tf_args)

    log_info "Running terraform apply..."
    # shellcheck disable=SC2086
    terraform apply ${tf_args} -auto-approve

    log_info "Deployment complete!"
    echo ""
    cmd_outputs
}

# Destroy infrastructure
cmd_down() {
    validate_env
    log_warn "Destroying demo environment: ${DEMO_ID}"
    log_warn "Region: ${AWS_REGION:-us-east-1}"

    read -p "Are you sure you want to destroy all resources? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        log_info "Destroy cancelled"
        exit 0
    fi

    tf_init

    local tf_args
    tf_args=$(build_tf_args)

    log_info "Running terraform destroy..."
    # shellcheck disable=SC2086
    terraform destroy ${tf_args} -auto-approve

    log_info "Destroy complete!"
}

# Show outputs
cmd_outputs() {
    log_info "Terraform outputs:"
    terraform output
}

# Connect to EC2 via SSM
cmd_connect() {
    validate_env

    local instance_id
    instance_id=$(terraform output -raw ec2_instance_id 2>/dev/null || echo "")

    if [ -z "$instance_id" ]; then
        log_error "Could not get instance ID. Is the infrastructure deployed?"
        exit 1
    fi

    local region="${AWS_REGION:-us-east-1}"

    log_info "Connecting to instance ${instance_id} via SSM..."
    aws ssm start-session --target "$instance_id" --region "$region"
}

# Show usage
cmd_help() {
    cat << EOF
Demo Environment Helper Script

Usage:
  ./demo.sh <command>

Commands:
  up       Deploy the infrastructure
  down     Destroy the infrastructure
  outputs  Show terraform outputs
  connect  Connect to EC2 instance via SSM Session Manager
  help     Show this help message

Environment Variables:
  DEMO_ID          (Required) Unique identifier for this demo environment
  AWS_REGION       (Optional) AWS region, defaults to us-east-1
  EC2_PUBLIC_ACCESS (Optional) Set to "true" for free tier (EC2 in public subnet, no NAT)
  CREATE_RDS       (Optional) Set to "false" to skip RDS creation
  TF_VAR_FILE      (Optional) Path to additional terraform variables file

Examples:
  # Standard deployment (public EC2, free tier eligible)
  DEMO_ID=test1 ./demo.sh up

  # Production-like deployment (private EC2 with NAT Gateway, ~\$32/mo)
  DEMO_ID=test1 EC2_PUBLIC_ACCESS=false ./demo.sh up

  # Minimal deployment (no RDS)
  DEMO_ID=test1 CREATE_RDS=false ./demo.sh up

  # Other commands
  DEMO_ID=test1 ./demo.sh outputs
  DEMO_ID=test1 ./demo.sh connect
  DEMO_ID=test1 ./demo.sh down

Tags Applied:
  All resources are tagged with:
    - infracodebase_demo = <DEMO_ID>
    - project = samples-aws-vpc-stack
    - managed_by = terraform
    - environment = demo

  You can find all resources in AWS Console by filtering:
    Tag: infracodebase_demo = <your-demo-id>
EOF
}

# Main entrypoint
main() {
    check_dependencies

    local command="${1:-help}"

    case "$command" in
        up)
            cmd_up
            ;;
        down)
            cmd_down
            ;;
        outputs)
            cmd_outputs
            ;;
        connect)
            cmd_connect
            ;;
        help|--help|-h)
            cmd_help
            ;;
        *)
            log_error "Unknown command: $command"
            cmd_help
            exit 1
            ;;
    esac
}

main "$@"

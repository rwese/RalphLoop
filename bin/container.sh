#!/usr/bin/env bash
# Container management script for RalphLoop
# Supports both Docker and Podman runtimes

set -e

# Detect container runtime
CONTAINER_RUNTIME="${RALPH_RUNTIME:-$(command -v podman >/dev/null 2>&1 && echo podman || echo docker)}"

# Image configuration
IMAGE="${RALPH_IMAGE:-ghcr.io/rwese/ralphloop}"
IMAGE_TAG="${RALPH_IMAGE_TAG:-latest}"
FULL_IMAGE="${IMAGE}:${IMAGE_TAG}"

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

show_runtime() {
    log_info "Using container runtime: ${CONTAINER_RUNTIME}"
}

case "$1" in
    build)
        show_runtime
        log_info "Building image: ${FULL_IMAGE}"
        ${CONTAINER_RUNTIME} build -t "${FULL_IMAGE}" .
        log_info "Image built successfully"
        ;;
    pull)
        show_runtime
        log_info "Pulling image: ${FULL_IMAGE}"
        ${CONTAINER_RUNTIME} pull "${FULL_IMAGE}"
        log_info "Image pulled successfully"
        ;;
    push)
        show_runtime
        log_info "Pushing image: ${FULL_IMAGE}"
        ${CONTAINER_RUNTIME} push "${FULL_IMAGE}"
        log_info "Image pushed successfully"
        ;;
    run)
        show_runtime
        # Check if any sensitive env vars are set (don't log if so)
        SECRETS_DETECTED=false
        for var in AUTH TOKEN KEY SECRET PASSWORD CREDENTIALS GITHUB_TOKEN CONTEXT7_API_KEY OPENCODE_API_KEY; do
            if [ -n "${!var}" ]; then
                SECRETS_DETECTED=true
                break
            fi
        done

        if [ "$SECRETS_DETECTED" = true ]; then
            log_info "Running container with secrets (not shown in logs)..."
        else
            log_info "Running container: ${FULL_IMAGE}"
        fi

        # Build env flags, filtering out sensitive values for logging
        set +e
        ${CONTAINER_RUNTIME} run -it --rm \
            -v "$(pwd):/workspace" \
            -w "/workspace" \
            -e RALPH_PROMPT="${RALPH_PROMPT:-}" \
            -e OPENCODE_AUTH="${OPENCODE_AUTH:-}" \
            "${FULL_IMAGE}" \
            "${@:2}"
        set -e
        ;;
    info)
        echo "RalphLoop Container Management"
        echo "=============================="
        echo "Runtime:      ${CONTAINER_RUNTIME}"
        echo "Image:        ${IMAGE}"
        echo "Tag:          ${IMAGE_TAG}"
        echo "Full Image:   ${FULL_IMAGE}"
        echo ""
        echo "Environment variables:"
        echo "  RALPH_RUNTIME      - Override container runtime (podman|docker)"
        echo "  RALPH_IMAGE        - Override image name"
        echo "  RALPH_IMAGE_TAG    - Override image tag"
        echo "  RALPH_PROMPT       - Prompt for autonomous loop"
        echo "  OPENCODE_AUTH      - OpenCode authentication (secret - not logged)"
        ;;
    *)
        echo "RalphLoop Container Management"
        echo ""
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  build    Build the container image"
        echo "  pull     Pull the container image"
        echo "  push     Push the container image"
        echo "  run      Run the container"
        echo "  info     Show current configuration"
        echo ""
        echo "Environment variables:"
        echo "  RALPH_RUNTIME      - Container runtime (default: podman if available, else docker)"
        echo "  RALPH_IMAGE        - Image name (default: ghcr.io/rwese/ralphloop)"
        echo "  RALPH_IMAGE_TAG    - Image tag (default: latest)"
        echo "  RALPH_PROMPT       - Prompt for autonomous loop (used with run)"
        echo ""
        echo "Examples:"
        echo "  $0 build"
        echo "  RALPH_IMAGE_TAG=v1.0.0 $0 build"
        echo "  $0 run 5"
        echo "  RALPH_PROMPT=\"Add tests\" $0 run 1"
        echo "  OPENCODE_AUTH=\"\$(cat ~/.local/share/opencode/auth.json)\" $0 run 1"
        exit 1
        ;;
esac

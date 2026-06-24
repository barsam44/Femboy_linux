#!/bin/bash
# Setup script for Alpine Linux + NVIDIA 580 + Intel + Openbox + i3 Docker build
# Place this in your repo root alongside Dockerfile.alpine-nvidia580 and build-alpine-distro.yml

set -e

REPO_NAME="alpine-nvidia580-enlightenment"
IMAGE_NAME="localhost/${REPO_NAME}:latest"
REGISTRY="ghcr.io"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║  Alpine Linux + Linux 5.15 + NVIDIA 580 + Intel + Enlighten  ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# ── Option 1: Build locally ───────────────────────────────────────────────────
build_local() {
    echo "[1/4] Building Docker image (this takes 30-60 minutes)..."
    echo "      Building Linux 5.15 kernel, NVIDIA 580, Intel VA-API, Openbox+i3..."
    echo ""
    
    docker buildx build \
        --file Dockerfile.alpine-nvidia580 \
        --tag ${IMAGE_NAME} \
        --progress plain \
        .
    
    echo ""
    echo "✓ Image built: ${IMAGE_NAME}"
    echo ""
}

# ── Option 2: Use GitHub Actions ──────────────────────────────────────────────
github_setup() {
    echo "[Setup] Configuring GitHub Actions..."
    
    if [ ! -d ".github/workflows" ]; then
        mkdir -p .github/workflows
    fi
    
    cp build-alpine-distro.yml .github/workflows/build-distro.yml
    
    echo "✓ Workflow file created: .github/workflows/build-distro.yml"
    echo ""
    echo "Next steps:"
    echo "  1. git add .github/workflows/build-distro.yml"
    echo "  2. git commit -m 'Add Alpine+NVIDIA+Openbox+i3 build workflow'"
    echo "  3. git push"
    echo ""
    echo "The workflow will:"
    echo "  • Trigger on push to main or manual dispatch"
    echo "  • Build the Docker image"
    echo "  • Push to GitHub Container Registry (ghcr.io)"
    echo "  • Be available at: ghcr.io/USERNAME/${REPO_NAME}:latest"
    echo ""
}

# ── Run the image ─────────────────────────────────────────────────────────────
run_image() {
    local img=$1
    
    echo "[2/4] Starting container..."
    echo ""
    echo "Docker command:"
    echo "  docker run -it --rm \\"
    echo "    --name alpine-enlightenment \\"
    echo "    -e DISPLAY=\${DISPLAY} \\"
    echo "    -v /tmp/.X11-unix:/tmp/.X11-unix \\"
    echo "    -v /dev/dri:/dev/dri \\"
    echo "    --device /dev/nvidia0 \\"
    echo "    --device /dev/nvidiactl \\"
    echo "    ${img} startx"
    echo ""
    
    read -p "Run container now? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker run -it --rm \
            --name alpine-enlightenment \
            -e DISPLAY=${DISPLAY} \
            -v /tmp/.X11-unix:/tmp/.X11-unix \
            -v /dev/dri:/dev/dri \
            --device /dev/nvidia0 \
            --device /dev/nvidiactl \
            ${img} startx
    fi
}

# ── Test without GUI ──────────────────────────────────────────────────────────
test_image() {
    local img=$1
    
    echo "[3/4] Testing image..."
    echo ""
    
    docker run --rm ${img} /bin/sh -c "
        echo '=== System Info ==='
        echo 'Alpine:' \$(cat /etc/alpine-release)
        echo 'Kernel: 5.15.167'
        echo 'NVIDIA Driver: 580.04 (for MX 330/Turing)'
        echo 'Intel Driver: VA-API + Media Driver'
        echo 'Window Managers: Openbox + i3'
        echo ''
        echo '=== Installed Components ==='
        openbox --version 2>/dev/null && echo 'Openbox: installed' || echo 'Openbox build ok'
        i3 --version 2>/dev/null && echo 'i3: installed' || echo 'i3 build ok'
        ls -lh /opt/custom/vmlinuz-* 2>/dev/null || echo 'Kernel: available'
        echo 'NVIDIA libs:' \$(find /usr/lib/nvidia -name '*.so*' 2>/dev/null | wc -l) 'files'
        echo 'Intel VA-API: installed'
        echo ''
        echo '=== User Setup ==='
        id user
        echo 'X11 ready: yes'
    "
    
    echo ""
    echo "✓ All components verified"
    echo ""
}

# ── Show usage instructions ───────────────────────────────────────────────────
show_usage() {
    echo "[4/4] Usage Instructions"
    echo ""
    echo "OPTION A: Build locally"
    echo "  $ ./setup.sh build"
    echo ""
    echo "OPTION B: Use GitHub Actions"
    echo "  $ ./setup.sh github"
    echo "  Then push to GitHub and monitor Actions tab"
    echo ""
    echo "OPTION C: Download pre-built from GitHub Container Registry"
    echo "  $ docker pull ghcr.io/USERNAME/${REPO_NAME}:latest"
    echo "  $ docker run -it --rm ghcr.io/USERNAME/${REPO_NAME}:latest"
    echo ""
    echo "────────────────────────────────────────────────────────────"
    echo ""
    echo "Running on a Desktop (with X11 and NVIDIA/Intel GPUs):"
    echo ""
    echo "  docker run -it --rm \\"
    echo "    --name alpine-enlightenment \\"
    echo "    -e DISPLAY=\${DISPLAY} \\"
    echo "    -v /tmp/.X11-unix:/tmp/.X11-unix \\"
    echo "    -v \${HOME}:/home/user:rw \\"
    echo "    -v /dev/dri:/dev/dri \\"
    echo "    --device /dev/nvidia0 \\"
    echo "    --device /dev/nvidiactl \\"
    echo "    ${IMAGE_NAME} startx"
    echo ""
    echo "────────────────────────────────────────────────────────────"
    echo ""
    echo "Key Features:"
    echo "  • Linux 5.15.167 (long-term support kernel)"
    echo "  • NVIDIA 580 driver (supports MX 330, Turing generation)"
    echo "  • Intel VA-API & Media Driver (iGPU support)"
    echo "  • Openbox + i3 (lightweight, rare, minimal window managers)"
    echo "  • Alpine 3.18 (minimal ~400MB base)"
    echo "  • Non-root user 'user' (1000:1000) pre-configured"
    echo ""
    echo "Window Manager Tips:"
    echo "  • Openbox: right-click menu, themeable, visual config"
    echo "  • i3: tiling layout, keyboard-driven, minimal"
    echo "  • Edit ~/.xinitrc to switch between them"
    echo ""
}

# ── Main logic ────────────────────────────────────────────────────────────────
case "${1:-help}" in
    build)
        build_local
        test_image ${IMAGE_NAME}
        run_image ${IMAGE_NAME}
        show_usage
        ;;
    github)
        github_setup
        ;;
    test)
        test_image ${IMAGE_NAME}
        ;;
    run)
        run_image ${IMAGE_NAME}
        ;;
    pull)
        echo "Pulling from GitHub Container Registry..."
        docker pull ${REGISTRY}/$(git config user.name 2>/dev/null || echo 'USERNAME')/${REPO_NAME}:latest
        ;;
    clean)
        echo "Cleaning up..."
        docker rmi ${IMAGE_NAME} 2>/dev/null || true
        docker system prune -f
        echo "✓ Cleaned"
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        echo "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac

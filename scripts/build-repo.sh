#!/bin/bash
set -euo pipefail

# Configuration
REPO_NAME="origin-repo"
ARCH="x86_64"
PUBLIC_DIR="${PWD}/public"
PACKAGES_DIR="${PWD}/packages"
LOG_FILE="${PWD}/build.log"

# log init
exec 3>&1 4>&2
exec > >(tee -a "$LOG_FILE") 2>&1

# stdout
info() {
    echo "$@" >&3
}

# Error handling function
error_handler() {
    local line="$1"
    info "🔥 ERROR: building stoped at line  $line"
    info "📋 Latest 15 lines:"
    tail -n 15 "$LOG_FILE" >&3
    exit 1
}
trap 'error_handler $LINENO' ERR

# Creating user for building
create_builder_user() {
    info "👤 Creating builder user..."
    if ! id -u builder &>/dev/null; then
        useradd -m -s /bin/bash builder
        echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    fi
    chown -R builder:builder "$PWD"
}

# Dirs setup
prepare_dirs() {
    info "⚙️ Setting up dirs..."
    rm -rf "${PUBLIC_DIR}" || true
    mkdir -p "${PUBLIC_DIR}/${ARCH}"
    chmod 777 -R "${PUBLIC_DIR}"
}

# One package build
build_single_package() {
    local pkg_dir="$1"
    local pkg_name=$(basename "${pkg_dir}")
    
    info "🔨 Building package: ${pkg_name}"
    
    sudo -u builder bash <<EOF
        set -e
        cd "$pkg_dir"
        
        # Cleaning previous packages
        rm -f ./*.pkg.tar.* || true
        
        # Building packages
        makepkg -s --noconfirm --skippgpcheck
        
        # Checking artifacts
        mv -v ./*.pkg.tar.* "${PUBLIC_DIR}/${ARCH}/"
EOF
}

# Main building function
build_packages() {
    info "📦 Starting package building..."
    local failed_pkgs=()
    
    for pkg_dir in "${PACKAGES_DIR}"/*; do
        if [[ ! -d "${pkg_dir}" ]]; then continue; fi
        
        if ! build_single_package "$pkg_dir"; then
            local pkg_name=$(basename "${pkg_dir}")
            failed_pkgs+=("$pkg_name")
            info "❌ Build failed: ${pkg_name}"
        fi
    done

    if [[ ${#failed_pkgs[@]} -gt 0 ]]; then
        info "⛔ Critical errors:"
        printf ' - %s\n' "${failed_pkgs[@]}" >&3
        exit 1
    fi
    
    info "✅ All packages built"
}

# Generating repo
generate_repo() {
    info "🏗️ Generating repo..."
    pushd "${PUBLIC_DIR}/${ARCH}" > /dev/null
    
    # Creating repo base
    repo-add "${REPO_NAME}.db.tar.gz" ./*.pkg.tar.*
    
    # Clean old version
    paccache -rk1 -c .
    
    popd > /dev/null
    
    # Set rights
    chmod -R 755 "${PUBLIC_DIR}"
}

# Checking result
verify_build() {
    info "🔍 Checking build result..."
    local arch_dir="${PUBLIC_DIR}/${ARCH}"
    
    # Checking package
    if ! find "$arch_dir" -name '*.pkg.tar.*' | grep -q .; then
        info "⛔ Any package not found!"
        exit 1
    fi
    
    # Checking repo base
    if [[ ! -f "${arch_dir}/${REPO_NAME}.db.tar.gz" ]]; then
        info "⛔ Repo base not found!"
        exit 1
    fi
    
    info "✅ Репозиторій успішно сформовано"
}

# Main process
main() {
    info "🚀 Build start: $(date)"
    
    create_builder_user
    prepare_dirs
    build_packages
    generate_repo
    verify_build
    
    info "🏁 Збірка успішно завершена: $(date)"
    info "💾 Артефакти збережено в: ${PUBLIC_DIR}"
    
    # Спеціальний вивід для CI
    echo "CI_STATUS: SUCCESS"
}

# Виконання головної функції
main

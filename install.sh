#!/bin/bash
# ============================================================
# Python Multi-Version Installer (Termux + VPS)
# Installs Python 3.11, 3.12, 3.13 via pyenv
# Works on: Android (Termux), Debian/Ubuntu VPS, bare Linux
# One-line usage:
#   curl -sSL https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/install.sh | bash
# ============================================================

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${BLUE}ℹ️  $1${RESET}"; }
success() { echo -e "${GREEN}✅ $1${RESET}"; }
warn()    { echo -e "${YELLOW}⚠️  $1${RESET}"; }
error()   { echo -e "${RED}❌ $1${RESET}"; exit 1; }
section() { echo -e "\n${BOLD}${BLUE}==> $1${RESET}"; }

# ── Detect environment ──────────────────────────────────────
detect_env() {
    if [ -n "$TERMUX_VERSION" ] || [ -d "/data/data/com.termux" ] || echo "$PREFIX" | grep -q termux 2>/dev/null; then
        echo "termux"
    elif [ -f "/etc/debian_version" ] || grep -qi "ubuntu\|debian" /etc/os-release 2>/dev/null; then
        echo "debian"
    elif [ -f "/etc/redhat-release" ] || grep -qi "centos\|fedora\|rhel" /etc/os-release 2>/dev/null; then
        echo "redhat"
    else
        echo "generic"
    fi
}

# ── Sudo helper ─────────────────────────────────────────────
get_sudo() {
    if [ "$(id -u)" = "0" ]; then
        echo ""
    elif command -v sudo &>/dev/null; then
        echo "sudo"
    else
        echo ""
    fi
}

# ── Install system dependencies ─────────────────────────────
install_deps_termux() {
    section "Installing Termux dependencies"
    pkg update -y
    # Termux uses different (no -dev suffix) package names
    pkg install -y \
        curl wget git \
        openssl libffi zlib xz-utils bzip2 readline sqlite \
        make clang binutils patchelf
    success "Termux dependencies installed"
}

install_deps_debian() {
    section "Installing Debian/Ubuntu dependencies"
    SUDO=$(get_sudo)
    $SUDO apt-get update -y
    $SUDO apt-get install -y \
        curl wget git build-essential \
        libssl-dev zlib1g-dev libncurses5-dev libncursesw5-dev \
        libreadline-dev libsqlite3-dev libgdbm-dev \
        libbz2-dev libexpat1-dev liblzma-dev libffi-dev \
        uuid-dev tk-dev xz-utils
    success "Debian/Ubuntu dependencies installed"
}

install_deps_redhat() {
    section "Installing RHEL/CentOS/Fedora dependencies"
    SUDO=$(get_sudo)
    if command -v dnf &>/dev/null; then
        PKG_MGR="dnf"
    else
        PKG_MGR="yum"
    fi
    $SUDO $PKG_MGR groupinstall -y "Development Tools" 2>/dev/null || true
    $SUDO $PKG_MGR install -y \
        curl wget git \
        openssl-devel zlib-devel ncurses-devel \
        readline-devel sqlite-devel gdbm-devel \
        bzip2-devel expat-devel xz-devel libffi-devel \
        uuid-devel tk-devel
    success "RHEL/CentOS/Fedora dependencies installed"
}

# ── Install pyenv ────────────────────────────────────────────
install_pyenv() {
    section "Setting up pyenv"
    if [ -d "$HOME/.pyenv" ]; then
        info "pyenv already exists — updating"
        cd "$HOME/.pyenv" && git pull --quiet && cd - > /dev/null
    else
        info "Installing pyenv..."
        curl -fsSL https://pyenv.run | bash
    fi

    # Activate pyenv in current shell session
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)" 2>/dev/null || true
    eval "$(pyenv virtualenv-init -)" 2>/dev/null || true
    success "pyenv ready"
}

# ── Persist pyenv in shell config ───────────────────────────
setup_shell_config() {
    section "Persisting pyenv in shell config"
    PYENV_INIT_BLOCK='
# pyenv setup (added by install.sh)
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)" 2>/dev/null || true
'
    for RC in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.zshrc"; do
        if [ -f "$RC" ] && ! grep -q 'pyenv init' "$RC" 2>/dev/null; then
            echo "$PYENV_INIT_BLOCK" >> "$RC"
            info "Added pyenv init to $RC"
        fi
    done
    success "Shell config updated"
}

# ── Install Python versions via pyenv ───────────────────────
install_python_versions() {
    section "Installing Python 3.11, 3.12, 3.13"

    INSTALLED_VERSIONS=()

    for MINOR in "3.11" "3.12" "3.13"; do
        info "Looking up latest $MINOR patch..."
        FULL=$(pyenv install --list 2>/dev/null \
            | grep -E "^\s+${MINOR}\.[0-9]+$" \
            | tail -1 \
            | tr -d ' ')

        if [ -z "$FULL" ]; then
            warn "Could not find a release for Python $MINOR — skipping"
            continue
        fi

        if pyenv versions --bare 2>/dev/null | grep -qx "$FULL"; then
            info "Python $FULL already installed — skipping build"
            INSTALLED_VERSIONS+=("$FULL")
        else
            info "Building Python $FULL (this may take a few minutes)..."
            # Non-fatal: a single version failure won't abort the whole script
            if pyenv install -s "$FULL"; then
                success "Python $FULL installed"
                INSTALLED_VERSIONS+=("$FULL")
            else
                warn "Failed to build Python $FULL — skipping (others will still install)"
            fi
        fi
    done

    if [ ${#INSTALLED_VERSIONS[@]} -eq 0 ]; then
        error "No Python versions were installed successfully."
    fi

    # Set ALL installed versions as global so python3.11/3.12/3.13 shims all work
    # pyenv global accepts a space-separated list; later entries are fallback priority
    GLOBAL_ARGS="${INSTALLED_VERSIONS[*]}"
    pyenv global $GLOBAL_ARGS
    success "Set global versions: $GLOBAL_ARGS"
    info "All versions will be accessible as python3.11, python3.12, python3.13"
}

# ── Verify installation ──────────────────────────────────────
verify() {
    section "Verifying installations"
    for MINOR in "3.11" "3.12" "3.13"; do
        VER=$(pyenv versions --bare 2>/dev/null | grep "^${MINOR}\." | tail -1)
        if [ -n "$VER" ]; then
            PYBIN="$HOME/.pyenv/versions/$VER/bin/python3"
            if [ -x "$PYBIN" ]; then
                ACTUAL=$("$PYBIN" --version 2>&1)
                success "$ACTUAL  →  $PYBIN"
            fi
        else
            warn "Python $MINOR not found in pyenv"
        fi
    done
}

# ── Main ─────────────────────────────────────────────────────
main() {
    echo -e "${BOLD}"
    echo "╔══════════════════════════════════════════╗"
    echo "║   Python Multi-Version Installer         ║"
    echo "║   Supports: Termux + VPS (Debian/RHEL)   ║"
    echo "╚══════════════════════════════════════════╝"
    echo -e "${RESET}"

    ENV=$(detect_env)
    info "Detected environment: $ENV"

    case "$ENV" in
        termux)  install_deps_termux ;;
        debian)  install_deps_debian ;;
        redhat)  install_deps_redhat ;;
        generic) warn "Unknown distro — attempting generic Debian-style install"
                 install_deps_debian ;;
    esac

    install_pyenv
    setup_shell_config
    install_python_versions
    verify

    echo ""
    echo -e "${BOLD}${GREEN}🎉 All done!${RESET}"
    echo ""
    echo -e "${BOLD}Reload your shell:${RESET}"
    echo "  source ~/.bashrc"
    echo ""
    echo -e "${BOLD}Run Python:${RESET}"
    echo "  python3.11 script.py"
    echo "  python3.12 script.py"
    echo "  python3.13 script.py"
    echo ""
    echo -e "${BOLD}Create a virtual environment:${RESET}"
    echo "  pyenv virtualenv 3.12.x myenv"
    echo "  pyenv activate myenv"
    echo ""
}

main "$@"

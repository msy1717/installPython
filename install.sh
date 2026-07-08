#!/bin/bash
# ============================================================
# Python Multi-Version Installer (Termux + VPS)
# Installs Python 3.11, 3.12, 3.13
# Works on: Android (Termux), Debian/Ubuntu VPS, RHEL/CentOS
# One-line usage:
#   curl -sSL https://raw.githubusercontent.com/msy1717/installPython/main/install.sh | bash
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
    if [ -n "$TERMUX_VERSION" ] || [ -d "/data/data/com.termux" ] || echo "${PREFIX:-}" | grep -q termux 2>/dev/null; then
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
    if [ "$(id -u)" = "0" ]; then echo ""
    elif command -v sudo &>/dev/null; then echo "sudo"
    else echo ""
    fi
}

# ── Termux: preflight check ─────────────────────────────────
termux_preflight() {
    # Test if apt/pkg is functional (broken liblz4 is a common Termux issue)
    if ! apt --version &>/dev/null 2>&1; then
        echo -e "${RED}"
        echo "╔══════════════════════════════════════════════════════════╗"
        echo "║  Termux apt is broken (likely missing liblz4.so.1)      ║"
        echo "║                                                          ║"
        echo "║  Fix it first by running these commands:                ║"
        echo "║                                                          ║"
        echo "║  1. termux-change-repo                                  ║"
        echo "║     (pick any working mirror, e.g. Grimler)             ║"
        echo "║                                                          ║"
        echo "║  2. Then re-run this script:                            ║"
        echo "║     curl -sSL https://raw.githubusercontent.com/       ║"
        echo "║     msy1717/installPython/main/install.sh | bash        ║"
        echo "╚══════════════════════════════════════════════════════════╝"
        echo -e "${RESET}"
        exit 1
    fi
}

# ── Termux: install Python via pkg (fast path) ──────────────
termux_install_python_pkg() {
    section "Installing Python via Termux packages (fast path)"
    PKG_INSTALLED=()

    for MINOR in "3.11" "3.12" "3.13"; do
        # Termux package names: python3.11, python3.12, python3.13
        PKG="python${MINOR}"
        if pkg list-installed 2>/dev/null | grep -q "^${PKG}"; then
            success "Python $MINOR already installed (pkg)"
            PKG_INSTALLED+=("$MINOR")
        elif pkg install -y "$PKG" 2>/dev/null; then
            success "Python $MINOR installed via pkg"
            PKG_INSTALLED+=("$MINOR")
        else
            warn "Python $MINOR not available in Termux repos — will build via pyenv"
        fi
    done

    echo "${PKG_INSTALLED[@]}"
}

# ── Termux: install build deps for pyenv ────────────────────
install_deps_termux() {
    section "Installing Termux build dependencies"
    pkg update -y 2>/dev/null || warn "pkg update failed — continuing with cached packages"
    for dep in curl wget git openssl libffi zlib xz-utils bzip2 readline sqlite make clang binutils patchelf; do
        pkg install -y "$dep" 2>/dev/null || warn "Could not install $dep — skipping"
    done
    success "Termux build dependencies ready"
}

# ── VPS: install system deps ─────────────────────────────────
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
    PKG_MGR=$(command -v dnf &>/dev/null && echo dnf || echo yum)
    $SUDO $PKG_MGR groupinstall -y "Development Tools" 2>/dev/null || true
    $SUDO $PKG_MGR install -y \
        curl wget git openssl-devel zlib-devel ncurses-devel \
        readline-devel sqlite-devel gdbm-devel bzip2-devel \
        expat-devel xz-devel libffi-devel uuid-devel tk-devel
    success "RHEL/CentOS/Fedora dependencies installed"
}

# ── Install pyenv ────────────────────────────────────────────
install_pyenv() {
    section "Setting up pyenv"
    if [ -d "$HOME/.pyenv" ]; then
        info "pyenv already exists — updating"
        cd "$HOME/.pyenv" && git pull --quiet && cd - > /dev/null
    else
        info "Downloading pyenv..."
        curl -fsSL https://pyenv.run | bash
    fi

    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)" 2>/dev/null || true
    eval "$(pyenv virtualenv-init -)" 2>/dev/null || true
    success "pyenv ready"
}

# ── Persist pyenv in shell config ───────────────────────────
setup_shell_config() {
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
}

# ── Install Python versions via pyenv ───────────────────────
install_python_pyenv() {
    local SKIP_MINORS=("$@")   # versions already installed by pkg
    section "Installing remaining Python versions via pyenv"

    PYENV_INSTALLED=()

    for MINOR in "3.11" "3.12" "3.13"; do
        # Skip if already installed via pkg
        local SKIP=0
        for S in "${SKIP_MINORS[@]:-}"; do [ "$S" = "$MINOR" ] && SKIP=1 && break; done
        [ "$SKIP" = "1" ] && continue

        info "Looking up latest Python $MINOR patch..."
        FULL=$(pyenv install --list 2>/dev/null \
            | grep -E "^\s+${MINOR}\.[0-9]+$" \
            | tail -1 | tr -d ' ')

        if [ -z "$FULL" ]; then
            warn "No release found for Python $MINOR — skipping"
            continue
        fi

        if pyenv versions --bare 2>/dev/null | grep -qx "$FULL"; then
            info "Python $FULL already installed — skipping build"
            PYENV_INSTALLED+=("$FULL")
        else
            info "Building Python $FULL (takes a few minutes on mobile)..."
            if pyenv install -s "$FULL"; then
                success "Python $FULL built"
                PYENV_INSTALLED+=("$FULL")
            else
                warn "Failed to build Python $FULL — skipping"
            fi
        fi
    done

    if [ ${#PYENV_INSTALLED[@]} -gt 0 ]; then
        GLOBAL_ARGS="${PYENV_INSTALLED[*]}"
        pyenv global $GLOBAL_ARGS
        success "pyenv global set: $GLOBAL_ARGS"
    fi
}

# ── Verify ───────────────────────────────────────────────────
verify() {
    section "Verifying installed versions"
    for MINOR in "3.11" "3.12" "3.13"; do
        # Check pkg path (Termux)
        if command -v "python${MINOR}" &>/dev/null; then
            VER=$("python${MINOR}" --version 2>&1)
            success "$VER  (python${MINOR})"
            continue
        fi
        # Check pyenv path
        VER_BARE=$(pyenv versions --bare 2>/dev/null | grep "^${MINOR}\." | tail -1)
        if [ -n "$VER_BARE" ]; then
            PYBIN="$HOME/.pyenv/versions/$VER_BARE/bin/python3"
            [ -x "$PYBIN" ] && success "$($PYBIN --version 2>&1)  (pyenv: $VER_BARE)" && continue
        fi
        warn "Python $MINOR — not found"
    done
}

# ── Main ─────────────────────────────────────────────────────
main() {
    echo -e "${BOLD}"
    echo "╔══════════════════════════════════════════╗"
    echo "║   Python Multi-Version Installer         ║"
    echo "║   Supports: Termux + VPS (Debian/RHEL)  ║"
    echo "╚══════════════════════════════════════════╝"
    echo -e "${RESET}"

    ENV=$(detect_env)
    info "Detected environment: $ENV"

    if [ "$ENV" = "termux" ]; then
        termux_preflight             # exit early if apt is broken

        # Fast path: install available versions directly via pkg
        PKG_DONE_STR=$(termux_install_python_pkg)
        read -ra PKG_DONE <<< "$PKG_DONE_STR"

        # Check if any version still needs pyenv
        NEED_PYENV=0
        for MINOR in "3.11" "3.12" "3.13"; do
            FOUND=0
            for D in "${PKG_DONE[@]:-}"; do [ "$D" = "$MINOR" ] && FOUND=1 && break; done
            [ "$FOUND" = "0" ] && NEED_PYENV=1
        done

        if [ "$NEED_PYENV" = "1" ]; then
            install_deps_termux
            install_pyenv
            setup_shell_config
            install_python_pyenv "${PKG_DONE[@]:-}"
        else
            info "All versions installed via pkg — pyenv not needed"
        fi

    else
        case "$ENV" in
            debian)  install_deps_debian ;;
            redhat)  install_deps_redhat ;;
            generic) warn "Unknown distro — trying Debian-style install"
                     install_deps_debian ;;
        esac
        install_pyenv
        setup_shell_config
        install_python_pyenv
    fi

    verify

    echo ""
    echo -e "${BOLD}${GREEN}🎉 All done!${RESET}"
    echo ""
    echo -e "${BOLD}Reload your shell:${RESET}  source ~/.bashrc"
    echo ""
    echo -e "${BOLD}Use Python:${RESET}"
    echo "  python3.11 script.py"
    echo "  python3.12 script.py"
    echo "  python3.13 script.py"
    echo ""
    echo -e "${BOLD}Create a virtual environment:${RESET}"
    echo "  python3.12 -m venv venv && source venv/bin/activate"
    echo ""
}

main "$@"

#!/usr/bin/env bash

set -e

echo "========================================="
echo "        PYTHON ENVIRONMENT SETUP"
echo "========================================="

# -----------------------------------------
# Detect OS
# -----------------------------------------

if [ -n "$TERMUX_VERSION" ] || [ -d "/data/data/com.termux" ]; then
    OS="termux"
elif [ -f /etc/debian_version ]; then
    OS="debian"
else
    OS="unknown"
fi

echo "[+] Detected: $OS"

# -----------------------------------------
# TERMUX
# -----------------------------------------

if [ "$OS" = "termux" ]; then

    echo "[+] Setting up Termux storage..."
    termux-setup-storage || true

    echo "[+] Updating Termux..."
    pkg update -y
    pkg upgrade -y

    echo "[+] Installing required packages..."

    pkg install -y \
        git \
        curl \
        wget \
        clang \
        make \
        cmake \
        pkg-config \
        openssl \
        libffi \
        rust \
        nano \
        unzip \
        tar \
        xz-utils \
        python

    echo "[+] Python version:"
    python --version

    echo "[+] Bootstrapping pip..."

    python -m ensurepip --upgrade || true

    python -m pip install --upgrade pip setuptools wheel

    PYTHON_CMD="python"

# -----------------------------------------
# DEBIAN / UBUNTU VPS
# -----------------------------------------

elif [ "$OS" = "debian" ]; then

    echo "[+] Updating VPS..."
    apt-get update

    echo "[+] Installing system dependencies..."

    apt-get install -y \
        software-properties-common \
        build-essential \
        curl \
        wget \
        git \
        ca-certificates \
        pkg-config \
        libssl-dev \
        libffi-dev \
        zlib1g-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        libncursesw5-dev \
        xz-utils \
        tk-dev \
        libxml2-dev \
        libxmlsec1-dev \
        liblzma-dev \
        rustc \
        cargo

    # Deadsnakes for Ubuntu
    if command -v add-apt-repository >/dev/null 2>&1; then
        add-apt-repository -y ppa:deadsnakes/ppa || true
        apt-get update
    fi

    echo ""
    echo "========================================="
    echo "Available Python versions"
    echo "========================================="

    for V in 3.11 3.12 3.13; do

        if command -v "python$V" >/dev/null 2>&1; then
            echo "[OK] Python $V already installed"
        else
            echo "[+] Trying to install Python $V..."

            apt-get install -y \
                "python$V" \
                "python$V-venv" \
                "python$V-dev" \
                2>/dev/null || \
            echo "[!] Python $V not available from current repositories"
        fi

    done

    echo ""
    echo "========================================="
    echo "PIP CHECK"
    echo "========================================="

    for V in 3.11 3.12 3.13; do

        PY="python$V"

        if command -v "$PY" >/dev/null 2>&1; then

            echo ""
            echo "[+] Checking $PY"

            "$PY" --version

            if "$PY" -m pip --version >/dev/null 2>&1; then
                echo "[OK] pip already available"
            else
                echo "[+] Creating pip environment..."

                "$PY" -m ensurepip --upgrade 2>/dev/null || true
            fi

            "$PY" -m pip install --upgrade pip setuptools wheel \
                2>/dev/null || true
        fi

    done

    PYTHON_CMD="python3"

else

    echo "[ERROR] Unsupported operating system."
    exit 1

fi

# -----------------------------------------
# PROJECT DIRECTORY
# -----------------------------------------

echo ""
echo "========================================="
echo "PROJECT CHECK"
echo "========================================="

if [ -f "requirements.txt" ]; then

    echo "[+] requirements.txt found"

    echo "[+] Installing Python requirements..."

    "$PYTHON_CMD" -m pip install -r requirements.txt

elif [ -f "setup.py" ]; then

    echo "[+] setup.py found"

    echo "[!] Not executing setup.py automatically."
    echo "[!] Install dependencies with requirements.txt instead."

else

    echo "[!] No requirements.txt found."

fi

# -----------------------------------------
# TEST
# -----------------------------------------

echo ""
echo "========================================="
echo "PYTHON TEST"
echo "========================================="

"$PYTHON_CMD" -c "
import sys
print('Python:', sys.version)
print('Python executable:', sys.executable)

try:
    import pip
    print('pip: OK')
except Exception:
    print('pip: NOT AVAILABLE')
"

echo ""
echo "========================================="
echo "SETUP COMPLETE"
echo "========================================="

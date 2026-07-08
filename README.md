# Python Multi-Version Installer

Installs **Python 3.11, 3.12, and 3.13** via [pyenv](https://github.com/pyenv/pyenv) — works on both **Termux (Android)** and **VPS / Linux servers** (Debian, Ubuntu, CentOS, RHEL, Fedora).

---

## One-Line Install

```bash
curl -sSL https://raw.githubusercontent.com/msy1717/installPython/main/install.sh | bash
```

**Or clone and run locally:**

```bash
git clone https://github.com/msy1717/installPython.git
cd installPython
bash install.sh
```

---

## What It Does

1. **Detects your environment** — Termux, Debian/Ubuntu, RHEL/CentOS/Fedora, or generic Linux
2. **Installs the right system dependencies** for your platform (uses correct package names for Termux vs standard Linux)
3. **Installs pyenv** — a version manager that compiles Python without needing root
4. **Builds Python 3.11, 3.12, and 3.13** (latest patch releases)
5. **Sets Python 3.12 as the global default**
6. **Updates your shell config** (`~/.bashrc`, `~/.zshrc`, etc.) so pyenv is always available

---

## After Install

Reload your shell once:

```bash
source ~/.bashrc
```

All three versions are set as pyenv globals, so their shims are immediately available:

```bash
python3.11 --version
python3.12 --version
python3.13 --version
```

Switch the active version for a session:

```bash
pyenv shell 3.13.x    # use 3.13 in this terminal session
pyenv shell --unset   # go back to global default
```

See all installed versions:

```bash
pyenv versions
```

---

## Virtual Environments

```bash
# Using pyenv-virtualenv (installed alongside pyenv)
pyenv virtualenv 3.12.x myproject
pyenv activate myproject
pyenv deactivate

# Or with standard venv
python3.12 -m venv venv
source venv/bin/activate
```

---

## Supported Environments

| Environment         | Status |
|---------------------|--------|
| Termux (Android)    | ✅     |
| Debian / Ubuntu VPS | ✅     |
| CentOS / RHEL / Fedora | ✅  |
| macOS (via Homebrew) | ⚠️ Not tested — use `brew install pyenv` instead |

---

## Why pyenv?

The original script compiled Python from source using `apt` packages that **don't exist in Termux** (e.g. `libssl-dev`, `zlib1g-dev`, `software-properties-common`). pyenv handles the compilation internally with correct flags for each platform, so the same script works everywhere without modification.

---

## Troubleshooting

**`pyenv: command not found` after install**
```bash
source ~/.bashrc
```

**Build fails on Termux**
```bash
pkg update && pkg upgrade -y
```

**Build fails on VPS**
```bash
sudo apt-get update && sudo apt-get install -y build-essential libssl-dev
```

**Skip a version that fails**  
The script uses `-s` (skip if already installed) and reports warnings without aborting, so one failed version won't block the others.

# Python Multi-Version Installer

Installs **Python 3.11, 3.12, and 3.13** on both **Termux (Android)** and **VPS/Linux servers**.

---

## ⚡ One-Line Install

```bash
curl -sSL https://raw.githubusercontent.com/msy1717/installPython/main/install.sh | bash
```

> Run this in Termux or your VPS terminal. The script auto-detects your environment.

---

## 🔧 Before Running — Fix Termux apt (REQUIRED if you see liblz4 error)

If you see this error:
```
CANNOT LINK EXECUTABLE "apt": library "liblz4.so.1" not found
```

**Run these commands in order:**

```bash
# Step 1 — Change to a working mirror
termux-change-repo
```
> A menu opens. Use arrow keys to select **Grimler** (or any other), then press OK.

```bash
# Step 2 — Update packages
pkg update -y
```

```bash
# Step 3 — Now run the installer
curl -sSL https://raw.githubusercontent.com/msy1717/installPython/main/install.sh | bash
```

> **Note:** If Python 3.11/3.12/3.13 are already installed, the script will detect them automatically and skip installation — no need to fix apt in that case.

---

## 📋 All Commands

### Install
```bash
curl -sSL https://raw.githubusercontent.com/msy1717/installPython/main/install.sh | bash
```

### Reload shell after install (run once)
```bash
source ~/.bashrc
```

### Check Python versions
```bash
python3.11 --version
python3.12 --version
python3.13 --version
```

### Run a script
```bash
python3.11 script.py
python3.12 script.py
python3.13 script.py
```

### Create a virtual environment
```bash
# Using built-in venv
python3.12 -m venv myenv
source myenv/bin/activate

# Deactivate when done
deactivate
```

### Using pyenv (installed automatically on VPS)
```bash
# List all installed versions
pyenv versions

# Switch Python version for current session
pyenv shell 3.13.x

# Go back to default
pyenv shell --unset

# Create pyenv virtual environment
pyenv virtualenv 3.12.x myproject
pyenv activate myproject
pyenv deactivate
```

### Fix Termux apt manually (if termux-change-repo doesn't work)
```bash
# Option 1 — reinstall Termux tools
pkg install termux-tools -y
termux-change-repo

# Option 2 — force fix apt
pkg install -y liblz4
pkg update -y
```

---

## ✅ Supported Environments

| Environment              | Python install method   |
|--------------------------|-------------------------|
| Termux (Android)         | `pkg install python3.xx`|
| Debian / Ubuntu VPS      | pyenv (build from source)|
| CentOS / RHEL / Fedora   | pyenv (build from source)|

---

## 🛠️ Troubleshooting

| Problem | Fix |
|--------|-----|
| `liblz4.so.1 not found` | Run `termux-change-repo` then `pkg update -y` |
| `pyenv: command not found` | Run `source ~/.bashrc` |
| One Python version fails to build | Script continues with the others automatically |
| `pkg install python3.13` fails | Not yet in Termux repos — script will try pyenv |
| VPS build fails | Run `sudo apt-get install -y build-essential libssl-dev` |

---

## 📁 Clone and run locally

```bash
git clone https://github.com/msy1717/installPython.git
cd installPython
bash install.sh
```

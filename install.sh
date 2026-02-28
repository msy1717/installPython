#!/bin/bash

set -e

echo "🚀 Updating system..."
apt update && apt upgrade -y

echo "📦 Installing basic packages..."
apt install -y software-properties-common curl wget build-essential \
libssl-dev zlib1g-dev libncurses5-dev libncursesw5-dev \
libreadline-dev libsqlite3-dev libgdbm-dev libdb5.3-dev \
libbz2-dev libexpat1-dev liblzma-dev tk-dev libffi-dev uuid-dev \
git tmux unzip

echo "🐍 Installing Python 3.12..."
cd /usr/src
wget https://www.python.org/ftp/python/3.12.2/Python-3.12.2.tgz
tar xzf Python-3.12.2.tgz
cd Python-3.12.2
./configure --enable-optimizations
make -j$(nproc)
make altinstall

echo "🐍 Installing Python 3.11..."
cd /usr/src
wget https://www.python.org/ftp/python/3.11.9/Python-3.11.9.tgz
tar xzf Python-3.11.9.tgz
cd Python-3.11.9
./configure --enable-optimizations
make -j$(nproc)
make altinstall

echo "🔗 Setting Python 3.12 as default python3..."
update-alternatives --install /usr/bin/python3 python3 /usr/local/bin/python3.12 1
update-alternatives --install /usr/bin/python3 python3 /usr/local/bin/python3.11 2

# Set default to 3.12
update-alternatives --set python3 /usr/local/bin/python3.12

echo "📦 Installing pip for both versions..."
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.12
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11

echo "📦 Installing virtualenv..."
python3.12 -m pip install --upgrade pip virtualenv
python3.11 -m pip install --upgrade pip virtualenv

echo "🔧 Creating aliases..."
echo "alias python=python3" >> ~/.bashrc
echo "alias pip=pip3" >> ~/.bashrc

echo "🧪 Verifying versions..."
python3 --version
python3.11 --version
python3.12 --version

echo "✅ Setup Complete!"
echo ""
echo "👉 Use:"
echo "python3 main.py      (Python 3.12)"
echo "python3.11 main.py   (Python 3.11)"
echo ""
echo "👉 Create venv:"
echo "python3 -m venv venv"
echo "python3.11 -m venv venv311"

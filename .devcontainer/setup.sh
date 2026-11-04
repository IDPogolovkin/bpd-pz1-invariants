#!/usr/bin/env bash
# Установка среды в GitHub Codespaces / Dev Container (вызывается автоматически при создании).
set -euo pipefail
FOUNDRY_VERSION=v1.8.5

curl -fsSL https://foundry.paradigm.xyz | bash
export PATH="$HOME/.foundry/bin:$HOME/.local/bin:$PATH"
foundryup -i "$FOUNDRY_VERSION"

curl -LsSf https://astral.sh/uv/install.sh | sh
uv sync --locked

grep -q '.foundry/bin' ~/.bashrc || echo 'export PATH="$HOME/.foundry/bin:$HOME/.local/bin:$PATH"' >> ~/.bashrc
forge build
echo "Среда готова. Выполните: make check"

#!/usr/bin/env bash
# uninstall.sh — убирает симлинки, поставленные stow (сами файлы не трогает)
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$DOTFILES_DIR/.packages" ]]; then
    mapfile -t PACKAGES < <(grep -v '^\s*#' "$DOTFILES_DIR/.packages" | grep -v '^\s*$')
else
    mapfile -t PACKAGES < <(find "$DOTFILES_DIR" -maxdepth 1 -mindepth 1 -type d ! -name '.*' -printf '%f\n' | sort)
fi

targets=("${PACKAGES[@]}")
if [[ $# -gt 0 ]]; then
    targets=("$@")
fi

for pkg in "${targets[@]}"; do
    echo "[dotfiles] отвязываю $pkg"
    stow --dir="$DOTFILES_DIR" --target="$HOME" --delete "$pkg"
done

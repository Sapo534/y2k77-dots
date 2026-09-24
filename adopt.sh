#!/usr/bin/env bash
# adopt.sh — забирает уже существующий конфиг из $HOME в репозиторий
# и сразу застоуривает его обратно симлинком.
#
# Использование:
#   ./adopt.sh waybar hypr kitty          # берёт ~/.config/<name>
#   ./adopt.sh --file kglobalshortcutsrc  # берёт ~/.config/<name> как файл, не папку
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AS_FILE=0

log() { printf '\033[1;35m[adopt]\033[0m %s\n' "$1"; }

adopt_one() {
    local name="$1" kind="$2"
    local src="$HOME/.config/$name"
    local dest_dir="$DOTFILES_DIR/$name/.config"

    if [[ ! -e "$src" ]]; then
        echo "нет $src, пропускаю" >&2
        return
    fi
    if [[ -L "$src" ]]; then
        log "$name уже симлинк — похоже, уже усыновлён"
        return
    fi

    mkdir -p "$dest_dir"
    log "переношу $src -> $dest_dir/$name"
    mv "$src" "$dest_dir/$name"

    stow --dir="$DOTFILES_DIR" --target="$HOME" --restow "$name"
    log "$name готов и застоурен обратно"
}

main() {
    command -v stow &>/dev/null || { echo "stow не найден, сначала ./install.sh"; exit 1; }

    for arg in "$@"; do
        if [[ "$arg" == "--file" ]]; then AS_FILE=1; continue; fi
        adopt_one "$arg" "$AS_FILE"
    done
}

main "$@"

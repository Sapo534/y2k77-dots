#!/usr/bin/env bash
# bootstrap.sh — разворачивает dotfiles через GNU Stow
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# какие пакеты разворачивать — по умолчанию все папки репозитория,
# кроме служебных (.git и т.п.). Можно переопределить через .packages
# (по одному имени пакета на строку) или явно передать аргументами.
discover_packages() {
    if [[ -f "$DOTFILES_DIR/.packages" ]]; then
        grep -v '^\s*#' "$DOTFILES_DIR/.packages" | grep -v '^\s*$'
        return
    fi
    find "$DOTFILES_DIR" -maxdepth 1 -mindepth 1 -type d ! -name '.*' -printf '%f\n' | sort
}
mapfile -t PACKAGES < <(discover_packages)

log() { printf '\033[1;35m[dotfiles]\033[0m %s\n' "$1"; }

ensure_stow() {
    if command -v stow &>/dev/null; then
        return
    fi
    log "stow не найден, ставлю через pacman..."
    if command -v pacman &>/dev/null; then
        sudo pacman -S --needed --noconfirm stow
    else
        echo "Не Arch и не нашла pacman — поставь stow сама (apt/dnf/brew install stow)." >&2
        exit 1
    fi
}

backup_conflicts() {
    local pkg="$1"
    # для каждого файла в пакете смотрим, есть ли уже такой же путь в $HOME,
    # и если это НЕ симлинк на наш репозиторий — бэкапим перед stow
    while IFS= read -r -d '' src; do
        local rel="${src#"$DOTFILES_DIR"/"$pkg"/}"
        local target="$HOME/$rel"
        if [[ -e "$target" && ! -L "$target" ]]; then
            mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
            log "бэкаплю существующий $target -> $BACKUP_DIR/$rel"
            mv "$target" "$BACKUP_DIR/$rel"
        elif [[ -L "$target" && "$(readlink -f "$target")" != "$(readlink -f "$src")" ]]; then
            # симлинк есть, но указывает не туда — тоже в бэкап
            log "бэкаплю чужой симлинк $target -> $BACKUP_DIR/$rel"
            mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
            mv "$target" "$BACKUP_DIR/$rel"
        fi
    done < <(find "$DOTFILES_DIR/$pkg" -type f -print0)
}

stow_package() {
    local pkg="$1"
    if [[ ! -d "$DOTFILES_DIR/$pkg" ]]; then
        log "пакет '$pkg' не найден, пропускаю"
        return
    fi
    backup_conflicts "$pkg"
    log "линкую $pkg"
    stow --dir="$DOTFILES_DIR" --target="$HOME" --restow "$pkg"
}

main() {
    ensure_stow

    local targets=("${PACKAGES[@]}")
    if [[ $# -gt 0 ]]; then
        targets=("$@")
    fi

    for pkg in "${targets[@]}"; do
        stow_package "$pkg"
    done

    log "готово. Если что-то поломалось — бэкап лежит в $BACKUP_DIR"
}

main "$@"

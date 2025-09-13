#!/bin/bash

# Скрипт для управления настройками (dotfiles)
SETTINGS_DIR="$HOME/settings"

function show_help() {
    echo "Управление настройками системы"
    echo ""
    echo "Использование: $0 [команда]"
    echo ""
    echo "Команды:"
    echo "  link     - Создать символические ссылки для всех настроек"
    echo "  backup   - Создать резервную копию текущих настроек"
    echo "  restore  - Восстановить настройки из резервной копии"
    echo "  status   - Показать статус настроек"
    echo "  help     - Показать эту справку"
}

function create_links() {
    echo "Создание символических ссылок..."
    
    # Shell configurations
    for file in "$SETTINGS_DIR/shell"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            target="$HOME/.$filename"
            if [ -e "$target" ] && [ ! -L "$target" ]; then
                echo "Создание резервной копии: $target -> $target.backup"
                mv "$target" "$target.backup"
            fi
            echo "Создание ссылки: $target -> $file"
            ln -sf "$file" "$target"
        fi
    done
    
    # Editor configurations
    for file in "$SETTINGS_DIR/editors"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            target="$HOME/.$filename"
            if [ -e "$target" ] && [ ! -L "$target" ]; then
                echo "Создание резервной копии: $target -> $target.backup"
                mv "$target" "$target.backup"
            fi
            echo "Создание ссылки: $target -> $file"
            ln -sf "$file" "$target"
        fi
    done
    
    # Desktop configurations
    for file in "$SETTINGS_DIR/desktop"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            target="$HOME/.$filename"
            if [ -e "$target" ] && [ ! -L "$target" ]; then
                echo "Создание резервной копии: $target -> $target.backup"
                mv "$target" "$target.backup"
            fi
            echo "Создание ссылки: $target -> $file"
            ln -sf "$file" "$target"
        fi
    done
    
    echo "Символические ссылки созданы!"
}

function backup_settings() {
    BACKUP_DIR="$SETTINGS_DIR/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    echo "Создание резервной копии в $BACKUP_DIR..."
    
    # Copy current dotfiles
    for file in ~/.bashrc ~/.bash_profile ~/.bash_logout ~/.zshrc ~/.vimrc ~/.gtkrc-2.0 ~/.xinitrc ~/.Xclients ~/.dir_colors; do
        if [ -f "$file" ]; then
            cp "$file" "$BACKUP_DIR/"
            echo "Скопирован: $(basename $file)"
        fi
    done
    
    echo "Резервная копия создана: $BACKUP_DIR"
}

function show_status() {
    echo "Статус настроек:"
    echo ""
    
    for dir in shell editors desktop; do
        echo "=== $dir ==="
        for file in "$SETTINGS_DIR/$dir"/*; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                target="$HOME/.$filename"
                if [ -L "$target" ]; then
                    echo "✓ .$filename -> символическая ссылка"
                elif [ -f "$target" ]; then
                    echo "⚠ .$filename -> обычный файл"
                else
                    echo "✗ .$filename -> отсутствует"
                fi
            fi
        done
        echo ""
    done
}

case "$1" in
    link)
        create_links
        ;;
    backup)
        backup_settings
        ;;
    status)
        show_status
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        show_help
        ;;
esac
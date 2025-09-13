#!/bin/bash

# Скрипт управления пользовательскими скриптами
SCRIPTS_DIR="$HOME/settings/scripts"
LEGACY_SCRIPTS_DIR="$HOME/scripts"

function show_help() {
    echo "🔧 Управление пользовательскими скриптами"
    echo ""
    echo "Использование: $0 [команда]"
    echo ""
    echo "Команды:"
    echo "  status       - Показать статус скриптов"
    echo "  list         - Показать список доступных скриптов"
    echo "  setup-legacy - Создать ссылки в старой директории ~/scripts/"
    echo "  test-path    - Проверить доступность скриптов в PATH"
    echo "  help         - Показать эту справку"
    echo ""
    echo "Пользовательские скрипты:"
    for script in "$SCRIPTS_DIR"/*; do
        if [[ -f "$script" && -x "$script" ]]; then
            filename=$(basename "$script")
            # Пропускаем системные скрипты dotfiles
            if [[ "$filename" != "manage-settings.sh" && "$filename" != "sync-dotfiles.sh" && "$filename" != "install-dotfiles.sh" && "$filename" != "manage-user-scripts.sh" ]]; then
                echo "  - $filename"
            fi
        fi
    done
}

function show_status() {
    echo "📊 Статус пользовательских скриптов"
    echo ""
    
    # Проверяем PATH
    if echo "$PATH" | grep -q "$SCRIPTS_DIR"; then
        echo "✅ Директория скриптов в PATH: $SCRIPTS_DIR"
    else
        echo "❌ Директория скриптов НЕ в PATH: $SCRIPTS_DIR"
        echo "   Добавьте в ~/.bashrc или ~/.zshrc: export PATH=\"$SCRIPTS_DIR:\$PATH\""
    fi
    
    echo ""
    echo "📝 Пользовательские скрипты:"
    
    for script in "$SCRIPTS_DIR"/*; do
        if [[ -f "$script" && -x "$script" ]]; then
            filename=$(basename "$script")
            # Пропускаем системные скрипты dotfiles
            if [[ "$filename" != "manage-settings.sh" && "$filename" != "sync-dotfiles.sh" && "$filename" != "install-dotfiles.sh" && "$filename" != "manage-user-scripts.sh" ]]; then
                if command -v "$filename" >/dev/null 2>&1; then
                    echo "  ✅ $filename - доступен глобально"
                else
                    echo "  ❌ $filename - недоступен в PATH"
                fi
            fi
        fi
    done
    
    echo ""
    echo "🔗 Совместимость со старой структурой:"
    if [[ -d "$LEGACY_SCRIPTS_DIR" ]]; then
        echo "  📁 Старая директория существует: $LEGACY_SCRIPTS_DIR"
        
        # Проверяем символические ссылки
        for script in "$SCRIPTS_DIR"/*; do
            if [[ -f "$script" && -x "$script" ]]; then
                filename=$(basename "$script")
                if [[ "$filename" != "manage-settings.sh" && "$filename" != "sync-dotfiles.sh" && "$filename" != "install-dotfiles.sh" && "$filename" != "manage-user-scripts.sh" ]]; then
                    legacy_link="$LEGACY_SCRIPTS_DIR/$filename"
                    if [[ -L "$legacy_link" ]]; then
                        echo "  ✅ $filename -> ссылка существует"
                    elif [[ -f "$legacy_link" ]]; then
                        echo "  ⚠️  $filename -> обычный файл (не ссылка)"
                    else
                        echo "  ❌ $filename -> ссылка отсутствует"
                    fi
                fi
            fi
        done
    else
        echo "  📁 Старая директория не существует: $LEGACY_SCRIPTS_DIR"
    fi
}

function list_scripts() {
    echo "📋 Доступные пользовательские скрипты:"
    echo ""
    
    for script in "$SCRIPTS_DIR"/*; do
        if [[ -f "$script" && -x "$script" ]]; then
            filename=$(basename "$script")
            # Пропускаем системные скрипты dotfiles
            if [[ "$filename" != "manage-settings.sh" && "$filename" != "sync-dotfiles.sh" && "$filename" != "install-dotfiles.sh" && "$filename" != "manage-user-scripts.sh" ]]; then
                echo "🔧 $filename"
                
                # Пытаемся извлечь описание из первых строк скрипта
                description=$(head -10 "$script" | grep -E "^#.*[Оо]писание|^# .*[Dd]escription|^#.*Purpose" | head -1 | sed 's/^# *//')
                if [[ -n "$description" ]]; then
                    echo "   $description"
                else
                    # Альтернативный способ - ищем комментарии
                    alt_desc=$(head -5 "$script" | grep "^#" | grep -v "#!/" | head -1 | sed 's/^# *//')
                    if [[ -n "$alt_desc" ]]; then
                        echo "   $alt_desc"
                    else
                        echo "   (без описания)"
                    fi
                fi
                echo ""
            fi
        fi
    done
}

function setup_legacy_links() {
    echo "🔗 Создание ссылок в старой директории $LEGACY_SCRIPTS_DIR"
    
    mkdir -p "$LEGACY_SCRIPTS_DIR"
    
    for script in "$SCRIPTS_DIR"/*; do
        if [[ -f "$script" && -x "$script" ]]; then
            filename=$(basename "$script")
            # Пропускаем системные скрипты dotfiles
            if [[ "$filename" != "manage-settings.sh" && "$filename" != "sync-dotfiles.sh" && "$filename" != "install-dotfiles.sh" && "$filename" != "manage-user-scripts.sh" ]]; then
                legacy_link="$LEGACY_SCRIPTS_DIR/$filename"
                
                if [[ -e "$legacy_link" && ! -L "$legacy_link" ]]; then
                    echo "⚠️  Резервное копирование: $legacy_link -> $legacy_link.backup_$(date +%Y%m%d_%H%M%S)"
                    mv "$legacy_link" "$legacy_link.backup_$(date +%Y%m%d_%H%M%S)"
                fi
                
                echo "✅ Создание ссылки: $legacy_link -> $script"
                ln -sf "$script" "$legacy_link"
            fi
        fi
    done
    
    echo "🎉 Ссылки созданы! Теперь скрипты доступны и в $LEGACY_SCRIPTS_DIR"
}

function test_path() {
    echo "🧪 Тестирование доступности скриптов в PATH"
    echo ""
    
    for script in "$SCRIPTS_DIR"/*; do
        if [[ -f "$script" && -x "$script" ]]; then
            filename=$(basename "$script")
            # Пропускаем системные скрипты dotfiles
            if [[ "$filename" != "manage-settings.sh" && "$filename" != "sync-dotfiles.sh" && "$filename" != "install-dotfiles.sh" && "$filename" != "manage-user-scripts.sh" ]]; then
                echo -n "🔍 Тестирование $filename: "
                if command -v "$filename" >/dev/null 2>&1; then
                    which_result=$(which "$filename")
                    echo "✅ найден в $which_result"
                else
                    echo "❌ не найден в PATH"
                fi
            fi
        fi
    done
    
    echo ""
    echo "💡 Если скрипты не найдены, выполните:"
    echo "   source ~/.bashrc"
    echo "   # или перезапустите терминал"
}

case "$1" in
    status)
        show_status
        ;;
    list|ls)
        list_scripts
        ;;
    setup-legacy)
        setup_legacy_links
        ;;
    test-path|test)
        test_path
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        show_help
        ;;
esac
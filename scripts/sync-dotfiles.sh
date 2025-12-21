#!/bin/bash

# Скрипт для быстрой синхронизации dotfiles с GitHub

SETTINGS_DIR="$HOME/settings"

# Определяем, как был вызван скрипт
SCRIPT_NAME="$(basename "$0")"

function sync_dotfiles() {
    cd "$SETTINGS_DIR" || {
        echo "❌ Ошибка: не могу найти папку settings"
        exit 1
    }

    echo "🔍 Проверяю изменения..."
    
    if [[ -z $(git status --porcelain) ]]; then
        echo "✅ Нет изменений для сохранения"
        echo "🔄 Проверяю обновления с GitHub..."
        git pull
        return 0
    fi

    echo "📝 Найдены изменения:"
    git status --short

    if [[ $1 ]]; then
        commit_message="$*"
    else
        echo ""
        echo "💬 Введите описание изменений (или Enter для автоматического):"
        read -r user_message
        
        if [[ -n $user_message ]]; then
            commit_message="$user_message"
        else
            # Автоматическое сообщение на основе изменённых файлов
            changed_files=$(git diff --name-only HEAD)
            if [[ $changed_files == *"shell"* ]]; then
                commit_message="📝 Update shell configuration"
            elif [[ $changed_files == *"editors"* ]]; then
                commit_message="⚡ Update editor settings"
            elif [[ $changed_files == *"desktop"* ]]; then
                commit_message="🎨 Update desktop configuration"
            else
                commit_message="🔧 Update dotfiles configuration"
            fi
        fi
    fi

    echo "💾 Сохраняю изменения..."
    git add .
    git commit -m "$commit_message"

    echo "☁️  Загружаю на GitHub..."
    if git push; then
        echo "✅ Готово! Настройки синхронизированы"
        echo "🔗 https://github.com/GoncharenkoVitaliy/dotfiles"
    else
        echo "❌ Ошибка при загрузке. Проверьте подключение к интернету"
        exit 1
    fi
}

function show_status() {
    cd "$SETTINGS_DIR" || exit 1
    echo "📊 Статус репозитория dotfiles:"
    echo ""
    git status
    echo ""
    echo "📈 Последние коммиты:"
    git log --oneline -5
}

function pull_updates() {
    cd "$SETTINGS_DIR" || exit 1
    echo "🔄 Получаю обновления с GitHub..."
    git pull
    echo "🔗 Обновляю символические ссылки..."
    ~/settings/scripts/manage-settings.sh link
}

# Если вызван как dotpush, выполняем sync
if [[ "$SCRIPT_NAME" == "dotpush" ]]; then
    sync_dotfiles "$@"
    exit 0
fi

# Если вызван как dotpull, выполняем pull
if [[ "$SCRIPT_NAME" == "dotpull" ]]; then
    pull_updates
    exit 0
fi

case "$1" in
    sync|push|save)
        shift
        sync_dotfiles "$@"
        ;;
    status|st)
        show_status
        ;;
    pull|update)
        pull_updates
        ;;
    *)
        echo "🔧 Синхронизация dotfiles"
        echo ""
        echo "Использование: $0 [команда] [сообщение]"
        echo ""
        echo "Команды:"
        echo "  sync [сообщение]  - Сохранить и загрузить изменения"
        echo "  status           - Показать статус репозитория"
        echo "  pull             - Получить обновления с GitHub"
        echo ""
        echo "Примеры:"
        echo "  $0 sync \"Added vim configuration\""
        echo "  $0 sync     # интерактивный режим"
        echo "  $0 status   # посмотреть статус"
        ;;
esac
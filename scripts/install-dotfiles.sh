#!/bin/bash

# Скрипт для установки dotfiles на новую машину

REPO_URL="https://github.com/GoncharenkoVitaliy/dotfiles.git"
SETTINGS_DIR="$HOME/settings"

function show_banner() {
    echo "🚀 Установка dotfiles на новую машину"
    echo "======================================"
    echo ""
}

function check_requirements() {
    echo "🔍 Проверяю требования..."
    
    # Проверяем git
    if ! command -v git &> /dev/null; then
        echo "❌ Git не установлен. Установите git и повторите попытку."
        exit 1
    fi
    
    echo "✅ Git найден: $(git --version)"
}

function backup_existing() {
    if [[ -d "$SETTINGS_DIR" ]]; then
        echo "⚠️  Папка $SETTINGS_DIR уже существует"
        echo "🔄 Создаю резервную копию..."
        mv "$SETTINGS_DIR" "${SETTINGS_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
}

function clone_dotfiles() {
    echo "📥 Клонирую dotfiles репозиторий..."
    
    if git clone "$REPO_URL" "$SETTINGS_DIR"; then
        echo "✅ Репозиторий успешно склонирован"
    else
        echo "❌ Ошибка при клонировании репозитория"
        echo "Проверьте подключение к интернету и права доступа"
        exit 1
    fi
}

function setup_permissions() {
    echo "🔧 Настраиваю права доступа..."
    chmod +x "$SETTINGS_DIR/scripts"/*.sh
}

function create_backups() {
    echo "💾 Создаю резервные копии существующих настроек..."
    BACKUP_DIR="$SETTINGS_DIR/backups/initial_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Список файлов для резервного копирования
    files_to_backup=(
        "$HOME/.bashrc"
        "$HOME/.bash_profile" 
        "$HOME/.bash_logout"
        "$HOME/.zshrc"
        "$HOME/.vimrc"
        "$HOME/.gtkrc-2.0"
        "$HOME/.xinitrc"
        "$HOME/.Xclients"
        "$HOME/.dir_colors"
    )
    
    for file in "${files_to_backup[@]}"; do
        if [[ -f "$file" && ! -L "$file" ]]; then
            cp "$file" "$BACKUP_DIR/"
            echo "📋 Скопирован: $(basename "$file")"
        fi
    done
    
    if [[ $(ls -A "$BACKUP_DIR" 2>/dev/null) ]]; then
        echo "✅ Резервные копии созданы в: $BACKUP_DIR"
    else
        echo "ℹ️  Существующие конфигурационные файлы не найдены"
        rmdir "$BACKUP_DIR"
    fi
}

function create_symlinks() {
    echo "🔗 Создаю символические ссылки..."
    "$SETTINGS_DIR/scripts/manage-settings.sh" link
}

function setup_git() {
    echo "⚙️  Настройка Git..."
    cd "$SETTINGS_DIR" || exit 1
    
    # Проверяем конфигурацию git
    if [[ -z $(git config user.name) ]]; then
        echo "📝 Настройте Git:"
        echo -n "Введите ваше имя: "
        read -r git_name
        git config user.name "$git_name"
        
        echo -n "Введите ваш email: "
        read -r git_email
        git config user.email "$git_email"
    fi
    
    echo "✅ Git настроен для пользователя: $(git config user.name)"
}

function install_tools() {
    echo "🛠️  Рекомендуется установить дополнительные инструменты:"
    echo ""
    echo "# Manjaro/Arch Linux:"
    echo "sudo pacman -S vim git github-cli nodejs npm"
    echo ""
    echo "# Ubuntu/Debian:"
    echo "sudo apt update && sudo apt install vim git gh nodejs npm"
    echo ""
    echo "# После установки GitHub CLI выполните:"
    echo "gh auth login"
    echo ""
}

function finish_installation() {
    echo ""
    echo "🎉 Установка завершена!"
    echo ""
    echo "📋 Что дальше:"
    echo "1. Перезапустите терминал для применения настроек"
    echo "2. Проверьте статус: dotfiles status"
    echo "3. Синхронизируйте изменения: dotsync"
    echo ""
    echo "🔧 Полезные команды:"
    echo "  dotfiles status  - статус настроек"
    echo "  dotfiles link    - создать ссылки"
    echo "  dotsync         - синхронизация с GitHub"
    echo "  dotpush         - быстро сохранить изменения"
    echo "  dotpull         - получить обновления"
    echo ""
    echo "📚 Документация: $SETTINGS_DIR/README.md"
    echo "🔗 Репозиторий: https://github.com/GoncharenkoVitaliy/dotfiles"
    echo ""
}

# Основная функция установки
function main() {
    show_banner
    check_requirements
    backup_existing
    clone_dotfiles
    setup_permissions
    create_backups
    create_symlinks
    setup_git
    install_tools
    finish_installation
}

# Запуск установки
main
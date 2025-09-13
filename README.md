# Настройки системы (Dotfiles)

Эта директория содержит централизованные настройки системы, организованные по категориям.

## Структура

```
settings/
├── shell/          # Настройки оболочек (bash, zsh, etc.)
├── editors/        # Настройки редакторов (vim, nano, etc.)
├── development/    # Настройки для разработки (git, ssh, etc.)
├── desktop/        # Настройки рабочего стола (gtk, x11, etc.)
├── applications/   # Настройки приложений
├── scripts/        # Вспомогательные скрипты
└── backups/        # Резервные копии
```

## Использование

### Скрипт управления настройками

Используйте `scripts/manage-settings.sh` для управления настройками:

```bash
# Показать справку
~/settings/scripts/manage-settings.sh help

# Показать статус настроек
~/settings/scripts/manage-settings.sh status

# Создать символические ссылки
~/settings/scripts/manage-settings.sh link

# Создать резервную копию
~/settings/scripts/manage-settings.sh backup
```

### Добавление новых настроек

**Для файлов:**
1. Поместите файл конфигурации в соответствующую папку (без точки в начале)
2. Запустите `~/settings/scripts/manage-settings.sh link`

**Для директорий:**
1. Поместите директорию в `editors/` (например: `editors/vim/`)
2. Запустите `~/settings/scripts/manage-settings.sh link`
3. Создастся ссылка `~/.vim -> ~/settings/editors/vim`

### 🚀 Быстрая установка на НОВУЮ машину

Для установки dotfiles на новый компьютер выполните одну команду:

```bash
bash <(curl -s https://raw.githubusercontent.com/GoncharenkoVitaliy/dotfiles/main/scripts/install-dotfiles.sh)
```

**Или вручную:**

```bash
# 1. Клонировать репозиторий
git clone https://github.com/GoncharenkoVitaliy/dotfiles.git ~/settings

# 2. Запустить установку
~/settings/scripts/install-dotfiles.sh
```

### 🔄 Ежедневная синхронизация

**Быстрые команды:**
```bash
dotpush          # Сохранить изменения на GitHub
dotpull          # Получить обновления с GitHub
dotsync status   # Проверить статус
```

**Подробные команды:**
```bash
# Сохранить с описанием
dotsync sync "Added new vim plugins"

# Интерактивное сохранение
dotsync sync

# Проверить статус
dotsync status

# Получить обновления
dotsync pull
```

### 🚀 Управление пользовательскими скриптами

**Основные команды:**
```bash
scripts status      # Проверить статус скриптов
scripts list        # Показать список скриптов
scripts test-path   # Проверить доступность в PATH
scripts setup-legacy # Создать ссылки в ~/scripts/
```

**Полная команда:**
```bash
manage-user-scripts.sh [status|list|test-path|setup-legacy|help]
```

**После перезапуска терминала скрипты доступны глобально:**
```bash
CS              # Создать новый скрипт
user_add        # Добавить пользователя
user_del        # Удалить пользователя
upgradeSystem   # Обновить систему
```

## Резервные копии

- Оригинальные файлы сохраняются с расширением `.backup`
- Автоматические резервные копии создаются в `backups/` с временной меткой
- Используйте `manage-settings.sh backup` перед внесением изменений

## Безопасность

- Файл `.gitignore` настроен для исключения чувствительных данных
- Никогда не добавляйте пароли, токены или ключи в настройки
- Проверяйте содержимое файлов перед коммитом в git

## Текущие настройки

### Shell
- `bashrc` - конфигурация Bash
- `bash_profile` - профиль Bash
- `bash_logout` - команды при выходе из Bash
- `zshrc` - конфигурация Zsh
- `dir_colors` - цвета для ls

### Desktop
- `gtkrc-2.0` - настройки GTK 2.0
- `xinitrc` - скрипт инициализации X11
- `Xclients` - клиенты X11

### Editors
- `vim/` - конфигурация Vim (директория .vim)
  - `vimrc` - основной файл конфигурации

### Scripts (Пользовательские скрипты)
- `CS` - скрипт для создания новых скриптов
- `user_add` - скрипт для добавления пользователей
- `user_del` - скрипт для удаления пользователей
- `upgradeSystem` - скрипт для обновления системы

ℹ️ **Пользовательские скрипты доступны глобально** через PATH после перезапуска терминала.

### Development
- (будут добавлены конфигурации git, ssh и других инструментов разработки)

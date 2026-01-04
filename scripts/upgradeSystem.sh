#!/usr/bin/env bash
# upgradeSystem.sh — universal system updater (host or VM)
# Supports: APT, Pacman, DNF, Zypper, Flatpak, Snap, Timeshift (any distro)
# + cache cleanup + disk usage report

if [[ -t 1 ]]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; CYAN='\033[0;36m'
    BOLD='\033[1m'; RESET='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; MAGENTA=''; CYAN=''; BOLD=''; RESET=''
fi

header() { echo -e "${BOLD}${MAGENTA}$*${RESET}"; }
section() { echo -e "${BOLD}${BLUE}$*${RESET}"; }
info() { echo -e "${GREEN}✓ $*${RESET}"; }
warn() { echo -e "${YELLOW}⚠ $*${RESET}"; }
error() { echo -e "${RED}✗ $*${RESET}"; }

LOG_DIR="$HOME/settings/backups/update_logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(date +%Y%m%d_%H%M%S)_upgradeSystem.log"
exec > >(tee -a "$LOG_FILE") 2>&1

#=========================================================
# Вспомогательные функции

is_timeshift_available() {
    command -v timeshift >/dev/null 2>&1 && [[ -f /etc/timeshift/timeshift.json ]]
}

backup_system() {
    section "📁 Creating filesystem snapshot via Timeshift..."

    # 1. Проверка: установлен ли timeshift
    if ! command -v timeshift >/dev/null 2>&1; then
        warn "Timeshift is not installed — skipping snapshot."
        return
    fi

    # 2. Опциональная проверка конфига (только с jq)
    local config="/etc/timeshift/timeshift.json"
    if command -v jq >/dev/null 2>&1; then
        if [[ -f "$config" ]] && [[ -s "$config" ]] && jq empty "$config" >/dev/null 2>&1; then
            local device
            device=$(jq -r '.backup_device // empty' "$config" 2>/dev/null)
            if [[ -n "$device" ]] && [[ "$device" != "null" ]]; then
                info "✅ Timeshift config: backup device = $device"
            else
                info "ⓘ Timeshift config: no external backup device (local snapshots only)"
            fi
        else
            info "ⓘ Timeshift config not found or invalid — using defaults."
        fi
    else
        info "ⓘ jq not installed — skipping config validation."
    fi

    # 3. 🔥 Создаём снапшот ВСЕГДА перед обновлением (даже если расписание выключено)
    info "→ Creating manual snapshot (pre-update)..."
    if sudo timeshift --create --tags O --comments "Pre-update snapshot @ $(date '+%Y-%m-%d %H:%M')" --scripted; then
        success "✅ Snapshot created successfully."
    else
        warn "❌ Failed to create snapshot. System update will continue without backup."
        # Не прерываем — продолжаем обновление (на ваше усмотрение)
    fi
}

report_disk_usage() {
    section "📊 Disk usage report"
    echo "Mountpoint      Size  Used Avail Use% Path"
    df -h / /home /tmp /var 2>/dev/null | grep -E '^(/|[[:space:]])' | while IFS= read -r line; do
        [[ -n "$line" ]] && echo "  $line"
    done

    echo -e "\n  Key directories:"
    for dir in /var/log /var/cache /tmp "$HOME/.cache" "$HOME/.local/share/flatpak"; do
        [[ -d "$dir" ]] && printf "  %-30s %s\n" "$dir:" "$(du -sh "$dir" 2>/dev/null | cut -f1)"
    done
}

cleanup_caches() {
    section "🧹 Cleaning caches & logs"

    # System logs
    if command -v journalctl &> /dev/null; then
        info "→ Cleaning systemd journal..."
        sudo journalctl --vacuum-time=14d -q 2>/dev/null || \
        sudo journalctl --vacuum-size=200M -q 2>/dev/null || true
    fi

    # Package managers
    if command -v apt &> /dev/null; then
        info "→ Cleaning APT cache..."
        sudo apt clean -qq 2>/dev/null
        sudo apt autoclean -qq 2>/dev/null
    elif command -v pacman &> /dev/null; then
        info "→ Cleaning Pacman cache (keeping last 3 versions)..."
        # Оставляем последние 3 версии вместо полного удаления
        if command -v paccache &> /dev/null; then
            sudo paccache -r -k 3 2>/dev/null || true
            sudo paccache -r -u -k 0 2>/dev/null || true  # Удалить все деинсталлированные
        else
            sudo pacman -Sc --noconfirm 2>/dev/null || true
        fi
        
        # Очистка AUR helper cache
        if command -v yay &> /dev/null; then
            info "→ Cleaning yay cache..."
            yay -Sc --noconfirm 2>/dev/null || true
        elif command -v paru &> /dev/null; then
            info "→ Cleaning paru cache..."
            paru -Sc --noconfirm 2>/dev/null || true
        fi
    elif command -v dnf &> /dev/null; then
        info "→ Cleaning DNF cache..."
        sudo dnf clean all -q 2>/dev/null || true
    elif command -v zypper &> /dev/null; then
        info "→ Cleaning Zypper cache..."
        sudo zypper clean -a -q 2>/dev/null || true
    fi

    # User cache cleanup
    if [[ -d "$HOME/.cache" ]]; then
        info "→ Cleaning user cache (~/.cache)..."
        
        # Очистка старых файлов (не использовались 30+ дней)
        local cleaned
        cleaned=$(find "$HOME/.cache" -type f -atime +30 -delete -print 2>/dev/null | wc -l)
        [[ $cleaned -gt 0 ]] && info "  Deleted $cleaned old files (30+ days)"
        
        # UV cache (Python package manager)
        if command -v uv &> /dev/null && [[ -d "$HOME/.cache/uv" ]]; then
            local uv_size_before=$(du -sm "$HOME/.cache/uv" 2>/dev/null | cut -f1)
            uv cache clean 2>/dev/null || true
            local uv_size_after=$(du -sm "$HOME/.cache/uv" 2>/dev/null | cut -f1)
            info "  UV cache: ${uv_size_before}MB → ${uv_size_after}MB"
        fi
        
        # Pip cache
        if command -v pip &> /dev/null && [[ -d "$HOME/.cache/pip" ]]; then
            pip cache purge 2>/dev/null || true
            info "  Pip cache cleared"
        fi
        
        # Chrome/Chromium cache (безопасная очистка старых файлов)
        for chrome_dir in "$HOME/.cache/google-chrome" "$HOME/.cache/chromium"; do
            if [[ -d "$chrome_dir" ]]; then
                find "$chrome_dir" -type f -atime +7 -delete 2>/dev/null || true
            fi
        done
    fi

    # Thumbnail cache
    if [[ -d "$HOME/.cache/thumbnails" ]]; then
        info "→ Cleaning thumbnail cache..."
        find "$HOME/.cache/thumbnails" -type f -atime +30 -delete 2>/dev/null || true
    fi

    # Trash cleanup
    if [[ -d "$HOME/.local/share/Trash" ]]; then
        info "→ Emptying trash..."
        rm -rf "$HOME/.local/share/Trash/"* 2>/dev/null || true
    fi

    # Temp files
    if [[ -d "/tmp" ]]; then
        info "→ Cleaning /tmp (files older than 7 days)..."
        sudo find /tmp -type f -atime +7 -user "$USER" -delete 2>/dev/null || true
    fi

    # Flatpak/Snap cleanup
    if command -v flatpak &> /dev/null; then
        info "→ Cleaning Flatpak unused runtimes..."
        flatpak uninstall --user --unused -y 2>/dev/null || true
        sudo flatpak uninstall --unused -y 2>/dev/null || true
        flatpak repair --user 2>/dev/null || true
    fi
    if command -v snap &> /dev/null; then
        info "→ Cleaning old Snap revisions..."
        sudo snap set system refresh.retain=2 2>/dev/null || true
        # Удаление старых ревизий снапов
        snap list --all | awk '/disabled/{print $1, $3}' | \
        while read snapname revision; do
            sudo snap remove "$snapname" --revision="$revision" 2>/dev/null || true
        done
    fi

    # Docker cleanup (если установлен)
    if command -v docker &> /dev/null && docker info &>/dev/null; then
        info "→ Cleaning Docker resources..."
        docker system prune -af --volumes 2>/dev/null || true
    fi
}

#=========================================================
# Основной процесс

header "🚀 Starting system update..."

# 0. Disk report (before)
report_disk_usage

# 1. Filesystem snapshot (if Timeshift available)
backup_system

# --- 2. Обновление для APT (Debian, Ubuntu, Pop!_OS, Mint) ---
if command -v apt-get &> /dev/null; then
    section "  Detected APT-based system (using apt-get for scripting stability)."
    
    # Тихое обновление списка пакетов
    sudo apt-get update -qq
    
    # Обновление установленных пакетов (без вопросов о конфигах)
    sudo apt-get upgrade -y \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" || true
    
    # Полное обновление (учитывает зависимости, как full-upgrade)
    sudo apt-get dist-upgrade -y \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" || true
    
    # Восстановление после частичных обновлений
    sudo dpkg --configure -a || true
    
    # Очистка
    sudo apt-get autoremove -y --purge
    sudo apt-get autoclean -qq
    sudo apt-get clean -qq
    
    info "  APT packages updated (via apt-get)."
fi

# --- 3. Pacman ---
if command -v pacman &> /dev/null; then
    section "📦 Pacman (Arch family)"
    sudo pacman -Syu --noconfirm || warn "Core update failed."

    # AUR
    if command -v yay &> /dev/null; then
        info "→ Updating AUR (yay)..."
        yay -Sua --devel --timeupdate --noconfirm 2>/dev/null || warn "AUR update failed."
    elif command -v paru &> /dev/null; then
        info "→ Updating AUR (paru)..."
        paru -Sua --devel --timeupdate --noconfirm 2>/dev/null || warn "AUR update failed."
    fi

    # Orphans
    orphans=$(pacman -Qdtq 2>/dev/null)
    if [[ -n "$orphans" ]]; then
        sudo pacman -Rs $orphans --noconfirm 2>/dev/null && info "Removed orphans: $orphans"
    fi
    info "Pacman update completed."
fi

# --- 4. DNF ---
if command -v dnf &> /dev/null; then
    section "📦 DNF (Fedora/RHEL family)"
    sudo dnf upgrade -y || true
    sudo dnf autoremove -y || true
    info "DNF update completed."
fi

# --- 5. Zypper ---
if command -v zypper &> /dev/null; then
    section "📦 Zypper (openSUSE)"
    sudo zypper refresh -y || true
    sudo zypper update -y || true
    info "Zypper update completed."
fi

# --- 6. Flatpak/Snap (update only; cleanup in cleanup_caches)
if command -v flatpak &> /dev/null; then :; fi  # already covered
if command -v flatpak &> /dev/null; then
    section "📦 Flatpak"
    flatpak update --user -y 2>/dev/null || true
    sudo flatpak update -y 2>/dev/null || true
    info "Flatpak update completed."
fi
if command -v snap &> /dev/null; then
    section "📦 Snap"
    sudo snap refresh 2>/dev/null || true
    info "Snap update completed."
fi

# --- 7. Final cleanup ---
cleanup_caches

# 8. Disk report (after)
report_disk_usage

header "✅ System update & cleanup finished. Log: $LOG_FILE"



# sudo journalctl --vacuum-time=7d # Очистка старых логов (пример, сохранение за 7 дней)
# sudo apt-get purge $(dpkg -l 'linux-*' | sed '/^ii/!d; /prereq/d; /rc/d' | grep -v "$(uname -r | sed 's/-generic//')" | awk '{print $2}' | xargs) # Удаление старых ядер (ОЧЕНЬ ОСТОРОЖНО)

# Настройка zram и отключение swap
# RAM_GB=$(free -g | awk '/^Mem:/ {print $2}'); SIZE_PCT=$(( RAM_GB >= 16 ? 50 : 100 )); SWAPPINESS=$(( RAM_GB >= 16 ? 40 : 80 )); sudo apt install -y zram-tools && echo -e "ENABLED=true\nSIZE=${SIZE_PCT}%\nALGO=zstd\nPRIORITY=100" | sudo tee /etc/default/zramswap > /dev/null && echo "vm.swappiness = $SWAPPINESS" | sudo tee -a /etc/sysctl.conf > /dev/null && sudo sysctl -w vm.swappiness=$SWAPPINESS && sudo swapoff -a && sudo sed -i 's/^\([^#].*swap.*\)$/# \1/' /etc/fstab && sudo systemctl restart zramswap

# Однострочник для Manjaro
# sudo tee /etc/systemd/zram-generator.conf <<'EOF' && sudo systemctl daemon-reload && sudo systemctl start /dev/zram0 && echo 'vm.swappiness=40' | sudo tee -a /etc/sysctl.d/90-zram.conf && sudo sysctl --system
# [zram0]
# zram-size = ram / 2
# compression-algorithm = zstd
# swap-priority = 100
# EOF#

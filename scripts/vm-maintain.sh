#! /usr/bin/env bash

# vm-maintain.sh — VM-specific maintenance (no duplication with upgradeSystem.sh)
# Focus: disk compaction, zram, zerofree prep, extended disk report

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

LOG_DIR="$HOME/settings/backups/maintenance_logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(date +%Y%m%d_%H%M%S)_vm-maintain.log"
exec > >(tee -a "$LOG_FILE") 2>&1

header "🔧 VM-Specific Maintenance..."

# --- 1. TRIM for SSD / VirtualBox ---
if [[ $(findmnt -n -o FSTYPE /) == "ext4" ]]; then
    section "🔍 TRIM (fstrim)"
    if sudo fstrim -v / 2>/dev/null; then
        info "TRIM completed."
    else
        warn "TRIM not supported (check disk type or permissions)."
    fi
fi

# --- 2. zram status ---
if command -v zramctl &> /dev/null && zramctl | grep -q zram; then
    section "💾 zram status"
    zramctl | grep -v '^NAME' | while IFS= read -r line; do [[ -n "$line" ]] && echo "  $line"; done
    info "zram active."
elif [[ -e /proc/swaps ]] && grep -q zram /proc/swaps; then
    info "zram active (fallback check)."
else
    warn "zram not active — consider: sudo apt install zram-config"
fi

# --- 3. Extended disk report (VM-focused) ---
section "📊 Extended VM disk report"
echo "  Disk device info:"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE 2>/dev/null | while IFS= read -r line; do [[ -n "$line" ]] && echo "  $line"; done

echo -e "\n  Inode usage (important for many small files):"
df -i / 2>/dev/null | while IFS= read -r line; do [[ -n "$line" ]] && echo "  $line"; done

# --- 4. Prepare for zerofree (only with --full) ---
if [[ "$1" == "--full" ]]; then
    section "⚠️  Preparing for zerofree (requires reboot to recovery)"
    info "Writing zeros to free space (this may take several minutes)..."
    local zero_file="/tmp/ZERO"
    dd if=/dev/zero of="$zero_file" bs=1M count=1024 2>/dev/null || \
    dd if=/dev/zero of="$zero_file" bs=1M count=512 2>/dev/null || \
    { warn "Partial zero-fill completed (disk may be full). Still useful for compaction."; }
    sync
    rm -f "$zero_file"
    info "✅ Zero-fill done. Now:"
    echo -e "${YELLOW}  1. Reboot into recovery mode${RESET}"
    echo -e "${YELLOW}  2. Run: sudo zerofree -v /dev/sda1${RESET}"
    echo -e "${YELLOW}  3. Shutdown → VirtualBox: Media Manager → Compact${RESET}"
fi

# Убедимся, что curl/wget есть — иначе Guest Additions не вставятся
if ! command -v curl &> /dev/null || ! command -v wget &> /dev/null; then
    warn "curl/wget missing — Guest Additions may fail to download. Installing..."
    sudo apt install -y --no-install-recommends curl wget ca-certificates
fi

header "✅ VM maintenance finished. Log: $LOG_FILE"


#!/usr/bin/env bash
# vim configuration installer
# Supports: macOS, Ubuntu/Debian, CentOS/RHEL/Fedora
set -euo pipefail

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ─── Globals ──────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOME_DIR="$HOME"
VIMRC_SRC="$SCRIPT_DIR/.vimrc"
VIMRC_DST="$HOME_DIR/.vimrc"
VIMRC_BAK="$HOME_DIR/.vimrc.bak"
PLUG_DST="$HOME_DIR/.vim/autoload/plug.vim"
PLUG_URL="https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
PLUG_MIRROR="https://gitee.com/mirrors/vim-plug/raw/master/plug.vim"
PLUG_RETRY=3
PLUG_RETRY_DELAY=5

# ─── Helpers ──────────────────────────────────────────────────────────────────
info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()      { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; }

die() {
    error "$*"
    echo ""
    rollback
    exit 1
}

# ─── Rollback ─────────────────────────────────────────────────────────────────
_rollback_done=0
rollback() {
    [ "$_rollback_done" -eq 1 ] && return
    _rollback_done=1

    # Restore vimrc from backup if we replaced it
    if [ -f "$VIMRC_BAK" ] && [ -f "$VIMRC_DST" ]; then
        warn "Restoring previous .vimrc from backup"
        cp -f "$VIMRC_BAK" "$VIMRC_DST"
    fi
}
trap rollback EXIT

# ─── OS Detection ─────────────────────────────────────────────────────────────
detect_os() {
    local kernel
    kernel="$(uname -s)"

    case "$kernel" in
        Darwin)
            echo "macos"
            return
            ;;
        Linux)
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                case "$ID" in
                    ubuntu|debian|devuan)  echo "debian"; return ;;
                    centos|rhel|fedora)    echo "rhel";   return ;;
                    *)                     echo "unknown ($ID)" ;;
                esac
            fi
            echo "unknown"
            ;;
        *)
            echo "unknown ($kernel)"
            ;;
    esac
}

has_command() { command -v "$1" >/dev/null 2>&1; }

# ─── Package Manager ──────────────────────────────────────────────────────────
pkg_install() {
    local os="$1"; shift
    local packages=("$@")

    case "$os" in
        macos)
            if ! has_command brew; then
                die "Homebrew not found. Install it first: https://brew.sh"
            fi
            for pkg in "${packages[@]}"; do
                if brew list "$pkg" >/dev/null 2>&1; then
                    ok "$pkg already installed"
                else
                    info "Installing $pkg via Homebrew..."
                    brew install "$pkg" || die "Failed to install $pkg"
                    ok "$pkg installed"
                fi
            done
            ;;
        debian)
            if ! has_command sudo; then
                die "sudo not found — install it or run as root"
            fi
            info "Updating apt cache..."
            sudo apt-get update -qq || die "apt-get update failed"
            for pkg in "${packages[@]}"; do
                if dpkg -s "$pkg" 2>/dev/null | grep -q 'Status: install ok installed'; then
                    ok "$pkg already installed"
                else
                    info "Installing $pkg via apt-get..."
                    sudo apt-get install -y -qq "$pkg" || die "Failed to install $pkg"
                    ok "$pkg installed"
                fi
            done
            ;;
        rhel)
            local mgr="yum"
            has_command dnf && mgr="dnf"
            if ! has_command sudo; then
                die "sudo not found — install it or run as root"
            fi
            for pkg in "${packages[@]}"; do
                if rpm -q "$pkg" >/dev/null 2>&1; then
                    ok "$pkg already installed"
                else
                    info "Installing $pkg via $mgr..."
                    sudo "$mgr" install -y -q "$pkg" || die "Failed to install $pkg"
                    ok "$pkg installed"
                fi
            done
            ;;
        *)
            die "Unsupported OS: $os — please install clang, ctags, astyle manually"
            ;;
    esac
}

# ─── Network Check ────────────────────────────────────────────────────────────
check_network() {
    info "Checking network connectivity..."
    if ! has_command ping; then
        warn "ping not found, skipping network check"
        return
    fi
    if ! ping -c 2 -W 3 baidu.com >/dev/null 2>&1; then
        die "No network connection. Please check your network and retry."
    fi
    ok "Network OK"
}

# ─── Download with Retry ─────────────────────────────────────────────────────
download_with_retry() {
    local url="$1" dest="$2"
    local attempt=1

    while [ "$attempt" -le "$PLUG_RETRY" ]; do
        info "Download attempt $attempt/$PLUG_RETRY from $url"

        if has_command curl; then
            if curl -fSL --connect-timeout 10 --max-time 30 \
               -o "$dest" "$url" 2>/dev/null; then
                return 0
            fi
        elif has_command wget; then
            if wget -q --timeout=10 --tries=1 -O "$dest" "$url" 2>/dev/null; then
                return 0
            fi
        else
            die "Neither curl nor wget found"
        fi

        warn "Attempt $attempt failed"
        attempt=$((attempt + 1))
        [ "$attempt" -le "$PLUG_RETRY" ] && sleep "$PLUG_RETRY_DELAY"
    done
    return 1
}

# ─── Install vim-plug ─────────────────────────────────────────────────────────
install_plug() {
    if [ -f "$PLUG_DST" ]; then
        ok "vim-plug already installed ($PLUG_DST)"
        return
    fi

    info "Installing vim-plug..."
    mkdir -p "$(dirname "$PLUG_DST")"

    # Try primary URL first, then mirror
    if download_with_retry "$PLUG_URL" "$PLUG_DST"; then
        ok "vim-plug installed from GitHub"
        return
    fi

    warn "GitHub unreachable, trying mirror..."
    if download_with_retry "$PLUG_MIRROR" "$PLUG_DST"; then
        ok "vim-plug installed from Gitee mirror"
        return
    fi

    rm -f "$PLUG_DST"
    die "Failed to download vim-plug from all sources"
}

# ─── Backup & Copy vimrc ─────────────────────────────────────────────────────
install_vimrc() {
    if [ ! -f "$VIMRC_SRC" ]; then
        die ".vimrc not found in script directory ($VIMRC_SRC)"
    fi

    # Backup existing .vimrc (never overwrite backup)
    if [ -f "$VIMRC_DST" ]; then
        if [ -f "$VIMRC_BAK" ]; then
            # Save timestamped backup to avoid losing old configs
            local ts_bak="${VIMRC_BAK}.$(date +%Y%m%d%H%M%S)"
            info "Backup already exists, saving additional copy to $(basename "$ts_bak")"
            cp -f "$VIMRC_DST" "$ts_bak"
        else
            info "Backing up existing .vimrc to .vimrc.bak"
            cp -f "$VIMRC_DST" "$VIMRC_BAK"
        fi
    fi

    cp -f "$VIMRC_SRC" "$VIMRC_DST"
    ok "vimrc installed to $VIMRC_DST"
}

# ─── Install Plugins via PlugInstall ──────────────────────────────────────────
install_plugins() {
    if ! has_command vim; then
        die "vim not found — please install vim first"
    fi

    info "Running :PlugInstall to install plugins..."
    # Run vim in headless mode, install plugins, then quit
    vim -es -u "$VIMRC_DST" -c "PlugInstall --sync" -c "qa!" 2>&1 || true

    # Verify at least some plugins were installed
    local plugged_dir="$HOME_DIR/.vim/plugged"
    if [ -d "$plugged_dir" ] && [ "$(ls -A "$plugged_dir" 2>/dev/null)" ]; then
        local count
        count=$(find "$plugged_dir" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
        ok "Installed $count plugins in $plugged_dir"
    else
        warn "No plugins installed — you may need to run :PlugInstall manually in vim"
    fi
}

# ─── User Confirmation ────────────────────────────────────────────────────────
confirm() {
    echo ""
    echo "This script will:"
    echo "  1. Install your vim configuration (~/.vimrc)"
    echo "  2. Install vim-plug (plugin manager)"
    echo "  3. Install system dependencies (clang, ctags, astyle)"
    echo "  4. Run :PlugInstall to download vim plugins"
    echo ""
    if [ -f "$VIMRC_DST" ]; then
        echo "  Your current ~/.vimrc will be backed up to ~/.vimrc.bak"
    fi
    echo ""
    read -rp "Continue? [y/N] " answer
    case "$answer" in
        [yY]|[yY][eE][sS]) return ;;
        *) echo "Aborted."; exit 0 ;;
    esac
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    echo "====================================="
    echo "  Vim Configuration Installer"
    echo "====================================="
    echo ""

    confirm

    # Detect OS
    local os
    os="$(detect_os)"
    info "Detected OS: $os"
    case "$os" in
        macos|debian|rhel) ;;
        *) warn "Unknown OS, will skip system dependency installation" ;;
    esac

    # Check network
    check_network

    # Install vimrc
    install_vimrc

    # Install vim-plug
    install_plug

    # Install system dependencies
    info "Installing system dependencies..."
    case "$os" in
        macos)
            # clang comes from Xcode CLT, ctags is pre-installed on macOS
            if ! has_command clang; then
                info "clang not found. Installing Xcode Command Line Tools..."
                xcode-select --install
            else
                ok "clang already available (Xcode CLT)"
            fi
            if ! has_command ctags; then
                ok "ctags already available"
            fi
            pkg_install "$os" astyle
            ;;
        debian|rhel)
            pkg_install "$os" clang universal-ctags astyle
            ;;
        *)
            warn "Unsupported OS ($os), skipping system dependency installation"
            ;;
    esac

    # Install vim plugins
    install_plugins

    echo ""
    echo "====================================="
    ok "Installation complete!"
    echo "====================================="
    echo ""
    echo "Your vim config is at: $VIMRC_DST"
    echo "Plugins are in:        $HOME_DIR/.vim/plugged/"
    echo ""
    echo "To reinstall plugins later, run in vim:"
    echo "  :PlugInstall"
    echo "To update plugins, run in vim:"
    echo "  :PlugUpdate"

    # Mark success so rollback trap does nothing
    _rollback_done=1
    trap - EXIT
}

main "$@"

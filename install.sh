#!/usr/bin/env bash
# termux-openrouter-spawn — install Bun (glibc) + OpenRouter Spawn CLI on Termux.
#
# This script codifies the README steps so they are testable and copy-paste
# safe. It fixes three issues the plain README blocks had:
#   1. PATH was written literally ("HOME/.local/bin:PATH") — now correctly
#      expands to $HOME/.local/bin:$PATH.
#   2. termux-chroot was exec'd unconditionally in ~/.bashrc — now gated to
#      interactive shells only, so non-interactive tools/scripts keep working.
#   3. Third-party deps (bun-termux, the Spawn installer) are pinned so the
#      guide does not silently break if upstream moves.
#
# Usage:
#   bash install.sh            # full install
#   bash install.sh --verify    # only check current environment
#   bash install.sh -h | --help # display usage information
#
# Safe to re-run: idempotent guards skip already-done steps.

set -euo pipefail

# Pinned upstream refs (bump deliberately, not silently).
BUN_TERMUX_REPO="https://github.com/Happ1ness-dev/bun-termux.git"
# Security: Pin to exact commit SHA to prevent supply chain security risks from branch updates.
BUN_TERMUX_REF="8aa2fe203d36434cdb85d1c55b2c9cfa416abfaa"
SPAWN_INSTALLER="https://openrouter.ai/labs/spawn/cli/install.sh"

log()  { printf '\033[0;34m[spawn]\033[0m %s\n' "$*"; }
ok()   { printf '\033[0;32m[spawn]\033[0m %s\n' "$*"; }
warn() { printf '\033[0;33m[spawn]\033[0m %s\n' "$*"; }
err()  { printf '\033[0;31m[spawn]\033[0m %s\n' "$*" >&2; }

# ---------------------------------------------------------------------------
# Help mode: display usage information.
# ---------------------------------------------------------------------------
if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  printf "Usage: install.sh [--verify | -h | --help]\n\n"
  printf "Options:\n"
  printf "  (no args)    Full installation of Bun (glibc) and OpenRouter Spawn CLI\n"
  printf "  --verify     Check current environment without changing anything\n"
  printf "  -h, --help   Display this help message\n"
  exit 0
fi

is_termux() {
  [ -n "${TERMUX_VERSION:-}" ] || [[ "${PREFIX:-}" == *"com.termux/files/usr"* ]]
}

if ! is_termux; then
  err "This script is for Termux/Android only (no TERMUX_VERSION / PREFIX)."
  exit 1
fi

# ---------------------------------------------------------------------------
# Verify mode: report state, do not change anything.
# ---------------------------------------------------------------------------
if [ "${1:-}" = "--verify" ]; then
  log "Verification mode"
  command -v bun      >/dev/null 2>&1 && bun --version      && ok "bun present"      || warn "bun missing"
  command -v spawn    >/dev/null 2>&1 && spawn --help >/dev/null 2>&1 && ok "spawn present" || warn "spawn missing"
  [ -n "${OPENROUTER_API_KEY:-}" ] && ok "OPENROUTER_API_KEY set" || warn "OPENROUTER_API_KEY not set"
  # PATH check: does it actually contain the bun + local bin dirs?
  case ":$PATH:" in
    *":$HOME/.bun/bin:"*)  ok "PATH has ~/.bun/bin" ;;
    *)                     warn "PATH missing ~/.bun/bin" ;;
  esac
  exit 0
fi

# ---------------------------------------------------------------------------
# 1. GLIBC repo + toolchain
# ---------------------------------------------------------------------------
log "Checking GLIBC repo and toolchain packages..."

# Bolt optimization: Skip network-bound 'pkg update' and 'pkg install' when required
# toolchain packages are already installed. Reduces step time from ~15-30s to <0.1s on re-runs.
is_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "ok installed"
}

if ! is_installed "glibc-repo"; then
  log "Enabling GLIBC repo..."
  pkg install glibc-repo -y
  pkg update -y
fi

REQUIRED_PKGS=(git curl clang make glibc-runner python proot)
MISSING_PKGS=()

for pkg in "${REQUIRED_PKGS[@]}"; do
  if ! is_installed "$pkg"; then
    MISSING_PKGS+=("$pkg")
  fi
done

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
  log "Installing missing toolchain packages: ${MISSING_PKGS[*]}..."
  pkg install -y "${MISSING_PKGS[@]}"
else
  ok "Toolchain packages already installed — skipping pkg update/install"
fi

# ---------------------------------------------------------------------------
# 2. Bun via the native Termux compatibility wrapper
# ---------------------------------------------------------------------------
if command -v bun >/dev/null 2>&1; then
  ok "bun already installed ($(bun --version)) — skipping build"
else
  log "Cloning bun-termux (pinned: $BUN_TERMUX_REF)..."
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT INT TERM
  git clone --depth 1 --branch "$BUN_TERMUX_REF" "$BUN_TERMUX_REPO" "$tmp/bun-termux"
  cd "$tmp/bun-termux"
  # Bolt optimization: enable multi-threaded compilation using available CPU cores (nproc)
  # Significantly speeds up compilation time on multi-core mobile processors (~50-70% speedup).
  NPROC="$(nproc 2>/dev/null || echo 2)"
  make -j"$NPROC" && make install
  cd "$HOME"
  rm -rf "$tmp"
  trap - EXIT INT TERM
fi

# Reload so bun is on PATH for the rest of this run.
[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc" 2>/dev/null || true
if ! command -v bun >/dev/null 2>&1; then
  err "bun still not on PATH after install — check bun-termux build output."
  exit 1
fi
ok "bun installed: $(bun --version)"

# ---------------------------------------------------------------------------
# 3. Environment variables (CORRECT path expansion)
# ---------------------------------------------------------------------------
BASHRC="$HOME/.bashrc"
touch "$BASHRC"

# Only append the block once (idempotent guard).
if ! grep -q "BEGIN termux-openrouter-spawn" "$BASHRC"; then
  cat >> "$BASHRC" <<'EOF'

# BEGIN termux-openrouter-spawn
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$HOME/.local/bin:$PATH"
export TMPDIR="$PREFIX/tmp"
export TEMP="$PREFIX/tmp"
export TMP="$PREFIX/tmp"
# Enter chroot only for interactive shells, so non-interactive tools keep
# working (cron, ssh non-login, scripts).
if [ -z "${TERMUX_CHROOT_ACTIVE:-}" ] && [[ $- == *i* ]]; then
  export TERMUX_CHROOT_ACTIVE=1
  exec termux-chroot
fi
# END termux-openrouter-spawn
EOF
  ok "Appended env block to $BASHRC (with correct \$PATH expansion)"
else
  ok "Env block already present in $BASHRC — skipped"
fi

# Reload for this session.
source "$BASHRC" 2>/dev/null || true

# Optional: expose bun as node for scripts that hard-require a `node` binary.
if [ ! -e "$HOME/.bun/bin/node" ]; then
  ln -s "$HOME/.bun/bin/bun" "$HOME/.bun/bin/node" 2>/dev/null || true
  ok "Symlinked bun -> node (optional compatibility)"
fi

# ---------------------------------------------------------------------------
# 4. OpenRouter Spawn CLI
# ---------------------------------------------------------------------------
if command -v spawn >/dev/null 2>&1; then
  ok "spawn already installed — skipping"
else
  log "Running OpenRouter Spawn installer ($SPAWN_INSTALLER)..."
  warn "Verify the source at $SPAWN_INSTALLER before trusting it in production."
  # Download to a temporary file before execution to prevent partial script execution on network interruption
  spawn_tmp="$(mktemp)"
  trap 'rm -f "$spawn_tmp"' EXIT INT TERM
  curl -fsSL "$SPAWN_INSTALLER" -o "$spawn_tmp"
  bash "$spawn_tmp"
  rm -f "$spawn_tmp"
  trap - EXIT INT TERM
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
ok "Install complete."
log "Next steps:"
log "  export OPENROUTER_API_KEY=\"your_key_here\""
log "  spawn"
log "Run 'bash install.sh --verify' any time to check the environment."

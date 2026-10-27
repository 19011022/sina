#!/usr/bin/env bash
# sina installer
#
#   curl -fsSL https://get.ottomind.ai/sina | bash
#   curl -fsSL https://get.ottomind.ai/sina | sudo bash
#
# Published with every release at get.ottomind.ai/sina/<version>; the version below is filled in at publish time.
# Run from the repository instead, it resolves the latest version from get.ottomind.ai/sina/latest.json.
#
# Env overrides:
#   SINA_VERSION=0.3.1   # pin a version (default: the version this script was published with)
#   SINA_GET=https://get.ottomind.ai   # download host (mirrors, tests)
#   SINA_PREFIX=/usr/local/bin   # or a user directory without sudo; set it after the pipe: curl … | SINA_PREFIX=… bash
#   SINA_DEBUG=1         # verbose

set -euo pipefail

GET="${SINA_GET:-https://get.ottomind.ai}"
PREFIX="${SINA_PREFIX:-/usr/local/bin}"
BIN="sina"

# ---------- pretty output ----------
if [[ -t 1 ]]; then
  c_ok=$'\033[1;32m'; c_warn=$'\033[1;33m'; c_err=$'\033[1;31m'
  c_dim=$'\033[2m';   c_acc=$'\033[1;36m'; c_off=$'\033[0m'
else
  c_ok=""; c_warn=""; c_err=""; c_dim=""; c_acc=""; c_off=""
fi
ok()    { printf "%s✓%s %s\n" "$c_ok"   "$c_off" "$*"; }
info()  { printf "%s·%s %s\n" "$c_dim"  "$c_off" "$*"; }
warn()  { printf "%s!%s %s\n" "$c_warn" "$c_off" "$*"; }
fail()  { printf "%s✗%s %s\n" "$c_err"  "$c_off" "$*" >&2; exit 1; }
debug() { [[ -n "${SINA_DEBUG:-}" ]] && printf "%s[debug]%s %s\n" "$c_dim" "$c_off" "$*" || true; }

trap 'fail "install aborted (line $LINENO)"' ERR

# ---------- platform detection ----------
detect_os() {
  case "$(uname -s)" in
    Linux*)   echo linux  ;;
    *) fail "sina checks Linux servers and runs only on Linux (this is $(uname -s)); install it on the server, e.g.: ssh my-server 'curl -fsSL https://get.ottomind.ai/sina | sudo bash'" ;;
  esac
}

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64)  echo amd64 ;;
    aarch64|arm64) echo arm64 ;;
    *) fail "unsupported arch: $(uname -m)" ;;
  esac
}

OS="$(detect_os)"
ARCH="$(detect_arch)"
ok "platform: ${c_acc}${OS}/${ARCH}${c_off}"

# ---------- prerequisites ----------
need_cmd() { command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"; }
need_cmd uname
need_cmd tar
need_cmd install
HTTP=""
if command -v curl >/dev/null 2>&1; then
  HTTP="curl -fsSL"
elif command -v wget >/dev/null 2>&1; then
  HTTP="wget -qO-"
else
  fail "need curl or wget"
fi
debug "http client: $HTTP"

# ---------- privilege ----------
# A user directory (SINA_PREFIX=$HOME/.local/bin) is created without sudo; sudo only when the target isn't writable.
mkdir -p "$PREFIX" 2>/dev/null || true
SUDO=""
if [[ "$(id -u)" -ne 0 && ! -w "$PREFIX" ]]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    fail "$PREFIX is not writable and sudo is not installed (set SINA_PREFIX to a directory you own)"
  fi
fi

# ---------- resolve version ----------
PUBLISHED="{{version}}"
VERSION="${SINA_VERSION:-$PUBLISHED}"
VERSION="${VERSION#v}"
if [[ "$VERSION" == *"{{"* ]]; then
  # Not a published copy (run from the repository): ask get.ottomind.ai for the latest version.
  info "resolving latest version from $GET/sina/latest.json ..."
  VERSION="$($HTTP "$GET/sina/latest.json" 2>/dev/null \
    | grep -E '"version"[[:space:]]*:' \
    | head -n1 \
    | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' || true)"
  [[ -n "$VERSION" ]] || fail "could not resolve the latest version — set SINA_VERSION"
fi
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]] || fail "invalid version: $VERSION"
ok "version: ${c_acc}${VERSION}${c_off}"

# ---------- download ----------
ASSET="sina_${OS}_${ARCH}.tar.gz"
URL="$GET/sina/${VERSION}/${ASSET}"
SUMS_URL="$GET/sina/${VERSION}/SHA256SUMS"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

info "downloading $ASSET ..."
debug "url: $URL"
$HTTP "$URL" > "$tmp/$ASSET" || fail "download failed: $URL"

# ---------- verify checksum (required) ----------
if command -v sha256sum >/dev/null 2>&1; then
  SHASUM_BIN="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
  SHASUM_BIN="shasum -a 256"
else
  fail "sha256sum or shasum is required to verify the download"
fi

info "verifying checksum ..."
expected="$($HTTP "$SUMS_URL" 2>/dev/null | awk -v f="$ASSET" '$2 == f {print $1}' || true)"
[[ -n "$expected" ]] || fail "no checksum for $ASSET in $SUMS_URL"
actual="$($SHASUM_BIN "$tmp/$ASSET" | awk '{print $1}')"
[[ "$expected" == "$actual" ]] || fail "checksum mismatch: expected $expected got $actual"
ok "checksum verified"

# ---------- extract & install ----------
tar -xzf "$tmp/$ASSET" -C "$tmp"
[[ -f "$tmp/$BIN" ]] || fail "archive did not contain expected binary: $BIN"

info "installing to $PREFIX/$BIN ..."
$SUDO mkdir -p "$PREFIX"
$SUDO install -m 0755 "$tmp/$BIN" "$PREFIX/$BIN"
case ":$PATH:" in *":$PREFIX:"*) ;; *) warn "$PREFIX is not on PATH; run it as $PREFIX/$BIN or add it to PATH" ;; esac

# ---------- smoke test ----------
if "$PREFIX/$BIN" --version >/dev/null 2>&1; then
  ok "$($PREFIX/$BIN --version)"
else
  warn "binary installed but --version failed"
fi

echo
printf "  Run:  %ssina%s             %s# interactive TUI%s\n"        "$c_acc" "$c_off" "$c_dim" "$c_off"
printf "        %ssina --plain%s     %s# scriptable / cron%s\n"      "$c_acc" "$c_off" "$c_dim" "$c_off"
echo

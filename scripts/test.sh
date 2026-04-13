#!/usr/bin/env zsh
# Smoke-test script: verifies every required tool is present and executable.
# Exit code 0 = all checks passed; non-zero = at least one tool missing.
set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

PASS=0
FAIL=0

check() {
    local label="$1"; shift
    if "$@" > /dev/null 2>&1; then
        printf "${GREEN}  PASS${RESET}  %s\n" "$label"
        (( PASS++ )) || true
    else
        printf "${RED}  FAIL${RESET}  %s  (command: %s)\n" "$label" "$*"
        (( FAIL++ )) || true
    fi
}

echo "──────────────────────────────────────────────"
echo "  devcontainer smoke tests"
echo "──────────────────────────────────────────────"

# Runtimes
check "bun"      bun --version
check "python3"  python3 --version
check "uv"       uv --version
check "go"       go version
check "rustc"    rustc --version
check "cargo"    cargo --version

# Editor
check "nvim"     nvim --version

# Shell & multiplexer
check "zsh"      zsh --version
check "tmux"     tmux -V

# CLI utilities
check "just"     just --version
check "task"     task --version
check "grpcurl"  grpcurl --version
check "wget"     wget --version
check "http"     http --version
check "usql"     usql --version
check "aws"      aws --version
check "rg"       rg --version
check "fd"       fd --version
check "bat"      bat --version
check "fzf"      fzf --version
check "jq"       jq --version
check "btop"     btop --version

# Navigation
check "zoxide"   zoxide --version

echo "──────────────────────────────────────────────"
printf "  Results: ${GREEN}%d passed${RESET}, ${RED}%d failed${RESET}\n" "$PASS" "$FAIL"
echo "──────────────────────────────────────────────"

[[ $FAIL -eq 0 ]]

#!/usr/bin/env bash
# Run Antigravity CLI (agy) from a brief — headless, Google account auth.
set -euo pipefail

MODEL="Gemini 3.5 Flash (Low)"
DIR="$(pwd)"
PRINT_TIMEOUT="15m"
TIMEOUT_MINUTES=20
BRIEF_PATH=""
BRIEF=""
CONTINUE=0
SANDBOX=0
CHECK_AUTH=1

usage() {
  cat <<'EOF'
Usage:
  delegate-antigravity.sh --brief-path FILE [--dir DIR] [--model MODEL]
  delegate-antigravity.sh --brief "text" [--continue] [--sandbox] [--print-timeout 15m]
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --brief-path) BRIEF_PATH="${2:-}"; shift 2 ;;
    --brief) BRIEF="${2:-}"; shift 2 ;;
    --model) MODEL="${2:-}"; shift 2 ;;
    --dir) DIR="${2:-}"; shift 2 ;;
    --print-timeout) PRINT_TIMEOUT="${2:-}"; shift 2 ;;
    --timeout-minutes) TIMEOUT_MINUTES="${2:-}"; shift 2 ;;
    --continue) CONTINUE=1; shift ;;
    --sandbox) SANDBOX=1; shift ;;
    --no-check-auth) CHECK_AUTH=0; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown: $1" >&2; usage ;;
  esac
done

[[ -n "$BRIEF_PATH" && -n "$BRIEF" ]] && { echo "Use --brief-path OR --brief" >&2; exit 1; }
[[ -z "$BRIEF_PATH" && -z "$BRIEF" ]] && usage

command -v agy >/dev/null 2>&1 || { echo "agy not found" >&2; exit 127; }
[[ -d "$DIR" ]] || { echo "Dir not found: $DIR" >&2; exit 1; }
WORKDIR="$(cd "$DIR" && pwd)"

if [[ -n "$BRIEF_PATH" ]]; then
  [[ -f "$BRIEF_PATH" ]] || { echo "Brief not found" >&2; exit 1; }
  BRIEF_TEXT="$(cat "$BRIEF_PATH")"
else
  BRIEF_TEXT="$BRIEF"
fi
[[ -n "${BRIEF_TEXT// }" ]] || { echo "Empty brief" >&2; exit 1; }

if [[ "$CHECK_AUTH" -eq 1 ]]; then
  if [[ "$(uname -s)" == "Darwin" ]]; then
    security find-generic-password -s "gemini:antigravity" >/dev/null 2>&1 || {
      echo "Run agy and sign in with Google" >&2; exit 1; }
  fi
fi

ARGS=()
[[ "$CONTINUE" -eq 1 ]] && ARGS+=(--continue)
if [[ ${#BRIEF_TEXT} -gt 7000 ]]; then
  ARGS+=(-p "Execute task on stdin. Do not commit unless asked.")
  USE_STDIN=1
else
  ARGS+=(-p "$BRIEF_TEXT")
  USE_STDIN=0
fi
ARGS+=(--model "$MODEL" --print-timeout "$PRINT_TIMEOUT" --dangerously-skip-permissions)
[[ "$SANDBOX" -eq 1 ]] && ARGS+=(--sandbox)

TIMEOUT_SEC=$((TIMEOUT_MINUTES * 60))
echo "Antigravity delegate: model=$MODEL dir=$WORKDIR print-timeout=$PRINT_TIMEOUT"
set +e
if [[ "$USE_STDIN" -eq 1 ]]; then
  cd "$WORKDIR"
  printf '%s' "$BRIEF_TEXT" | timeout "$TIMEOUT_SEC" agy "${ARGS[@]}"
else
  cd "$WORKDIR"
  timeout "$TIMEOUT_SEC" agy "${ARGS[@]}" </dev/null
fi
code=$?
set -e
[[ $code -eq 124 ]] && { echo "Timed out" >&2; exit 124; }
[[ $code -ne 0 ]] && { echo "Exit $code" >&2; exit "$code"; }
echo "Antigravity finished successfully."

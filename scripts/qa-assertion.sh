#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$ROOT_DIR/.build/ModuleCache}"
swift build --disable-sandbox -c debug --product KeepAwakeAssertionQA >/dev/null
LOG_FILE=$(mktemp "${TMPDIR:-/tmp}/keepawake-qa.XXXXXX")
"$ROOT_DIR/.build/debug/KeepAwakeAssertionQA" >"$LOG_FILE" &
QA_PID=$!

cleanup() {
    if kill -0 "$QA_PID" 2>/dev/null; then kill "$QA_PID" 2>/dev/null || true; fi
    wait "$QA_PID" 2>/dev/null || true
    rm -f "$LOG_FILE"
}
trap cleanup EXIT INT TERM

i=0
while [ "$i" -lt 20 ] && ! grep -q QA_ASSERTION_ACTIVE "$LOG_FILE"; do
    sleep 0.1
    i=$((i + 1))
done

grep QA_ASSERTION_ACTIVE "$LOG_FILE"
pmset -g assertions | grep -E "KeepAwakeAssertionQA|KeepAwake が選択時間中" || {
    echo "QA_ERROR: pmset で active assertion を確認できませんでした" >&2
    exit 1
}

wait "$QA_PID"
grep QA_ASSERTION_RELEASED "$LOG_FILE"

if pmset -g assertions | grep -E "KeepAwakeAssertionQA|KeepAwake が選択時間中"; then
    echo "QA_ERROR: assertion が残っています" >&2
    exit 1
fi

trap - EXIT INT TERM
rm -f "$LOG_FILE"
echo "QA_OK: assertion は開始後に確認され、終了後に解除されました"

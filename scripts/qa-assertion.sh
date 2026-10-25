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
pmset -g assertions | grep -F "pid $QA_PID(KeepAwakeAssertionQA)" || {
    echo "QA_ERROR: pmset で active assertion を確認できませんでした" >&2
    exit 1
}

i=0
while [ "$i" -lt 50 ] && ! grep -q QA_ASSERTION_RELEASED_PROCESS_ALIVE "$LOG_FILE"; do
    sleep 0.1
    i=$((i + 1))
done

grep QA_ASSERTION_RELEASED_PROCESS_ALIVE "$LOG_FILE"
kill -0 "$QA_PID" 2>/dev/null || {
    echo "QA_ERROR: 明示 release の確認前に helper が終了しました" >&2
    exit 1
}

if pmset -g assertions | grep -F "pid $QA_PID(KeepAwakeAssertionQA)"; then
    echo "QA_ERROR: 生存中 helper の assertion が明示 release 後も残っています" >&2
    exit 1
fi

wait "$QA_PID"

trap - EXIT INT TERM
rm -f "$LOG_FILE"
echo "QA_OK: assertion は開始後に存在し、同一プロセス生存中の明示 release 後に消滅しました"

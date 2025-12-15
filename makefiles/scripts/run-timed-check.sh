#!/bin/bash
# Run a timed check and output result in standard format
# Usage: run-timed-check.sh <log_file> <command...>
# Output format: "OK:time" or "FAILED:time" or "SKIPPED:time"

log_file="$1"
shift
check_cmd="$@"

check_start=$(date +%s)

if eval "$check_cmd" > /dev/null 2>&1; then
    check_end=$(date +%s)
    echo "OK:$(( check_end - check_start ))" > "$log_file"
    exit 0
else
    exit_code=$?
    check_end=$(date +%s)
    echo "FAILED:$(( check_end - check_start ))" > "$log_file"
    exit $exit_code
fi

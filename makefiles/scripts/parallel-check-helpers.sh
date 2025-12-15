#!/bin/bash
# Reusable helper functions for parallel checks with timing

# Run a timed check in background
# Args: $1=log_file, $2=command to run, $3=optional_skip_condition
run_timed_check() {
    local log_file="$1"
    local check_cmd="$2"
    local skip_cond="$3"

    check_start=$(date +%s)

    if [ -n "$skip_cond" ]; then
        if eval "$skip_cond"; then
            check_end=$(date +%s)
            echo "SKIPPED:$(( check_end - check_start ))" > "$log_file"
            return 0
        fi
    fi

    if eval "$check_cmd" > /dev/null 2>&1; then
        check_end=$(date +%s)
        echo "OK:$(( check_end - check_start ))" > "$log_file"
    else
        check_end=$(date +%s)
        echo "FAILED:$(( check_end - check_start ))" > "$log_file"
    fi
}

# Parse check result from log output
# Args: $1=output_string
# Returns: prints "result:time"
parse_check_result() {
    local output="$1"
    local result=$(echo "$output" | cut -d: -f1)
    local time=$(echo "$output" | cut -d: -f2)
    echo "$result:$time"
}

# Parse check result with extra data (like dart failed packages)
# Args: $1=output_string
# Returns: prints "result:data:time"
parse_check_result_with_data() {
    local output="$1"
    local result=$(echo "$output" | cut -d: -f1)
    local time=$(echo "$output" | rev | cut -d: -f1 | rev)
    local data=$(echo "$output" | cut -d: -f2- | rev | cut -d: -f2- | rev)
    echo "$result:$data:$time"
}

#!/bin/bash
#
# check-clone-instances.sh
#
# Enforces that code appearing in 3+ locations must be refactored.
# Parses jscpd JSON output and fails if any clone appears in 3 or more locations.
#
# Exit codes:
#   0 - No clones with 3+ instances found
#   1 - Found clones appearing in 3+ locations (must be refactored)
#   2 - jscpd report not found (run jscpd first)
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Get the root directory (parent of makefiles/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

REPORT_FILE="$ROOT_DIR/report/jscpd-report.json"

# Check if report exists
if [ ! -f "$REPORT_FILE" ]; then
    echo -e "${RED}✗ jscpd report not found at: $REPORT_FILE${NC}"
    echo "Run 'npx jscpd . --config .jscpd.json' first"
    exit 2
fi

# Parse JSON and check for 3+ instance clones
# jscpd JSON structure has "duplicates" array with objects containing "format" and "clones" array
# Each clone in the array represents one instance of the duplication

violations=()

# Use Python to parse JSON (more reliable than jq which may not be installed)
result=$(python3 - "$REPORT_FILE" <<'EOF'
import json
import sys

try:
    with open(sys.argv[1], 'r') as f:
        data = json.load(f)

    violations = []

    # Group clones by their content/signature to count instances
    clone_groups = {}

    if 'duplicates' in data and isinstance(data['duplicates'], list):
        for dup_entry in data['duplicates']:
            if 'clones' in dup_entry and isinstance(dup_entry['clones'], list):
                clones = dup_entry['clones']

                # Group clones by their fingerprint (combination of lines/tokens)
                for clone in clones:
                    # Create a unique key for this clone based on content signature
                    lines = clone.get('lines', 0)
                    tokens = clone.get('tokens', 0)
                    # Use first line content as part of signature
                    first_line = clone.get('firstLine', {}).get('code', '')[:50]

                    key = f"{lines}_{tokens}_{first_line}"

                    if key not in clone_groups:
                        clone_groups[key] = []

                    clone_groups[key].append({
                        'file': clone.get('name', 'unknown'),
                        'start': clone.get('start', {}).get('line', 0),
                        'end': clone.get('end', {}).get('line', 0),
                        'lines': lines,
                        'tokens': tokens
                    })

    # Find groups with 3+ instances
    for key, instances in clone_groups.items():
        if len(instances) >= 3:
            violations.append({
                'count': len(instances),
                'instances': instances
            })

    # Output results
    print(json.dumps({
        'violations': violations,
        'total_violations': len(violations)
    }))

except Exception as e:
    print(json.dumps({
        'error': str(e),
        'violations': [],
        'total_violations': 0
    }))
    sys.exit(1)
EOF
)

# Parse the result
total_violations=$(echo "$result" | python3 -c "import sys, json; print(json.load(sys.stdin).get('total_violations', 0))")

if [ "$total_violations" -eq 0 ]; then
    echo -e "${GREEN}✓ No code duplications with 3+ instances found${NC}"
    exit 0
fi

# Report violations
echo -e "${RED}✗ Found $total_violations clone(s) appearing in 3 or more locations${NC}"
echo ""
echo -e "${YELLOW}Code appearing in 3+ locations MUST be refactored immediately.${NC}"
echo ""

# Pretty print violations
echo "$result" | python3 <<'EOF'
import sys
import json

data = json.load(sys.stdin)
violations = data.get('violations', [])

for i, violation in enumerate(violations, 1):
    count = violation['count']
    instances = violation['instances']

    # Get details from first instance
    first = instances[0]
    lines = first['lines']
    tokens = first['tokens']

    print(f"\n{i}. Clone found in {count} locations ({lines} lines, {tokens} tokens):")
    for inst in instances:
        file_path = inst['file']
        start = inst['start']
        end = inst['end']
        print(f"   - {file_path}:{start}-{end}")

print("\n")
print("Action required:")
print("  Refactor these duplications using shared base classes, mixins, or utility functions")
print("  See contributing/architecture.md for refactoring guidelines")
EOF

exit 1

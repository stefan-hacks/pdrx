#!/usr/bin/env bash
#
# pdrx comprehensive test suite
# Tests every command, option, and flag
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PDRX_SCRIPT="${SCRIPT_DIR}/pdrx"

# Colors
RED=$'\e[0;31m'
GREEN=$'\e[0;32m'
YELLOW=$'\e[1;33m'
BLUE=$'\e[0;34m'
NC=$'\e[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Current test directory
CURRENT_TEST_DIR=""

# Initialize a fresh test environment
fresh_init() {
    if [ -n "${CURRENT_TEST_DIR:-}" ] && [ -d "$CURRENT_TEST_DIR" ]; then
        rm -rf "$CURRENT_TEST_DIR"
    fi
    CURRENT_TEST_DIR=$(mktemp -d)
    export PDRX_HOME="$CURRENT_TEST_DIR"
}

# Cleanup
cleanup() {
    if [ -n "${CURRENT_TEST_DIR:-}" ] && [ -d "$CURRENT_TEST_DIR" ]; then
        rm -rf "$CURRENT_TEST_DIR"
    fi
}

# Run a test
run_test() {
    local name="$1"
    shift
    
    if [ -z "${CURRENT_TEST_DIR:-}" ]; then
        fresh_init
    fi
    
    TESTS_RUN=$((TESTS_RUN + 1))
    printf "${BLUE}[TEST]${NC} %s\n" "$name"
    
    local output_file="$CURRENT_TEST_DIR/test_output.log"
    if eval "$*" > "$output_file" 2>&1; then
        printf "${GREEN}[PASS]${NC} %s\n" "$name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        printf "${RED}[FAIL]${NC} %s\n" "$name"
        echo "  Command: $*"
        if [ -f "$output_file" ]; then
            echo "  Output:"
            sed 's/^/    /' "$output_file" 2>/dev/null || true
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Check file content
file_contains() {
    local file="$1"
    local pattern="$2"
    [ -f "$file" ] && grep -qi "$pattern" "$file" 2>/dev/null
}

test_help_version() {
    printf "\n${YELLOW}=== Help & Version Tests ===${NC}\n"
    
    run_test "Help flag (-h)" "bash '$PDRX_SCRIPT' -h"
    run_test "Help flag (--help)" "bash '$PDRX_SCRIPT' --help"
    run_test "Version flag (-v)" "bash '$PDRX_SCRIPT' -v"
    run_test "Version flag (--version)" "bash '$PDRX_SCRIPT' --version"
    run_test "Version shows 1.7.0" "bash '$PDRX_SCRIPT' --version | grep -q '1.7.0'"
}

test_init() {
    printf "\n${YELLOW}=== Init Tests ===${NC}\n"
    
    fresh_init
    run_test "Basic init" "bash '$PDRX_SCRIPT' init -q"
    run_test "Init creates config dir" "[ -d '$CURRENT_TEST_DIR/config' ]"
    run_test "Init creates state dir" "[ -d '$CURRENT_TEST_DIR/state' ]"
    run_test "Init creates backup dir" "[ -d '$CURRENT_TEST_DIR/backups' ]"
    run_test "Init creates packages.conf" "[ -f '$CURRENT_TEST_DIR/config/packages.conf' ]"
    run_test "Init creates sources.conf" "[ -f '$CURRENT_TEST_DIR/config/sources.conf' ]"
    run_test "Init creates systemd.conf" "[ -f '$CURRENT_TEST_DIR/config/systemd.conf' ]"
    run_test "Init creates hooks dir" "[ -d '$CURRENT_TEST_DIR/config/hooks' ]"
    run_test "Init creates initialized marker" "[ -f '$CURRENT_TEST_DIR/state/initialized' ]"
    run_test "Init with quiet flag" "bash '$PDRX_SCRIPT' -q init"
}

test_status() {
    printf "\n${YELLOW}=== Status Tests ===${NC}\n"
    
    fresh_init
    bash "$PDRX_SCRIPT" init -q >/dev/null 2>&1
    
    run_test "Basic status" "bash '$PDRX_SCRIPT' status"
    # Capture output to file and check
    bash "$PDRX_SCRIPT" status > "$CURRENT_TEST_DIR/status_output.txt" 2>&1
    run_test "Status shows OS" "file_contains '$CURRENT_TEST_DIR/status_output.txt' 'os'"
    run_test "Status shows PMs" "file_contains '$CURRENT_TEST_DIR/status_output.txt' 'pms'"
    run_test "Status shows packages" "file_contains '$CURRENT_TEST_DIR/status_output.txt' 'packages'"
    run_test "Status shows sources" "file_contains '$CURRENT_TEST_DIR/status_output.txt' 'sources'"
    run_test "Status shows systemd" "file_contains '$CURRENT_TEST_DIR/status_output.txt' 'systemd'"
    run_test "Status shows hook" "file_contains '$CURRENT_TEST_DIR/status_output.txt' 'hook'"
}

test_list() {
    printf "\n${YELLOW}=== List Tests ===${NC}\n"
    
    fresh_init
    bash "$PDRX_SCRIPT" init -q >/dev/null 2>&1
    
    run_test "List empty packages" "bash '$PDRX_SCRIPT' list"
}

test_backup() {
    printf "\n${YELLOW}=== Backup Tests ===${NC}\n"
    
    fresh_init
    bash "$PDRX_SCRIPT" init -q >/dev/null 2>&1
    
    run_test "Basic backup" "bash '$PDRX_SCRIPT' backup test"
    run_test "Backup creates directory" "ls '$CURRENT_TEST_DIR/backups' | grep -q '_test'"
    run_test "Backup includes packages.conf" "find '$CURRENT_TEST_DIR/backups' -name 'packages.conf' | grep -q ."
    run_test "Backup includes sources.conf" "find '$CURRENT_TEST_DIR/backups' -name 'sources.conf' | grep -q ."
    run_test "Backup includes systemd.conf" "find '$CURRENT_TEST_DIR/backups' -name 'systemd.conf' | grep -q ."
    run_test "Backup includes hooks" "find '$CURRENT_TEST_DIR/backups' -type d -name 'hooks' | grep -q ."
    run_test "Generations command" "bash '$PDRX_SCRIPT' generations"
}

test_clean() {
    printf "\n${YELLOW}=== Clean Tests ===${NC}\n"
    
    fresh_init
    bash "$PDRX_SCRIPT" init -q >/dev/null 2>&1
    bash "$PDRX_SCRIPT" backup test1 >/dev/null 2>&1
    bash "$PDRX_SCRIPT" backup test2 >/dev/null 2>&1
    
    run_test "Clean list" "bash '$PDRX_SCRIPT' clean"
    run_test "Clean current with yes" "bash '$PDRX_SCRIPT' -y clean current"
    run_test "Clean all with yes" "bash '$PDRX_SCRIPT' -y clean all"
}

test_source() {
    printf "\n${YELLOW}=== Source Tests ===${NC}\n"
    
    fresh_init
    bash "$PDRX_SCRIPT" init -q >/dev/null 2>&1
    
    run_test "Source list empty" "bash '$PDRX_SCRIPT' source list"
    run_test "Source apply empty" "bash '$PDRX_SCRIPT' source apply"
    run_test "Source apply dry-run" "bash '$PDRX_SCRIPT' -n source apply"
}

test_hook() {
    printf "\n${YELLOW}=== Hook Tests ===${NC}\n"
    
    fresh_init
    bash "$PDRX_SCRIPT" init -q >/dev/null 2>&1
    
    run_test "Hook edit creates file" "bash '$PDRX_SCRIPT' hook edit && [ -f '$CURRENT_TEST_DIR/config/hooks/post-apply.sh' ]"
    run_test "Hook file is executable" "[ -x '$CURRENT_TEST_DIR/config/hooks/post-apply.sh' ]"
    run_test "Hook has shebang" "grep -q '#!/usr/bin/env bash' '$CURRENT_TEST_DIR/config/hooks/post-apply.sh'"
}

test_history() {
    printf "\n${YELLOW}=== History Tests ===${NC}\n"
    
    fresh_init
    bash "$PDRX_SCRIPT" init -q >/dev/null 2>&1
    bash "$PDRX_SCRIPT" backup test >/dev/null 2>&1
    
    run_test "History default" "bash '$PDRX_SCRIPT' history"
    run_test "History with count" "bash '$PDRX_SCRIPT' history 10"
}

test_apply() {
    printf "\n${YELLOW}=== Apply Tests ===${NC}\n"
    
    fresh_init
    bash "$PDRX_SCRIPT" init -q >/dev/null 2>&1
    
    run_test "Apply dry-run" "bash '$PDRX_SCRIPT' -n apply"
    run_test "Apply dry-run parallel" "bash '$PDRX_SCRIPT' -n apply --parallel"
}

test_export_import() {
    printf "\n${YELLOW}=== Export/Import Tests ===${NC}\n"
    
    fresh_init
    bash "$PDRX_SCRIPT" init -q > /dev/null 2>&1
    bash "$PDRX_SCRIPT" backup test > /dev/null 2>&1
    
    # Export to a fixed location that survives fresh_init
    local export_file="/tmp/pdrx_test_export_$$.tar.gz"
    run_test "Export to file" "bash '$PDRX_SCRIPT' export '$export_file' && [ -f '$export_file' ]"
    
    fresh_init
    bash "$PDRX_SCRIPT" init -q > /dev/null 2>&1
    run_test "Import from file" "bash '$PDRX_SCRIPT' import '$export_file'"
    
    # Cleanup
    rm -f "$export_file"
}

test_custom_config() {
    printf "\n${YELLOW}=== Custom Config Tests ===${NC}\n"
    
    fresh_init
    run_test "Init with -c" "bash '$PDRX_SCRIPT' -c '$CURRENT_TEST_DIR/custom_pdrx' init -q"
    run_test "Custom config created" "[ -d '$CURRENT_TEST_DIR/custom_pdrx/config' ]"
    run_test "Status with -c" "bash '$PDRX_SCRIPT' -c '$CURRENT_TEST_DIR/custom_pdrx' status"
}

test_destroy() {
    printf "\n${YELLOW}=== Destroy Tests ===${NC}\n"
    
    fresh_init
    local test_dir="$CURRENT_TEST_DIR"
    bash "$PDRX_SCRIPT" init -q > /dev/null 2>&1
    run_test "Destroy with -y" "bash '$PDRX_SCRIPT' -y destroy"
    # After destroy, the directory might be removed by the destroy command
    # So we just check the command succeeded (run_test checks exit code)
}

test_errors() {
    printf "\n${YELLOW}=== Error Handling Tests ===${NC}\n"
    
    fresh_init
    run_test "Status before init fails" "! bash '$PDRX_SCRIPT' status 2>/dev/null"
    run_test "Unknown command fails" "! bash '$PDRX_SCRIPT' unknowncmd 2>/dev/null"
    
    bash "$PDRX_SCRIPT" init -q >/dev/null 2>&1
    run_test "Install without args fails" "! bash '$PDRX_SCRIPT' install 2>/dev/null"
    run_test "Remove without args fails" "! bash '$PDRX_SCRIPT' remove 2>/dev/null"
}

test_shellcheck() {
    printf "\n${YELLOW}=== Shellcheck Test ===${NC}\n"
    
    if command -v shellcheck >/dev/null 2>&1; then
        run_test "Shellcheck passes" "shellcheck --severity=warning '$PDRX_SCRIPT'"
    else
        printf "${YELLOW}[SKIP]${NC} shellcheck not installed\n"
    fi
}

print_summary() {
    printf "\n${YELLOW}=================================${NC}\n"
    printf "${YELLOW}Test Summary${NC}\n"
    printf "${YELLOW}=================================${NC}\n"
    printf "Tests run:    %d\n" "$TESTS_RUN"
    printf "${GREEN}Tests passed: %d${NC}\n" "$TESTS_PASSED"
    printf "${RED}Tests failed: %d${NC}\n" "$TESTS_FAILED"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        printf "\n${GREEN}✓ All tests passed!${NC}\n"
        return 0
    else
        printf "\n${RED}✗ Some tests failed!${NC}\n"
        return 1
    fi
}

main() {
    printf "${BLUE}=================================${NC}\n"
    printf "${BLUE}pdrx Comprehensive Test Suite${NC}\n"
    printf "${BLUE}=================================${NC}\n"
    
    if [ ! -f "$PDRX_SCRIPT" ]; then
        printf "${RED}Error: pdrx script not found at %s${NC}\n" "$PDRX_SCRIPT"
        exit 1
    fi
    
    trap cleanup EXIT
    
    test_help_version
    test_init
    test_status
    test_list
    test_backup
    test_clean
    test_source
    test_hook
    test_history
    test_apply
    test_export_import
    test_custom_config
    test_destroy
    test_errors
    test_shellcheck
    
    print_summary
}

main "$@"

#!/usr/bin/env zsh

# PostgreSQL Connection Management Utility
# Manages PostgreSQL connections using mise version manager

set -euo pipefail

# Configuration
readonly SCRIPT_NAME="${0:t}"
readonly MISE_POSTGRES_PATH="$HOME/.local/share/mise/installs/postgres"
readonly MISE_BIN="/opt/homebrew/bin/mise"

# Logging functions
log_info() {
    print "[INFO] $*"
}

log_error() {
    print "[ERROR] $*" >&2
}

log_debug() {
    print "[DEBUG] $*"
}

# Get PostgreSQL version - try running instance first, then mise config
get_postgres_version() {
    local version
    
    # First try to detect running postgres instance
    version=$(pgrep postgres | head -1 | xargs ps -p 2>/dev/null | tail -1 | awk '{print $4}' | sed 's|.*/postgres/\([^/]*\)/bin/postgres.*|\1|' 2>/dev/null)
    
    if [[ -n "$version" ]]; then
        print "$version"
        return 0
    fi
    
    # Fallback to mise configuration for current directory
    version=$($MISE_BIN ls postgres 2>/dev/null | grep "$(pwd)" | awk '{print $2}' | head -1)
    
    if [[ -z "$version" ]]; then
        log_error "No PostgreSQL version found (not running and not configured in mise)"
        log_info "Available versions: $MISE_BIN list postgres"
        log_info "Set version: $MISE_BIN use postgres@<version>"
        exit 1
    fi
    
    print "$version"
}

# Validate PostgreSQL installation
validate_installation() {
    local version="$1"
    local pg_bin="$MISE_POSTGRES_PATH/$version/bin"
    local pg_data="$MISE_POSTGRES_PATH/$version/data"
    
    if [[ ! -d "$pg_bin" ]]; then
        log_error "PostgreSQL $version installation not found at $pg_bin"
        log_debug "Current mise postgres configuration:"
        $MISE_BIN ls postgres 2>/dev/null || true
        exit 1
    fi
    
    print "$pg_bin:$pg_data"
}

# Count active PostgreSQL connections
count_connections() {
    local count
    count=$(ps aux | grep 'postgres:' | grep -v grep | wc -l)
    print ${count// /}
}

# Check server status and responsiveness
check_status() {
    local pg_bin="$1"
    local connection_count
    
    connection_count=$(count_connections)
    log_info "Active connections: $connection_count"
    
    if "$pg_bin/psql" -U postgres -c "SHOW max_connections;" >/dev/null 2>&1; then
        log_info "Server status: RESPONSIVE"
        return 0
    else
        log_error "Server status: UNRESPONSIVE (too many connections)"
        return 1
    fi
}

# Restart PostgreSQL server
restart_server() {
    local pg_bin="$1"
    local pg_data="$2"
    
    log_info "Stopping PostgreSQL server..."
    "$pg_bin/pg_ctl" -D "$pg_data" stop -m fast
    
    log_info "Starting PostgreSQL server..."
    "$pg_bin/pg_ctl" -D "$pg_data" start
    
    log_info "Server restart completed"
    check_status "$pg_bin"
}

# Terminate idle connections
kill_idle_connections() {
    local pg_bin="$1"
    local before_count after_count killed_count
    
    before_count=$(count_connections)
    
    log_info "Terminating idle connections..."
    pkill -f "postgres.*idle" 2>/dev/null || true
    sleep 2
    
    after_count=$(count_connections)
    killed_count=$((before_count - after_count))
    
    log_info "Terminated $killed_count idle connections"
    check_status "$pg_bin"
}

# Display usage information
show_usage() {
    print "Usage: $SCRIPT_NAME [COMMAND]"
    print ""
    print "PostgreSQL Connection Management Commands:"
    print "  check, c     Display connection status and server responsiveness"
    print "  restart, r   Restart the PostgreSQL server"
    print "  kill, k      Terminate idle connections"
    print "  help, h      Show this help message"
    print ""
    print "Examples:"
    print "  $SCRIPT_NAME check"
    print "  $SCRIPT_NAME restart"
    print "  $SCRIPT_NAME kill"
}

# Main execution
main() {
    local command="${1:-check}"
    local postgres_version pg_paths pg_bin pg_data
    
    # Initialize
    postgres_version=$(get_postgres_version)
    pg_paths=$(validate_installation "$postgres_version")
    
    # ZSH parameter expansion for splitting
    pg_bin="${pg_paths%%:*}"
    pg_data="${pg_paths##*:}"
    
    log_info "Using PostgreSQL $postgres_version (managed by mise)"
    
    # Execute command
    case "$command" in
        "check"|"c")
            check_status "$pg_bin"
            ;;
        "restart"|"r")
            restart_server "$pg_bin" "$pg_data"
            ;;
        "kill"|"k")
            kill_idle_connections "$pg_bin"
            ;;
        "help"|"h"|"--help")
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"

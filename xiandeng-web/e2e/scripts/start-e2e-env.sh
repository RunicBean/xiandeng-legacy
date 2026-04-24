#!/bin/bash
set -e

# E2E Environment Startup Script
# This script starts all services needed for E2E testing:
# 1. PostgreSQL database (via docker-compose)
# 2. Redis (via docker-compose)
# 3. Backend server (Go)
# 4. Frontend dev server (Vite)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SERVER_DIR="$PROJECT_ROOT/xiandeng-server"
WEB_DIR="$PROJECT_ROOT/xiandeng-web"
XIENG_DB_DIR="$PROJECT_ROOT/xiandeng-db"

# Database connection string for E2E tests
E2E_DB_URL="postgres://postgres:postgres@localhost:54329/xiandeng_e2e?sslmode=disable"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running from correct directory
if [ ! -d "$SERVER_DIR" ] || [ ! -d "$WEB_DIR" ] || [ ! -d "$XIENG_DB_DIR" ]; then
    log_error "Required directories not found: $SERVER_DIR, $WEB_DIR, or $XIENG_DB_DIR"
    exit 1
fi

stop_services() {
    log_info "Stopping existing services..."
    # Stop backend if running
    pkill -f "xiandeng-server" 2>/dev/null || true
    pkill -f "go-build" 2>/dev/null || true

    # Stop frontend dev server
    pkill -f "vite" 2>/dev/null || true

    # Stop and remove docker containers
    cd "$SERVER_DIR"
    docker-compose -f docker-compose.e2e.yml down -v 2>/dev/null || true
}

start_database() {
    log_info "Starting PostgreSQL and Redis containers..."
    cd "$SERVER_DIR"
    docker-compose -f docker-compose.e2e.yml up -d

    log_info "Waiting for PostgreSQL to be ready..."
    local max_attempts=30
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        if docker exec xiandeng-e2e-postgres pg_isready -U postgres -d xiandeng_e2e > /dev/null 2>&1; then
            log_info "PostgreSQL is ready!"
            break
        fi
        echo -n "."
        sleep 1
        attempt=$((attempt + 1))
    done

    if [ $attempt -gt $max_attempts ]; then
        log_error "PostgreSQL failed to start"
        exit 1
    fi

    log_info "Waiting for Redis to be ready..."
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if docker exec xiandeng-e2e-redis redis-cli ping > /dev/null 2>&1; then
            log_info "Redis is ready!"
            return 0
        fi
        echo -n "."
        sleep 1
        attempt=$((attempt + 1))
    done

    log_error "Redis failed to start"
    exit 1
}

run_migrations() {
    log_info "Running database migrations using golang-migrate..."

    # Check if migrate CLI is installed
    if ! command -v migrate &> /dev/null; then
        log_info "Installing migrate CLI..."
        go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest
    fi

    # Run migrations from xiandeng-db/migrations
    migrate -source "file://$XIENG_DB_DIR/migrations" -database "$E2E_DB_URL" up
    log_info "Migrations completed!"
}

load_test_data() {
    log_info "Loading test data..."
    local fixture_file="$SCRIPT_DIR/test-data.sql"

    if [ -f "$fixture_file" ]; then
        docker exec -i xiandeng-e2e-postgres psql -U postgres -d xiandeng_e2e < "$fixture_file"
        log_info "Test data loaded!"
    else
        log_warn "No test data fixture found at $fixture_file"
    fi
}

start_backend() {
    log_info "Building backend server..."
    cd "$SERVER_DIR"

    if [ ! -f "$SERVER_DIR/server" ]; then
        go build -o server .
    fi

    log_info "Starting backend server on port 8080..."
    cd "$SERVER_DIR"
    ./server -conf conf/e2e_config.yaml > /tmp/xiandeng-server.log 2>&1 &
    SERVER_PID=$!

    # Wait for server to start
    sleep 3

    # Check if server is running
    if ! kill -0 $SERVER_PID 2>/dev/null; then
        log_error "Backend server failed to start. Check /tmp/xiandeng-server.log"
        cat /tmp/xiandeng-server.log
        exit 1
    fi

    log_info "Backend server started (PID: $SERVER_PID)"
}

start_frontend() {
    log_info "Starting frontend dev server on port 5173..."
    cd "$WEB_DIR"
    npm run dev > /tmp/xiandeng-frontend.log 2>&1 &
    FRONTEND_PID=$!

    # Wait for frontend to start
    sleep 5

    log_info "Frontend dev server started (PID: $FRONTEND_PID)"
}

cleanup() {
    log_info "Cleaning up..."
    pkill -f "xiandeng-server" 2>/dev/null || true
    pkill -f "vite" 2>/dev/null || true
}

# Parse command line arguments
case "${1:-}" in
    start)
        stop_services
        start_database
        run_migrations
        load_test_data
        start_backend
        start_frontend
        log_info "E2E environment is ready!"
        log_info "Frontend: http://localhost:5173"
        log_info "Backend: http://localhost:8080"
        log_info ""
        log_info "To stop all services, run: $0 stop"
        ;;
    stop)
        cleanup
        cd "$SERVER_DIR"
        docker-compose -f docker-compose.e2e.yml down -v 2>/dev/null || true
        log_info "All services stopped"
        ;;
    restart)
        $0 stop
        sleep 2
        $0 start
        ;;
    logs)
        tail -f /tmp/xiandeng-server.log /tmp/xiandeng-frontend.log
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|logs}"
        echo ""
        echo "Commands:"
        echo "  start   - Start all E2E services (database, backend, frontend)"
        echo "  stop    - Stop all E2E services"
        echo "  restart - Restart all E2E services"
        echo "  logs    - View logs from backend and frontend"
        exit 1
        ;;
esac
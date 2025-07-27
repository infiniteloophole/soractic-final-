#!/bin/bash

# Redis Cluster Management Script
# This script helps manage the Redis cluster for scaling operations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Redis cluster nodes
REDIS_NODES=(
    "redis-node-1:6379"
    "redis-node-2:6379"
    "redis-node-3:6379"
    "redis-node-4:6379"
    "redis-node-5:6379"
    "redis-node-6:6379"
)

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Start Redis cluster
start_cluster() {
    log_info "Starting Redis cluster..."
    docker-compose -f "$COMPOSE_FILE" up -d redis-node-1 redis-node-2 redis-node-3 redis-node-4 redis-node-5 redis-node-6
    
    log_info "Waiting for nodes to be ready..."
    sleep 15
    
    log_info "Initializing cluster..."
    docker-compose -f "$COMPOSE_FILE" up redis-cluster-init
    
    log_success "Redis cluster started successfully!"
}

# Stop Redis cluster
stop_cluster() {
    log_info "Stopping Redis cluster..."
    docker-compose -f "$COMPOSE_FILE" stop redis-node-1 redis-node-2 redis-node-3 redis-node-4 redis-node-5 redis-node-6 redis-cluster-init
    log_success "Redis cluster stopped!"
}

# Restart Redis cluster
restart_cluster() {
    log_info "Restarting Redis cluster..."
    stop_cluster
    sleep 5
    start_cluster
}

# Check cluster status
check_status() {
    log_info "Checking Redis cluster status..."
    
    for i in {1..6}; do
        port=$((6378 + i))
        if docker-compose -f "$COMPOSE_FILE" exec -T redis-node-$i redis-cli -p 6379 ping &>/dev/null; then
            log_success "redis-node-$i (port $port): HEALTHY"
        else
            log_error "redis-node-$i (port $port): UNHEALTHY"
        fi
    done
    
    log_info "Cluster information:"
    docker-compose -f "$COMPOSE_FILE" exec -T redis-node-1 redis-cli --cluster info redis-node-1:6379 2>/dev/null || log_warning "Could not get cluster info"
}

# Show cluster nodes
show_nodes() {
    log_info "Redis cluster nodes:"
    docker-compose -f "$COMPOSE_FILE" exec -T redis-node-1 redis-cli cluster nodes 2>/dev/null || log_warning "Could not get cluster nodes"
}

# Monitor cluster
monitor_cluster() {
    log_info "Monitoring Redis cluster... (Press Ctrl+C to stop)"
    
    while true; do
        clear
        echo "=== Redis Cluster Monitor ==="
        echo "$(date)"
        echo ""
        
        check_status
        echo ""
        
        log_info "Memory usage:"
        for i in {1..6}; do
            memory=$(docker-compose -f "$COMPOSE_FILE" exec -T redis-node-$i redis-cli info memory | grep used_memory_human | cut -d: -f2 | tr -d '\r' 2>/dev/null || echo "N/A")
            echo "  redis-node-$i: $memory"
        done
        
        echo ""
        log_info "Connected clients:"
        for i in {1..6}; do
            clients=$(docker-compose -f "$COMPOSE_FILE" exec -T redis-node-$i redis-cli info clients | grep connected_clients | cut -d: -f2 | tr -d '\r' 2>/dev/null || echo "N/A")
            echo "  redis-node-$i: $clients clients"
        done
        
        sleep 10
    done
}

# Test cluster performance
test_performance() {
    log_info "Running Redis cluster performance test..."
    
    log_info "Testing write performance..."
    docker-compose -f "$COMPOSE_FILE" exec -T redis-node-1 redis-cli --cluster eval "
        for i=1,1000 do
            redis.call('set', 'test:key:' .. i, 'value:' .. i, 'ex', 300)
        end
        return 'OK'
    " 0
    
    log_info "Testing read performance..."
    docker-compose -f "$COMPOSE_FILE" exec -T redis-node-1 redis-cli --cluster eval "
        local count = 0
        for i=1,1000 do
            local val = redis.call('get', 'test:key:' .. i)
            if val then count = count + 1 end
        end
        return count
    " 0
    
    log_success "Performance test completed!"
}

# Scale cluster (add nodes)
scale_up() {
    log_warning "Scaling up functionality not implemented yet."
    log_info "To scale up manually:"
    log_info "1. Add new Redis nodes to docker-compose.yml"
    log_info "2. Start the new nodes"
    log_info "3. Add them to cluster using: redis-cli --cluster add-node"
    log_info "4. Rebalance slots using: redis-cli --cluster rebalance"
}

# Backup cluster data
backup_cluster() {
    log_info "Creating Redis cluster backup..."
    
    BACKUP_DIR="$SCRIPT_DIR/redis-backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    for i in {1..6}; do
        log_info "Backing up redis-node-$i..."
        docker-compose -f "$COMPOSE_FILE" exec -T redis-node-$i redis-cli --rdb "/data/backup-node-$i.rdb" &>/dev/null || log_warning "Backup failed for redis-node-$i"
        docker cp "$(docker-compose -f "$COMPOSE_FILE" ps -q redis-node-$i):/data/backup-node-$i.rdb" "$BACKUP_DIR/" 2>/dev/null || log_warning "Could not copy backup for redis-node-$i"
    done
    
    log_success "Backup completed: $BACKUP_DIR"
}

# Show help
show_help() {
    echo "Redis Cluster Management Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start       Start the Redis cluster"
    echo "  stop        Stop the Redis cluster"
    echo "  restart     Restart the Redis cluster"
    echo "  status      Check cluster status"
    echo "  nodes       Show cluster nodes"
    echo "  monitor     Monitor cluster in real-time"
    echo "  test        Run performance test"
    echo "  scale       Scale up cluster (placeholder)"
    echo "  backup      Backup cluster data"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 status"
    echo "  $0 monitor"
}

# Main script logic
case "${1:-help}" in
    start)
        start_cluster
        ;;
    stop)
        stop_cluster
        ;;
    restart)
        restart_cluster
        ;;
    status)
        check_status
        ;;
    nodes)
        show_nodes
        ;;
    monitor)
        monitor_cluster
        ;;
    test)
        test_performance
        ;;
    scale)
        scale_up
        ;;
    backup)
        backup_cluster
        ;;
    help|*)
        show_help
        ;;
esac

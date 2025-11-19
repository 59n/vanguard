#!/bin/bash
# Quick Docker Test Script

echo "🐳 Testing Vanguard Docker Setup"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if containers are running
echo "📦 Checking containers..."
if docker-compose ps | grep -q "Up"; then
    echo -e "${GREEN}✅ Containers are running${NC}"
    docker-compose ps
else
    echo -e "${RED}❌ No containers running. Start with: docker-compose up -d${NC}"
    exit 1
fi

echo ""
echo "🔍 Checking service health..."

# Check PostgreSQL
echo -n "PostgreSQL: "
if docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Ready${NC}"
else
    echo -e "${RED}❌ Not ready${NC}"
fi

# Check Redis
echo -n "Redis: "
if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Responding${NC}"
else
    echo -e "${RED}❌ Not responding${NC}"
fi

# Check HTTP
echo -n "Web Server: "
if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200\|302"; then
    echo -e "${GREEN}✅ Responding${NC}"
else
    echo -e "${YELLOW}⚠️  Check http://localhost manually${NC}"
fi

# Check migrations
echo -n "Database Migrations: "
if docker-compose exec -T app php artisan migrate:status > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Run${NC}"
else
    echo -e "${YELLOW}⚠️  Migrations may not be run${NC}"
fi

echo ""
echo "📊 Resource Usage:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | head -10

echo ""
echo "🌐 Access points:"
echo "  - Web: http://localhost"
echo "  - Horizon: http://localhost/horizon"
echo "  - Reverb: ws://localhost:8080"

echo ""
echo -e "${GREEN}✅ Quick test complete!${NC}"

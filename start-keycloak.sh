#!/bin/bash

# 🔑 Start Keycloak for MCP Auth Demo Server
# This script starts Keycloak with Docker Compose and provides helpful information

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  Starting Keycloak for MCP Auth Demo Server${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${YELLOW}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker is running${NC}"
echo ""

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}⚠️  docker-compose not found, trying 'docker compose'${NC}"
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

echo -e "${BLUE}🚀 Starting Keycloak...${NC}"
$DOCKER_COMPOSE up -d keycloak

echo ""
echo -e "${BLUE}⏳ Waiting for Keycloak to be ready...${NC}"

# Wait for Keycloak to be healthy
MAX_ATTEMPTS=60
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if docker exec mcp-keycloak curl -sf http://localhost:8080/health/ready > /dev/null 2>&1; then
        echo ""
        echo -e "${GREEN}✅ Keycloak is ready!${NC}"
        break
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
    echo -n "."
    sleep 2
    
    if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
        echo ""
        echo -e "${YELLOW}⚠️  Keycloak is taking longer than expected to start${NC}"
        echo -e "${YELLOW}   Check logs with: docker-compose logs keycloak${NC}"
        exit 1
    fi
done

echo ""
echo -e "${BLUE}============================================================${NC}"
echo -e "${GREEN}  🎉 Keycloak is running!${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""
echo -e "📍 Admin Console: ${GREEN}http://localhost:8080${NC}"
echo -e "👤 Admin Username: ${GREEN}admin${NC}"
echo -e "🔑 Admin Password: ${GREEN}admin${NC}"
echo ""
echo -e "🌍 Realm: ${GREEN}mcp-demo${NC}"
echo -e "📱 Client ID: ${GREEN}mcp-auth-demo${NC}"
echo ""
echo -e "👥 Demo User:"
echo -e "   Email: ${GREEN}demo@example.com${NC}"
echo -e "   Password: ${GREEN}demo123${NC}"
echo ""
echo -e "${BLUE}============================================================${NC}"
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo ""
echo -e "1. Get the client secret:"
echo -e "   ${GREEN}http://localhost:8080${NC} → mcp-demo realm"
echo -e "   → Clients → mcp-auth-demo → Credentials"
echo ""
echo -e "2. Copy the Keycloak environment template:"
echo -e "   ${GREEN}cp keycloak.env .env${NC}"
echo ""
echo -e "3. Update .env with your client secret"
echo ""
echo -e "4. Start the MCP server:"
echo -e "   ${GREEN}python run.py${NC}"
echo ""
echo -e "${BLUE}============================================================${NC}"
echo ""
echo -e "💡 Useful commands:"
echo -e "   Stop: ${GREEN}docker-compose stop${NC}"
echo -e "   Logs: ${GREEN}docker-compose logs -f keycloak${NC}"
echo -e "   Reset: ${GREEN}docker-compose down -v${NC}"
echo ""


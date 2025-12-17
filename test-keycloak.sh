#!/bin/bash

# Keycloak Integration Test Script
# Tests that Keycloak is properly configured and working

set -e

echo "============================================================"
echo "🧪 Keycloak Integration Test"
echo "============================================================"
echo ""

# Configuration
KEYCLOAK_URL="${KEYCLOAK_URL:-http://localhost:8080}"
REALM_NAME="${REALM_NAME:-mcp-demo}"
CLIENT_ID="${CLIENT_ID:-mcp-server}"
TEST_USER="${TEST_USER:-testuser}"
TEST_PASSWORD="${TEST_PASSWORD:-testpassword}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
test_step() {
    local description=$1
    local command=$2
    
    echo -n "Testing: $description... "
    
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

echo "📋 Configuration:"
echo "  Keycloak URL: $KEYCLOAK_URL"
echo "  Realm: $REALM_NAME"
echo "  Client ID: $CLIENT_ID"
echo ""

# Test 1: Keycloak is running
echo "1️⃣  Testing Keycloak Availability"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
test_step "Keycloak is reachable" "curl -sf $KEYCLOAK_URL > /dev/null"
test_step "Keycloak health endpoint" "curl -sf $KEYCLOAK_URL/health/ready | grep -q 'status.*UP'"
echo ""

# Test 2: OIDC Discovery
echo "2️⃣  Testing OIDC Discovery"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
OIDC_URL="$KEYCLOAK_URL/realms/$REALM_NAME/.well-known/openid-configuration"
test_step "OIDC discovery endpoint" "curl -sf $OIDC_URL > /dev/null"
test_step "Authorization endpoint exists" "curl -sf $OIDC_URL | jq -e '.authorization_endpoint' > /dev/null"
test_step "Token endpoint exists" "curl -sf $OIDC_URL | jq -e '.token_endpoint' > /dev/null"
test_step "JWKS URI exists" "curl -sf $OIDC_URL | jq -e '.jwks_uri' > /dev/null"
echo ""

# Test 3: Get access token
echo "3️⃣  Testing User Authentication"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -z "$CLIENT_SECRET" ]; then
    echo -e "${YELLOW}⚠️  CLIENT_SECRET not set, skipping token tests${NC}"
    echo "   Set CLIENT_SECRET environment variable to run these tests"
    echo ""
else
    TOKEN_URL="$KEYCLOAK_URL/realms/$REALM_NAME/protocol/openid-connect/token"
    
    TOKEN_RESPONSE=$(curl -sf -X POST "$TOKEN_URL" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=$TEST_USER" \
        -d "password=$TEST_PASSWORD" \
        -d "grant_type=password" \
        -d "client_id=$CLIENT_ID" \
        -d "client_secret=$CLIENT_SECRET" \
        -d "scope=read:notes write:notes use:calculator" 2>/dev/null || echo "")
    
    if [ -n "$TOKEN_RESPONSE" ]; then
        ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token' 2>/dev/null || echo "")
        
        if [ -n "$ACCESS_TOKEN" ] && [ "$ACCESS_TOKEN" != "null" ]; then
            echo -e "${GREEN}✓ Successfully obtained access token${NC}"
            ((TESTS_PASSED++))
            
            # Decode token to check claims
            TOKEN_PAYLOAD=$(echo "$ACCESS_TOKEN" | cut -d'.' -f2 | base64 -d 2>/dev/null || echo "")
            
            if [ -n "$TOKEN_PAYLOAD" ]; then
                echo -e "${GREEN}✓ Token is valid JWT${NC}"
                ((TESTS_PASSED++))
                
                # Check for required claims
                if echo "$TOKEN_PAYLOAD" | jq -e '.aud' > /dev/null 2>&1; then
                    echo -e "${GREEN}✓ Token has audience claim${NC}"
                    ((TESTS_PASSED++))
                else
                    echo -e "${RED}✗ Token missing audience claim${NC}"
                    ((TESTS_FAILED++))
                fi
                
                if echo "$TOKEN_PAYLOAD" | jq -e '.scope' > /dev/null 2>&1; then
                    echo -e "${GREEN}✓ Token has scope claim${NC}"
                    ((TESTS_PASSED++))
                    
                    SCOPES=$(echo "$TOKEN_PAYLOAD" | jq -r '.scope' 2>/dev/null)
                    echo "   Scopes: $SCOPES"
                else
                    echo -e "${RED}✗ Token missing scope claim${NC}"
                    ((TESTS_FAILED++))
                fi
            fi
        else
            echo -e "${RED}✗ Failed to obtain access token${NC}"
            echo "   Response: $TOKEN_RESPONSE"
            ((TESTS_FAILED++))
        fi
    else
        echo -e "${RED}✗ Token request failed${NC}"
        ((TESTS_FAILED++))
    fi
    echo ""
fi

# Test 4: MCP Server
echo "4️⃣  Testing MCP Server"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
MCP_URL="http://localhost:8000"
test_step "MCP server is running" "curl -sf $MCP_URL > /dev/null"

if [ -n "$ACCESS_TOKEN" ]; then
    test_step "MCP accepts authenticated requests" "curl -sf -X POST $MCP_URL/mcp -H 'Authorization: Bearer $ACCESS_TOKEN' -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"tools/list\",\"id\":1}' > /dev/null"
fi
echo ""

# Test 5: Docker
echo "5️⃣  Testing Docker Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
test_step "Docker is installed" "command -v docker > /dev/null"
test_step "Docker Compose is installed" "command -v docker-compose > /dev/null"
test_step "Keycloak container is running" "docker ps | grep -q keycloak"
echo ""

# Summary
echo "============================================================"
echo "📊 Test Summary"
echo "============================================================"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed! Keycloak is properly configured.${NC}"
    echo ""
    echo "🚀 Next Steps:"
    echo "  1. Update src/server.py to use Keycloak"
    echo "  2. Start MCP server: python run.py"
    echo "  3. Test with MCP Inspector: npx @modelcontextprotocol/inspector"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please check the configuration.${NC}"
    echo ""
    echo "🔧 Troubleshooting:"
    echo "  1. Make sure Keycloak is running: docker-compose up -d"
    echo "  2. Run setup script: ./keycloak-setup.sh"
    echo "  3. Set CLIENT_SECRET: export CLIENT_SECRET=<your-secret>"
    echo "  4. Check logs: docker-compose logs keycloak"
    echo ""
    echo "📖 For more help, see KEYCLOAK_MIGRATION_GUIDE.md"
    exit 1
fi


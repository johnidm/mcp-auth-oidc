#!/bin/bash

# Test OAuth discovery endpoints

echo "============================================================"
echo "🧪 Testing OAuth Discovery Endpoints"
echo "============================================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test function
test_endpoint() {
    local name=$1
    local url=$2
    
    echo -n "Testing $name... "
    
    if response=$(curl -s -w "%{http_code}" -o /tmp/response.json "$url"); then
        http_code="${response: -3}"
        if [ "$http_code" = "200" ]; then
            echo -e "${GREEN}✓ PASS${NC} (HTTP $http_code)"
            return 0
        else
            echo -e "${RED}✗ FAIL${NC} (HTTP $http_code)"
            return 1
        fi
    else
        echo -e "${RED}✗ FAIL${NC} (Connection error)"
        return 1
    fi
}

# Test OAuth authorization server metadata
test_endpoint "OAuth Authorization Server" "http://localhost:8000/.well-known/oauth-authorization-server"

# Test OIDC configuration
test_endpoint "OIDC Configuration" "http://localhost:8000/.well-known/openid-configuration"

# Test client registration
echo -n "Testing Client Registration... "
response=$(curl -s -w "%{http_code}" -X POST "http://localhost:8000/register" \
  -H "Content-Type: application/json" \
  -d '{"client_name": "Test Client"}' \
  -o /tmp/register_response.json)
http_code="${response: -3}"

if [ "$http_code" = "201" ]; then
    echo -e "${GREEN}✓ PASS${NC} (HTTP $http_code)"
    client_id=$(jq -r '.client_id' /tmp/register_response.json 2>/dev/null)
    if [ -n "$client_id" ]; then
        echo "  Client ID: $client_id"
    fi
else
    echo -e "${RED}✗ FAIL${NC} (HTTP $http_code)"
fi

echo ""
echo "============================================================"
echo "📊 View Full Responses"
echo "============================================================"
echo ""

echo "OAuth Authorization Server Metadata:"
jq '.' /tmp/response.json 2>/dev/null | head -20

echo ""
echo "🎉 Tests complete!"
echo ""
echo "If all tests passed, your OAuth endpoints are working!"
echo "Try connecting with MCP Inspector now."


#!/bin/bash

# Token debugging script
# Helps diagnose why token validation is failing

set -e

echo "============================================================"
echo "🔍 Token Validation Debugging"
echo "============================================================"
echo ""

# Configuration
KEYCLOAK_URL="${KEYCLOAK_BASE_URL:-http://localhost:8080}"
REALM="${KEYCLOAK_REALM:-mcp-demo}"
CLIENT_ID="${KEYCLOAK_CLIENT_ID:-mcp-server}"
CLIENT_SECRET="${KEYCLOAK_CLIENT_SECRET}"

if [ -z "$CLIENT_SECRET" ]; then
    echo "⚠️  CLIENT_SECRET not set. Reading from .env..."
    if [ -f .env ]; then
        export $(grep -v '^#' .env | xargs)
        CLIENT_SECRET="${KEYCLOAK_CLIENT_SECRET}"
    fi
fi

if [ -z "$CLIENT_SECRET" ]; then
    echo "❌ Error: KEYCLOAK_CLIENT_SECRET not found in environment or .env"
    echo "   Please set it in your .env file or export it"
    exit 1
fi

REALM_URL="$KEYCLOAK_URL/realms/$REALM"

echo "📋 Configuration:"
echo "  Keycloak URL: $KEYCLOAK_URL"
echo "  Realm: $REALM"
echo "  Realm URL: $REALM_URL"
echo "  Client ID: $CLIENT_ID"
echo ""

# Step 1: Test OIDC Discovery
echo "1️⃣  Testing OIDC Discovery..."
DISCOVERY=$(curl -s "$REALM_URL/.well-known/openid-configuration")

if [ $? -eq 0 ]; then
    echo "✅ OIDC Discovery successful"
    
    ISSUER=$(echo "$DISCOVERY" | jq -r '.issuer')
    TOKEN_ENDPOINT=$(echo "$DISCOVERY" | jq -r '.token_endpoint')
    JWKS_URI=$(echo "$DISCOVERY" | jq -r '.jwks_uri')
    
    echo "   Issuer: $ISSUER"
    echo "   Token Endpoint: $TOKEN_ENDPOINT"
    echo "   JWKS URI: $JWKS_URI"
else
    echo "❌ OIDC Discovery failed"
    exit 1
fi
echo ""

# Step 2: Test JWKS Endpoint
echo "2️⃣  Testing JWKS Endpoint..."
JWKS=$(curl -s "$JWKS_URI")

if [ $? -eq 0 ]; then
    KEY_COUNT=$(echo "$JWKS" | jq '.keys | length')
    echo "✅ JWKS retrieved successfully"
    echo "   Number of keys: $KEY_COUNT"
    
    if [ "$KEY_COUNT" -eq 0 ]; then
        echo "⚠️  Warning: No keys found in JWKS!"
    fi
else
    echo "❌ JWKS retrieval failed"
    exit 1
fi
echo ""

# Step 3: Get a Test Token
echo "3️⃣  Getting test token..."
TOKEN_RESPONSE=$(curl -s -X POST "$TOKEN_ENDPOINT" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET" \
  -d "username=testuser" \
  -d "password=testpassword" \
  -d "scope=openid profile email claudeai read:notes write:notes use:calculator")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" == "null" ]; then
    echo "❌ Failed to get access token"
    echo "Response:"
    echo "$TOKEN_RESPONSE" | jq
    exit 1
fi

echo "✅ Access token obtained"
echo ""

# Step 4: Decode Token
echo "4️⃣  Decoding token..."
# Split token into parts
IFS='.' read -ra TOKEN_PARTS <<< "$ACCESS_TOKEN"

# Decode header
HEADER=$(echo "${TOKEN_PARTS[0]}" | base64 -d 2>/dev/null | jq 2>/dev/null || echo "{}")
# Decode payload (add padding if needed)
PAYLOAD_B64="${TOKEN_PARTS[1]}"
case $((${#PAYLOAD_B64} % 4)) in
    2) PAYLOAD_B64="${PAYLOAD_B64}==" ;;
    3) PAYLOAD_B64="${PAYLOAD_B64}=" ;;
esac
PAYLOAD=$(echo "$PAYLOAD_B64" | base64 -d 2>/dev/null | jq 2>/dev/null || echo "{}")

echo "Token Header:"
echo "$HEADER" | jq '.'
echo ""

echo "Token Claims:"
echo "$PAYLOAD" | jq '.'
echo ""

# Extract key claims
TOKEN_ISS=$(echo "$PAYLOAD" | jq -r '.iss')
TOKEN_AUD=$(echo "$PAYLOAD" | jq -r '.aud')
TOKEN_SCOPE=$(echo "$PAYLOAD" | jq -r '.scope')
TOKEN_EXP=$(echo "$PAYLOAD" | jq -r '.exp')

echo "📊 Key Claims:"
echo "  Issuer (iss): $TOKEN_ISS"
echo "  Audience (aud): $TOKEN_AUD"
echo "  Scope: $TOKEN_SCOPE"
echo "  Expires (exp): $TOKEN_EXP"
echo ""

# Step 5: Check Configuration
echo "5️⃣  Checking your configuration..."
echo ""
echo "Your keycloak_auth_config.py should have:"
echo ""
echo "KEYCLOAK_ISSUER = \"$TOKEN_ISS\""
echo "KEYCLOAK_JWKS_URI = \"$JWKS_URI\""
echo "KEYCLOAK_AUDIENCE = \"$TOKEN_AUD\" (or one of the audiences if array)"
echo ""

# Step 6: Compare with .env
echo "6️⃣  Checking .env file..."
if [ -f .env ]; then
    echo ""
    echo "Current .env settings:"
    grep -E "KEYCLOAK_REALM|KEYCLOAK_BASE_URL|KEYCLOAK_AUDIENCE" .env | while read line; do
        echo "  $line"
    done
    echo ""
    
    ENV_AUDIENCE=$(grep KEYCLOAK_AUDIENCE .env | cut -d '=' -f2)
    EXPECTED_ISSUER="$KEYCLOAK_URL/realms/$REALM"
    
    echo "✅ Expected values:"
    echo "  KEYCLOAK_ISSUER should be: $EXPECTED_ISSUER"
    echo "  Token issuer is: $TOKEN_ISS"
    
    if [ "$EXPECTED_ISSUER" != "$TOKEN_ISS" ]; then
        echo ""
        echo "⚠️  WARNING: Issuer mismatch!"
        echo "   Expected: $EXPECTED_ISSUER"
        echo "   Token has: $TOKEN_ISS"
        echo ""
        echo "This will cause token validation to fail!"
    fi
    
    echo ""
    echo "  KEYCLOAK_AUDIENCE in .env: $ENV_AUDIENCE"
    echo "  Token audience is: $TOKEN_AUD"
    
    if [ "$ENV_AUDIENCE" != "$TOKEN_AUD" ]; then
        echo ""
        echo "⚠️  WARNING: Audience mismatch!"
        echo "   .env has: $ENV_AUDIENCE"
        echo "   Token has: $TOKEN_AUD"
        echo ""
        echo "This will cause token validation to fail!"
    fi
fi
echo ""

# Step 7: Test with MCP Server
echo "7️⃣  Testing token with MCP server..."
MCP_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "http://localhost:8000/mcp" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/list",
    "id": 1
  }')

HTTP_CODE=$(echo "$MCP_RESPONSE" | tail -n 1)
RESPONSE_BODY=$(echo "$MCP_RESPONSE" | head -n -1)

echo "HTTP Status: $HTTP_CODE"

if [ "$HTTP_CODE" == "200" ]; then
    echo "✅ Token validation successful!"
    echo ""
    echo "Response:"
    echo "$RESPONSE_BODY" | jq
elif [ "$HTTP_CODE" == "401" ]; then
    echo "❌ Token validation failed (401 Unauthorized)"
    echo ""
    echo "Response:"
    echo "$RESPONSE_BODY" | jq
    echo ""
    echo "🔧 Possible fixes:"
    echo "  1. Check issuer matches: $TOKEN_ISS"
    echo "  2. Check audience matches: $TOKEN_AUD"
    echo "  3. Check JWKS URI is accessible: $JWKS_URI"
    echo "  4. Restart your MCP server after fixing .env"
else
    echo "⚠️  Unexpected status: $HTTP_CODE"
    echo ""
    echo "Response:"
    echo "$RESPONSE_BODY"
fi

echo ""
echo "============================================================"
echo "🎯 Summary"
echo "============================================================"
echo ""
echo "If token validation failed, check:"
echo "  1. Issuer in token: $TOKEN_ISS"
echo "  2. Audience in token: $TOKEN_AUD"
echo "  3. JWKS URI works: $JWKS_URI"
echo "  4. Your .env file has correct values"
echo "  5. Restart MCP server after .env changes"
echo ""
echo "Test token (first 50 chars): ${ACCESS_TOKEN:0:50}..."
echo ""


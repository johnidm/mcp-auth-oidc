#!/bin/bash

# Script to fix audience in Keycloak tokens
# Removes extra audiences so token only has "mcp-server"

set -e

echo "============================================================"
echo "🔧 Fix Keycloak Token Audience"
echo "============================================================"
echo ""

# Configuration
KEYCLOAK_URL="${KEYCLOAK_URL:-http://localhost:8080}"
ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin}"
REALM_NAME="${REALM_NAME:-mcp-demo}"
CLIENT_ID="${CLIENT_ID:-mcp-server}"

echo "📋 Configuration:"
echo "  Keycloak URL: $KEYCLOAK_URL"
echo "  Realm: $REALM_NAME"
echo "  Client ID: $CLIENT_ID"
echo ""

# Get admin token
echo "🔑 Getting admin access token..."
ADMIN_TOKEN=$(curl -sf -X POST "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=$ADMIN_USER" \
  -d "password=$ADMIN_PASSWORD" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')

if [ -z "$ADMIN_TOKEN" ] || [ "$ADMIN_TOKEN" == "null" ]; then
    echo "❌ Error: Failed to get admin token"
    exit 1
fi
echo "✅ Admin token acquired"
echo ""

# Get client UUID
echo "🔍 Finding client..."
CLIENT_UUID=$(curl -sf "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r ".[] | select(.clientId==\"$CLIENT_ID\") | .id")

if [ -z "$CLIENT_UUID" ]; then
    echo "❌ Error: Client '$CLIENT_ID' not found"
    exit 1
fi
echo "✅ Client found: $CLIENT_UUID"
echo ""

# The "account" audience comes from the account client scope
# We need to remove it from optional client scopes

echo "📖 Checking client scopes..."
OPTIONAL_SCOPES=$(curl -sf "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients/$CLIENT_UUID/optional-client-scopes" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

echo "Current optional client scopes:"
echo "$OPTIONAL_SCOPES" | jq -r '.[].name'
echo ""

# Find the "account" scope ID
ACCOUNT_SCOPE_ID=$(echo "$OPTIONAL_SCOPES" | jq -r '.[] | select(.name=="account") | .id')

if [ -n "$ACCOUNT_SCOPE_ID" ] && [ "$ACCOUNT_SCOPE_ID" != "null" ]; then
    echo "🗑️  Removing 'account' scope..."
    curl -sf -X DELETE "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients/$CLIENT_UUID/optional-client-scopes/$ACCOUNT_SCOPE_ID" \
      -H "Authorization: Bearer $ADMIN_TOKEN"
    
    echo "✅ Removed 'account' scope from client"
else
    echo "ℹ️  'account' scope not found in optional scopes"
fi
echo ""

# Also check default scopes
DEFAULT_SCOPES=$(curl -sf "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients/$CLIENT_UUID/default-client-scopes" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

ACCOUNT_DEFAULT_ID=$(echo "$DEFAULT_SCOPES" | jq -r '.[] | select(.name=="account") | .id')

if [ -n "$ACCOUNT_DEFAULT_ID" ] && [ "$ACCOUNT_DEFAULT_ID" != "null" ]; then
    echo "🗑️  Removing 'account' from default scopes..."
    curl -sf -X DELETE "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients/$CLIENT_UUID/default-client-scopes/$ACCOUNT_DEFAULT_ID" \
      -H "Authorization: Bearer $ADMIN_TOKEN"
    
    echo "✅ Removed 'account' scope from default scopes"
else
    echo "ℹ️  'account' scope not in default scopes"
fi
echo ""

echo "============================================================"
echo "✅ Audience Configuration Fixed!"
echo "============================================================"
echo ""
echo "🧪 Testing new token..."
echo ""

# Get new token
if [ -n "$CLIENT_SECRET" ]; then
    TOKEN_RESPONSE=$(curl -s -X POST "$KEYCLOAK_URL/realms/$REALM_NAME/protocol/openid-connect/token" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "grant_type=password" \
      -d "client_id=$CLIENT_ID" \
      -d "client_secret=$CLIENT_SECRET" \
      -d "username=testuser" \
      -d "password=testpassword" \
      -d "scope=openid profile email claudeai read:notes write:notes use:calculator")
    
    ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')
    
    if [ -n "$ACCESS_TOKEN" ] && [ "$ACCESS_TOKEN" != "null" ]; then
        # Decode token
        IFS='.' read -ra TOKEN_PARTS <<< "$ACCESS_TOKEN"
        PAYLOAD_B64="${TOKEN_PARTS[1]}"
        case $((${#PAYLOAD_B64} % 4)) in
            2) PAYLOAD_B64="${PAYLOAD_B64}==" ;;
            3) PAYLOAD_B64="${PAYLOAD_B64}=" ;;
        esac
        PAYLOAD=$(echo "$PAYLOAD_B64" | base64 -d 2>/dev/null | jq 2>/dev/null || echo "{}")
        
        NEW_AUD=$(echo "$PAYLOAD" | jq -r '.aud')
        
        echo "New token audience: $NEW_AUD"
        
        if [ "$NEW_AUD" == "mcp-server" ] || [ "$NEW_AUD" == '["mcp-server"]' ]; then
            echo "✅ Perfect! Token now only has 'mcp-server' audience"
        else
            echo "⚠️  Token still has: $NEW_AUD"
            echo "   You may need to restart Keycloak or wait a moment"
        fi
    fi
fi

echo ""
echo "🎯 Next Steps:"
echo "  1. Restart your MCP server: python run.py"
echo "  2. Get a new token (old tokens still have old audience)"
echo "  3. Test again with MCP Inspector or curl"
echo ""


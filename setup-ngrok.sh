#!/bin/bash

# Script to setup ngrok with Keycloak
# Automatically updates redirect URIs

set -e

echo "============================================================"
echo "🌐 Setup ngrok for MCP Server"
echo "============================================================"
echo ""

# Check if ngrok URL is provided
if [ -z "$1" ]; then
    echo "Usage: ./setup-ngrok.sh <ngrok-url>"
    echo ""
    echo "Example:"
    echo "  ./setup-ngrok.sh https://abc123.ngrok-free.app"
    echo ""
    echo "Or start ngrok first and get the URL:"
    echo "  ngrok http 8000"
    echo "  # Then copy the Forwarding URL (https://...)"
    echo ""
    exit 1
fi

NGROK_URL="$1"

# Remove trailing slash if present
NGROK_URL="${NGROK_URL%/}"

echo "📋 Configuration:"
echo "  ngrok URL: $NGROK_URL"
echo ""

# Keycloak configuration
KEYCLOAK_URL="${KEYCLOAK_URL:-http://localhost:8080}"
ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin}"
REALM_NAME="${REALM_NAME:-mcp-demo}"
CLIENT_ID="${CLIENT_ID:-mcp-server}"

# Step 1: Update .env file
echo "1️⃣  Updating .env file..."

if [ -f .env ]; then
    # Backup .env
    cp .env .env.backup
    
    # Update RESOURCE_ID
    if grep -q "^RESOURCE_ID=" .env; then
        sed -i.bak "s|^RESOURCE_ID=.*|RESOURCE_ID=$NGROK_URL|" .env
        rm .env.bak  # Remove sed backup
        echo "✅ Updated RESOURCE_ID to $NGROK_URL"
    else
        echo "RESOURCE_ID=$NGROK_URL" >> .env
        echo "✅ Added RESOURCE_ID=$NGROK_URL"
    fi
else
    echo "⚠️  .env file not found, creating one..."
    cat > .env << EOF
# Keycloak Configuration
KEYCLOAK_REALM=mcp-demo
KEYCLOAK_BASE_URL=http://localhost:8080
KEYCLOAK_CLIENT_ID=mcp-server
KEYCLOAK_CLIENT_SECRET=your-secret-here
KEYCLOAK_AUDIENCE=mcp-server

# Server Configuration (ngrok)
RESOURCE_ID=$NGROK_URL
SERVER_HOST=0.0.0.0
SERVER_PORT=8000

# Auth Provider
AUTH_PROVIDER=keycloak
EOF
    echo "✅ Created .env file with ngrok URL"
fi
echo ""

# Step 2: Update Keycloak redirect URIs
echo "2️⃣  Updating Keycloak redirect URIs..."

# Get admin token
ADMIN_TOKEN=$(curl -sf -X POST "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=$ADMIN_USER" \
  -d "password=$ADMIN_PASSWORD" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')

if [ -z "$ADMIN_TOKEN" ] || [ "$ADMIN_TOKEN" == "null" ]; then
    echo "⚠️  Could not get admin token - you'll need to update Keycloak manually"
    echo "   Go to: $KEYCLOAK_URL"
    echo "   Clients → $CLIENT_ID → Settings"
    echo "   Add to Valid Redirect URIs:"
    echo "     $NGROK_URL/auth/callback"
    echo "     $NGROK_URL/oauth/callback"
    echo ""
else
    # Get client UUID
    CLIENT_UUID=$(curl -sf "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients" \
      -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r ".[] | select(.clientId==\"$CLIENT_ID\") | .id")
    
    if [ -n "$CLIENT_UUID" ]; then
        # Update redirect URIs
        curl -sf -X PUT "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients/$CLIENT_UUID" \
          -H "Authorization: Bearer $ADMIN_TOKEN" \
          -H "Content-Type: application/json" \
          -d "{
            \"clientId\": \"$CLIENT_ID\",
            \"redirectUris\": [
              \"http://localhost:8000/auth/callback\",
              \"http://localhost:6274/oauth/callback\",
              \"$NGROK_URL/auth/callback\",
              \"$NGROK_URL/oauth/callback\"
            ],
            \"webOrigins\": [
              \"http://localhost:8000\",
              \"http://localhost:6274\",
              \"$NGROK_URL\",
              \"*\"
            ]
          }"
        
        echo "✅ Updated Keycloak redirect URIs"
    else
        echo "⚠️  Client not found - update manually"
    fi
fi
echo ""

# Step 3: Show OAuth endpoints
echo "3️⃣  OAuth Discovery URLs:"
echo ""
echo "  OAuth Metadata:"
echo "    $NGROK_URL/.well-known/oauth-authorization-server"
echo ""
echo "  OIDC Configuration:"
echo "    $NGROK_URL/.well-known/openid-configuration"
echo ""
echo "  Client Registration:"
echo "    $NGROK_URL/register"
echo ""

echo "============================================================"
echo "✅ ngrok Setup Complete!"
echo "============================================================"
echo ""
echo "🎯 Next Steps:"
echo ""
echo "  1. Restart your MCP server:"
echo "     python run.py"
echo ""
echo "  2. Use this URL in MCP Inspector:"
echo "     $NGROK_URL/mcp"
echo ""
echo "  3. OAuth endpoints will return ngrok URLs"
echo ""
echo "⚠️  Remember: ngrok URL changes when you restart ngrok!"
echo "   Run this script again with the new URL."
echo ""


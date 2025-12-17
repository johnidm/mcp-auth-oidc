#!/bin/bash

# Keycloak Automated Setup Script
# This script helps automate the initial Keycloak configuration for MCP server

set -e

echo "============================================================"
echo "🔐 Keycloak Setup for MCP Server"
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

# Check if Keycloak is running
echo "🔍 Checking if Keycloak is running..."
if ! curl -sf "$KEYCLOAK_URL/health/ready" > /dev/null 2>&1; then
    echo "❌ Error: Keycloak is not running or not ready"
    echo "   Please start Keycloak with: docker-compose up -d"
    exit 1
fi
echo "✅ Keycloak is running"
echo ""

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "❌ Error: jq is not installed"
    echo "   Please install jq: brew install jq (macOS) or apt-get install jq (Linux)"
    exit 1
fi

# Get admin token
echo "🔑 Getting admin access token..."
ADMIN_TOKEN=$(curl -sf -X POST "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=$ADMIN_USER" \
  -d "password=$ADMIN_PASSWORD" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')

if [ -z "$ADMIN_TOKEN" ] || [ "$ADMIN_TOKEN" == "null" ]; then
    echo "❌ Error: Failed to get admin token. Check credentials."
    exit 1
fi
echo "✅ Admin token acquired"
echo ""

# Create realm
echo "🏗️  Creating realm '$REALM_NAME'..."
REALM_EXISTS=$(curl -sf "$KEYCLOAK_URL/admin/realms/$REALM_NAME" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.realm' 2>/dev/null || echo "")

if [ "$REALM_EXISTS" == "$REALM_NAME" ]; then
    echo "⚠️  Realm '$REALM_NAME' already exists, skipping creation"
else
    curl -sf -X POST "$KEYCLOAK_URL/admin/realms" \
      -H "Authorization: Bearer $ADMIN_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "realm": "'"$REALM_NAME"'",
        "enabled": true,
        "displayName": "MCP Demo Realm",
        "loginTheme": "keycloak",
        "accessTokenLifespan": 3600,
        "ssoSessionMaxLifespan": 36000
      }'
    echo "✅ Realm created"
fi
echo ""

# Create client scopes
echo "🎫 Creating client scopes..."
for SCOPE_NAME in "read:notes" "write:notes" "use:calculator"; do
    SCOPE_DESCRIPTION=""
    case $SCOPE_NAME in
        "read:notes") SCOPE_DESCRIPTION="Permission to read notes" ;;
        "write:notes") SCOPE_DESCRIPTION="Permission to create, update, and delete notes" ;;
        "use:calculator") SCOPE_DESCRIPTION="Permission to use calculator tools" ;;
    esac
    
    SCOPE_ID=$(curl -sf "$KEYCLOAK_URL/admin/realms/$REALM_NAME/client-scopes" \
      -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r ".[] | select(.name==\"$SCOPE_NAME\") | .id" 2>/dev/null || echo "")
    
    if [ -n "$SCOPE_ID" ]; then
        echo "  ⚠️  Scope '$SCOPE_NAME' already exists, skipping"
    else
        curl -sf -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/client-scopes" \
          -H "Authorization: Bearer $ADMIN_TOKEN" \
          -H "Content-Type: application/json" \
          -d '{
            "name": "'"$SCOPE_NAME"'",
            "description": "'"$SCOPE_DESCRIPTION"'",
            "protocol": "openid-connect",
            "attributes": {
              "include.in.token.scope": "true",
              "display.on.consent.screen": "true"
            }
          }'
        echo "  ✅ Created scope: $SCOPE_NAME"
    fi
done
echo ""

# Create client
echo "📱 Creating client '$CLIENT_ID'..."
CLIENT_UUID=$(curl -sf "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r ".[] | select(.clientId==\"$CLIENT_ID\") | .id" 2>/dev/null || echo "")

if [ -n "$CLIENT_UUID" ]; then
    echo "⚠️  Client '$CLIENT_ID' already exists"
else
    curl -sf -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients" \
      -H "Authorization: Bearer $ADMIN_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "clientId": "'"$CLIENT_ID"'",
        "name": "MCP Server",
        "description": "MCP Server with OAuth Authentication",
        "enabled": true,
        "clientAuthenticatorType": "client-secret",
        "redirectUris": [
          "http://localhost:8000/auth/callback",
          "http://localhost:6274/oauth/callback"
        ],
        "webOrigins": ["http://localhost:8000"],
        "publicClient": false,
        "protocol": "openid-connect",
        "standardFlowEnabled": true,
        "directAccessGrantsEnabled": true,
        "serviceAccountsEnabled": false,
        "attributes": {
          "access.token.lifespan": "3600"
        }
      }'
    
    # Get the newly created client UUID
    sleep 1
    CLIENT_UUID=$(curl -sf "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients" \
      -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r ".[] | select(.clientId==\"$CLIENT_ID\") | .id")
    
    echo "✅ Client created"
fi
echo ""

# Get client secret
echo "🔑 Retrieving client secret..."
CLIENT_SECRET=$(curl -sf "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients/$CLIENT_UUID/client-secret" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.value')

if [ -z "$CLIENT_SECRET" ] || [ "$CLIENT_SECRET" == "null" ]; then
    echo "❌ Error: Failed to get client secret"
    exit 1
fi
echo "✅ Client secret retrieved"
echo ""

# Add client scopes to client
echo "🔗 Adding scopes to client..."
for SCOPE_NAME in "read:notes" "write:notes" "use:calculator"; do
    SCOPE_ID=$(curl -sf "$KEYCLOAK_URL/admin/realms/$REALM_NAME/client-scopes" \
      -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r ".[] | select(.name==\"$SCOPE_NAME\") | .id")
    
    if [ -n "$SCOPE_ID" ]; then
        curl -sf -X PUT "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients/$CLIENT_UUID/optional-client-scopes/$SCOPE_ID" \
          -H "Authorization: Bearer $ADMIN_TOKEN"
        echo "  ✅ Added scope: $SCOPE_NAME"
    fi
done
echo ""

# Create audience mapper
echo "🎯 Creating audience mapper..."
curl -sf -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients/$CLIENT_UUID/protocol-mappers/models" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "audience-mapper",
    "protocol": "openid-connect",
    "protocolMapper": "oidc-audience-mapper",
    "config": {
      "included.client.audience": "'"$CLIENT_ID"'",
      "id.token.claim": "false",
      "access.token.claim": "true"
    }
  }' 2>/dev/null || echo "  ⚠️  Audience mapper may already exist"
echo "✅ Audience mapper configured"
echo ""

# Create test user
echo "👤 Creating test user..."
USER_ID=$(curl -sf "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users?username=testuser" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[0].id' 2>/dev/null || echo "")

if [ -n "$USER_ID" ] && [ "$USER_ID" != "null" ]; then
    echo "⚠️  User 'testuser' already exists"
else
    curl -sf -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users" \
      -H "Authorization: Bearer $ADMIN_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "username": "testuser",
        "email": "testuser@example.com",
        "firstName": "Test",
        "lastName": "User",
        "enabled": true,
        "emailVerified": true
      }'
    
    sleep 1
    USER_ID=$(curl -sf "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users?username=testuser" \
      -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[0].id')
    
    # Set password
    curl -sf -X PUT "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users/$USER_ID/reset-password" \
      -H "Authorization: Bearer $ADMIN_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "type": "password",
        "value": "testpassword",
        "temporary": false
      }'
    
    echo "✅ Test user created (username: testuser, password: testpassword)"
fi
echo ""

# Generate .env file
echo "📝 Generating .env configuration..."
cat > .env.keycloak << EOF
# Keycloak Configuration (Auto-generated)
KEYCLOAK_REALM=$REALM_NAME
KEYCLOAK_BASE_URL=$KEYCLOAK_URL
KEYCLOAK_CLIENT_ID=$CLIENT_ID
KEYCLOAK_CLIENT_SECRET=$CLIENT_SECRET
KEYCLOAK_AUDIENCE=$CLIENT_ID

# Server Configuration
RESOURCE_ID=http://localhost:8000
SERVER_HOST=0.0.0.0
SERVER_PORT=8000

# Auth Provider
AUTH_PROVIDER=keycloak
EOF

echo "✅ Configuration saved to .env.keycloak"
echo ""

echo "============================================================"
echo "✅ Keycloak Setup Complete!"
echo "============================================================"
echo ""
echo "📋 Summary:"
echo "  • Realm: $REALM_NAME"
echo "  • Client ID: $CLIENT_ID"
echo "  • Client Secret: $CLIENT_SECRET"
echo "  • Test User: testuser / testpassword"
echo "  • Scopes: read:notes, write:notes, use:calculator"
echo ""
echo "🚀 Next Steps:"
echo "  1. Copy configuration: cp .env.keycloak .env"
echo "  2. Update src/server.py to use Keycloak (see KEYCLOAK_MIGRATION_GUIDE.md)"
echo "  3. Start MCP server: python run.py"
echo "  4. Test with MCP Inspector: npx @modelcontextprotocol/inspector"
echo ""
echo "🔗 Useful Links:"
echo "  • Keycloak Admin: $KEYCLOAK_URL"
echo "  • OIDC Discovery: $KEYCLOAK_URL/realms/$REALM_NAME/.well-known/openid-configuration"
echo "  • Admin Console: $KEYCLOAK_URL (admin / admin)"
echo ""
echo "✨ Happy testing!"


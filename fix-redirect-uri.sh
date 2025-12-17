#!/bin/bash

# Script to add redirect URIs to Keycloak client
# This fixes the "Invalid parameter: redirect_uri" error

set -e

echo "============================================================"
echo "🔧 Fix Keycloak Redirect URI"
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

# Get current client configuration
echo "📖 Reading current configuration..."
CLIENT_CONFIG=$(curl -sf "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients/$CLIENT_UUID" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

CURRENT_URIS=$(echo "$CLIENT_CONFIG" | jq -r '.redirectUris | join(", ")')
echo "Current redirect URIs:"
echo "  $CURRENT_URIS"
echo ""

# Update redirect URIs
echo "📝 Adding redirect URIs..."

# Common redirect URIs that should be included
NEW_URIS='[
  "http://localhost:8000/auth/callback",
  "http://localhost:8000/oauth/callback",
  "http://localhost:6274/oauth/callback",
  "http://localhost:6274/*",
  "http://127.0.0.1:8000/auth/callback",
  "http://127.0.0.1:6274/oauth/callback"
]'

# Update the client
curl -sf -X PUT "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients/$CLIENT_UUID" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"clientId\": \"$CLIENT_ID\",
    \"redirectUris\": $NEW_URIS,
    \"webOrigins\": [\"http://localhost:8000\", \"http://localhost:6274\", \"*\"]
  }"

echo "✅ Redirect URIs updated!"
echo ""

# Verify
echo "🔍 Verifying update..."
UPDATED_CONFIG=$(curl -sf "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients/$CLIENT_UUID" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

UPDATED_URIS=$(echo "$UPDATED_CONFIG" | jq -r '.redirectUris[]')
echo "Updated redirect URIs:"
echo "$UPDATED_URIS" | while read uri; do
    echo "  ✓ $uri"
done
echo ""

echo "============================================================"
echo "✅ Redirect URIs Fixed!"
echo "============================================================"
echo ""
echo "🎯 Next Steps:"
echo "  1. Go back to your browser"
echo "  2. Refresh the authentication page"
echo "  3. Try connecting again"
echo ""
echo "If you still get errors, add your specific redirect URI manually:"
echo "  1. Go to: $KEYCLOAK_URL"
echo "  2. Login as: $ADMIN_USER"
echo "  3. Navigate to: Clients → $CLIENT_ID → Settings"
echo "  4. Add your redirect URI to 'Valid Redirect URIs'"
echo "  5. Click 'Save'"
echo ""


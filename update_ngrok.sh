#!/bin/bash
# Helper script to update configuration when ngrok URL changes

echo "🔄 Update ngrok Configuration"
echo "================================"
echo ""

# Get current ngrok URL
echo "Enter your new ngrok URL (e.g., https://abc123.ngrok-free.app):"
read NGROK_URL

# Remove trailing slash if present
NGROK_URL=${NGROK_URL%/}

# Validate URL format
if [[ ! $NGROK_URL =~ ^https://[a-z0-9]+\.ngrok-free\.app$ ]]; then
    echo "❌ Invalid ngrok URL format"
    echo "Expected format: https://xxxxxx.ngrok-free.app"
    exit 1
fi

echo ""
echo "✅ Using ngrok URL: $NGROK_URL"
echo ""

# Update .env file
if [ -f .env ]; then
    echo "📝 Updating .env file..."
    
    # Backup original
    cp .env .env.backup
    
    # Update RESOURCE_ID
    if grep -q "^RESOURCE_ID=" .env; then
        sed -i '' "s|^RESOURCE_ID=.*|RESOURCE_ID=$NGROK_URL|" .env
    else
        echo "RESOURCE_ID=$NGROK_URL" >> .env
    fi
    
    # Update AUTH0_AUDIENCE
    if grep -q "^AUTH0_AUDIENCE=" .env; then
        sed -i '' "s|^AUTH0_AUDIENCE=.*|AUTH0_AUDIENCE=$NGROK_URL|" .env
    else
        echo "AUTH0_AUDIENCE=$NGROK_URL" >> .env
    fi
    
    echo "✅ .env updated (backup saved as .env.backup)"
else
    echo "❌ .env file not found!"
    exit 1
fi

echo ""
echo "================================"
echo "⚠️  MANUAL STEPS REQUIRED:"
echo "================================"
echo ""
echo "1. Go to Auth0 Dashboard: https://manage.auth0.com/"
echo ""
echo "2. Create/Update API:"
echo "   - Applications → APIs → Create API"
echo "   - Name: MCP Demo API"
echo "   - Identifier: $NGROK_URL"
echo "   - Add permissions: read:notes, write:notes, use:calculator"
echo "   - Enable RBAC + Add Permissions in Access Token"
echo ""
echo "3. Update Application Callbacks:"
echo "   - Applications → Your App → Settings"
echo "   - Allowed Callback URLs:"
echo "     http://localhost:8000/auth/callback,"
echo "     http://localhost:6274/oauth/callback,"
echo "     $NGROK_URL/auth/callback"
echo ""
echo "   - Allowed Web Origins:"
echo "     http://localhost:8000,"
echo "     http://localhost:6274,"
echo "     $NGROK_URL"
echo ""
echo "4. Restart your server:"
echo "   python run.py"
echo ""
echo "5. Use in MCP Inspector:"
echo "   $NGROK_URL/mcp"
echo ""
echo "================================"
echo ""
echo "✅ .env file updated!"
echo "⚠️  Complete Auth0 steps above, then restart server."


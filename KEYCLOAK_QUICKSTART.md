# 🚀 Keycloak Quick Start

Get your MCP server running with Keycloak in under 5 minutes!

## ⚡ Ultra-Fast Setup

### Step 1: Start Keycloak (30 seconds)

```bash
# Start Keycloak with Docker
docker-compose up -d

# Wait for Keycloak to be ready (check health)
docker-compose logs -f keycloak
# Wait until you see: "Keycloak 23.0 started"
```

Keycloak is now running at http://localhost:8080 🎉

### Step 2: Auto-Configure Keycloak (1 minute)

```bash
# Run the automated setup script
./keycloak-setup.sh
```

This script will:
- ✅ Create realm: `mcp-demo`
- ✅ Create client: `mcp-server`
- ✅ Create scopes: `read:notes`, `write:notes`, `use:calculator`
- ✅ Create test user: `testuser` / `testpassword`
- ✅ Generate `.env.keycloak` with all credentials

### Step 3: Configure Your Server (30 seconds)

```bash
# Use the generated Keycloak config
cp .env.keycloak .env
```

### Step 4: Update Server Code (30 seconds)

Option A - Environment Variable Switch (Recommended):

Edit your `.env`:
```env
AUTH_PROVIDER=keycloak
```

And update `src/server.py`:
```python
import os
# Choose provider based on environment
AUTH_PROVIDER = os.getenv("AUTH_PROVIDER", "auth0")

if AUTH_PROVIDER == "keycloak":
    from src.keycloak_auth_config import create_auth_provider
else:
    from src.auth_config import create_auth_provider
```

Option B - Direct Import:

Edit `src/server.py`:
```python
# Change this line:
# from src.auth_config import create_auth_provider

# To this:
from src.keycloak_auth_config import create_auth_provider
```

### Step 5: Start Your Server (10 seconds)

```bash
python run.py
```

You should see:
```
============================================================
MCP Auth Demo Server (FastMCP + OIDC Proxy)
============================================================
Base URL: http://localhost:8000
Keycloak Realm: mcp-demo
Server: http://0.0.0.0:8000
Auth Callback: http://localhost:8000/auth/callback
============================================================
```

### Step 6: Test It! (1 minute)

```bash
# In a new terminal
npx @modelcontextprotocol/inspector
```

Configure Inspector:
- **Server URL**: `http://localhost:8000/mcp`
- **Scopes**: `read:notes write:notes use:calculator`

Click **Connect**, login with:
- **Username**: `testuser`
- **Password**: `testpassword`

🎉 **Done!** You're now running with Keycloak!

## 🧪 Quick Test Commands

### Test User Login

```bash
curl -X POST 'http://localhost:8080/realms/mcp-demo/protocol/openid-connect/token' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'grant_type=password' \
  -d 'client_id=mcp-server' \
  -d 'client_secret=<your-client-secret>' \
  -d 'username=testuser' \
  -d 'password=testpassword' \
  -d 'scope=read:notes write:notes use:calculator' | jq
```

### Test MCP Tool Call

```bash
# Get token from above command
TOKEN="<your-access-token>"

curl -X POST 'http://localhost:8000/mcp' \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "add_numbers",
      "arguments": {"a": 5, "b": 3}
    },
    "id": 1
  }' | jq
```

## 🔧 Troubleshooting Quick Fixes

### Keycloak won't start

```bash
# Check if port 8080 is in use
lsof -ti:8080

# Kill process on port 8080
lsof -ti:8080 | xargs kill -9

# Restart Keycloak
docker-compose up -d
```

### Setup script fails

```bash
# Check if jq is installed
brew install jq  # macOS
apt-get install jq  # Linux

# Check if Keycloak is ready
curl http://localhost:8080/health/ready

# Wait and retry
./keycloak-setup.sh
```

### Can't login to Keycloak Admin

- **URL**: http://localhost:8080
- **Username**: `admin`
- **Password**: `admin`

If it doesn't work:
```bash
docker-compose logs keycloak | grep -i password
```

### MCP Inspector can't connect

1. Check server is running: `curl http://localhost:8000/`
2. Check Keycloak is running: `curl http://localhost:8080/health/ready`
3. Verify redirect URI in Keycloak:
   - Login to http://localhost:8080
   - Go to Clients → mcp-server → Valid redirect URIs
   - Should include: `http://localhost:6274/oauth/callback`

## 📖 Next Steps

### Explore Keycloak Admin Console

- **Users**: http://localhost:8080/admin/master/console/#/mcp-demo/users
- **Clients**: http://localhost:8080/admin/master/console/#/mcp-demo/clients
- **Scopes**: http://localhost:8080/admin/master/console/#/mcp-demo/client-scopes

### Production Deployment

For production setup with PostgreSQL and HTTPS:

```bash
# Use production docker-compose
docker-compose -f docker-compose.prod.yml up -d
```

See [KEYCLOAK_MIGRATION_GUIDE.md](KEYCLOAK_MIGRATION_GUIDE.md) for details.

### Advanced Configuration

Want to customize Keycloak? See the full guide:
- [KEYCLOAK_MIGRATION_GUIDE.md](KEYCLOAK_MIGRATION_GUIDE.md)

## 🎯 Summary

You now have:
- ✅ Keycloak running locally
- ✅ Realm and client configured
- ✅ Test user created
- ✅ MCP server integrated
- ✅ Ready to test with Inspector

**Total setup time**: ~5 minutes ⚡

---

<div align="center">

**Need more details?** See [KEYCLOAK_MIGRATION_GUIDE.md](KEYCLOAK_MIGRATION_GUIDE.md)

Made with ❤️ for the open-source community

</div>

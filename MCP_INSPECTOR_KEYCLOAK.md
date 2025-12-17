# 🔍 Using MCP Inspector with Keycloak

## ⚠️ Important: OAuth Discovery with JWTVerifier

When using `JWTVerifier` + `RemoteAuthProvider` (required for Keycloak), your MCP server **does not** expose OAuth discovery endpoints like:
- `/.well-known/oauth-authorization-server`
- `/.well-known/openid-configuration`

This is **by design** - `JWTVerifier` only validates tokens, it doesn't manage OAuth flows.

## ✅ Solution: Configure Inspector to Use Keycloak Directly

MCP Inspector needs to know where to find Keycloak's OAuth endpoints. Here's how to configure it:

### Step 1: Start Your Servers

```bash
# Terminal 1: Start Keycloak
docker-compose up -d

# Terminal 2: Start MCP Server
python run.py
```

### Step 2: Get Client Secret from Keycloak

If you ran the setup script, your client secret is in `.env.keycloak`:

```bash
# View your client secret
grep KEYCLOAK_CLIENT_SECRET .env.keycloak
```

Or get it from Keycloak Admin:
1. Go to http://localhost:8080
2. Login as `admin` / `admin`
3. Select realm: `mcp-demo`
4. Go to **Clients** → **mcp-server**
5. Go to **Credentials** tab
6. Copy the **Client Secret**

### Step 3: Launch MCP Inspector

```bash
# Terminal 3: Start Inspector
npx @modelcontextprotocol/inspector
```

Browser opens at http://localhost:6274

### Step 4: Configure Connection in Inspector

#### Basic Settings

- **Server URL**: `http://localhost:8000/mcp` or `http://localhost:8000/sse`
- **Transport**: HTTP with SSE

#### OAuth Configuration

Click on **"OAuth"** or **"Authentication"** section and configure:

**Option A: Manual Configuration (Recommended)**

Provide Keycloak endpoints directly:

- **Authorization Endpoint**: 
  ```
  http://localhost:8080/realms/mcp-demo/protocol/openid-connect/auth
  ```

- **Token Endpoint**: 
  ```
  http://localhost:8080/realms/mcp-demo/protocol/openid-connect/token
  ```

- **Client ID**: `mcp-server`

- **Client Secret**: (paste from Step 2)

- **Scopes**: 
  ```
  openid profile email read:notes write:notes use:calculator
  ```

- **Redirect URI**: 
  ```
  http://localhost:6274/oauth/callback
  ```

**Option B: Discovery URL**

If Inspector supports OIDC discovery, use Keycloak's discovery endpoint:

- **Discovery URL**: 
  ```
  http://localhost:8080/realms/mcp-demo/.well-known/openid-configuration
  ```

- **Client ID**: `mcp-server`

- **Client Secret**: (paste from Step 2)

- **Scopes**: 
  ```
  openid profile email read:notes write:notes use:calculator
  ```

### Step 5: Connect and Test

1. Click **"Connect"** in Inspector
2. You'll be redirected to Keycloak login
3. Login with: `testuser` / `testpassword`
4. Approve the consent screen
5. You'll be redirected back to Inspector
6. Inspector now has a valid token!

### Step 6: Test MCP Tools

Try calling a tool:

**Example: add_numbers**
```json
{
  "a": 5,
  "b": 3
}
```

**Expected Result**: `8`

## 🔧 Troubleshooting

### Error: "Failed to discover OAuth endpoints"

**Problem**: Inspector tried to discover OAuth at your MCP server (`http://localhost:8000/.well-known/...`)

**Solution**: Configure Keycloak endpoints manually (Option A above)

### Error: "Redirect URI mismatch"

**Problem**: Inspector's callback URL not registered in Keycloak

**Solution**: 
1. Go to Keycloak Admin Console
2. Select realm `mcp-demo`
3. Go to **Clients** → **mcp-server** → **Settings**
4. Add to **Valid Redirect URIs**:
   ```
   http://localhost:6274/oauth/callback
   http://localhost:6274/*
   ```
5. Save

### Error: "Invalid client credentials"

**Problem**: Client secret is wrong or not provided

**Solution**: 
1. Get the correct secret from Keycloak (see Step 2)
2. Make sure it's in your `.env` file
3. Restart your MCP server if you changed `.env`

### Error: "Invalid token" or "Token validation failed"

**Problem**: Token audience or issuer doesn't match

**Solution**: Check your `keycloak_auth_config.py`:
```python
KEYCLOAK_ISSUER = f"{KEYCLOAK_BASE_URL}/realms/{KEYCLOAK_REALM}"
KEYCLOAK_AUDIENCE = os.getenv("KEYCLOAK_AUDIENCE", "mcp-server")
```

Make sure:
- Issuer matches Keycloak realm URL exactly
- Audience matches what Keycloak puts in tokens

### Error: "Scope not granted"

**Problem**: Requested scopes not configured in Keycloak

**Solution**:
1. Go to Keycloak Admin → **Client Scopes**
2. Verify scopes exist: `read:notes`, `write:notes`, `use:calculator`
3. Go to **Clients** → **mcp-server** → **Client scopes**
4. Add missing scopes as **Optional**

## 📝 Complete Configuration Example

Here's a complete setup that works:

### .env file
```env
KEYCLOAK_REALM=mcp-demo
KEYCLOAK_BASE_URL=http://localhost:8080
KEYCLOAK_CLIENT_ID=mcp-server
KEYCLOAK_CLIENT_SECRET=your-secret-here
KEYCLOAK_AUDIENCE=mcp-server
RESOURCE_ID=http://localhost:8000
SERVER_HOST=0.0.0.0
SERVER_PORT=8000
```

### Keycloak Setup
- **Realm**: `mcp-demo`
- **Client**: `mcp-server`
- **Client Type**: Confidential
- **Valid Redirect URIs**: 
  - `http://localhost:6274/oauth/callback`
  - `http://localhost:8000/auth/callback`
- **Scopes**: `read:notes`, `write:notes`, `use:calculator`

### MCP Inspector Config
- **Server URL**: `http://localhost:8000/mcp`
- **Auth Endpoint**: `http://localhost:8080/realms/mcp-demo/protocol/openid-connect/auth`
- **Token Endpoint**: `http://localhost:8080/realms/mcp-demo/protocol/openid-connect/token`
- **Client ID**: `mcp-server`
- **Client Secret**: (from Keycloak)
- **Scopes**: `openid profile email read:notes write:notes use:calculator`

## 🎯 How It Works

```
1. Inspector → Keycloak: "I need to authenticate"
2. Keycloak → User: Shows login page
3. User → Keycloak: Enters credentials
4. Keycloak → Inspector: "Here's an access token"
5. Inspector → MCP Server: "Here's my token"
6. MCP Server (JWTVerifier): "Let me validate that..."
7. MCP Server → Keycloak JWKS: "Is this token valid?"
8. Keycloak JWKS → MCP Server: "Yes, valid signature"
9. MCP Server → Inspector: "Token valid, here's your data"
```

**Key Point**: Your MCP server **never handles** the OAuth flow, it only validates tokens.

## 🚀 Quick Test

```bash
# 1. Get token from Keycloak manually
curl -X POST 'http://localhost:8080/realms/mcp-demo/protocol/openid-connect/token' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'grant_type=password' \
  -d 'client_id=mcp-server' \
  -d 'client_secret=YOUR_SECRET' \
  -d 'username=testuser' \
  -d 'password=testpassword' \
  -d 'scope=openid read:notes write:notes use:calculator' | jq

# 2. Use token with MCP server
TOKEN="<access_token_from_above>"

curl -X POST 'http://localhost:8000/mcp' \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/list",
    "id": 1
  }' | jq

# Should return list of tools!
```

## 📚 Related Guides

- [KEYCLOAK_QUICKSTART.md](KEYCLOAK_QUICKSTART.md) - Quick Keycloak setup
- [KEYCLOAK_MIGRATION_GUIDE.md](KEYCLOAK_MIGRATION_GUIDE.md) - Complete migration guide
- [FASTMCP_AUTH_REALITY.md](FASTMCP_AUTH_REALITY.md) - Understanding FastMCP auth
- [MCP_INSPECTOR_GUIDE.md](MCP_INSPECTOR_GUIDE.md) - General Inspector guide (Auth0)

## ✅ Summary

With `JWTVerifier` + `RemoteAuthProvider`:
- ✅ Your MCP server validates tokens from Keycloak
- ✅ MCP Inspector handles OAuth flow with Keycloak directly
- ✅ Configure Inspector to use Keycloak's endpoints, not your server's
- ✅ This is the correct and expected behavior!

---

**The 404 on `/.well-known/oauth-authorization-server` is expected and correct!** Just configure Inspector to use Keycloak's endpoints directly. 🎯


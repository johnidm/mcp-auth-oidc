# Quick Start Guide

Get your MCP server with OAuth authentication running in 5 minutes using FastMCP's OIDC Proxy!

## Step 1: Install Dependencies (1 minute)

```bash
pip install -r requirements.txt
```

## Step 2: Set Up Auth0 (2 minutes)

### Option A: Use Demo Credentials (Fastest)

Create a `.env` file with the pre-configured demo credentials:

```bash
cat > .env << 'EOF'
# Auth0 Configuration (Demo)
AUTH0_DOMAIN=dev-zilqiezmsk6ylig2.us.auth0.com
AUTH0_CLIENT_ID=GsJfBMVGn5cDgWQwTiq91SIQBYxQccJA
AUTH0_CLIENT_SECRET=Qst5RVD9Vt79F5NgM_s6ymZSvMYemKrFMykWrDOtextPC2nBeK593yBvpJBafIDl
AUTH0_AUDIENCE=https://dev-zilqiezmsk6ylig2.us.auth0.com/api/v2/

# Server Configuration
RESOURCE_ID=http://localhost:8000
SERVER_HOST=0.0.0.0
SERVER_PORT=8000
EOF
```

### Option B: Use Your Own Auth0 Account

1. Create an Auth0 application (Regular Web App)
2. Set redirect URI to: `http://localhost:8000/auth/callback`
3. Create an API and add scopes: `read:notes`, `write:notes`, `use:calculator`
4. Create `.env` with your credentials:

```env
AUTH0_DOMAIN=your-domain.us.auth0.com
AUTH0_CLIENT_ID=your_client_id
AUTH0_CLIENT_SECRET=your_client_secret
AUTH0_AUDIENCE=https://your-domain.us.auth0.com/api/v2/
RESOURCE_ID=http://localhost:8000
SERVER_HOST=0.0.0.0
SERVER_PORT=8000
```

## Step 3: Start the Server (30 seconds)

```bash
python run.py
```

You should see:

```
============================================================
MCP Auth Demo Server (FastMCP + OIDC Proxy)
============================================================
Base URL: http://localhost:8000
Auth0 Domain: dev-zilqiezmsk6ylig2.us.auth0.com
Server: http://0.0.0.0:8000
Auth Callback: http://localhost:8000/auth/callback
============================================================

Starting server with FastMCP's built-in HTTP/SSE transport...
```

## Step 4: Connect to Claude.ai (1 minute)

### Option A: Claude.ai Web

1. Go to [Claude.ai](https://claude.ai)
2. Settings → Integrations → Model Context Protocol
3. Add Remote MCP Server: `http://localhost:8000`
4. Follow the OAuth flow (authenticate with Auth0)
5. Approve the consent screen
6. Start using the tools!

### Option B: Claude Desktop

Add to your config file:

**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "auth-demo": {
      "url": "http://localhost:8000",
      "transport": "sse"
    }
  }
}
```

Restart Claude Desktop.

## Step 5: Try the Tools (30 seconds)

In Claude, try these commands:

### Calculator Tools
- "Add 42 and 13"
- "Multiply 7 by 8"
- "Divide 100 by 4"

### Notes Tools
- "Create a note titled 'Meeting' with content 'Discuss Q4 goals'"
- "List all my notes"
- "Read note note_1"
- "Delete note note_1"

## What Just Happened?

1. **FastMCP's OIDC Proxy** acted as a bridge between Claude.ai and Auth0
2. **Dynamic Client Registration** was handled automatically by the proxy
3. **Auth0** authenticated you and issued an access token
4. **FastMCP** validated the token and protected the MCP tools
5. **Scopes** determined which tools you could access

## Architecture

```
Claude.ai → FastMCP (OIDC Proxy) → Auth0
              ↓
          MCP Tools
         (Protected)
```

The OIDC Proxy is built into FastMCP and handles:
- Dynamic Client Registration (DCR) proxying
- OAuth authorization flow
- Token validation via Auth0's JWKS
- Scope-based authorization

## Next Steps

- **Read [README.md](README.md)** for detailed documentation
- **Check [TESTING.md](TESTING.md)** for testing strategies  
- **Customize tools** in `src/server.py`
- **Add your own scopes** in `src/auth_config.py`
- **Deploy to production** with ngrok or a cloud provider

## Troubleshooting

### Server won't start?
- Check Python version: `python --version` (need 3.10+)
- Verify `.env` file exists with all required variables
- Reinstall dependencies: `pip install -r requirements.txt`

### Can't connect from Claude.ai?
- Ensure server is running
- For local testing, try ngrok: `ngrok http 8000`
- Update `RESOURCE_ID` and Auth0 redirect URI to match ngrok URL

### Authentication fails?
- Verify Auth0 credentials in `.env`
- Check redirect URI in Auth0 matches: `{RESOURCE_ID}/auth/callback`
- Ensure scopes are configured in Auth0 API

## Understanding the Code

The entire server is just 3 simple files:

### 1. `src/auth_config.py` - Auth0 Configuration
```python
from fastmcp.server.auth.providers.auth0 import Auth0Provider

def create_auth_provider():
    return Auth0Provider(
        config_url=f"https://{AUTH0_DOMAIN}/.well-known/openid-configuration",
        client_id=AUTH0_CLIENT_ID,
        client_secret=AUTH0_CLIENT_SECRET,
        audience=AUTH0_AUDIENCE,
        base_url=BASE_URL,
        required_scopes=SUPPORTED_SCOPES,
    )
```

### 2. `src/server.py` - MCP Tools
```python
from fastmcp import FastMCP

auth = create_auth_provider()
mcp = FastMCP("MCP Auth Demo", auth=auth)

@mcp.tool()
def add_numbers(a: float, b: float) -> float:
    """Add two numbers (requires authentication)"""
    return a + b
```

### 3. `src/main.py` - Start Server
```python
from src.server import mcp

mcp.run(transport="http", host="0.0.0.0", port=8000)
```

That's it! FastMCP handles everything else automatically.

## Why OIDC Proxy?

Auth0 (and many other providers) don't support Dynamic Client Registration (DCR) out of the box, which Claude.ai requires. FastMCP's OIDC Proxy solves this by:

1. **Accepting DCR requests** from Claude.ai
2. **Using your pre-registered credentials** with Auth0
3. **Proxying the OAuth flow** seamlessly
4. **Validating tokens** automatically

This means Claude.ai thinks it's talking to an OAuth server with DCR support, while Auth0 continues working normally!

---

🎉 **You're all set!** Your MCP server with OAuth authentication is ready to use with Claude.ai.

For more details, see:
- [README.md](README.md) - Full documentation
- [TESTING.md](TESTING.md) - Testing guide
- [FastMCP OIDC Proxy Docs](https://gofastmcp.com/servers/auth/oidc-proxy)

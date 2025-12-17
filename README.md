# MCP Server with OAuth Authentication via Auth0

A production-ready Model Context Protocol (MCP) server with OAuth 2.1 authentication using FastMCP's built-in OIDC Proxy and Auth0 as the identity provider.

## Features

- **FastMCP OIDC Proxy**: Built-in OAuth authentication via [FastMCP's OIDCProxy](https://gofastmcp.com/servers/auth/oidc-proxy)
- **Auth0 Integration**: Pre-configured Auth0 provider for seamless authentication
- **Dynamic Client Registration**: Proxies DCR for Auth0 to work with Claude.ai
- **Demo Tools**: Calculator and notes management tools for testing
- **HTTP/SSE Transport**: Built-in server with automatic routing and auth

## Architecture

FastMCP's OIDC Proxy acts as a bridge between Claude.ai and Auth0:

```
┌─────────────┐
│  Claude.ai  │
│   Client    │
└──────┬──────┘
       │
       │ 1. DCR Request
       ↓
┌──────────────────────────────────┐
│   FastMCP Server (OIDC Proxy)    │
│  - Proxies DCR                   │
│  - Handles OAuth flow            │
│  - Validates tokens              │
│  - Protects MCP tools            │
└──────────┬───────────────────────┘
           │
           │ 2. OAuth with Auth0
           ↓
┌──────────────────────────────────┐
│      Auth0 (IdP)                 │
│  - User authentication           │
│  - Token issuance                │
│  - OIDC discovery                │
└──────────────────────────────────┘
```

## Prerequisites

- Python 3.10 or higher
- Auth0 account (free tier works)
- Auth0 application configured with redirect URI

## Installation

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd mcp-auth-oidcO
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

Or with a virtual environment:

```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 3. Configure Auth0

#### Create an Auth0 Application

1. Log in to your [Auth0 Dashboard](https://manage.auth0.com/)
2. Navigate to **Applications** → **Create Application**
3. Choose **Regular Web Application**
4. Note your **Domain**, **Client ID**, and **Client Secret**

#### Configure Redirect URI

In your Auth0 application settings, add the callback URL:

**For local development:**
```
http://localhost:8000/auth/callback
```

**For production:**
```
https://your-domain.com/auth/callback
```

#### Create an API (for audience)

1. Navigate to **APIs** → **Create API**
2. Set an identifier (e.g., `https://dev-zilqiezmsk6ylig2.us.auth0.com/api/v2/`)
3. Add the following scopes:
   - `read:notes` - Read notes
   - `write:notes` - Create, update, delete notes
   - `use:calculator` - Use calculator tools

### 4. Configure Environment Variables

Create a `.env` file in the project root:

```env
# Auth0 Configuration
AUTH0_DOMAIN=your-domain.us.auth0.com
AUTH0_CLIENT_ID=your_client_id
AUTH0_CLIENT_SECRET=your_client_secret
AUTH0_AUDIENCE=https://your-domain.us.auth0.com/api/v2/

# Server Configuration
RESOURCE_ID=http://localhost:8000
SERVER_HOST=0.0.0.0
SERVER_PORT=8000
```

**Demo credentials** (pre-configured):
```env
AUTH0_DOMAIN=dev-zilqiezmsk6ylig2.us.auth0.com
AUTH0_CLIENT_ID=GsJfBMVGn5cDgWQwTiq91SIQBYxQccJA
AUTH0_CLIENT_SECRET=Qst5RVD9Vt79F5NgM_s6ymZSvMYemKrFMykWrDOtextPC2nBeK593yBvpJBafIDl
AUTH0_AUDIENCE=https://dev-zilqiezmsk6ylig2.us.auth0.com/api/v2/
RESOURCE_ID=http://localhost:8000
SERVER_HOST=0.0.0.0
SERVER_PORT=8000
```

## Running the Server

Start the server:

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

The server will start on `http://localhost:8000` with the following endpoints:
- **MCP/SSE**: `/mcp/sse` or `/sse` (authenticated)
- **Auth Callback**: `/auth/callback` (OAuth redirect)
- **Consent**: `/auth/consent` (user authorization)

## Available Tools

### Calculator Tools

All calculator tools require the `use:calculator` scope:

1. **add_numbers(a, b)** - Add two numbers
2. **subtract_numbers(a, b)** - Subtract b from a
3. **multiply_numbers(a, b)** - Multiply two numbers
4. **divide_numbers(a, b)** - Divide a by b

### Notes Tools

Notes tools require either `read:notes` or `write:notes` scope:

1. **create_note(title, content)** - Create a new note (requires `write:notes`)
2. **read_note(note_id)** - Read a specific note (requires `read:notes`)
3. **list_notes()** - List all notes (requires `read:notes`)
4. **update_note(note_id, title, content)** - Update a note (requires `write:notes`)
5. **delete_note(note_id)** - Delete a note (requires `write:notes`)

## Connecting to Claude.ai

### Method 1: Claude.ai Web Interface

1. Open [Claude.ai](https://claude.ai)
2. Go to Settings → Integrations → Model Context Protocol
3. Click "Add Remote MCP Server"
4. Enter your server URL: `http://localhost:8000`
5. Claude.ai will:
   - Perform Dynamic Client Registration (DCR) via the proxy
   - Redirect you to Auth0 for authentication
   - Request consent for the required scopes
   - Connect to your MCP server with a valid access token

### Method 2: Using ngrok for Remote Access

If Claude.ai needs to access your local server over the internet:

1. Install [ngrok](https://ngrok.com/)
2. Start ngrok:
   ```bash
   ngrok http 8000
   ```
3. Update your `.env` file with the ngrok URL:
   ```env
   RESOURCE_ID=https://your-ngrok-id.ngrok.io
   ```
4. Update Auth0 redirect URI to: `https://your-ngrok-id.ngrok.io/auth/callback`
5. Restart the server
6. Use the ngrok URL in Claude.ai: `https://your-ngrok-id.ngrok.io`

### Method 3: Claude Desktop App

For the Claude Desktop application, add to your MCP configuration:

**Location**: 
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`

**Configuration**:

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

## How It Works

### OAuth Flow with OIDC Proxy

1. **Client Registration**: Claude.ai sends a DCR request to FastMCP
2. **Proxy DCR**: FastMCP proxies the registration (Auth0 doesn't support DCR natively)
3. **Authorization**: User is redirected to Auth0 for authentication
4. **Consent**: User authorizes the scopes requested by Claude.ai
5. **Token Exchange**: FastMCP exchanges the authorization code for tokens
6. **Token Validation**: FastMCP validates tokens using Auth0's OIDC configuration
7. **Tool Access**: Authenticated requests can access protected MCP tools

### Key Benefits of OIDC Proxy

- **No Manual Registration**: Clients register dynamically
- **Automatic Token Validation**: JWT verification via Auth0's JWKS
- **Scope-Based Authorization**: Tools protected by OAuth scopes
- **Consent Flow**: Users see and approve what clients can access
- **Works with Any OIDC Provider**: Not just Auth0

## Project Structure

```
mcp-auth-oidcO/
├── src/
│   ├── __init__.py           # Package initialization
│   ├── auth_config.py        # Auth0Provider configuration
│   ├── server.py             # FastMCP server with demo tools
│   ├── app.py                # FastMCP app export
│   └── main.py               # Main entry point
├── .env                      # Environment variables (not in git)
├── .gitignore               # Git ignore rules
├── pyproject.toml           # Python project configuration
├── requirements.txt         # Python dependencies
├── run.py                   # Convenience script
├── README.md               # This file
├── QUICKSTART.md           # Quick start guide
└── TESTING.md              # Testing guide
```

## Development

### Code Structure

The server is built with three simple files:

1. **`auth_config.py`** - Configures Auth0Provider
2. **`server.py`** - Defines MCP tools with `@mcp.tool()` decorator
3. **`main.py`** - Starts the FastMCP HTTP server

That's it! FastMCP handles all the routing, authentication, and SSE automatically.

### Adding New Tools

To add new tools:

1. Open `src/server.py`
2. Add a new function with the `@mcp.tool()` decorator:

```python
@mcp.tool()
def my_new_tool(param: str) -> str:
    """
    Description of what the tool does.
    
    Args:
        param: Description
    
    Returns:
        Description of return value
    
    Requires:
        Scope: my:scope
    """
    return f"Result: {param}"
```

3. Add the scope to `src/auth_config.py`:

```python
SUPPORTED_SCOPES = [
    "read:notes",
    "write:notes",
    "use:calculator",
    "my:scope",  # Add your new scope
]
```

4. Configure the scope in Auth0

## Testing

See [TESTING.md](TESTING.md) for comprehensive testing instructions.

### Quick Test

Start the server and verify it's running:

```bash
# Start server
python run.py

# In another terminal, check health (if you add a health endpoint)
curl http://localhost:8000/
```

## Troubleshooting

### Server Won't Start

- Check Python version: `python --version` (need 3.10+)
- Verify all environment variables are set in `.env`
- Ensure dependencies are installed: `pip install -r requirements.txt`

### Authentication Fails

- Verify Auth0 credentials in `.env` are correct
- Check that redirect URI in Auth0 matches `{BASE_URL}/auth/callback`
- Ensure scopes are configured in Auth0 API

### Claude.ai Can't Connect

- Verify the server is running and accessible
- Check that the base URL is correct
- For local testing, ensure Claude.ai can reach localhost (try ngrok)
- Review server logs for authentication errors

## Security Considerations

### For Production Deployment

1. **HTTPS Only**: Always use HTTPS in production
2. **Environment Variables**: Never commit `.env` to version control
3. **Secure Secrets**: Use a secrets manager (AWS Secrets Manager, Azure Key Vault, etc.)
4. **Token Storage**: Configure encrypted storage backend (Redis with encryption)
5. **JWT Signing Key**: Set explicit `jwt_signing_key` in production
6. **Rate Limiting**: Add rate limiting middleware
7. **Logging**: Implement comprehensive audit logs
8. **CORS**: Configure specific origins (not `*`)

### Production Configuration

```python
from fastmcp.server.auth.providers.auth0 import Auth0Provider
from key_value.aio.stores.redis import RedisStore
from key_value.aio.wrappers.encryption import FernetEncryptionWrapper
from cryptography.fernet import Fernet
import os

auth = Auth0Provider(
    config_url=f"https://{os.environ['AUTH0_DOMAIN']}/.well-known/openid-configuration",
    client_id=os.environ['AUTH0_CLIENT_ID'],
    client_secret=os.environ['AUTH0_CLIENT_SECRET'],
    audience=os.environ['AUTH0_AUDIENCE'],
    base_url=os.environ['BASE_URL'],
    required_scopes=SUPPORTED_SCOPES,
    jwt_signing_key=os.environ['JWT_SIGNING_KEY'],
    client_storage=FernetEncryptionWrapper(
        key_value=RedisStore(host="redis.example.com", port=6379),
        fernet=Fernet(os.environ['STORAGE_ENCRYPTION_KEY'])
    )
)
```

## References

- [FastMCP Documentation](https://gofastmcp.com/)
- [FastMCP OIDC Proxy Guide](https://gofastmcp.com/servers/auth/oidc-proxy)
- [Model Context Protocol Specification](https://spec.modelcontextprotocol.io/)
- [OAuth 2.1 Draft](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-1)
- [Auth0 Documentation](https://auth0.com/docs)

## License

MIT License - feel free to use this as a template for your own MCP servers.

## Support

For issues and questions:
- FastMCP: [GitHub Issues](https://github.com/jlowin/fastmcp/issues) | [Discord](https://discord.gg/prefect)
- Auth0: [Community Forum](https://community.auth0.com/)

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

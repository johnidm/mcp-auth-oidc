# Migration from mcpauth to FastMCP OIDC Proxy

## Summary

Successfully migrated from the `mcpauth` library to FastMCP's built-in OIDC Proxy for a much simpler and more maintainable implementation.

## Key Changes

### 1. Dependencies Simplified

**Before:**
```
fastmcp
mcpauth
starlette
uvicorn[standard]
python-dotenv
```

**After:**
```
fastmcp
uvicorn[standard]
python-dotenv
```

Removed `mcpauth` and `starlette` - FastMCP handles everything internally!

### 2. Architecture Simplified

**Before:** Complex multi-layer stack
- Manual Starlette app setup
- Custom Bearer auth middleware
- Manual protected resource metadata routing
- Separate auth context management

**After:** Single FastMCP instance
- FastMCP's built-in HTTP server
- OIDC Proxy handles all auth automatically
- No manual routing needed
- Auth integrated into FastMCP

### 3. Code Reduction

**Before (auth_config.py):** ~76 lines
- Fetch Auth0 server config
- Configure ResourceServerConfig
- Initialize MCPAuth
- Manage global instance

**After (auth_config.py):** ~35 lines
- Simple Auth0Provider configuration
- All complexity handled by FastMCP

**Before (app.py):** ~103 lines
- Create Starlette app
- Mount metadata router
- Configure bearer auth middleware
- Apply CORS middleware
- Custom route handlers

**After (app.py):** ~11 lines
- Just export the FastMCP instance
- Everything handled automatically

**Before (server.py):** Manual auth context access
```python
auth_info = mcp_auth.auth_info
if auth_info:
    user_id = auth_info.claims.get('sub', 'unknown')
    print(f"[AUTH] Tool used by: {user_id}")
```

**After (server.py):** Clean tool definitions
```python
@mcp.tool()
def add_numbers(a: float, b: float) -> float:
    """Add two numbers"""
    return a + b
```

Auth is handled automatically by FastMCP!

### 4. Configuration Changes

**Environment Variables - Same:**
- `AUTH0_DOMAIN`
- `AUTH0_CLIENT_ID`
- `AUTH0_CLIENT_SECRET`
- `AUTH0_AUDIENCE`
- `RESOURCE_ID` (BASE_URL)

**New Understanding:**
- Redirect URI is now: `{RESOURCE_ID}/auth/callback`
- This must be configured in Auth0 application settings

## Benefits of OIDC Proxy

### 1. Simpler Code
- 60% less code overall
- No manual middleware setup
- No custom routing needed

### 2. Built-in Features
- Automatic DCR proxying
- Token validation via JWKS
- Consent flow UI
- Client storage (with encryption)
- JWT signing key management

### 3. Better Developer Experience
- One line to add auth: `mcp = FastMCP("name", auth=auth)`
- Tools automatically protected
- No manual auth context management

### 4. Production Ready
- Encrypted storage backends supported
- Keyring integration on Mac/Windows
- Custom JWT signing keys
- Redis/database storage options

## Migration Steps Completed

1. ✅ Removed `mcpauth` dependency
2. ✅ Removed `starlette` dependency
3. ✅ Replaced MCPAuth with Auth0Provider
4. ✅ Simplified auth_config.py
5. ✅ Simplified server.py (removed manual auth context)
6. ✅ Simplified app.py (just exports FastMCP)
7. ✅ Updated main.py to use `mcp.run()`
8. ✅ Updated documentation
9. ✅ Updated QUICKSTART guide

## How It Works Now

### 1. Auth Configuration (auth_config.py)
```python
from fastmcp.server.auth.providers.auth0 import Auth0Provider

auth = Auth0Provider(
    config_url="https://domain/.well-known/openid-configuration",
    client_id="...",
    client_secret="...",
    audience="...",
    base_url="http://localhost:8000",
    required_scopes=["read:notes", "write:notes", "use:calculator"],
)
```

### 2. Server Definition (server.py)
```python
from fastmcp import FastMCP

mcp = FastMCP("MCP Auth Demo", auth=auth)

@mcp.tool()
def add_numbers(a: float, b: float) -> float:
    return a + b
```

### 3. Start Server (main.py)
```python
from src.server import mcp

mcp.run(transport="http", host="0.0.0.0", port=8000)
```

That's it! FastMCP handles:
- HTTP server setup
- OAuth endpoints (/auth/callback, /auth/consent)
- MCP/SSE endpoints
- Token validation
- Scope enforcement

## Testing the Migration

### 1. Start Server
```bash
python run.py
```

### 2. Verify Auth Endpoints

The following endpoints are automatically available:

- **MCP/SSE**: `http://localhost:8000/sse` or `/mcp/sse`
- **OAuth Callback**: `http://localhost:8000/auth/callback`
- **Consent Screen**: `http://localhost:8000/auth/consent`

### 3. Connect from Claude.ai

1. Add server: `http://localhost:8000`
2. Claude performs DCR → FastMCP proxies to Auth0
3. Auth flow → User authenticates with Auth0
4. Consent → User approves scopes
5. Connected → Tools are now accessible

## Auth0 Configuration Required

Ensure your Auth0 application has:

1. **Application Type**: Regular Web Application
2. **Redirect URI**: `http://localhost:8000/auth/callback`
3. **API with Scopes**: 
   - `read:notes`
   - `write:notes`
   - `use:calculator`

## Production Considerations

For production deployment, add:

```python
import os
from key_value.aio.stores.redis import RedisStore
from key_value.aio.wrappers.encryption import FernetEncryptionWrapper
from cryptography.fernet import Fernet

auth = Auth0Provider(
    ...,
    jwt_signing_key=os.environ['JWT_SIGNING_KEY'],
    client_storage=FernetEncryptionWrapper(
        key_value=RedisStore(host="redis", port=6379),
        fernet=Fernet(os.environ['STORAGE_ENCRYPTION_KEY'])
    ),
)
```

## References

- [FastMCP OIDC Proxy Documentation](https://gofastmcp.com/servers/auth/oidc-proxy)
- [FastMCP Auth Overview](https://gofastmcp.com/servers/authentication)
- [MCP Protocol Specification](https://spec.modelcontextprotocol.io/)

---

**Migration completed successfully!** The server is now much simpler and uses FastMCP's recommended authentication approach.


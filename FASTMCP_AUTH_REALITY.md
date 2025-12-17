# 🔍 FastMCP Authentication: The Reality

## ⚠️ Important Discovery

After testing, we discovered that **FastMCP only provides one high-level authentication provider**: `Auth0Provider`.

For **all other OIDC providers** (Keycloak, Okta, Azure AD, etc.), you must use the lower-level:
- `JWTVerifier` (for token validation)
- `RemoteAuthProvider` (for remote auth setup)

## 📦 What FastMCP Actually Provides

### Available in FastMCP

```python
# ✅ High-level provider (Auth0 ONLY)
from fastmcp.server.auth.providers.auth0 import Auth0Provider

# ✅ Low-level JWT verification (for any OIDC provider)
from fastmcp.server.auth.providers.jwt import JWTVerifier
from fastmcp.server.auth import RemoteAuthProvider
```

### NOT Available in FastMCP

```python
# ❌ These don't exist!
from fastmcp.server.auth.providers.keycloak import KeycloakAuthProvider  # ❌
from fastmcp.server.auth.providers.oidc import OIDCProvider  # ❌
from fastmcp.server.auth.providers.okta import OktaProvider  # ❌
```

## 🎯 The Two Approaches

### Approach 1: Auth0 (High-Level)

**If using Auth0**, you get a nice high-level provider:

```python
from fastmcp.server.auth.providers.auth0 import Auth0Provider

auth = Auth0Provider(
    config_url=f"https://{domain}/.well-known/openid-configuration",
    client_id=client_id,
    client_secret=client_secret,
    audience=audience,
    base_url=base_url,
    required_scopes=scopes,
)
```

**What you get:**
- ✅ Automatic OIDC discovery
- ✅ Token validation via JWKS
- ✅ DCR (Dynamic Client Registration) proxy
- ✅ OAuth flow handling
- ✅ Scope management

### Approach 2: Keycloak/Others (Low-Level)

**If using Keycloak or any other OIDC provider**, you must build it manually:

```python
from fastmcp.server.auth.providers.jwt import JWTVerifier
from fastmcp.server.auth import RemoteAuthProvider

# Build JWKS URI and issuer manually
issuer = f"{keycloak_url}/realms/{realm}"
jwks_uri = f"{issuer}/protocol/openid-connect/certs"

# Create JWT verifier
verifier = JWTVerifier(
    jwks_uri=jwks_uri,
    issuer=issuer,
    audience=audience,
    algorithm="RS256",
    required_scopes=scopes,
)

# Create auth provider
auth = RemoteAuthProvider(
    token_verifier=verifier,
    authorization_servers=[base_url],
    base_url=base_url,
)
```

**What you get:**
- ✅ Token validation via JWKS
- ✅ Signature verification
- ✅ Issuer/audience checks
- ✅ Scope validation

**What you DON'T get:**
- ❌ Automatic OIDC discovery
- ❌ OAuth authorization flow
- ❌ Token exchange
- ❌ DCR handling

## 🔄 Trade-offs

| Feature | Auth0Provider | JWTVerifier + RemoteAuthProvider |
|---------|---------------|----------------------------------|
| **OIDC Discovery** | ✅ Automatic | ❌ Manual configuration |
| **Token Validation** | ✅ Yes | ✅ Yes |
| **OAuth Flow** | ✅ Handled | ⚠️ Must implement separately |
| **DCR Support** | ✅ Built-in | ❌ Not included |
| **Ease of Use** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Works with** | Auth0 only | Any OIDC provider |

## 💡 Understanding the Limitations

### What JWTVerifier Does

`JWTVerifier` is **only** for validating tokens:

```
Client → Gets token somehow → Sends to your server → JWTVerifier validates it
```

It does **NOT**:
- Redirect users to login
- Handle authorization codes
- Exchange codes for tokens
- Manage refresh tokens

### How to Use with Keycloak

**Option A: Client-side OAuth flow**
1. Your client (Claude.ai, MCP Inspector) handles OAuth
2. Client gets token from Keycloak
3. Client sends token to your MCP server
4. Your server validates with `JWTVerifier`

**Option B: Implement authorization endpoints**
1. Add OAuth endpoints to your server (e.g., using `authlib`)
2. Handle redirect to Keycloak
3. Exchange authorization code for tokens
4. Use `JWTVerifier` for subsequent requests

**For MCP Inspector / Claude.ai:**
- These tools can handle OAuth flow themselves
- They just need your Keycloak OIDC endpoints
- Your server validates the tokens they send

## ✅ Working Configuration

Here's the complete working `keycloak_auth_config.py`:

```python
"""Keycloak configuration using FastMCP's JWT verification."""

import os
from fastmcp.server.auth.providers.jwt import JWTVerifier
from fastmcp.server.auth import RemoteAuthProvider

# Keycloak configuration
KEYCLOAK_REALM = os.getenv("KEYCLOAK_REALM", "mcp-demo")
KEYCLOAK_BASE_URL = os.getenv("KEYCLOAK_BASE_URL", "http://localhost:8080")
KEYCLOAK_CLIENT_ID = os.getenv("KEYCLOAK_CLIENT_ID")
KEYCLOAK_AUDIENCE = os.getenv("KEYCLOAK_AUDIENCE", "mcp-server")
BASE_URL = os.getenv("RESOURCE_ID", "http://localhost:8000")

# Construct endpoints
KEYCLOAK_ISSUER = f"{KEYCLOAK_BASE_URL}/realms/{KEYCLOAK_REALM}"
KEYCLOAK_JWKS_URI = f"{KEYCLOAK_ISSUER}/protocol/openid-connect/certs"

# Scopes
SUPPORTED_SCOPES = ["read:notes", "write:notes", "use:calculator"]


def create_auth_provider() -> RemoteAuthProvider:
    """Create Keycloak auth provider."""
    
    # Validate config
    if not KEYCLOAK_CLIENT_ID:
        raise ValueError("KEYCLOAK_CLIENT_ID required")
    
    # Create JWT verifier
    verifier = JWTVerifier(
        jwks_uri=KEYCLOAK_JWKS_URI,
        issuer=KEYCLOAK_ISSUER,
        audience=KEYCLOAK_AUDIENCE,
        algorithm="RS256",
        required_scopes=SUPPORTED_SCOPES,
    )
    
    # Create auth provider
    auth = RemoteAuthProvider(
        token_verifier=verifier,
        authorization_servers=[BASE_URL],
        base_url=BASE_URL,
    )
    
    return auth
```

## 🧪 Testing

### Start the server:

```bash
python run.py
```

You should see:
```
🔐 Configuring Keycloak authentication:
   Issuer: http://localhost:8080/realms/mcp-demo
   JWKS URI: http://localhost:8080/realms/mcp-demo/protocol/openid-connect/certs
   Audience: mcp-server
   Scopes: read:notes, write:notes, use:calculator

Starting server with FastMCP's built-in HTTP/SSE transport...
```

### Test token validation:

```bash
# 1. Get a token from Keycloak
TOKEN=$(curl -s -X POST 'http://localhost:8080/realms/mcp-demo/protocol/openid-connect/token' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'grant_type=password' \
  -d 'client_id=mcp-server' \
  -d 'client_secret=YOUR_SECRET' \
  -d 'username=testuser' \
  -d 'password=testpassword' \
  -d 'scope=read:notes write:notes use:calculator' | jq -r '.access_token')

# 2. Use it with your MCP server
curl -X POST 'http://localhost:8000/mcp' \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/list",
    "id": 1
  }' | jq
```

## 🎓 Key Lessons

1. **FastMCP is Auth0-centric** - Only Auth0 gets a high-level provider
2. **Other providers need manual setup** - Use `JWTVerifier` + `RemoteAuthProvider`
3. **Token validation works great** - The low-level approach validates tokens perfectly
4. **OAuth flow is separate** - Your client handles OAuth, server validates tokens
5. **MCP Inspector works** - It can handle Keycloak OAuth flow on its own

## 📝 Summary

| If you're using... | Then use... | What you get |
|-------------------|-------------|--------------|
| **Auth0** | `Auth0Provider` | Full OAuth + validation |
| **Keycloak** | `JWTVerifier` + `RemoteAuthProvider` | Token validation only |
| **Okta** | `JWTVerifier` + `RemoteAuthProvider` | Token validation only |
| **Azure AD** | `JWTVerifier` + `RemoteAuthProvider` | Token validation only |
| **Any OIDC** | `JWTVerifier` + `RemoteAuthProvider` | Token validation only |

---

**Bottom Line:** FastMCP's Keycloak support requires more manual configuration than Auth0, but it works reliably for token validation, which is what you need for an MCP server! ✅


# 📝 Important: FastMCP Authentication Providers

## ⚠️ Key Finding

FastMCP **only provides `Auth0Provider`** as a high-level authentication provider. For other OIDC providers like Keycloak, you must use the **lower-level approach** with `JWTVerifier` + `RemoteAuthProvider`.

## ✅ Correct Configuration for Keycloak

### Correct Imports

```python
from fastmcp.server.auth.providers.jwt import JWTVerifier
from fastmcp.server.auth import RemoteAuthProvider
```

### Why This Approach?

FastMCP's architecture:
- ✅ `Auth0Provider` - High-level provider **only for Auth0**
- ✅ `JWTVerifier` + `RemoteAuthProvider` - Low-level approach for **any other OIDC provider**

Since Keycloak is OIDC-compliant but not Auth0, we use JWT verification.

## 🚫 Common Mistakes

### ❌ Wrong: Non-existent providers

```python
# These don't exist in FastMCP!
from fastmcp.server.auth.providers.keycloak import KeycloakAuthProvider  # ❌
from fastmcp.server.auth.providers.oidc import OIDCProvider  # ❌
```

**Errors:**
```
ModuleNotFoundError: No module named 'fastmcp.server.auth.providers.keycloak'
ModuleNotFoundError: No module named 'fastmcp.server.auth.providers.oidc'
```

### ✅ Correct: Using JWTVerifier + RemoteAuthProvider

```python
# This works - available in FastMCP
from fastmcp.server.auth.providers.jwt import JWTVerifier
from fastmcp.server.auth import RemoteAuthProvider
```

## 📖 Complete Working Example

Here's the complete `keycloak_auth_config.py`:

```python
"""Keycloak configuration using FastMCP's JWT verification."""

import os
from fastmcp.server.auth.providers.jwt import JWTVerifier
from fastmcp.server.auth import RemoteAuthProvider


# Keycloak configuration from environment variables
KEYCLOAK_REALM = os.getenv("KEYCLOAK_REALM", "mcp-demo")
KEYCLOAK_BASE_URL = os.getenv("KEYCLOAK_BASE_URL", "http://localhost:8080")
KEYCLOAK_CLIENT_ID = os.getenv("KEYCLOAK_CLIENT_ID")
KEYCLOAK_CLIENT_SECRET = os.getenv("KEYCLOAK_CLIENT_SECRET")
KEYCLOAK_AUDIENCE = os.getenv("KEYCLOAK_AUDIENCE", "mcp-server")
BASE_URL = os.getenv("RESOURCE_ID", "http://localhost:8000")

# Keycloak OIDC endpoints
KEYCLOAK_ISSUER = f"{KEYCLOAK_BASE_URL}/realms/{KEYCLOAK_REALM}"
KEYCLOAK_JWKS_URI = f"{KEYCLOAK_ISSUER}/protocol/openid-connect/certs"

# Define supported scopes for this MCP server
SUPPORTED_SCOPES = [
    "read:notes",
    "write:notes",
    "use:calculator",
]


def create_auth_provider() -> RemoteAuthProvider:
    """
    Create Keycloak authentication provider using FastMCP's JWT verification.
    
    Returns:
        RemoteAuthProvider: Configured authentication provider for Keycloak
    """
    if not KEYCLOAK_CLIENT_ID:
        raise ValueError(
            "Missing required Keycloak configuration. "
            "Please set KEYCLOAK_CLIENT_ID in .env"
        )
    
    # Create JWT verifier for Keycloak tokens
    verifier = JWTVerifier(
        jwks_uri=KEYCLOAK_JWKS_URI,
        issuer=KEYCLOAK_ISSUER,
        audience=KEYCLOAK_AUDIENCE,
        algorithm="RS256",  # Keycloak uses RS256 by default
        required_scopes=SUPPORTED_SCOPES,
    )
    
    # Create remote auth provider with the JWT verifier
    auth = RemoteAuthProvider(
        token_verifier=verifier,
        authorization_servers=[BASE_URL],
        base_url=BASE_URL,
    )
    
    return auth
```

## 🔍 What FastMCP Actually Provides

FastMCP includes these authentication components:

1. **`Auth0Provider`** - High-level provider ONLY for Auth0
   - Includes DCR proxy
   - Handles OIDC discovery
   - Manages OAuth flows automatically

2. **`JWTVerifier`** + **`RemoteAuthProvider`** - For all other OIDC providers
   - Manual configuration required
   - You specify JWKS URI, issuer, audience
   - Token validation only (no DCR, no OAuth flow management)

## 📚 Provider Comparison

| Approach | Use For | Complexity | What You Get |
|----------|---------|------------|--------------|
| `Auth0Provider` | Auth0 only | Low | Full OAuth + DCR + validation |
| `JWTVerifier` + `RemoteAuthProvider` | Keycloak, Okta, others | Medium | Token validation only |

## 🎯 Reality Check

**For Keycloak**, you **must** use `JWTVerifier` + `RemoteAuthProvider` because:
- ✅ It's the only option available in FastMCP
- ✅ Provides token validation via JWKS
- ✅ Validates issuer, audience, scopes
- ⚠️ **Does NOT handle**: OAuth authorization flow, token exchange, DCR

## 🔧 What You Need to Handle Manually

When using `JWTVerifier` + `RemoteAuthProvider`:

### ✅ FastMCP Handles:
- Token validation using JWKS
- Signature verification (RS256)
- Issuer and audience checks
- Scope validation

### ❌ You Must Handle (or use external OAuth client):
- Authorization flow (redirect to Keycloak login)
- Token exchange (authorization code → access token)
- Refresh token management
- Dynamic Client Registration (if needed)

**Note:** For full OAuth flow integration, you may need to implement authorization endpoints separately or use an OAuth client library alongside FastMCP.

## ✅ Verification

Your configuration is correct if:
1. ✅ Imports use `JWTVerifier` from `fastmcp.server.auth.providers.jwt`
2. ✅ Imports use `RemoteAuthProvider` from `fastmcp.server.auth`
3. ✅ `jwks_uri` points to Keycloak's JWKS endpoint
4. ✅ `issuer` matches your Keycloak realm URL
5. ✅ All environment variables are set
6. ✅ Server starts without `ModuleNotFoundError`

## 🚀 Quick Test

```bash
# 1. Verify config
cat src/keycloak_auth_config.py | grep "from fastmcp"
# Should show:
# from fastmcp.server.auth.providers.jwt import JWTVerifier
# from fastmcp.server.auth import RemoteAuthProvider

# 2. Test server start
python run.py
# Should start without errors

# 3. Test JWKS endpoint
curl http://localhost:8080/realms/mcp-demo/protocol/openid-connect/certs | jq

# 4. Get a test token
curl -X POST 'http://localhost:8080/realms/mcp-demo/protocol/openid-connect/token' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'grant_type=password' \
  -d 'client_id=mcp-server' \
  -d 'client_secret=YOUR_SECRET' \
  -d 'username=testuser' \
  -d 'password=testpassword' \
  -d 'scope=read:notes write:notes use:calculator' | jq
```

## 📞 Need Help?

- 📖 Check: [KEYCLOAK_MIGRATION_GUIDE.md](KEYCLOAK_MIGRATION_GUIDE.md)
- 🔍 Test: Run `./test-keycloak.sh`
- 💬 Issue: Open GitHub issue with error details

## 🎓 Key Takeaways

1. **FastMCP Reality**: Only `Auth0Provider` exists as a high-level provider
2. **For Keycloak**: Use `JWTVerifier` + `RemoteAuthProvider` 
3. **Token Validation**: FastMCP handles JWT verification automatically
4. **OAuth Flow**: You may need to handle authorization flow separately
5. **Works Great**: Despite being lower-level, it's production-ready

---

**Summary:** For Keycloak with FastMCP, use `JWTVerifier` + `RemoteAuthProvider`. It's the only option, and it works great for token validation! ✅


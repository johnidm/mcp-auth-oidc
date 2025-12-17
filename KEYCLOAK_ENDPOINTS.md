# 🔗 Keycloak Endpoint Reference

## Standard Keycloak OIDC Endpoints

For realm `mcp-demo` on `http://localhost:8080`:

### Base URLs
```
Realm URL:    http://localhost:8080/realms/mcp-demo
OIDC Base:    http://localhost:8080/realms/mcp-demo/protocol/openid-connect
```

### Discovery Endpoints

**OIDC Discovery (Recommended)**
```
http://localhost:8080/realms/mcp-demo/.well-known/openid-configuration
```

**OAuth Authorization Server Metadata**
```
http://localhost:8080/realms/mcp-demo/.well-known/oauth-authorization-server
```

### JWKS Endpoints

Keycloak provides JWKS at **two locations**:

**Option 1: Protocol endpoint (Standard)**
```
http://localhost:8080/realms/mcp-demo/protocol/openid-connect/certs
```
✅ This is the **standard** Keycloak JWKS endpoint
✅ Returned in OIDC discovery as `jwks_uri`
✅ Most commonly used

**Option 2: Well-known endpoint (Also works)**
```
http://localhost:8080/realms/mcp-demo/.well-known/jwks.json
```
✅ Also valid
⚠️ Not always documented
⚠️ May not be in OIDC discovery

### OAuth Endpoints

**Authorization Endpoint**
```
http://localhost:8080/realms/mcp-demo/protocol/openid-connect/auth
```

**Token Endpoint**
```
http://localhost:8080/realms/mcp-demo/protocol/openid-connect/token
```

**Userinfo Endpoint**
```
http://localhost:8080/realms/mcp-demo/protocol/openid-connect/userinfo
```

**Logout Endpoint**
```
http://localhost:8080/realms/mcp-demo/protocol/openid-connect/logout
```

**Token Introspection**
```
http://localhost:8080/realms/mcp-demo/protocol/openid-connect/token/introspect
```

**Token Revocation**
```
http://localhost:8080/realms/mcp-demo/protocol/openid-connect/revoke
```

## Testing Endpoints

### Test OIDC Discovery
```bash
curl http://localhost:8080/realms/mcp-demo/.well-known/openid-configuration | jq
```

Look for:
```json
{
  "issuer": "http://localhost:8080/realms/mcp-demo",
  "authorization_endpoint": "http://localhost:8080/realms/mcp-demo/protocol/openid-connect/auth",
  "token_endpoint": "http://localhost:8080/realms/mcp-demo/protocol/openid-connect/token",
  "jwks_uri": "http://localhost:8080/realms/mcp-demo/protocol/openid-connect/certs",
  ...
}
```

### Test JWKS Endpoint (Option 1 - Standard)
```bash
curl http://localhost:8080/realms/mcp-demo/protocol/openid-connect/certs | jq
```

Expected response:
```json
{
  "keys": [
    {
      "kid": "...",
      "kty": "RSA",
      "alg": "RS256",
      "use": "sig",
      "n": "...",
      "e": "AQAB",
      ...
    }
  ]
}
```

### Test JWKS Endpoint (Option 2 - Well-known)
```bash
curl http://localhost:8080/realms/mcp-demo/.well-known/jwks.json | jq
```

Should return same format as above.

### Get Access Token
```bash
curl -X POST 'http://localhost:8080/realms/mcp-demo/protocol/openid-connect/token' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'grant_type=password' \
  -d 'client_id=mcp-server' \
  -d 'client_secret=YOUR_SECRET' \
  -d 'username=testuser' \
  -d 'password=testpassword' \
  -d 'scope=openid read:notes write:notes use:calculator' | jq
```

## Recommended Configuration

### For `keycloak_auth_config.py`

**Recommended (Standard):**
```python
KEYCLOAK_ISSUER = f"{KEYCLOAK_BASE_URL}/realms/{KEYCLOAK_REALM}"
KEYCLOAK_JWKS_URI = f"{KEYCLOAK_ISSUER}/protocol/openid-connect/certs"
```

**Alternative (Also works):**
```python
KEYCLOAK_ISSUER = f"{KEYCLOAK_BASE_URL}/realms/{KEYCLOAK_REALM}"
KEYCLOAK_JWKS_URI = f"{KEYCLOAK_ISSUER}/.well-known/jwks.json"
```

Both work! Use the first one (standard) unless you have a specific reason to use the alternative.

## Port Reference

| Service | Default Port | URL |
|---------|--------------|-----|
| Keycloak | 8080 | http://localhost:8080 |
| MCP Server | 8000 | http://localhost:8000 |
| MCP Inspector | 6274 | http://localhost:6274 |
| PostgreSQL (prod) | 5432 | postgresql://localhost:5432 |

## Environment Variables

```env
# Keycloak Base
KEYCLOAK_BASE_URL=http://localhost:8080
KEYCLOAK_REALM=mcp-demo

# Derived URLs (don't need to set these)
# OIDC Discovery: {BASE_URL}/realms/{REALM}/.well-known/openid-configuration
# JWKS: {BASE_URL}/realms/{REALM}/protocol/openid-connect/certs
# Auth: {BASE_URL}/realms/{REALM}/protocol/openid-connect/auth
# Token: {BASE_URL}/realms/{REALM}/protocol/openid-connect/token
```

## Quick Reference for MCP Inspector

When configuring MCP Inspector for Keycloak:

```
Authorization Endpoint:
http://localhost:8080/realms/mcp-demo/protocol/openid-connect/auth

Token Endpoint:
http://localhost:8080/realms/mcp-demo/protocol/openid-connect/token

OIDC Discovery:
http://localhost:8080/realms/mcp-demo/.well-known/openid-configuration

Client ID: mcp-server
Scopes: openid profile email read:notes write:notes use:calculator
Redirect URI: http://localhost:6274/oauth/callback
```

## Troubleshooting

### Check if Keycloak is running
```bash
curl http://localhost:8080/health/ready
```

### Get all OIDC endpoints
```bash
curl http://localhost:8080/realms/mcp-demo/.well-known/openid-configuration | jq '
{
  issuer,
  authorization_endpoint,
  token_endpoint,
  jwks_uri,
  userinfo_endpoint
}'
```

### Verify JWKS works
```bash
# Test standard endpoint
curl -s http://localhost:8080/realms/mcp-demo/protocol/openid-connect/certs | jq '.keys | length'

# Test well-known endpoint
curl -s http://localhost:8080/realms/mcp-demo/.well-known/jwks.json | jq '.keys | length'

# Both should return the same number (typically 1 or 2)
```

---

**Bottom Line:** Both JWKS endpoints work, but `/protocol/openid-connect/certs` is the standard one returned in OIDC discovery. ✅


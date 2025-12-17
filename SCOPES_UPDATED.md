# ✅ OAuth Scopes Updated

## 🎯 New Scopes Configuration

Your MCP server now requires these OAuth scopes:

```
openid profile email claudeai read:notes write:notes use:calculator
```

## 📋 Scope Breakdown

| Scope | Type | Purpose |
|-------|------|---------|
| `openid` | Standard OIDC | Required for OpenID Connect authentication |
| `profile` | Standard OIDC | Access to user profile information (name, etc.) |
| `email` | Standard OIDC | Access to user email address |
| `claudeai` | Custom | Custom scope for Claude AI integration |
| `read:notes` | Custom | Permission to read notes |
| `write:notes` | Custom | Permission to create/update/delete notes |
| `use:calculator` | Custom | Permission to use calculator tools |

## ✅ Files Updated

1. **`src/keycloak_auth_config.py`** - Main Keycloak configuration
2. **`src/keycloak_auth_config_no_audience.py`** - Testing configuration
3. **`debug-token.sh`** - Token debugging script
4. **`fix-audience.sh`** - Audience fix script

## 🔧 What Changed

### Before:
```python
SUPPORTED_SCOPES = [
    "read:notes",
    "write:notes",
    "use:calculator",
]
```

### After:
```python
SUPPORTED_SCOPES = [
    "openid",           # Standard OIDC scope
    "profile",          # Standard OIDC scope for user profile
    "email",            # Standard OIDC scope for email
    "claudeai",         # Custom scope for Claude AI
    "read:notes",       # Custom scope for reading notes
    "write:notes",      # Custom scope for writing notes
    "use:calculator",   # Custom scope for calculator
]
```

## 🚀 Testing

### Get Token with New Scopes

```bash
TOKEN=$(curl -s -X POST \
  'http://localhost:8080/realms/mcp-demo/protocol/openid-connect/token' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'grant_type=password' \
  -d 'client_id=mcp-server' \
  -d 'client_secret=YOUR_SECRET' \
  -d 'username=testuser' \
  -d 'password=testpassword' \
  -d 'scope=openid profile email claudeai read:notes write:notes use:calculator' | jq -r '.access_token')
```

### Verify Scopes in Token

```bash
# Decode token and check scopes
echo $TOKEN | cut -d'.' -f2 | base64 -d | jq '.scope'
```

Should return:
```
"openid profile email claudeai read:notes write:notes use:calculator"
```

### Test with MCP Server

```bash
curl -X POST 'http://localhost:8000/mcp' \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' | jq
```

## 📝 Keycloak Configuration

### Adding Custom Scopes in Keycloak

If Keycloak doesn't recognize the `claudeai` scope, you need to create it:

#### Option 1: Using Keycloak Admin UI

1. Go to http://localhost:8080
2. Login as `admin`
3. Select your realm (e.g., `mcp-demo`)
4. Go to **Client scopes** → **Create client scope**
5. Name: `claudeai`
6. Type: `Optional`
7. Protocol: `openid-connect`
8. Click **Save**
9. Go to **Clients** → Your client (e.g., `mcp-server`)
10. Click **Client scopes** tab
11. Click **Add client scope**
12. Select `claudeai`
13. Add as **Optional** or **Default**

#### Option 2: Using Script

```bash
#!/bin/bash

KEYCLOAK_URL="http://localhost:8080"
ADMIN_TOKEN="<your-admin-token>"
REALM="mcp-demo"

# Create claudeai scope
curl -X POST "$KEYCLOAK_URL/admin/realms/$REALM/client-scopes" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "claudeai",
    "description": "Custom scope for Claude AI integration",
    "protocol": "openid-connect",
    "attributes": {
      "include.in.token.scope": "true",
      "display.on.consent.screen": "true"
    }
  }'
```

## 🔍 Debugging

### Test Scopes with Debug Script

```bash
./debug-token.sh
```

This will:
1. Get a token with all the new scopes
2. Decode and display the scopes
3. Test the token with your MCP server
4. Show any scope-related issues

### Common Issues

#### Issue 1: Scope Not Recognized

**Error:** `invalid_scope: Unknown scope: claudeai`

**Fix:** Create the `claudeai` scope in Keycloak (see above)

#### Issue 2: Token Missing Scopes

**Error:** Token doesn't include all requested scopes

**Fix:** 
1. Check client configuration in Keycloak
2. Ensure scopes are enabled for the client
3. Request scopes explicitly in token request

#### Issue 3: Server Rejects Token

**Error:** `401 Unauthorized: insufficient_scope`

**Fix:**
1. Restart your MCP server to pick up new scope configuration
2. Get a new token with all required scopes
3. Verify server logs show the new scopes

## 📊 Scope Validation

The server will now validate that tokens include these scopes. If a token is missing required scopes, it will be rejected with a `401 Unauthorized` response.

### Required vs Optional

Currently, all scopes are **required**. If you want to make some optional:

```python
# In src/keycloak_auth_config.py
SUPPORTED_SCOPES = [
    "openid",     # Required
    "profile",    # Required
    "email",      # Required
]

# Optional scopes can be checked in tools
# Example:
@mcp.tool()
def create_note(title: str, content: str):
    # Check if user has write:notes scope
    if "write:notes" not in request.auth.scopes:
        raise PermissionError("write:notes scope required")
    # ...
```

## 🎯 Next Steps

1. **Restart Server:**
   ```bash
   python run.py
   ```

2. **Test with New Scopes:**
   ```bash
   ./debug-token.sh
   ```

3. **Update Clients:** Ensure all OAuth clients request the new scopes

4. **Configure Keycloak:** Add custom `claudeai` scope if needed

## 📚 References

- [OAuth 2.0 Scopes](https://oauth.net/2/scope/)
- [OpenID Connect Standard Claims](https://openid.net/specs/openid-connect-core-1_0.html#StandardClaims)
- [Keycloak Client Scopes](https://www.keycloak.org/docs/latest/server_admin/#_client_scopes)

---

**Your server now requires these scopes:** `openid profile email claudeai read:notes write:notes use:calculator` ✅


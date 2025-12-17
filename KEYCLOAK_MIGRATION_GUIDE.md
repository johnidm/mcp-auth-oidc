# 🔐 Migrating from Auth0 to Keycloak

This guide walks you through migrating your MCP server from Auth0 to Keycloak as the OIDC provider.

## 📋 Table of Contents

- [Why Keycloak?](#why-keycloak)
- [Prerequisites](#prerequisites)
- [Quick Start with Docker](#quick-start-with-docker)
- [Step-by-Step Migration](#step-by-step-migration)
- [Configuration Changes](#configuration-changes)
- [Testing the Migration](#testing-the-migration)
- [Production Deployment](#production-deployment)
- [Troubleshooting](#troubleshooting)

## 🌟 Why Keycloak?

**Keycloak** is an open-source identity and access management solution that offers:

- ✅ **Self-Hosted**: Full control over your authentication infrastructure
- 💰 **Cost-Free**: No per-user pricing or rate limits
- 🔒 **Enterprise-Grade**: Used by Fortune 500 companies
- 🌐 **OIDC Compliant**: Full OAuth 2.1 and OIDC support
- 🛠️ **Highly Customizable**: Themes, extensions, and custom flows
- 📊 **Built-in Analytics**: User activity and authentication metrics
- 🔄 **Federation**: LDAP, Active Directory, social login integration

## 📋 Prerequisites

Before starting the migration, ensure you have:

- 🐳 **Docker & Docker Compose** installed (for local testing)
- 🐍 **Python 3.10+** with existing MCP server running
- 📝 **Current Auth0 configuration** documented
- 🔑 **List of scopes** your application uses
- 👥 **User migration plan** (if applicable)

## 🚀 Quick Start with Docker

### Launch Keycloak Locally

The project includes a Docker Compose configuration for local testing:

```bash
# Start Keycloak
docker-compose up -d

# Check if it's running
docker-compose ps
```

Keycloak will be available at:
- **Admin Console**: http://localhost:8080
- **Admin Username**: `admin`
- **Admin Password**: `admin`

### Access the Admin Console

1. Open http://localhost:8080 in your browser
2. Click on **Administration Console**
3. Login with `admin` / `admin`

## 📝 Step-by-Step Migration

### Step 1: Create a Realm

A realm in Keycloak is equivalent to an Auth0 tenant.

1. In the Keycloak Admin Console, hover over **Master** in the top-left
2. Click **Create Realm**
3. Enter realm name: `mcp-demo` (or your preferred name)
4. Click **Create**

### Step 2: Create a Client

This is equivalent to an Auth0 application.

1. In your realm, go to **Clients** → **Create client**
2. Configure the client:
   - **Client type**: `OpenID Connect`
   - **Client ID**: `mcp-server`
   - Click **Next**

3. **Capability config**:
   - ✅ **Client authentication**: ON
   - ✅ **Authorization**: OFF
   - ✅ **Standard flow**: ON (Authorization Code)
   - ✅ **Direct access grants**: ON
   - ✅ **Service accounts roles**: OFF (optional)
   - Click **Next**

4. **Login settings**:
   - **Root URL**: `http://localhost:8000`
   - **Home URL**: `http://localhost:8000`
   - **Valid redirect URIs**: 
     ```
     http://localhost:8000/auth/callback
     http://localhost:6274/oauth/callback
     ```
   - **Valid post logout redirect URIs**: `http://localhost:8000`
   - **Web origins**: `http://localhost:8000`
   - Click **Save**

5. Go to **Credentials** tab and copy the **Client Secret**

### Step 3: Create Client Scopes

Client scopes in Keycloak map to Auth0 API scopes.

#### Create `read:notes` scope:

1. Go to **Client Scopes** → **Create client scope**
2. Configure:
   - **Name**: `read:notes`
   - **Description**: `Permission to read notes`
   - **Type**: `Optional`
   - **Display on consent screen**: ON
   - **Include in token scope**: ON
3. Click **Save**

#### Create `write:notes` scope:

1. **Create client scope**
2. Configure:
   - **Name**: `write:notes`
   - **Description**: `Permission to create, update, and delete notes`
   - **Type**: `Optional`
   - **Display on consent screen**: ON
   - **Include in token scope**: ON
3. Click **Save**

#### Create `use:calculator` scope:

1. **Create client scope**
2. Configure:
   - **Name**: `use:calculator`
   - **Description**: `Permission to use calculator tools`
   - **Type**: `Optional`
   - **Display on consent screen**: ON
   - **Include in token scope**: ON
3. Click **Save**

### Step 4: Add Scopes to Client

1. Go to **Clients** → **mcp-server** → **Client scopes** tab
2. Click **Add client scope**
3. Select all three scopes (`read:notes`, `write:notes`, `use:calculator`)
4. Choose **Optional** (so users can consent to specific scopes)
5. Click **Add**

### Step 5: Create Test User

1. Go to **Users** → **Add user**
2. Configure:
   - **Username**: `testuser`
   - **Email**: `testuser@example.com`
   - **First name**: `Test`
   - **Last name**: `User`
   - **Email verified**: ON
3. Click **Create**

4. Go to **Credentials** tab:
   - Click **Set password**
   - Enter password: `testpassword` (or your choice)
   - **Temporary**: OFF
   - Click **Save**

### Step 6: Configure Audience

Keycloak needs to add the `aud` (audience) claim to tokens.

#### Create Audience Mapper:

1. Go to **Clients** → **mcp-server** → **Client scopes** tab
2. Click on **mcp-server-dedicated**
3. Go to **Mappers** tab → **Add mapper** → **By configuration**
4. Select **Audience**
5. Configure:
   - **Name**: `audience-mapper`
   - **Included Client Audience**: `mcp-server`
   - **Add to ID token**: OFF
   - **Add to access token**: ON
6. Click **Save**

## ⚙️ Configuration Changes

### Update Environment Variables

Edit your `.env` file:

```env
# Keycloak Configuration
KEYCLOAK_REALM=mcp-demo
KEYCLOAK_BASE_URL=http://localhost:8080
KEYCLOAK_CLIENT_ID=mcp-server
KEYCLOAK_CLIENT_SECRET=<your-client-secret-from-step-2>
KEYCLOAK_AUDIENCE=mcp-server

# Server Configuration
RESOURCE_ID=http://localhost:8000
SERVER_HOST=0.0.0.0
SERVER_PORT=8000
```

### Create Keycloak Auth Configuration

Create a new file `src/keycloak_auth_config.py`:

```python
"""Keycloak configuration using FastMCP's OIDCProvider."""

import os
from fastmcp.server.auth.providers.oidc import OIDCProvider


# Keycloak configuration from environment variables
KEYCLOAK_REALM = os.getenv("KEYCLOAK_REALM", "mcp-demo")
KEYCLOAK_BASE_URL = os.getenv("KEYCLOAK_BASE_URL", "http://localhost:8080")
KEYCLOAK_CLIENT_ID = os.getenv("KEYCLOAK_CLIENT_ID")
KEYCLOAK_CLIENT_SECRET = os.getenv("KEYCLOAK_CLIENT_SECRET")
KEYCLOAK_AUDIENCE = os.getenv("KEYCLOAK_AUDIENCE")
BASE_URL = os.getenv("RESOURCE_ID", "http://localhost:8000")

# Keycloak OIDC endpoints
KEYCLOAK_CONFIG_URL = f"{KEYCLOAK_BASE_URL}/realms/{KEYCLOAK_REALM}/.well-known/openid-configuration"

# Define supported scopes for this MCP server
SUPPORTED_SCOPES = [
    "read:notes",
    "write:notes",
    "use:calculator",
]


def create_auth_provider() -> OIDCProvider:
    """
    Create Keycloak authentication provider using FastMCP's OIDC Proxy.
    
    This uses FastMCP's built-in OIDCProvider which handles:
    - OIDC discovery
    - Dynamic Client Registration (DCR) proxy
    - Token validation
    - OAuth flow management
    
    Returns:
        OIDCProvider: Configured Keycloak authentication provider
    """
    if not all([KEYCLOAK_CLIENT_ID, KEYCLOAK_CLIENT_SECRET]):
        raise ValueError(
            "Missing required Keycloak configuration. "
            "Please set KEYCLOAK_CLIENT_ID and KEYCLOAK_CLIENT_SECRET in .env"
        )
    
    # Create OIDC provider with Keycloak configuration
    auth = OIDCProvider(
        config_url=KEYCLOAK_CONFIG_URL,
        client_id=KEYCLOAK_CLIENT_ID,
        client_secret=KEYCLOAK_CLIENT_SECRET,
        audience=KEYCLOAK_AUDIENCE,
        base_url=BASE_URL,
        required_scopes=SUPPORTED_SCOPES,
    )
    
    return auth
```

### Update Server Configuration

Option 1: Update `src/server.py` to use Keycloak:

```python
# Change this line:
# from src.auth_config import create_auth_provider

# To:
from src.keycloak_auth_config import create_auth_provider
```

Option 2: Use environment variable to switch providers:

```python
"""FastMCP server with demo tools (calculator and notes)."""

import os
from datetime import datetime
from typing import Dict, List, Optional
from fastmcp import FastMCP

# Choose auth provider based on environment variable
AUTH_PROVIDER = os.getenv("AUTH_PROVIDER", "auth0")  # "auth0" or "keycloak"

if AUTH_PROVIDER == "keycloak":
    from src.keycloak_auth_config import create_auth_provider
else:
    from src.auth_config import create_auth_provider

# Create authentication provider
auth = create_auth_provider()

# Rest of the server code remains the same...
```

Then add to `.env`:

```env
AUTH_PROVIDER=keycloak
```

## 🧪 Testing the Migration

### 1. Start Keycloak

```bash
docker-compose up -d
```

### 2. Verify Keycloak Configuration

```bash
# Check OIDC discovery endpoint
curl http://localhost:8080/realms/mcp-demo/.well-known/openid-configuration | jq
```

You should see endpoints for authorization, token, userinfo, etc.

### 3. Start Your MCP Server

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

### 4. Test with MCP Inspector

```bash
npx @modelcontextprotocol/inspector
```

Configure connection:
- **Server URL**: `http://localhost:8000/mcp`
- **OAuth Scopes**: `read:notes write:notes use:calculator`

Click **Connect** and you should be redirected to Keycloak for authentication.

### 5. Test Authentication Flow

1. Login with `testuser` / `testpassword`
2. Review and accept the consent screen
3. Verify you're redirected back to MCP Inspector
4. Test calling tools (e.g., `add_numbers`, `create_note`)

### 6. Manual Token Testing

Get a token directly from Keycloak:

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

Test the token with your MCP server:

```bash
TOKEN="<access_token_from_above>"

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

## 🚀 Production Deployment

### Docker Deployment

For production, use a more robust Keycloak setup:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: keycloak
      POSTGRES_USER: keycloak
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - keycloak_network

  keycloak:
    image: quay.io/keycloak/keycloak:23.0
    command: start --optimized
    environment:
      KC_DB: postgres
      KC_DB_URL: jdbc:postgresql://postgres:5432/keycloak
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD: ${DB_PASSWORD}
      KC_HOSTNAME: ${KEYCLOAK_HOSTNAME}
      KC_HOSTNAME_STRICT: true
      KC_HOSTNAME_STRICT_HTTPS: true
      KC_HTTPS_CERTIFICATE_FILE: /opt/keycloak/conf/tls.crt
      KC_HTTPS_CERTIFICATE_KEY_FILE: /opt/keycloak/conf/tls.key
      KEYCLOAK_ADMIN: ${ADMIN_USERNAME}
      KEYCLOAK_ADMIN_PASSWORD: ${ADMIN_PASSWORD}
    ports:
      - "443:8443"
    depends_on:
      - postgres
    volumes:
      - ./certs:/opt/keycloak/conf
    networks:
      - keycloak_network

volumes:
  postgres_data:

networks:
  keycloak_network:
```

### Production Checklist

- 🔐 **HTTPS**: Always use TLS/SSL certificates
- 💾 **Database**: Use PostgreSQL or MySQL (not H2)
- 🔑 **Secrets**: Use strong passwords and secrets management
- 🔄 **Backup**: Regular database backups
- 📊 **Monitoring**: Set up Keycloak metrics and logs
- 🚦 **Rate Limiting**: Configure rate limiting for login attempts
- 🛡️ **Security Headers**: Configure proper CORS and security headers
- 👥 **User Federation**: Set up LDAP/AD if needed
- 🎨 **Theming**: Customize login pages for your brand
- 📧 **Email**: Configure SMTP for password resets

## 🆚 Keycloak vs Auth0: Key Differences

| Feature | Auth0 | Keycloak |
|---------|-------|----------|
| **Hosting** | SaaS only | Self-hosted or managed |
| **Cost** | Per MAU | Free (hosting costs only) |
| **Customization** | Limited | Highly customizable |
| **Data Control** | Third-party | Full control |
| **Realm/Tenant** | Tenant | Realm |
| **Application** | Application | Client |
| **API** | API Resource | Client Audience |
| **Scopes** | API Scopes | Client Scopes |
| **Users** | Auth0 Dashboard | Keycloak Admin |
| **Social Login** | Built-in | Via Identity Providers |
| **MFA** | Built-in | Built-in |
| **OIDC Discovery** | /.well-known/openid-configuration | /realms/{realm}/.well-known/openid-configuration |

## 🔧 Troubleshooting

### Issue: "Invalid Redirect URI"

**Solution**:
- Verify redirect URIs in Keycloak client settings
- Check for trailing slashes
- Ensure http vs https matches

```
Valid redirect URIs:
http://localhost:8000/auth/callback
http://localhost:6274/oauth/callback
```

### Issue: "Audience claim missing"

**Solution**:
- Add audience mapper to client (see Step 6)
- Verify mapper is enabled and added to access token

### Issue: "Invalid client credentials"

**Solution**:
- Regenerate client secret in Keycloak
- Update `.env` with new secret
- Ensure client authentication is enabled

### Issue: "Scope not granted"

**Solution**:
- Verify client scopes are added to client
- Check scopes are set as "Optional" for consent
- Ensure scopes are included in token scope

### Issue: "Token validation fails"

**Solution**:
- Check OIDC discovery URL is correct
- Verify Keycloak is accessible from MCP server
- Check token signature algorithm (RS256 default)

### Issue: Docker container won't start

**Solution**:
```bash
# Check logs
docker-compose logs keycloak

# Common fixes:
# 1. Port 8080 already in use
docker-compose down
lsof -ti:8080 | xargs kill -9
docker-compose up -d

# 2. Permission issues
docker-compose down -v
docker-compose up -d
```

## 📚 Advanced Configuration

### Custom Token Claims

Add custom claims to tokens via mappers:

1. Go to **Client Scopes** → **mcp-server-dedicated** → **Mappers**
2. **Add mapper** → **By configuration** → **User Attribute**
3. Configure:
   - **Name**: `custom-claim`
   - **User Attribute**: `department`
   - **Token Claim Name**: `department`
   - **Add to access token**: ON

### User Federation

Connect to LDAP/Active Directory:

1. Go to **User Federation** → **Add provider** → **ldap**
2. Configure connection settings
3. Test connection and save

### Social Login

Add Google/GitHub/Facebook login:

1. Go to **Identity Providers**
2. Select provider (e.g., Google)
3. Configure OAuth credentials
4. Map attributes

### Email Configuration

Configure SMTP for email verification:

1. Go to **Realm Settings** → **Email** tab
2. Configure SMTP settings:
   - Host, Port, From address
   - Username, Password
   - Enable SSL/TLS
3. Test connection

## 🔄 Migrating Users from Auth0

If you need to migrate existing users:

### Option 1: Export/Import

1. **Export from Auth0**:
   - Use Auth0 Management API
   - Export users to JSON

2. **Import to Keycloak**:
   - Use Keycloak REST API
   - Import users via Admin CLI

### Option 2: Lazy Migration

1. Keep Auth0 running
2. Use Auth0 as Identity Provider in Keycloak
3. Users authenticate via Auth0 first time
4. Keycloak creates local user automatically
5. Eventually deprecate Auth0

### Option 3: Forced Migration

1. Export user emails
2. Send password reset emails via Keycloak
3. Users create new passwords
4. Deprecate Auth0

## 📖 Additional Resources

- 🌐 [Keycloak Documentation](https://www.keycloak.org/documentation)
- 🎓 [Keycloak Admin Guide](https://www.keycloak.org/docs/latest/server_admin/)
- 🔧 [Keycloak REST API](https://www.keycloak.org/docs-api/latest/rest-api/)
- 🐳 [Keycloak Docker Image](https://quay.io/repository/keycloak/keycloak)
- 💬 [Keycloak Community](https://github.com/keycloak/keycloak/discussions)
- 📺 [Keycloak YouTube Channel](https://www.youtube.com/@keycloak)

## 🎯 Summary

You've successfully migrated from Auth0 to Keycloak! Key achievements:

✅ Self-hosted OIDC provider running
✅ Clients and scopes configured
✅ Users created and authenticated
✅ MCP server integrated with Keycloak
✅ Testing completed successfully

Your MCP server now uses Keycloak for authentication, giving you full control over your identity and access management infrastructure!

---

<div align="center">

**Need help?** Check the [troubleshooting section](#troubleshooting) or open an issue on GitHub.

Made with ❤️ for the open-source community

</div>


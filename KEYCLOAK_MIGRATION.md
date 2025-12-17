# 🔄 Migrating from Auth0 to Keycloak

[![Keycloak](https://img.shields.io/badge/Keycloak-23.0-blue.svg)](https://www.keycloak.org/)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED.svg)](https://docs.docker.com/compose/)

This guide walks you through migrating your MCP server from Auth0 to Keycloak as the OAuth 2.0/OIDC provider.

## 📋 Table of Contents

- [Why Keycloak?](#-why-keycloak)
- [Quick Start with Docker](#-quick-start-with-docker)
- [Migration Steps](#-migration-steps)
- [Configuration Comparison](#-configuration-comparison)
- [Testing the Migration](#-testing-the-migration)
- [Production Deployment](#-production-deployment)
- [Troubleshooting](#-troubleshooting)

## 🌟 Why Keycloak?

Keycloak offers several advantages over Auth0:

- ✅ **Self-Hosted**: Complete control over your authentication infrastructure
- 💰 **Cost**: Free and open-source (no per-user pricing)
- 🔒 **Privacy**: Keep user data on your own infrastructure
- 🛠️ **Customization**: Extensive customization and extension options
- 🌐 **Standards**: Full OAuth 2.1 and OIDC compliance
- 🔧 **Integration**: Easy integration with LDAP, Active Directory, and other identity sources

## 🚀 Quick Start with Docker

### Prerequisites

- Docker and Docker Compose installed
- Your MCP server code

### 1. Start Keycloak

We've included a `docker-compose.yml` file that sets up Keycloak with a pre-configured realm:

```bash
# Start Keycloak
docker-compose up -d

# Wait for Keycloak to start (check health)
docker-compose ps
```

This will:
- 🚀 Start Keycloak on `http://localhost:8080`
- 👤 Create admin user: `admin` / `admin`
- 🌍 Import the `mcp-demo` realm with pre-configured client
- 👥 Create demo user: `demo@example.com` / `demo123`

### 2. Access Keycloak Admin Console

Open your browser and navigate to:

```
http://localhost:8080
```

**Admin credentials:**
- Username: `admin`
- Password: `admin`

### 3. Verify the Realm Configuration

1. Click on the **realm dropdown** (top left) and select `mcp-demo`
2. Navigate to **Clients** → `mcp-auth-demo` to see the pre-configured client
3. Note the **Client Secret** (or generate a new one)

## 🔄 Migration Steps

### Step 1: Update Environment Variables

Create or update your `.env` file with Keycloak configuration:

**Before (Auth0):**
```env
AUTH0_DOMAIN=dev-zilqiezmsk6ylig2.us.auth0.com
AUTH0_CLIENT_ID=GsJfBMVGn5cDgWQwTiq91SIQBYxQccJA
AUTH0_CLIENT_SECRET=Qst5RVD9Vt79F5NgM_s6ymZSvMYemKrFMykWrDOtextPC2nBeK593yBvpJBafIDl
AUTH0_AUDIENCE=https://dev-zilqiezmsk6ylig2.us.auth0.com/api/v2/
RESOURCE_ID=http://localhost:8000
```

**After (Keycloak):**
```env
# Keycloak Configuration
KEYCLOAK_SERVER_URL=http://localhost:8080
KEYCLOAK_REALM=mcp-demo
KEYCLOAK_CLIENT_ID=mcp-auth-demo
KEYCLOAK_CLIENT_SECRET=your-client-secret-here

# Server Configuration (unchanged)
RESOURCE_ID=http://localhost:8000
SERVER_HOST=0.0.0.0
SERVER_PORT=8000
```

### Step 2: Create Keycloak Configuration File

Create a new file `src/keycloak_config.py`:

```python
"""Keycloak configuration using FastMCP's OIDCProxy."""

import os
from fastmcp.server.auth.providers.oidc import OIDCProvider


# Keycloak configuration from environment variables
KEYCLOAK_SERVER_URL = os.getenv("KEYCLOAK_SERVER_URL", "http://localhost:8080")
KEYCLOAK_REALM = os.getenv("KEYCLOAK_REALM", "mcp-demo")
KEYCLOAK_CLIENT_ID = os.getenv("KEYCLOAK_CLIENT_ID")
KEYCLOAK_CLIENT_SECRET = os.getenv("KEYCLOAK_CLIENT_SECRET")
BASE_URL = os.getenv("RESOURCE_ID", "http://localhost:8000")

# Define supported scopes for this MCP server
SUPPORTED_SCOPES = [
    "read:notes",
    "write:notes",
    "use:calculator",
]


def create_auth_provider() -> OIDCProvider:
    """
    Create Keycloak authentication provider using FastMCP's OIDC Proxy.
    
    This uses FastMCP's generic OIDCProvider which handles:
    - OIDC discovery
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
    
    # Construct OIDC configuration URL for Keycloak
    config_url = f"{KEYCLOAK_SERVER_URL}/realms/{KEYCLOAK_REALM}/.well-known/openid-configuration"
    
    # Create OIDC provider for Keycloak
    auth = OIDCProvider(
        config_url=config_url,
        client_id=KEYCLOAK_CLIENT_ID,
        client_secret=KEYCLOAK_CLIENT_SECRET,
        base_url=BASE_URL,
        required_scopes=SUPPORTED_SCOPES,
    )
    
    return auth
```

### Step 3: Update Main Entry Point

Modify `src/main.py` to use Keycloak configuration:

**Option A: Switch completely to Keycloak**

```python
"""Main entry point for the MCP server with Keycloak authentication."""

import os
from src.keycloak_config import create_auth_provider  # Changed from auth_config
from src.app import mcp

# ... rest of the file remains the same
```

**Option B: Use environment variable to choose provider**

```python
"""Main entry point for MCP server with configurable auth provider."""

import os

# Choose auth provider based on environment variable
AUTH_PROVIDER = os.getenv("AUTH_PROVIDER", "auth0")  # "auth0" or "keycloak"

if AUTH_PROVIDER == "keycloak":
    from src.keycloak_config import create_auth_provider
else:
    from src.auth_config import create_auth_provider

from src.app import mcp

# ... rest of the file remains the same
```

### Step 4: Configure Client Scopes in Keycloak

If you didn't use the provided `realm-export.json`, manually configure scopes:

1. Go to **Keycloak Admin Console** → **mcp-demo** realm
2. Navigate to **Client Scopes** → **Create client scope**
3. Create three scopes:

**Scope 1: read:notes**
- Name: `read:notes`
- Description: `Read notes`
- Type: `Default`
- Include in Token Scope: `ON`
- Display on Consent Screen: `ON`

**Scope 2: write:notes**
- Name: `write:notes`
- Description: `Create, update, and delete notes`
- Type: `Default`
- Include in Token Scope: `ON`
- Display on Consent Screen: `ON`

**Scope 3: use:calculator**
- Name: `use:calculator`
- Description: `Use calculator tools`
- Type: `Default`
- Include in Token Scope: `ON`
- Display on Consent Screen: `ON`

4. Navigate to **Clients** → **mcp-auth-demo** → **Client Scopes** tab
5. Add all three scopes as **Default Client Scopes**

### Step 5: Update Redirect URIs

1. Go to **Clients** → **mcp-auth-demo** → **Settings**
2. Update **Valid Redirect URIs**:
   ```
   http://localhost:8000/*
   http://localhost:6274/*
   ```
3. Update **Web Origins**:
   ```
   http://localhost:8000
   http://localhost:6274
   +
   ```
4. Click **Save**

### Step 6: Restart Your MCP Server

```bash
# Stop the server if running
# Ctrl+C

# Start with Keycloak configuration
python run.py
```

You should see:

```
============================================================
MCP Auth Demo Server (FastMCP + OIDC Proxy)
============================================================
Base URL: http://localhost:8000
OIDC Provider: http://localhost:8080/realms/mcp-demo
Server: http://0.0.0.0:8000
Auth Callback: http://localhost:8000/auth/callback
============================================================
```

## 📊 Configuration Comparison

### Auth0 vs Keycloak

| Feature | Auth0 | Keycloak |
|---------|-------|----------|
| **Config URL** | `https://{domain}/.well-known/openid-configuration` | `http://{server}/realms/{realm}/.well-known/openid-configuration` |
| **Client Registration** | Via Auth0 Dashboard | Via Admin Console or REST API |
| **Scopes** | Configured in Auth0 API | Configured as Client Scopes |
| **Users** | Auth0 Dashboard | Admin Console or User Federation |
| **Token Lifetime** | Configured per API | Configured per Realm/Client |
| **Hosting** | SaaS (Auth0 managed) | Self-hosted (Docker, K8s, etc.) |

### Environment Variables Mapping

| Auth0 | Keycloak |
|-------|----------|
| `AUTH0_DOMAIN` | `KEYCLOAK_SERVER_URL` + `KEYCLOAK_REALM` |
| `AUTH0_CLIENT_ID` | `KEYCLOAK_CLIENT_ID` |
| `AUTH0_CLIENT_SECRET` | `KEYCLOAK_CLIENT_SECRET` |
| `AUTH0_AUDIENCE` | Handled automatically by Keycloak |

## 🧪 Testing the Migration

### 1. Test with MCP Inspector

```bash
# Terminal 1: Start Keycloak (if not running)
docker-compose up -d

# Terminal 2: Start MCP server
python run.py

# Terminal 3: Start MCP Inspector
npx @modelcontextprotocol/inspector
```

**Configure in Inspector:**
- Server URL: `http://localhost:8000/mcp`
- Transport: `HTTP with SSE`
- OAuth Scopes: `read:notes write:notes use:calculator`

**Test Authentication:**
1. Click **Connect** in Inspector
2. You'll be redirected to Keycloak login
3. Login with demo user:
   - Username: `demo@example.com`
   - Password: `demo123`
4. Approve the consent screen
5. You should be connected!

### 2. Test Calculator Tools

In MCP Inspector, try:

```json
{
  "a": 10,
  "b": 5
}
```

Test all calculator operations to verify OAuth is working.

### 3. Test Notes Tools

Create a note:

```json
{
  "title": "Keycloak Migration Test",
  "content": "Successfully migrated from Auth0 to Keycloak!"
}
```

List, read, update, and delete notes to verify all scopes work correctly.

## 🚀 Production Deployment

### Using PostgreSQL Backend

For production, use PostgreSQL instead of the in-memory database:

**1. Update docker-compose.yml:**

```bash
# Start with PostgreSQL
docker-compose --profile production up -d
```

**2. Update Keycloak service configuration:**

```yaml
services:
  keycloak:
    environment:
      # Use PostgreSQL
      KC_DB: postgres
      KC_DB_URL: jdbc:postgresql://postgres:5432/keycloak
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD: keycloak
      
      # Enable HTTPS
      KC_HOSTNAME: your-domain.com
      KC_HOSTNAME_STRICT: true
      KC_PROXY: edge
```

### Production Environment Variables

```env
# Production Keycloak Configuration
KEYCLOAK_SERVER_URL=https://auth.your-domain.com
KEYCLOAK_REALM=mcp-production
KEYCLOAK_CLIENT_ID=mcp-server-prod
KEYCLOAK_CLIENT_SECRET=<strong-secret-here>

# Server Configuration
RESOURCE_ID=https://mcp.your-domain.com
SERVER_HOST=0.0.0.0
SERVER_PORT=8000
```

### Security Best Practices

1. 🔐 **Use HTTPS**: Always use HTTPS in production
   ```yaml
   KC_HTTPS_CERTIFICATE_FILE: /path/to/cert.pem
   KC_HTTPS_CERTIFICATE_KEY_FILE: /path/to/key.pem
   ```

2. 🔑 **Strong Secrets**: Generate strong client secrets
   ```bash
   openssl rand -base64 32
   ```

3. 🗄️ **Database Backups**: Regularly backup PostgreSQL database
   ```bash
   docker exec mcp-postgres pg_dump -U keycloak keycloak > backup.sql
   ```

4. 📝 **Audit Logging**: Enable Keycloak event logging
   - Go to **Realm Settings** → **Events** → Enable **Save Events**

5. 🔄 **Token Rotation**: Configure short token lifetimes
   - **Realm Settings** → **Tokens** → Set appropriate timeouts

6. 🛡️ **Network Security**: Use firewall rules and network policies
   ```yaml
   networks:
     mcp-network:
       driver: bridge
       ipam:
         config:
           - subnet: 172.20.0.0/16
   ```

## 🔧 Troubleshooting

### Issue 1: Keycloak Won't Start

**Symptoms:**
```
Error: Container keeps restarting
```

**Solutions:**
- ✅ Check Docker logs: `docker-compose logs keycloak`
- ✅ Verify port 8080 is available: `lsof -i :8080`
- ✅ Ensure Docker has enough resources (4GB+ RAM recommended)
- ✅ Remove volumes and restart: `docker-compose down -v && docker-compose up -d`

### Issue 2: Realm Import Failed

**Symptoms:**
```
Realm mcp-demo not found
```

**Solutions:**
- ✅ Check if `keycloak/realm-export.json` exists
- ✅ Verify JSON syntax: `jq . keycloak/realm-export.json`
- ✅ Manually import: Admin Console → Realm Settings → Partial Import

### Issue 3: Invalid Redirect URI

**Symptoms:**
```
invalid_redirect_uri error during OAuth flow
```

**Solutions:**
- ✅ Verify redirect URIs in Keycloak client configuration
- ✅ Ensure wildcards are used: `http://localhost:8000/*`
- ✅ Check RESOURCE_ID matches redirect URI base

### Issue 4: Token Validation Failed

**Symptoms:**
```
Invalid token or JWT verification failed
```

**Solutions:**
- ✅ Verify Keycloak is accessible from MCP server
- ✅ Check realm name matches: `KEYCLOAK_REALM=mcp-demo`
- ✅ Ensure client secret is correct
- ✅ Verify scopes are configured in token

### Issue 5: Scope Not Present in Token

**Symptoms:**
```
Tool call fails with insufficient scope error
```

**Solutions:**
- ✅ Check client scopes are added to client
- ✅ Verify "Include in Token Scope" is enabled
- ✅ Re-authenticate to get new token with updated scopes
- ✅ Check token contents using jwt.io

### Issue 6: CORS Errors

**Symptoms:**
```
CORS policy: No 'Access-Control-Allow-Origin' header
```

**Solutions:**
- ✅ Add web origins in Keycloak client: `http://localhost:6274`
- ✅ Restart both Keycloak and MCP server
- ✅ Clear browser cache and cookies

## 🎯 Advanced Configuration

### Custom User Attributes

Add custom attributes to users:

1. **Realm Settings** → **User Profile**
2. Create new attribute (e.g., `organization`)
3. Add mapper to client:
   - **Clients** → **mcp-auth-demo** → **Client Scopes**
   - **Mappers** → **Create Protocol Mapper**
   - Mapper Type: `User Attribute`

### LDAP/Active Directory Integration

Connect to existing directory:

1. **User Federation** → **Add provider** → **LDAP**
2. Configure connection:
   ```
   Connection URL: ldap://your-ldap-server:389
   Bind DN: cn=admin,dc=example,dc=com
   Bind Credential: <password>
   ```
3. Test connection and save

### Multi-Realm Setup

For multiple environments:

```env
# Development
KEYCLOAK_REALM=mcp-dev

# Staging
KEYCLOAK_REALM=mcp-staging

# Production
KEYCLOAK_REALM=mcp-production
```

### Custom Themes

Customize login page:

```bash
# Create custom theme
mkdir -p keycloak/themes/mcp-custom/login

# Add to docker-compose.yml
volumes:
  - ./keycloak/themes:/opt/keycloak/themes
```

## 📚 Additional Resources

- 🌐 [Keycloak Documentation](https://www.keycloak.org/documentation)
- 🐳 [Keycloak Docker Hub](https://quay.io/repository/keycloak/keycloak)
- 🔐 [OIDC Specification](https://openid.net/specs/openid-connect-core-1_0.html)
- 📖 [FastMCP OIDC Guide](https://gofastmcp.com/servers/auth/oidc-proxy)
- 🎓 [Keycloak Admin REST API](https://www.keycloak.org/docs-api/latest/rest-api/)

## 🆘 Getting Help

### Keycloak Community

- 💬 [Keycloak Users Mailing List](https://www.keycloak.org/community)
- 💻 [GitHub Issues](https://github.com/keycloak/keycloak/issues)
- 📺 [Keycloak YouTube Channel](https://www.youtube.com/c/Keycloak)

### MCP Server Issues

- 🐛 [FastMCP GitHub Issues](https://github.com/jlowin/fastmcp/issues)
- 💬 [Discord Community](https://discord.gg/prefect)

---

<div align="center">

**🎉 Migration Complete! 🎉**

You're now running MCP with self-hosted Keycloak authentication!

Made with ❤️ using [FastMCP](https://gofastmcp.com/) and [Keycloak](https://www.keycloak.org/)

</div>


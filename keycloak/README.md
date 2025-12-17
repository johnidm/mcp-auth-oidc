# 🔑 Keycloak Configuration

This directory contains the Keycloak realm configuration for the MCP Auth Demo Server.

## 📁 Contents

- **realm-export.json** - Pre-configured Keycloak realm with:
  - Client: `mcp-auth-demo`
  - Scopes: `read:notes`, `write:notes`, `use:calculator`
  - Demo user: `demo@example.com` / `demo123`
  - Admin user: `admin` / `admin`

## 🚀 Quick Start

### Start Keycloak

From the project root:

```bash
docker-compose up -d
```

### Access Admin Console

Open your browser: http://localhost:8080

- Username: `admin`
- Password: `admin`

### Get Client Secret

1. Select realm: **mcp-demo** (dropdown in top-left)
2. Navigate to: **Clients** → **mcp-auth-demo**
3. Go to: **Credentials** tab
4. Copy the **Client Secret**
5. Update your `.env` file with this secret

## 🔄 Reimporting Configuration

If you make changes to the realm and want to export:

### Export Realm

```bash
# Using Keycloak CLI inside the container
docker exec -it mcp-keycloak /opt/keycloak/bin/kc.sh export \
  --dir /opt/keycloak/data/import \
  --realm mcp-demo \
  --users realm_file
```

### Manual Export

1. Go to **Realm Settings** → **Action** → **Partial export**
2. Select what to export:
   - ✅ Export clients
   - ✅ Export groups and roles
   - ✅ Export client scopes
3. Click **Export**
4. Save the JSON file as `realm-export.json`

## 🎯 Realm Configuration Details

### Clients

- **Client ID**: `mcp-auth-demo`
- **Client Protocol**: openid-connect
- **Access Type**: confidential
- **Standard Flow**: Enabled
- **Direct Access Grants**: Enabled
- **Consent Required**: Yes (for OAuth consent screen)

### Redirect URIs

- `http://localhost:8000/*` - MCP Server
- `http://localhost:6274/*` - MCP Inspector

### Client Scopes

1. **read:notes**
   - Display on consent: "Read your notes"
   - Included in token scope

2. **write:notes**
   - Display on consent: "Create, update, and delete your notes"
   - Included in token scope

3. **use:calculator**
   - Display on consent: "Use calculator tools"
   - Included in token scope

### Users

- **Demo User**
  - Username: `demo`
  - Email: `demo@example.com`
  - Password: `demo123`
  - Email verified: Yes
  - Enabled: Yes

## 🔧 Customization

### Add New Scopes

1. **Client Scopes** → **Create client scope**
2. Name: `your:scope`
3. Protocol: `openid-connect`
4. Include in token scope: `ON`
5. Display on consent screen: `ON`
6. **Client Scopes** → **mcp-auth-demo** → **Add scope**

### Add New Users

1. **Users** → **Add user**
2. Fill in details
3. **Credentials** tab → Set password
4. Uncheck "Temporary"
5. Click "Set Password"

### Token Lifetime

1. **Realm Settings** → **Tokens** tab
2. Adjust:
   - Access Token Lifespan: `3600s` (1 hour)
   - Access Token Lifespan For Implicit Flow: `900s` (15 min)
   - Client Session Idle: `1800s` (30 min)
   - Client Session Max: `36000s` (10 hours)

## 🐳 Docker Compose Integration

The realm is automatically imported when Keycloak starts:

```yaml
volumes:
  - ./keycloak/realm-export.json:/opt/keycloak/data/import/realm-export.json:ro
```

## 📚 Additional Resources

- [Keycloak Realm Import/Export](https://www.keycloak.org/docs/latest/server_admin/#_export_import)
- [Keycloak Client Configuration](https://www.keycloak.org/docs/latest/server_admin/#_clients)
- [OIDC Client Scopes](https://www.keycloak.org/docs/latest/server_admin/#_client_scopes)


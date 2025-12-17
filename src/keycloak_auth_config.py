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


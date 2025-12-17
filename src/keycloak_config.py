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
    
    Keycloak is a popular open-source identity and access management solution
    that provides full OAuth 2.0 and OpenID Connect support.
    
    Returns:
        OIDCProvider: Configured Keycloak authentication provider
        
    Raises:
        ValueError: If required configuration is missing
    """
    if not all([KEYCLOAK_CLIENT_ID, KEYCLOAK_CLIENT_SECRET]):
        raise ValueError(
            "Missing required Keycloak configuration. "
            "Please set KEYCLOAK_CLIENT_ID and KEYCLOAK_CLIENT_SECRET in .env"
        )
    
    # Construct OIDC configuration URL for Keycloak
    # Format: http(s)://{server}/realms/{realm}/.well-known/openid-configuration
    config_url = f"{KEYCLOAK_SERVER_URL}/realms/{KEYCLOAK_REALM}/.well-known/openid-configuration"
    
    print(f"Configuring Keycloak OIDC provider:")
    print(f"  Server: {KEYCLOAK_SERVER_URL}")
    print(f"  Realm: {KEYCLOAK_REALM}")
    print(f"  Client ID: {KEYCLOAK_CLIENT_ID}")
    print(f"  Config URL: {config_url}")
    
    # Create OIDC provider for Keycloak
    auth = OIDCProvider(
        config_url=config_url,
        client_id=KEYCLOAK_CLIENT_ID,
        client_secret=KEYCLOAK_CLIENT_SECRET,
        base_url=BASE_URL,
        required_scopes=SUPPORTED_SCOPES,
    )
    
    return auth


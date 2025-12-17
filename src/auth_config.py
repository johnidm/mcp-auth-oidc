"""Auth0 configuration using FastMCP's OIDCProxy."""

import os
from fastmcp.server.auth.providers.auth0 import Auth0Provider


# Auth0 configuration from environment variables
AUTH0_DOMAIN = os.getenv("AUTH0_DOMAIN", "dev-zilqiezmsk6ylig2.us.auth0.com")
AUTH0_CLIENT_ID = os.getenv("AUTH0_CLIENT_ID")
AUTH0_CLIENT_SECRET = os.getenv("AUTH0_CLIENT_SECRET")
AUTH0_AUDIENCE = os.getenv("AUTH0_AUDIENCE")
BASE_URL = os.getenv("RESOURCE_ID", "http://localhost:8000")

# Define supported scopes for this MCP server
SUPPORTED_SCOPES = [
    "read:notes",
    "write:notes",
    "use:calculator",
]


def create_auth_provider() -> Auth0Provider:
    """
    Create Auth0 authentication provider using FastMCP's OIDC Proxy.
    
    This uses FastMCP's built-in Auth0Provider which handles:
    - OIDC discovery
    - Dynamic Client Registration (DCR) proxy
    - Token validation
    - OAuth flow management
    
    Returns:
        Auth0Provider: Configured Auth0 authentication provider
    """
    if not all([AUTH0_CLIENT_ID, AUTH0_CLIENT_SECRET, AUTH0_AUDIENCE]):
        raise ValueError(
            "Missing required Auth0 configuration. "
            "Please set AUTH0_CLIENT_ID, AUTH0_CLIENT_SECRET, and AUTH0_AUDIENCE in .env"
        )
    
    # Create Auth0 provider with OIDC configuration
    auth = Auth0Provider(
        config_url=f"https://{AUTH0_DOMAIN}/.well-known/openid-configuration",
        client_id=AUTH0_CLIENT_ID,
        client_secret=AUTH0_CLIENT_SECRET,
        audience=AUTH0_AUDIENCE,
        base_url=BASE_URL,
        required_scopes=SUPPORTED_SCOPES,
    )
    
    return auth


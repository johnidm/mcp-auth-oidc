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
    "openid",           # Standard OIDC scope
    "profile",          # Standard OIDC scope for user profile
    "email",            # Standard OIDC scope for email
    "claudeai",         # Custom scope for Claude AI
    "read:notes",       # Custom scope for reading notes
    "write:notes",      # Custom scope for writing notes
    "use:calculator",   # Custom scope for calculator
]


def create_auth_provider() -> RemoteAuthProvider:
    """
    Create Keycloak authentication provider using FastMCP's JWT verification.
    
    Since FastMCP only provides Auth0Provider as a high-level provider,
    for Keycloak we use the lower-level JWTVerifier + RemoteAuthProvider.
    
    This configuration:
    - Validates JWT tokens from Keycloak using JWKS
    - Verifies issuer, audience, and algorithm
    - Checks required scopes
    - Works with Keycloak's standard OAuth 2.0 / OIDC implementation
    
    Returns:
        RemoteAuthProvider: Configured authentication provider for Keycloak
    
    Raises:
        ValueError: If required configuration is missing
    """
    if not KEYCLOAK_CLIENT_ID:
        raise ValueError(
            "Missing required Keycloak configuration. "
            "Please set KEYCLOAK_CLIENT_ID in .env"
        )
    
    print("🔐 Configuring Keycloak authentication:")
    print(f"   Issuer: {KEYCLOAK_ISSUER}")
    print(f"   JWKS URI: {KEYCLOAK_JWKS_URI}")
    print(f"   Audience: {KEYCLOAK_AUDIENCE}")
    print(f"   Scopes: {', '.join(SUPPORTED_SCOPES)}")
    
    # Create JWT verifier for Keycloak tokens
    # Note: audience can be a string or list. If the token has ["mcp-server", "account"],
    # JWTVerifier will accept it as long as our audience is in the list
    verifier = JWTVerifier(
        jwks_uri=KEYCLOAK_JWKS_URI,
        issuer=KEYCLOAK_ISSUER,
        audience=KEYCLOAK_AUDIENCE,  # Will match if "mcp-server" is in the token's audience array
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


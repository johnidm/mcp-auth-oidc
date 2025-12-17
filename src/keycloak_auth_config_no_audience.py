"""Keycloak configuration WITHOUT audience validation (for testing)."""

import os
from fastmcp.server.auth.providers.jwt import JWTVerifier
from fastmcp.server.auth import RemoteAuthProvider


# Keycloak configuration from environment variables
KEYCLOAK_REALM = os.getenv("KEYCLOAK_REALM", "mcp-demo")
KEYCLOAK_BASE_URL = os.getenv("KEYCLOAK_BASE_URL", "http://localhost:8080")
KEYCLOAK_CLIENT_ID = os.getenv("KEYCLOAK_CLIENT_ID")
KEYCLOAK_CLIENT_SECRET = os.getenv("KEYCLOAK_CLIENT_SECRET")
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
    Create Keycloak authentication provider WITHOUT audience validation.
    
    Use this for testing if you're having audience mismatch issues.
    """
    if not KEYCLOAK_CLIENT_ID:
        raise ValueError(
            "Missing required Keycloak configuration. "
            "Please set KEYCLOAK_CLIENT_ID in .env"
        )
    
    print("🔐 Configuring Keycloak authentication (NO audience validation):")
    print(f"   Issuer: {KEYCLOAK_ISSUER}")
    print(f"   JWKS URI: {KEYCLOAK_JWKS_URI}")
    print(f"   Audience: DISABLED (for testing)")
    print(f"   Scopes: {', '.join(SUPPORTED_SCOPES)}")
    print()
    print("⚠️  WARNING: Audience validation is disabled!")
    print("   This is OK for testing but should be fixed for production.")
    print()
    
    # Create JWT verifier WITHOUT audience validation
    verifier = JWTVerifier(
        jwks_uri=KEYCLOAK_JWKS_URI,
        issuer=KEYCLOAK_ISSUER,
        # audience=None,  # Skip audience validation
        algorithm="RS256",
        required_scopes=SUPPORTED_SCOPES,
    )
    
    # Create remote auth provider with the JWT verifier
    auth = RemoteAuthProvider(
        token_verifier=verifier,
        authorization_servers=[BASE_URL],
        base_url=BASE_URL,
    )
    
    return auth


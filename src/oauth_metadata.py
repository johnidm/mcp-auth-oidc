"""OAuth Authorization Server Metadata for Keycloak integration.

This module provides OAuth discovery endpoints that redirect clients
to Keycloak for authentication while keeping token validation in the MCP server.
"""

import os
from typing import Dict, Any


def get_oauth_metadata() -> Dict[str, Any]:
    """
    Generate OAuth Authorization Server Metadata.
    
    This metadata tells OAuth clients (like MCP Inspector) where to find
    Keycloak's OAuth endpoints for authentication.
    
    Returns:
        OAuth metadata dictionary following RFC 8414
    """
    keycloak_realm = os.getenv("KEYCLOAK_REALM", "mcp-demo")
    keycloak_base_url = os.getenv("KEYCLOAK_BASE_URL", "http://localhost:8080")
    keycloak_client_id = os.getenv("KEYCLOAK_CLIENT_ID", "mcp-server")
    base_url = os.getenv("RESOURCE_ID", "http://localhost:8000")
    
    # Keycloak realm URL
    realm_url = f"{keycloak_base_url}/realms/{keycloak_realm}"
    
    # OAuth endpoints point to Keycloak
    metadata = {
        "issuer": realm_url,
        "authorization_endpoint": f"{realm_url}/protocol/openid-connect/auth",
        "token_endpoint": f"{realm_url}/protocol/openid-connect/token",
        "token_endpoint_auth_methods_supported": [
            "client_secret_basic",
            "client_secret_post",
            "private_key_jwt",
            "client_secret_jwt"
        ],
        "jwks_uri": f"{realm_url}/protocol/openid-connect/certs",
        "response_types_supported": [
            "code",
            "none",
            "id_token",
            "token",
            "id_token token",
            "code id_token",
            "code token",
            "code id_token token"
        ],
        "grant_types_supported": [
            "authorization_code",
            "implicit",
            "refresh_token",
            "password",
            "client_credentials"
        ],
        "subject_types_supported": ["public", "pairwise"],
        "id_token_signing_alg_values_supported": [
            "PS384", "ES384", "RS384", "HS256", "HS512",
            "ES256", "RS256", "HS384", "ES512", "PS256", "PS512", "RS512"
        ],
        "userinfo_endpoint": f"{realm_url}/protocol/openid-connect/userinfo",
        "revocation_endpoint": f"{realm_url}/protocol/openid-connect/revoke",
        "introspection_endpoint": f"{realm_url}/protocol/openid-connect/token/introspect",
        "end_session_endpoint": f"{realm_url}/protocol/openid-connect/logout",
        "frontchannel_logout_supported": True,
        "frontchannel_logout_session_supported": True,
        "backchannel_logout_supported": True,
        "backchannel_logout_session_supported": True,
        "scopes_supported": [
            "openid",
            "profile",
            "email",
            "read:notes",
            "write:notes",
            "use:calculator",
            "offline_access"
        ],
        "claims_supported": [
            "aud",
            "sub",
            "iss",
            "auth_time",
            "name",
            "given_name",
            "family_name",
            "preferred_username",
            "email",
            "acr"
        ],
        "code_challenge_methods_supported": ["plain", "S256"],
        "request_parameter_supported": True,
        "request_uri_parameter_supported": True,
        "require_request_uri_registration": True,
    }
    
    return metadata


def get_openid_configuration() -> Dict[str, Any]:
    """
    Generate OpenID Connect Discovery metadata.
    
    This is similar to OAuth metadata but includes OIDC-specific endpoints.
    
    Returns:
        OIDC configuration dictionary following OpenID Connect Discovery 1.0
    """
    # OpenID Connect configuration is essentially the same as OAuth metadata
    # but may include additional OIDC-specific fields
    return get_oauth_metadata()


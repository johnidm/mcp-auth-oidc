"""OAuth and OIDC discovery endpoints for Keycloak integration.

These endpoints allow OAuth clients (like MCP Inspector) to discover
authentication configuration and register as clients.
"""

import os
import secrets
from typing import Dict, Any
from starlette.applications import Starlette
from starlette.responses import JSONResponse
from starlette.routing import Route
from starlette.middleware.cors import CORSMiddleware


# Keycloak configuration
def get_keycloak_config():
    """Get Keycloak configuration from environment."""
    return {
        'realm': os.getenv('KEYCLOAK_REALM', 'mcp-demo'),
        'base_url': os.getenv('KEYCLOAK_BASE_URL', 'http://localhost:8080'),
        'client_id': os.getenv('KEYCLOAK_CLIENT_ID', 'mcp-server'),
        'client_secret': os.getenv('KEYCLOAK_CLIENT_SECRET'),
        'audience': os.getenv('KEYCLOAK_AUDIENCE', 'mcp-server'),
        'server_url': os.getenv('RESOURCE_ID', 'http://localhost:8000'),
    }


async def oauth_authorization_server(request):
    """
    OAuth 2.0 Authorization Server Metadata (RFC 8414).
    
    Returns metadata that points to Keycloak's OAuth endpoints.
    """
    config = get_keycloak_config()
    realm_url = f"{config['base_url']}/realms/{config['realm']}"
    
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
        "registration_endpoint": f"{config['server_url']}/register",
        "scopes_supported": [
            "openid",
            "profile",
            "email",
            "read:notes",
            "write:notes",
            "use:calculator",
            "offline_access"
        ],
        "response_types_supported": [
            "code",
            "token",
            "id_token",
            "code token",
            "code id_token",
            "token id_token",
            "code token id_token"
        ],
        "response_modes_supported": ["query", "fragment", "form_post"],
        "grant_types_supported": [
            "authorization_code",
            "implicit",
            "refresh_token",
            "password",
            "client_credentials"
        ],
        "subject_types_supported": ["public", "pairwise"],
        "id_token_signing_alg_values_supported": [
            "RS256", "RS384", "RS512", "ES256", "ES384", "ES512",
            "HS256", "HS384", "HS512", "PS256", "PS384", "PS512"
        ],
        "userinfo_endpoint": f"{realm_url}/protocol/openid-connect/userinfo",
        "revocation_endpoint": f"{realm_url}/protocol/openid-connect/revoke",
        "introspection_endpoint": f"{realm_url}/protocol/openid-connect/token/introspect",
        "end_session_endpoint": f"{realm_url}/protocol/openid-connect/logout",
        "code_challenge_methods_supported": ["plain", "S256"],
        "introspection_endpoint_auth_methods_supported": [
            "client_secret_basic",
            "client_secret_post"
        ],
        "revocation_endpoint_auth_methods_supported": [
            "client_secret_basic",
            "client_secret_post"
        ],
    }
    
    return JSONResponse(metadata)


async def openid_configuration(request):
    """
    OpenID Connect Discovery (OpenID Connect Discovery 1.0).
    
    Returns the same metadata as OAuth authorization server.
    """
    return await oauth_authorization_server(request)


async def register_client(request):
    """
    Dynamic Client Registration (RFC 7591).
    
    Since we're using a pre-configured Keycloak client, this endpoint
    returns the existing client configuration instead of creating a new one.
    
    This allows OAuth clients to "register" and get our client credentials.
    """
    config = get_keycloak_config()
    realm_url = f"{config['base_url']}/realms/{config['realm']}"
    
    # Handle OPTIONS for CORS
    if request.method == "OPTIONS":
        return JSONResponse(
            {},
            status_code=204,
            headers={
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "POST, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type, Authorization",
                "Access-Control-Max-Age": "86400",
            }
        )
    
    # Parse registration request
    try:
        body = await request.json()
    except Exception:
        body = {}
    
    redirect_uris = body.get('redirect_uris', [])
    
    # Return our pre-configured Keycloak client
    # Note: In a real DCR implementation, you'd create a new client in Keycloak
    client_response = {
        "client_id": config['client_id'],
        "client_secret": config['client_secret'],
        "client_id_issued_at": 1234567890,  # Unix timestamp
        "client_secret_expires_at": 0,  # 0 means never expires
        "redirect_uris": redirect_uris if redirect_uris else [
            f"{config['server_url']}/auth/callback",
            "http://localhost:6274/oauth/callback",
        ],
        "token_endpoint_auth_method": "client_secret_post",
        "grant_types": [
            "authorization_code",
            "refresh_token"
        ],
        "response_types": ["code"],
        "client_name": body.get('client_name', 'MCP Client'),
        "scope": "openid profile email read:notes write:notes use:calculator",
        "authorization_endpoint": f"{realm_url}/protocol/openid-connect/auth",
        "token_endpoint": f"{realm_url}/protocol/openid-connect/token",
        "userinfo_endpoint": f"{realm_url}/protocol/openid-connect/userinfo",
        "jwks_uri": f"{realm_url}/protocol/openid-connect/certs",
        "issuer": realm_url,
    }
    
    return JSONResponse(client_response, status_code=201)


def create_oauth_app():
    """
    Create a Starlette app with OAuth discovery endpoints.
    
    This app provides the endpoints that OAuth clients expect to find.
    """
    routes = [
        Route('/.well-known/oauth-authorization-server', oauth_authorization_server),
        Route('/.well-known/openid-configuration', openid_configuration),
        Route('/register', register_client, methods=['POST', 'OPTIONS']),
    ]
    
    app = Starlette(routes=routes)
    
    # Add CORS middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    return app


"""ASGI application wrapper that combines FastMCP with OAuth discovery endpoints."""

import os
from starlette.requests import Request
from src.oauth_endpoints import (
    oauth_authorization_server,
    openid_configuration,
    register_client
)


def create_app_with_oauth(mcp_instance):
    """
    Wrap FastMCP app with OAuth discovery endpoints.
    
    This creates a custom ASGI app that handles OAuth discovery endpoints
    and forwards everything else to FastMCP.
    
    Args:
        mcp_instance: The FastMCP instance
        
    Returns:
        ASGI application with OAuth endpoints + MCP
    """
    # Check if using Keycloak
    keycloak_realm = os.getenv("KEYCLOAK_REALM")
    
    if not keycloak_realm:
        # If not using Keycloak, get FastMCP's ASGI app
        return mcp_instance._create_asgi_app() if hasattr(mcp_instance, '_create_asgi_app') else mcp_instance
    
    # Get FastMCP's HTTP ASGI app
    if hasattr(mcp_instance, 'http_app'):
        # FastMCP exposes http_app attribute
        mcp_asgi_app = mcp_instance.http_app
    else:
        raise RuntimeError("FastMCP instance does not have http_app attribute")
    
    # Create custom ASGI app that routes OAuth endpoints and forwards the rest
    async def combined_app(scope, receive, send):
        """Combined ASGI app that handles OAuth discovery and MCP."""
        if scope['type'] != 'http':
            # Forward non-HTTP requests directly to FastMCP
            return await mcp_asgi_app(scope, receive, send)
        
        path = scope.get('path', '')
        method = scope.get('method', 'GET')
        
        # Route OAuth discovery endpoints
        if path == '/.well-known/oauth-authorization-server':
            request = Request(scope, receive)
            response = await oauth_authorization_server(request)
            await response(scope, receive, send)
            return
        
        elif path == '/.well-known/openid-configuration':
            request = Request(scope, receive)
            response = await openid_configuration(request)
            await response(scope, receive, send)
            return
        
        elif path == '/register' and method in ['POST', 'OPTIONS']:
            request = Request(scope, receive)
            response = await register_client(request)
            await response(scope, receive, send)
            return
        
        # Forward everything else to FastMCP
        return await mcp_asgi_app(scope, receive, send)
    
    return combined_app


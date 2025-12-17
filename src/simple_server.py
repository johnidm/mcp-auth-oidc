"""Alternative server implementation with OAuth endpoints."""

import os
from starlette.applications import Starlette
from starlette.routing import Route
from starlette.middleware.cors import CORSMiddleware
from starlette.responses import JSONResponse, Response
from src.oauth_endpoints import (
    oauth_authorization_server,
    openid_configuration,
    register_client
)


def run_with_oauth(mcp_instance, host="0.0.0.0", port=8000):
    """
    Run MCP server with OAuth endpoints using a dual-server approach.
    
    This creates a wrapper that handles OAuth discovery endpoints
    and proxies MCP requests to the FastMCP instance.
    """
    import uvicorn
    import httpx
    from starlette.requests import Request
    
    # Start FastMCP server in background on a different port
    mcp_port = port + 1
    
    # Create OAuth wrapper app
    async def proxy_to_mcp(request: Request):
        """Proxy requests to FastMCP server."""
        async with httpx.AsyncClient() as client:
            url = f"http://localhost:{mcp_port}{request.url.path}"
            response = await client.request(
                method=request.method,
                url=url,
                headers=dict(request.headers),
                content=await request.body() if request.method in ['POST', 'PUT', 'PATCH'] else None,
            )
            return Response(
                content=response.content,
                status_code=response.status_code,
                headers=dict(response.headers),
            )
    
    routes = [
        Route('/.well-known/oauth-authorization-server', oauth_authorization_server),
        Route('/.well-known/openid-configuration', openid_configuration),
        Route('/register', register_client, methods=['POST', 'OPTIONS']),
        Route('/{path:path}', proxy_to_mcp, methods=['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']),
    ]
    
    app = Starlette(routes=routes)
    
    # Add CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    # Start FastMCP in background
    import threading
    def run_mcp():
        mcp_instance.run(transport="http", host="127.0.0.1", port=mcp_port)
    
    mcp_thread = threading.Thread(target=run_mcp, daemon=True)
    mcp_thread.start()
    
    # Wait a bit for FastMCP to start
    import time
    time.sleep(2)
    
    print(f"✅ OAuth proxy server starting on {host}:{port}")
    print(f"   Proxying to FastMCP on 127.0.0.1:{mcp_port}")
    print()
    
    # Run OAuth wrapper server
    uvicorn.run(app, host=host, port=port, log_level="info")


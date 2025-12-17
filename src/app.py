"""Application entry point using FastMCP's built-in HTTP server with authentication."""

from src.server import mcp

# FastMCP handles all the routing, authentication, and SSE automatically
# The auth provider configured in server.py provides:
# - OAuth 2.0 / OIDC authentication
# - Dynamic Client Registration (DCR) proxy
# - Token validation
# - Automatic consent flow

# Simply export the mcp instance - it has everything built-in
app = mcp

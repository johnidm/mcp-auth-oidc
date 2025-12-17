"""Main entry point for the MCP Auth Demo Server."""

import os
import sys
from dotenv import load_dotenv

# Load environment variables FIRST, before any imports that need them
load_dotenv()


def main():
    """
    Main entry point for the server.
    
    This function:
    1. Loads environment variables from .env file (already done above)
    2. Validates required configuration
    3. Starts the FastMCP server with built-in HTTP/SSE transport
    """
    
    # Get server configuration from environment
    host = os.getenv("SERVER_HOST", "0.0.0.0")
    port = int(os.getenv("SERVER_PORT", "8000"))
    base_url = os.getenv("RESOURCE_ID", "http://localhost:8000")
    
    print("=" * 60)
    print("MCP Auth Demo Server (FastMCP + OIDC Proxy)")
    print("=" * 60)
    print(f"Base URL: {base_url}")
    print(f"Auth0 Domain: {os.getenv('AUTH0_DOMAIN')}")
    print(f"Server: http://{host}:{port}")
    print(f"Auth Callback: {base_url}/auth/callback")
    print("=" * 60)
    print()
    print("Starting server with FastMCP's built-in HTTP/SSE transport...")
    print()
    
    # Import and run the FastMCP server
    # FastMCP handles all routing, auth, and SSE automatically
    from src.server import mcp
    
    mcp.run(
        transport="http",
        host=host,
        port=port,
    )


if __name__ == "__main__":
    main()


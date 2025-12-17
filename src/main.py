"""Main entry point for the MCP Auth Demo Server."""

import os
from dotenv import load_dotenv

# Load environment variables FIRST, before any imports that need them
load_dotenv()


def main():
    """
    Main entry point for the server.
    
    This function:
    1. Loads environment variables from .env file (already done above)
    2. Validates required configuration
    3. Adds OAuth discovery endpoints
    4. Starts the FastMCP server with built-in HTTP/SSE transport
    """
    
    # Get server configuration from environment
    host = os.getenv("SERVER_HOST", "0.0.0.0")
    port = int(os.getenv("SERVER_PORT", "8000"))
    base_url = os.getenv("RESOURCE_ID", "http://localhost:8000")
    
    # Check if using Keycloak
    keycloak_realm = os.getenv("KEYCLOAK_REALM")
    auth_provider = "Keycloak" if keycloak_realm else "Auth0"
    
    print("=" * 60)
    print("MCP Auth Demo Server (FastMCP + OAuth)")
    print("=" * 60)
    print(f"Base URL: {base_url}")
    print(f"Auth Provider: {auth_provider}")
    if keycloak_realm:
        print(f"Keycloak Realm: {keycloak_realm}")
        print(f"Keycloak: {os.getenv('KEYCLOAK_BASE_URL')}")
    else:
        print(f"Auth0 Domain: {os.getenv('AUTH0_DOMAIN')}")
    print(f"Server: http://{host}:{port}")
    print(f"Auth Callback: {base_url}/auth/callback")
    print("=" * 60)
    print()
    
    # Add OAuth discovery endpoints if using Keycloak
    if keycloak_realm:
        print("📝 OAuth Discovery Endpoints:")
        print("   ✓ /.well-known/oauth-authorization-server")
        print("   ✓ /.well-known/openid-configuration")
        print("   ✓ /register (Dynamic Client Registration)")
        print()
    
    print("Starting server with FastMCP's built-in HTTP/SSE transport...")
    print()
    
    # Import FastMCP server (OAuth endpoints are added via custom_route if using Keycloak)
    from src.server import mcp
    
    if keycloak_realm:
        print("✅ OAuth endpoints added via FastMCP custom routes")
        print()
    
    # Run FastMCP normally (it includes our custom OAuth routes)
    mcp.run(
        transport="http",
        host=host,
        port=port,
    )


if __name__ == "__main__":
    main()


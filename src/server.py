"""FastMCP server with demo tools (calculator and notes)."""

import os
from datetime import datetime
from typing import Dict, List, Optional
from fastmcp import FastMCP
from starlette.requests import Request
from starlette.responses import JSONResponse
from src.keycloak_auth_config import create_auth_provider


# Create authentication provider
auth = create_auth_provider()

# Initialize FastMCP server with authentication
mcp = FastMCP(
    name="MCP Do John",
    version="0.1.0",
    auth=auth
)

# Add OAuth discovery endpoints if using Keycloak
if os.getenv("KEYCLOAK_REALM"):
    from src.oauth_endpoints import (
        oauth_authorization_server,
        openid_configuration,
        register_client
    )
    
    @mcp.custom_route("/.well-known/oauth-authorization-server", methods=["GET"])
    async def oauth_server_metadata(request: Request):
        """OAuth 2.0 Authorization Server Metadata."""
        return await oauth_authorization_server(request)
    
    @mcp.custom_route("/.well-known/openid-configuration", methods=["GET"])
    async def oidc_configuration(request: Request):
        """OpenID Connect Discovery."""
        return await openid_configuration(request)
    
    @mcp.custom_route("/register", methods=["POST", "OPTIONS"])
    async def client_registration(request: Request):
        """Dynamic Client Registration."""
        return await register_client(request)

# In-memory storage for notes (demo purposes only)
notes_storage: Dict[str, Dict] = {}
note_id_counter = 0


# ========================================
# Calculator Tools (requires use:calculator scope)
# ========================================

@mcp.tool()
def add_numbers(a: float, b: float) -> float:
    """
    Add two numbers together.
    
    Args:
        a: First number
        b: Second number
    
    Returns:
        The sum of a and b
    
    Requires:
        Scope: use:calculator
    """
    # Note: Authentication is handled automatically by FastMCP
    # Access to auth info available via request context if needed
    result = a + b
    return result


@mcp.tool()
def subtract_numbers(a: float, b: float) -> float:
    """
    Subtract b from a.
    
    Args:
        a: Number to subtract from
        b: Number to subtract
    
    Returns:
        The difference of a - b
    
    Requires:
        Scope: use:calculator
    """
    result = a - b
    return result


@mcp.tool()
def multiply_numbers(a: float, b: float) -> float:
    """
    Multiply two numbers together.
    
    Args:
        a: First number
        b: Second number
    
    Returns:
        The product of a and b
    
    Requires:
        Scope: use:calculator
    """
    result = a * b
    return result


@mcp.tool()
def divide_numbers(a: float, b: float) -> float:
    """
    Divide a by b.
    
    Args:
        a: Numerator
        b: Denominator
    
    Returns:
        The quotient of a / b
    
    Raises:
        ValueError: If b is zero
    
    Requires:
        Scope: use:calculator
    """
    if b == 0:
        raise ValueError("Cannot divide by zero")
    
    result = a / b
    return result


# ========================================
# Notes Tools (requires read:notes or write:notes scope)
# ========================================

@mcp.tool()
def create_note(title: str, content: str) -> Dict:
    """
    Create a new note.
    
    Args:
        title: The title of the note
        content: The content of the note
    
    Returns:
        Dictionary containing the created note details
    
    Requires:
        Scope: write:notes
    """
    global note_id_counter
    
    note_id_counter += 1
    note_id = f"note_{note_id_counter}"
    
    note = {
        "id": note_id,
        "title": title,
        "content": content,
        "author": "authenticated_user",  # Auth info available via FastMCP context
        "created_at": datetime.utcnow().isoformat(),
        "updated_at": datetime.utcnow().isoformat(),
    }
    
    notes_storage[note_id] = note
    
    return note


@mcp.tool()
def read_note(note_id: str) -> Optional[Dict]:
    """
    Read a specific note by its ID.
    
    Args:
        note_id: The ID of the note to read
    
    Returns:
        Dictionary containing the note details, or None if not found
    
    Requires:
        Scope: read:notes
    """
    note = notes_storage.get(note_id)
    
    if note is None:
        return {"error": f"Note with ID '{note_id}' not found"}
    
    return note


@mcp.tool()
def list_notes() -> List[Dict]:
    """
    List all notes.
    
    Returns:
        List of all notes with their details
    
    Requires:
        Scope: read:notes
    """
    return list(notes_storage.values())


@mcp.tool()
def update_note(note_id: str, title: Optional[str] = None, content: Optional[str] = None) -> Dict:
    """
    Update an existing note.
    
    Args:
        note_id: The ID of the note to update
        title: New title (optional)
        content: New content (optional)
    
    Returns:
        Dictionary containing the updated note details
    
    Requires:
        Scope: write:notes
    """
    note = notes_storage.get(note_id)
    
    if note is None:
        return {"error": f"Note with ID '{note_id}' not found"}
    
    if title is not None:
        note["title"] = title
    
    if content is not None:
        note["content"] = content
    
    note["updated_at"] = datetime.utcnow().isoformat()
    
    return note


@mcp.tool()
def delete_note(note_id: str) -> Dict:
    """
    Delete a note by its ID.
    
    Args:
        note_id: The ID of the note to delete
    
    Returns:
        Dictionary confirming the deletion
    
    Requires:
        Scope: write:notes
    """
    note = notes_storage.pop(note_id, None)
    
    if note is None:
        return {"error": f"Note with ID '{note_id}' not found"}
    
    return {
        "message": f"Note '{note_id}' deleted successfully",
        "deleted_note": note
    }


# Export the FastMCP instance
__all__ = ["mcp"]


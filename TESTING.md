# Testing Guide

This guide provides detailed instructions for testing your MCP server with OAuth authentication.

## Quick Start Testing

### 1. Start the Server

```bash
python run.py
```

### 2. Verify Server is Running

```bash
curl http://localhost:8000/health
```

Expected output:
```json
{
  "status": "healthy",
  "server": "MCP Auth Demo"
}
```

### 3. Check Protected Resource Metadata

```bash
curl http://localhost:8000/.well-known/oauth-protected-resource | jq
```

This should return metadata about the OAuth configuration, including:
- Authorization servers
- Supported scopes
- Resource identifier

## Getting an Access Token

### Option 1: Client Credentials Flow (For Testing)

Use this method for direct API testing:

```bash
curl --request POST \
  --url https://dev-zilqiezmsk6ylig2.us.auth0.com/oauth/token \
  --header 'content-type: application/json' \
  --data '{
    "client_id": "GsJfBMVGn5cDgWQwTiq91SIQBYxQccJA",
    "client_secret": "Qst5RVD9Vt79F5NgM_s6ymZSvMYemKrFMykWrDOtextPC2nBeK593yBvpJBafIDl",
    "audience": "http://localhost:8000",
    "grant_type": "client_credentials",
    "scope": "read:notes write:notes use:calculator"
  }' | jq
```

Save the `access_token` from the response:

```bash
export ACCESS_TOKEN="your_access_token_here"
```

### Option 2: Via Claude.ai (Production Flow)

Claude.ai will handle the OAuth flow automatically when you connect:

1. Add your server URL in Claude.ai settings
2. Claude.ai performs Dynamic Client Registration with Auth0
3. Complete the authorization flow
4. Claude.ai automatically includes the token in requests

## Testing with Python

Create a test script `test_client.py`:

```python
import asyncio
from fastmcp import Client

async def test_tools():
    """Test the MCP server tools with authentication."""
    
    # You'll need a valid access token from Auth0
    access_token = "your_access_token_here"
    
    async with Client(
        "http://localhost:8000/sse",
        headers={"Authorization": f"Bearer {access_token}"}
    ) as client:
        # Test calculator tool
        result = await client.call_tool(
            name="add_numbers",
            arguments={"a": 5, "b": 3}
        )
        print(f"5 + 3 = {result}")
        
        # Test notes tool
        note = await client.call_tool(
            name="create_note",
            arguments={
                "title": "Test Note",
                "content": "This is a test note created via MCP"
            }
        )
        print(f"Created note: {note}")
        
        # List all notes
        notes = await client.call_tool(name="list_notes", arguments={})
        print(f"All notes: {notes}")

if __name__ == "__main__":
    asyncio.run(test_tools())
```

Run the test:

```bash
python test_client.py
```

## Testing Scope-Based Authorization

### Test with Limited Scopes

Get a token with only `read:notes` scope:

```bash
curl --request POST \
  --url https://dev-zilqiezmsk6ylig2.us.auth0.com/oauth/token \
  --header 'content-type: application/json' \
  --data '{
    "client_id": "GsJfBMVGn5cDgWQwTiq91SIQBYxQccJA",
    "client_secret": "Qst5RVD9Vt79F5NgM_s6ymZSvMYemKrFMykWrDOtextPC2nBeK593yBvpJBafIDl",
    "audience": "http://localhost:8000",
    "grant_type": "client_credentials",
    "scope": "read:notes"
  }' | jq
```

This token should:
- ✅ Allow `list_notes()` and `read_note()`
- ❌ Deny `create_note()`, `update_note()`, `delete_note()`
- ❌ Deny all calculator tools

### Test with All Scopes

Get a token with all scopes:

```bash
curl --request POST \
  --url https://dev-zilqiezmsk6ylig2.us.auth0.com/oauth/token \
  --header 'content-type: application/json' \
  --data '{
    "client_id": "GsJfBMVGn5cDgWQwTiq91SIQBYxQccJA",
    "client_secret": "Qst5RVD9Vt79F5NgM_s6ymZSvMYemKrFMykWrDOtextPC2nBeK593yBvpJBafIDl",
    "audience": "http://localhost:8000",
    "grant_type": "client_credentials",
    "scope": "read:notes write:notes use:calculator"
  }' | jq
```

This token should allow access to all tools.

## Verifying Authentication in Server Logs

When tools are executed, you should see authentication logs like:

```
[AUTH] Calculator tool used by: auth0|1234567890abcdef
[AUTH] Note created by: auth0|1234567890abcdef
```

These logs confirm that:
1. The token was successfully validated
2. The user identity was extracted from the token
3. The tool has access to authentication context

## Testing Error Cases

### 1. Missing Token

Try to access without authentication:

```bash
curl http://localhost:8000/sse
```

Expected: 401 Unauthorized

### 2. Invalid Token

Try with an invalid token:

```bash
curl -H "Authorization: Bearer invalid_token" http://localhost:8000/sse
```

Expected: 401 Unauthorized or 403 Forbidden

### 3. Expired Token

Tokens expire after a certain time (configured in Auth0). Test with an old token to verify expiration handling.

### 4. Wrong Audience

Get a token with a different audience and try to use it. Should be rejected.

## Automated Testing

Create a test suite using pytest:

```python
# tests/test_auth.py
import pytest
import asyncio
from fastmcp import Client

@pytest.fixture
def access_token():
    """Get a valid access token for testing."""
    # Implementation to fetch token from Auth0
    pass

@pytest.mark.asyncio
async def test_calculator_with_auth(access_token):
    """Test calculator tools with valid authentication."""
    async with Client(
        "http://localhost:8000/sse",
        headers={"Authorization": f"Bearer {access_token}"}
    ) as client:
        result = await client.call_tool("add_numbers", {"a": 2, "b": 3})
        assert result == 5

@pytest.mark.asyncio
async def test_notes_crud(access_token):
    """Test full CRUD operations on notes."""
    async with Client(
        "http://localhost:8000/sse",
        headers={"Authorization": f"Bearer {access_token}"}
    ) as client:
        # Create
        note = await client.call_tool("create_note", {
            "title": "Test",
            "content": "Content"
        })
        assert note["title"] == "Test"
        
        note_id = note["id"]
        
        # Read
        fetched = await client.call_tool("read_note", {"note_id": note_id})
        assert fetched["id"] == note_id
        
        # Update
        updated = await client.call_tool("update_note", {
            "note_id": note_id,
            "title": "Updated"
        })
        assert updated["title"] == "Updated"
        
        # Delete
        deleted = await client.call_tool("delete_note", {"note_id": note_id})
        assert "deleted_note" in deleted
```

Run tests:

```bash
pip install pytest pytest-asyncio
pytest tests/
```

## Load Testing

Use tools like `locust` or `ab` (Apache Bench) to test server performance:

```bash
# Install Apache Bench (usually pre-installed on macOS/Linux)
ab -n 1000 -c 10 -H "Authorization: Bearer $ACCESS_TOKEN" http://localhost:8000/health
```

## Monitoring

Watch server logs in real-time:

```bash
python run.py 2>&1 | tee server.log
```

Check for:
- Authentication success/failures
- Tool execution logs
- Error messages
- Performance metrics

## Common Issues

### Issue: Token validation fails

**Solution**: 
- Verify the `audience` in the token matches `RESOURCE_ID`
- Check Auth0 configuration
- Ensure token hasn't expired

### Issue: Scope errors

**Solution**:
- Verify scopes are configured in Auth0
- Check that token includes required scopes
- Review scope validation in tool handlers

### Issue: CORS errors

**Solution**:
- Check CORS middleware configuration in `src/app.py`
- Add specific origins instead of `*` for production
- Verify browser console for CORS error details

## Next Steps

After successful testing:

1. Deploy to production environment
2. Configure production Auth0 application
3. Update `RESOURCE_ID` to production URL
4. Enable HTTPS
5. Restrict CORS origins
6. Set up monitoring and logging
7. Configure rate limiting


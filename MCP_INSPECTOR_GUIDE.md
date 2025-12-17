# Testing OAuth Flow with MCP Inspector

This guide shows you how to test your OAuth-enabled MCP server using the MCP Inspector tool.

## What is MCP Inspector?

MCP Inspector is an interactive developer tool for testing and debugging MCP servers. It provides a web-based UI to:
- Connect to MCP servers
- Test authentication flows (including OAuth)
- Call tools interactively
- View resources and prompts
- Debug server responses

## Prerequisites

- Node.js 18+ installed
- Your MCP server running on `http://localhost:8000`
- Auth0 credentials configured in `.env`

## Installation

### Option 1: Use npx (Recommended - No Installation)

```bash
npx @modelcontextprotocol/inspector
```

### Option 2: Global Installation

```bash
npm install -g @modelcontextprotocol/inspector
mcp-inspector
```

The Inspector will automatically open in your browser at `http://localhost:6274`

## Step-by-Step Testing Guide

### Step 1: Start Your MCP Server

First, ensure your server is running:

```bash
# Terminal 1
cd /Users/johnimarangon/Projects/mcp-auth-oidcO
python run.py
```

You should see:
```
============================================================
MCP Auth Demo Server (FastMCP + OIDC Proxy)
============================================================
Base URL: http://localhost:8000
Auth0 Domain: dev-zilqiezmsk6ylig2.us.auth0.com
Server: http://0.0.0.0:8000
Auth Callback: http://localhost:8000/auth/callback
============================================================

Starting server with FastMCP's built-in HTTP/SSE transport...
```

### Step 2: Launch MCP Inspector

In a new terminal:

```bash
# Terminal 2
npx @modelcontextprotocol/inspector
```

This will:
1. Start the MCP Inspector server on port 6274
2. Open your browser automatically to `http://localhost:6274`

### Step 3: Configure Connection in Inspector

In the MCP Inspector web interface, you'll see a connection configuration form:

#### 3.1: Select Transport Type

- Choose **"HTTP with SSE"** or **"Streamable HTTP"** as the transport type

#### 3.2: Enter Server URL

- **Server URL**: `http://localhost:8000/mcp`
  - Alternative: `http://localhost:8000/sse` (try both if one doesn't work)
  - FastMCP typically uses `/mcp` as the default endpoint

#### 3.3: Configure OAuth Authentication

Click on the **Authentication** section and configure:

**OAuth Settings:**
- **Client ID**: Leave empty (will be dynamically registered)
- **Redirect URL**: `http://localhost:6274/oauth/callback`
  - This is MCP Inspector's callback URL
  - **Important**: Add this to your Auth0 application's allowed redirect URIs!
- **Scopes**: 
  ```
  read:notes write:notes use:calculator
  ```
  - Or: `openid profile email read:notes write:notes use:calculator`

### Step 4: Update Auth0 Configuration

**Critical Step**: Add Inspector's callback to Auth0!

1. Go to [Auth0 Dashboard](https://manage.auth0.com/)
2. Navigate to your application
3. Find **Allowed Callback URLs**
4. Add: `http://localhost:6274/oauth/callback`
5. Also add: `http://localhost:8000/auth/callback` (for your server)
6. Save changes

Your Auth0 callback URLs should now include:
```
http://localhost:8000/auth/callback,
http://localhost:6274/oauth/callback
```

### Step 5: Connect and Authenticate

1. Click **"Connect"** button in MCP Inspector
2. Inspector will initiate the OAuth flow:
   - **Discovery**: Inspector discovers your server's OAuth configuration
   - **Authorization Request**: Redirects to Auth0
   - **Login**: You'll see Auth0's login page
   - **Consent**: Approve the requested scopes
   - **Callback**: Redirected back to Inspector
   - **Connected**: Inspector shows "Connected ✅"

### Step 6: Verify Connection

Once connected, you should see:

**Server Information:**
```
Name: MCP Auth Demo Server
Version: 0.1.0
Status: Connected ✅
```

**Available Tools (9 total):**
- ✅ `add_numbers` - Add two numbers
- ✅ `subtract_numbers` - Subtract two numbers
- ✅ `multiply_numbers` - Multiply two numbers
- ✅ `divide_numbers` - Divide two numbers
- ✅ `create_note` - Create a new note
- ✅ `read_note` - Read a specific note
- ✅ `list_notes` - List all notes
- ✅ `update_note` - Update a note
- ✅ `delete_note` - Delete a note

### Step 7: Test Calculator Tools

#### Test 1: Add Numbers

1. Click on `add_numbers` in the tools list
2. Enter parameters in the JSON editor:
   ```json
   {
     "a": 42,
     "b": 13
   }
   ```
3. Click **"Call Tool"**
4. **Expected Result**: `55`

#### Test 2: Multiply Numbers

```json
{
  "a": 7,
  "b": 8
}
```
**Expected Result**: `56`

#### Test 3: Division

```json
{
  "a": 100,
  "b": 4
}
```
**Expected Result**: `25.0`

#### Test 4: Division by Zero (Error Handling)

```json
{
  "a": 10,
  "b": 0
}
```
**Expected Error**: `"Cannot divide by zero"`

### Step 8: Test Notes Tools

#### Test 1: Create a Note

```json
{
  "title": "Test from MCP Inspector",
  "content": "This note was created via MCP Inspector to test OAuth authentication"
}
```

**Expected Result:**
```json
{
  "id": "note_1",
  "title": "Test from MCP Inspector",
  "content": "This note was created via MCP Inspector to test OAuth authentication",
  "author": "authenticated_user",
  "created_at": "2025-01-16T10:30:00.000000",
  "updated_at": "2025-01-16T10:30:00.000000"
}
```

#### Test 2: List All Notes

```json
{}
```

**Expected Result:** Array of all notes

#### Test 3: Read Specific Note

```json
{
  "note_id": "note_1"
}
```

**Expected Result:** The note object

#### Test 4: Update Note

```json
{
  "note_id": "note_1",
  "title": "Updated via Inspector",
  "content": "This content was updated"
}
```

**Expected Result:** Updated note with new `updated_at` timestamp

#### Test 5: Delete Note

```json
{
  "note_id": "note_1"
}
```

**Expected Result:**
```json
{
  "message": "Note 'note_1' deleted successfully",
  "deleted_note": { ... }
}
```

#### Test 6: Read Non-Existent Note (Error Handling)

```json
{
  "note_id": "invalid_note_id"
}
```

**Expected Result:**
```json
{
  "error": "Note with ID 'invalid_note_id' not found"
}
```

## Understanding the OAuth Flow in Inspector

### What Happens Behind the Scenes

1. **Inspector → Your Server**: `GET /mcp` (discover capabilities)
2. **Your Server → Inspector**: Returns server info + auth requirements
3. **Inspector → Your Server**: Initiates OAuth (Dynamic Client Registration)
4. **Your Server (OIDC Proxy) → Auth0**: Proxies the DCR request
5. **Auth0 → Your Server**: Returns client credentials
6. **Your Server → Inspector**: Returns authorization URL
7. **Inspector → Browser**: Redirects to Auth0 login
8. **User → Auth0**: Authenticates and approves scopes
9. **Auth0 → Inspector**: Redirects with authorization code
10. **Inspector → Your Server**: Exchanges code for tokens
11. **Your Server → Auth0**: Validates and exchanges code
12. **Auth0 → Your Server**: Returns access token
13. **Your Server → Inspector**: Returns access token
14. **Inspector**: Stores token and uses for subsequent requests

### Viewing OAuth Details in Inspector

MCP Inspector provides detailed views of:

**Request Details:**
```json
{
  "method": "tools/call",
  "params": {
    "name": "add_numbers",
    "arguments": { "a": 5, "b": 3 }
  }
}
```

**Response Details:**
```json
{
  "result": {
    "content": [
      {
        "type": "text",
        "text": "8"
      }
    ]
  }
}
```

**Authentication Headers:**
```
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

## Testing Different Scenarios

### Scenario 1: Token Expiration

1. Keep Inspector connected
2. Wait for token to expire (default: 1 hour)
3. Try calling a tool
4. Inspector should automatically:
   - Detect 401 Unauthorized
   - Refresh the token
   - Retry the request

### Scenario 2: Insufficient Scopes

1. Modify `src/auth_config.py` to only include `read:notes`
2. Restart your server
3. Reconnect Inspector
4. Try `create_note` - should fail with scope error
5. Try `list_notes` - should succeed

### Scenario 3: Multiple Concurrent Requests

1. Open Inspector's Network tab
2. Call multiple tools rapidly
3. Verify all requests use the same token
4. Check for race conditions

## Debugging with Inspector

### Enable Debug Mode

In Inspector's settings:
- Enable **"Show Raw Messages"**
- Enable **"Log to Console"**
- Open browser DevTools (F12)

### Common Debug Information

**Check Server Logs:**
```bash
# In Terminal 1 (server)
INFO: SSE connection established
INFO: OAuth flow initiated
INFO: Token validated successfully
INFO: Tool called: add_numbers with args: {"a": 5, "b": 3}
INFO: Tool result: 8
```

**Check Inspector Console:**
```javascript
[MCP] Connecting to http://localhost:8000/mcp
[MCP] OAuth flow started
[MCP] Redirecting to authorization URL
[MCP] Authorization code received
[MCP] Token exchange successful
[MCP] Connection established
```

## Common Issues and Solutions

### Issue 1: "Failed to Connect"

**Symptoms:**
- Inspector shows connection error
- No OAuth prompt appears

**Solutions:**
1. ✅ Verify server is running: `curl http://localhost:8000/`
2. ✅ Check correct URL: Try both `/mcp` and `/sse`
3. ✅ Check server logs for errors
4. ✅ Restart both server and Inspector

### Issue 2: "Redirect URI Mismatch"

**Symptoms:**
- OAuth flow starts but fails at callback
- Auth0 shows "Redirect URI mismatch" error

**Solutions:**
1. ✅ Add `http://localhost:6274/oauth/callback` to Auth0
2. ✅ Ensure no trailing slashes
3. ✅ Check for http vs https mismatch
4. ✅ Clear browser cookies and retry

### Issue 3: "Invalid Scopes"

**Symptoms:**
- Connection succeeds
- Tool calls fail with scope errors

**Solutions:**
1. ✅ Configure scopes in Auth0 API settings
2. ✅ Ensure scopes match in Inspector config
3. ✅ Check `src/auth_config.py` SUPPORTED_SCOPES
4. ✅ Re-authenticate to get updated scopes

### Issue 4: "Token Expired"

**Symptoms:**
- Works initially
- Fails after some time
- 401 Unauthorized errors

**Solutions:**
- ✅ Normal behavior - tokens expire
- ✅ Inspector should auto-refresh
- ✅ If not, click "Reconnect"
- ✅ Check refresh token is being used

### Issue 5: CORS Errors

**Symptoms:**
- Browser console shows CORS errors
- Preflight requests fail

**Solutions:**
1. ✅ FastMCP should handle CORS automatically
2. ✅ Check browser console for specific CORS error
3. ✅ Verify server allows `http://localhost:6274` origin
4. ✅ Try disabling browser CORS (for testing only!)

## Advanced Testing with Inspector

### Test 1: Concurrent Tool Calls

```javascript
// Open browser console in Inspector
// Call multiple tools simultaneously
Promise.all([
  callTool('add_numbers', {a: 1, b: 2}),
  callTool('multiply_numbers', {a: 3, b: 4}),
  callTool('list_notes', {})
]).then(results => console.log(results));
```

### Test 2: Stress Testing

Create multiple notes rapidly:
```javascript
for (let i = 0; i < 10; i++) {
  callTool('create_note', {
    title: `Note ${i}`,
    content: `Content ${i}`
  });
}
```

### Test 3: Error Recovery

1. Stop your server (Ctrl+C)
2. Try calling a tool in Inspector
3. Restart your server
4. Click "Reconnect" in Inspector
5. Verify connection is re-established

## Alternative: MCPJam OAuth Debugger

For more detailed OAuth debugging, use [MCPJam OAuth Debugger](https://www.mcpjam.com/blog/oauth-debugger):

1. Visit https://www.mcpjam.com/oauth-debugger
2. Enter your server URL
3. Step through each OAuth stage
4. View detailed request/response data
5. Identify specific OAuth issues

## Automated Testing Script

Create a test script for automated testing:

```javascript
// test-oauth-flow.js
const { Client } = require('@modelcontextprotocol/sdk/client/index.js');
const { SSEClientTransport } = require('@modelcontextprotocol/sdk/client/sse.js');

async function testOAuthFlow() {
  console.log('Starting OAuth flow test...');
  
  const transport = new SSEClientTransport(
    new URL('http://localhost:8000/sse')
  );
  
  const client = new Client({
    name: 'test-client',
    version: '1.0.0'
  }, {
    capabilities: {}
  });

  try {
    await client.connect(transport);
    console.log('✅ Connected successfully');

    // Test calculator
    const result = await client.callTool({
      name: 'add_numbers',
      arguments: { a: 5, b: 3 }
    });
    console.log('✅ Calculator test:', result);

    // Test notes
    const note = await client.callTool({
      name: 'create_note',
      arguments: {
        title: 'Automated Test',
        content: 'Created by test script'
      }
    });
    console.log('✅ Notes test:', note);

    await client.close();
    console.log('✅ All tests passed!');
  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

testOAuthFlow();
```

Run with:
```bash
npm install @modelcontextprotocol/sdk
node test-oauth-flow.js
```

## Monitoring During Tests

### Terminal 1: Server Logs
```bash
python run.py
# Watch for:
# - OAuth flow initiation
# - Token validation
# - Tool calls
# - Errors
```

### Terminal 2: Inspector
```bash
npx @modelcontextprotocol/inspector
# Watch for:
# - Connection status
# - Tool responses
# - Error messages
```

### Browser: DevTools Console
```
F12 → Console tab
# Watch for:
# - Network requests
# - JavaScript errors
# - OAuth redirects
```

## Best Practices

1. ✅ **Test Incrementally**: Start with simple tools, progress to complex
2. ✅ **Monitor All Logs**: Server, Inspector, and browser console
3. ✅ **Clear State**: Restart server between major test changes
4. ✅ **Document Issues**: Note unexpected behavior for debugging
5. ✅ **Test Error Cases**: Don't just test happy paths
6. ✅ **Verify Scopes**: Ensure each tool respects scope requirements
7. ✅ **Check Token Refresh**: Test long-running sessions

## Next Steps After Inspector Testing

Once your OAuth flow works in Inspector:

1. ✅ **Test with Claude.ai**: Connect from actual Claude interface
2. ✅ **Test with Claude Desktop**: Configure local Claude app
3. ✅ **Deploy with ngrok**: Test remote access
4. ✅ **Production Deploy**: Use real domain with HTTPS
5. ✅ **Monitor Production**: Set up logging and alerting

## Resources

- **MCP Inspector**: [GitHub](https://github.com/modelcontextprotocol/inspector)
- **Inspector Docs**: [MCPJam Guide](https://docs.mcpjam.com/inspector/guided-oauth)
- **OAuth Debugger**: [MCPJam Tool](https://www.mcpjam.com/blog/oauth-debugger)
- **MCP Protocol**: [Specification](https://spec.modelcontextprotocol.io/)
- **Your Server Docs**: [README.md](README.md)

---

🔍 **Happy Testing!** MCP Inspector is the best way to verify your OAuth implementation works correctly before deploying to production or connecting with Claude.ai.

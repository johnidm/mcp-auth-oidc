# Troubleshooting Guide

Common issues and solutions for the MCP Auth Demo Server.

## Environment Variable Issues

### Issue: "Protected resource mismatch" Error

**Error Message:**
```
OAuth flow error: Error: Protected resource http://localhost:8000/mcp 
does not match expected http://0.0.0.0:8000/mcp (or origin)
```

**Cause:**
The `.env` file wasn't loaded before the auth provider was initialized, so it used default values instead of your configured values.

**Solution:**
This has been fixed in the code. The `.env` file is now loaded at the very beginning of `main.py` and `run.py` before any imports.

**To verify it's working:**
1. Restart your server: `python run.py`
2. Check the startup message shows your correct `RESOURCE_ID`:
   ```
   Base URL: http://localhost:8000  ← Should match your .env
   ```

### Issue: Using ngrok but getting localhost errors

**Error Message:**
```
Protected resource http://localhost:8000/mcp does not match 
expected https://xxxxx.ngrok-free.app/mcp
```

**Cause:**
Your `.env` file has `RESOURCE_ID=http://localhost:8000` but you're accessing via ngrok.

**Solution:**

1. **Update `.env`:**
   ```env
   RESOURCE_ID=https://your-ngrok-id.ngrok-free.app
   ```

2. **Update Auth0 Callback URLs:**
   - Go to [Auth0 Dashboard](https://manage.auth0.com/)
   - Add: `https://your-ngrok-id.ngrok-free.app/auth/callback`

3. **Restart server:**
   ```bash
   python run.py
   ```

**Pro Tip:** Keep separate env files:
```bash
# .env.local
RESOURCE_ID=http://localhost:8000

# .env.ngrok
RESOURCE_ID=https://xxxxx.ngrok-free.app

# Switch between them:
cp .env.local .env  # For local testing
cp .env.ngrok .env  # For ngrok testing
```

## Auth0 Configuration Issues

### Issue: "Missing required environment variables"

**Error Message:**
```
Error: Missing required environment variables: AUTH0_CLIENT_ID, AUTH0_CLIENT_SECRET
```

**Cause:**
The `.env` file doesn't exist or is missing required variables.

**Solution:**

1. **Create `.env` file** in project root:
   ```env
   # Auth0 Configuration
   AUTH0_DOMAIN=dev-zilqiezmsk6ylig2.us.auth0.com
   AUTH0_CLIENT_ID=your_client_id
   AUTH0_CLIENT_SECRET=your_client_secret
   AUTH0_AUDIENCE=https://dev-zilqiezmsk6ylig2.us.auth0.com/api/v2/
   
   # Server Configuration
   RESOURCE_ID=http://localhost:8000
   SERVER_HOST=0.0.0.0
   SERVER_PORT=8000
   ```

2. **Or use demo credentials** (for testing):
   ```env
   AUTH0_DOMAIN=dev-zilqiezmsk6ylig2.us.auth0.com
   AUTH0_CLIENT_ID=GsJfBMVGn5cDgWQwTiq91SIQBYxQccJA
   AUTH0_CLIENT_SECRET=Qst5RVD9Vt79F5NgM_s6ymZSvMYemKrFMykWrDOtextPC2nBeK593yBvpJBafIDl
   AUTH0_AUDIENCE=https://dev-zilqiezmsk6ylig2.us.auth0.com/api/v2/
   RESOURCE_ID=http://localhost:8000
   SERVER_HOST=0.0.0.0
   SERVER_PORT=8000
   ```

### Issue: "Redirect URI mismatch"

**Error in Auth0:**
```
Callback URL mismatch. The provided redirect_uri is not in the list of allowed callback URLs
```

**Cause:**
The callback URL used in OAuth flow isn't registered in Auth0.

**Solution:**

Add ALL these URLs to your Auth0 application's **Allowed Callback URLs**:

```
http://localhost:8000/auth/callback,
http://localhost:6274/oauth/callback,
https://your-ngrok-id.ngrok-free.app/auth/callback
```

- First URL: Your server's callback
- Second URL: MCP Inspector's callback
- Third URL: ngrok callback (if using ngrok)

**Steps:**
1. Go to [Auth0 Dashboard](https://manage.auth0.com/)
2. Applications → Your Application
3. Settings → Application URIs
4. Add to "Allowed Callback URLs"
5. Save Changes

### Issue: "Invalid audience"

**Error Message:**
```
Token validation failed: Invalid audience
```

**Cause:**
The `AUTH0_AUDIENCE` in `.env` doesn't match your Auth0 API identifier.

**Solution:**

1. Go to Auth0 Dashboard → APIs
2. Find your API
3. Copy the **Identifier** (e.g., `https://dev-zilqiezmsk6ylig2.us.auth0.com/api/v2/`)
4. Update `.env`:
   ```env
   AUTH0_AUDIENCE=https://your-domain.us.auth0.com/api/v2/
   ```
5. Restart server

## MCP Inspector Issues

### Issue: Inspector can't connect

**Symptoms:**
- "Connection failed" in Inspector
- No OAuth prompt appears

**Solutions:**

1. **Verify server is running:**
   ```bash
   curl http://localhost:8000/
   ```

2. **Try different endpoints:**
   - `http://localhost:8000/mcp`
   - `http://localhost:8000/sse`
   - `http://localhost:8000/mcp/sse`

3. **Check server logs** for errors

4. **Restart both:**
   ```bash
   # Terminal 1: Restart server
   python run.py
   
   # Terminal 2: Restart Inspector
   npx @modelcontextprotocol/inspector
   ```

### Issue: OAuth loop - keeps redirecting

**Symptoms:**
- Redirects to Auth0 repeatedly
- Never completes connection

**Solutions:**

1. **Clear browser cookies:**
   - Open DevTools (F12)
   - Application → Cookies
   - Clear all cookies for localhost

2. **Check Auth0 redirect URI:**
   - Must include: `http://localhost:6274/oauth/callback`

3. **Check browser console:**
   - F12 → Console tab
   - Look for specific error messages

4. **Try incognito/private window:**
   - Rules out cookie/cache issues

### Issue: "Insufficient scopes" error

**Symptoms:**
- Connection succeeds
- Tool calls fail with scope errors

**Solutions:**

1. **Configure scopes in Auth0:**
   - Dashboard → APIs → Your API → Permissions
   - Add: `read:notes`, `write:notes`, `use:calculator`

2. **Verify scopes in Inspector:**
   - Should request: `read:notes write:notes use:calculator`

3. **Check `auth_config.py`:**
   ```python
   SUPPORTED_SCOPES = [
       "read:notes",
       "write:notes",
       "use:calculator",
   ]
   ```

4. **Re-authenticate:**
   - Disconnect in Inspector
   - Reconnect to get updated scopes

## Server Startup Issues

### Issue: "Address already in use"

**Error Message:**
```
OSError: [Errno 48] Address already in use
```

**Cause:**
Port 8000 is already being used by another process.

**Solutions:**

1. **Find and kill the process:**
   ```bash
   # macOS/Linux
   lsof -ti:8000 | xargs kill -9
   
   # Or find the process
   lsof -i:8000
   ```

2. **Use a different port:**
   ```env
   SERVER_PORT=8001
   ```
   
   Then update `RESOURCE_ID` too:
   ```env
   RESOURCE_ID=http://localhost:8001
   ```

### Issue: Import errors

**Error Message:**
```
ModuleNotFoundError: No module named 'fastmcp'
```

**Cause:**
Dependencies not installed.

**Solution:**
```bash
pip install -r requirements.txt
```

Or with a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### Issue: Python version error

**Error Message:**
```
SyntaxError: invalid syntax
```

**Cause:**
Python version too old (need 3.10+).

**Solution:**

1. **Check version:**
   ```bash
   python --version
   ```

2. **Install Python 3.10+:**
   - macOS: `brew install python@3.10`
   - Ubuntu: `sudo apt install python3.10`
   - Windows: Download from python.org

3. **Use specific version:**
   ```bash
   python3.10 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   python run.py
   ```

## Claude.ai Connection Issues

### Issue: Claude.ai can't reach localhost

**Symptoms:**
- Connection fails from Claude.ai
- Works with Inspector locally

**Cause:**
Claude.ai runs in the cloud and can't access your local machine.

**Solution: Use ngrok**

1. **Install ngrok:**
   ```bash
   brew install ngrok  # macOS
   # Or download from ngrok.com
   ```

2. **Start ngrok:**
   ```bash
   ngrok http 8000
   ```

3. **Update `.env`:**
   ```env
   RESOURCE_ID=https://xxxxx.ngrok-free.app
   ```

4. **Update Auth0:**
   - Add callback: `https://xxxxx.ngrok-free.app/auth/callback`

5. **Restart server:**
   ```bash
   python run.py
   ```

6. **Use ngrok URL in Claude.ai:**
   - `https://xxxxx.ngrok-free.app`

## Token and Authentication Issues

### Issue: "Token expired"

**Symptoms:**
- Works initially
- Fails after ~1 hour
- 401 Unauthorized errors

**Cause:**
Access tokens expire (typically after 1 hour).

**Solution:**
- This is normal behavior
- MCP Inspector should auto-refresh
- If not, reconnect manually
- For production, implement refresh token handling

### Issue: "Invalid token signature"

**Error Message:**
```
Token validation failed: Invalid signature
```

**Cause:**
Token was issued by a different Auth0 tenant or with wrong keys.

**Solutions:**

1. **Verify Auth0 domain matches:**
   - `.env`: `AUTH0_DOMAIN=dev-zilqiezmsk6ylig2.us.auth0.com`
   - Token issuer should match

2. **Check token in jwt.io:**
   - Copy your access token
   - Paste into https://jwt.io
   - Verify `iss` (issuer) matches your Auth0 domain

3. **Clear cached tokens:**
   - Disconnect and reconnect
   - Clear browser storage

## CORS Issues

### Issue: CORS errors in browser

**Error in Console:**
```
Access to fetch at 'http://localhost:8000/mcp' from origin 'http://localhost:6274' 
has been blocked by CORS policy
```

**Cause:**
FastMCP should handle CORS automatically, but there might be a configuration issue.

**Solution:**

FastMCP's OIDC Proxy should handle CORS automatically. If you're still seeing errors:

1. **Check browser console** for specific CORS error
2. **Verify request origin** is allowed
3. **Try different browser** (Chrome, Firefox, Safari)
4. **Check for browser extensions** that might interfere

## Debugging Tips

### Enable Verbose Logging

Add to your server startup:

```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

### Monitor All Logs

```bash
# Terminal 1: Server with verbose output
python run.py 2>&1 | tee server.log

# Terminal 2: Inspector
npx @modelcontextprotocol/inspector

# Terminal 3: Watch logs
tail -f server.log
```

### Check Environment Variables

```python
# Add to main.py for debugging
print("Environment variables:")
print(f"  AUTH0_DOMAIN: {os.getenv('AUTH0_DOMAIN')}")
print(f"  RESOURCE_ID: {os.getenv('RESOURCE_ID')}")
print(f"  SERVER_HOST: {os.getenv('SERVER_HOST')}")
print(f"  SERVER_PORT: {os.getenv('SERVER_PORT')}")
```

### Test Auth0 Connection

```bash
# Test OIDC discovery
curl https://dev-zilqiezmsk6ylig2.us.auth0.com/.well-known/openid-configuration

# Should return JSON with endpoints
```

## Getting Help

If you're still stuck:

1. **Check server logs** for specific error messages
2. **Check browser console** (F12) for client-side errors
3. **Review Auth0 logs** in Auth0 Dashboard → Monitoring → Logs
4. **Consult documentation:**
   - [README.md](README.md)
   - [MCP_INSPECTOR_GUIDE.md](MCP_INSPECTOR_GUIDE.md)
   - [FastMCP Docs](https://gofastmcp.com/)
   - [Auth0 Docs](https://auth0.com/docs)

## Quick Diagnostic Checklist

- [ ] `.env` file exists in project root
- [ ] All required environment variables are set
- [ ] `RESOURCE_ID` matches how you're accessing the server
- [ ] Auth0 callback URLs include all necessary URLs
- [ ] Server starts without errors
- [ ] Port 8000 is not in use by another process
- [ ] Python version is 3.10 or higher
- [ ] Dependencies are installed
- [ ] Auth0 scopes are configured
- [ ] For ngrok: callback URL updated in Auth0

---

Still having issues? Open an issue on GitHub or consult the FastMCP Discord community!


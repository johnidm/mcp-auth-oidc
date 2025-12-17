# Auth0 Configuration Checklist

Use this checklist to verify your Auth0 setup is correct.

## ✅ Step 1: Application Settings

Go to [Auth0 Dashboard](https://manage.auth0.com/) → Applications → Your Application

### Basic Information
- [ ] **Application Type**: Regular Web Application
- [ ] **Client ID**: Copy this (should match your .env)
- [ ] **Client Secret**: Copy this (should match your .env)

### Application URIs

**Allowed Callback URLs** (Must include ALL of these):
```
http://localhost:8000/auth/callback,
http://localhost:6274/oauth/callback,
https://43846547bc6a.ngrok-free.app/auth/callback
```

- [ ] Added localhost callback
- [ ] Added Inspector callback
- [ ] Added ngrok callback (UPDATE this with your current ngrok URL!)
- [ ] No trailing slashes
- [ ] Separated by commas
- [ ] Clicked **"Save Changes"** at the bottom

**Allowed Logout URLs** (Optional but recommended):
```
http://localhost:8000,
http://localhost:6274,
https://43846547bc6a.ngrok-free.app
```

**Allowed Web Origins** (For CORS):
```
http://localhost:8000,
http://localhost:6274,
https://43846547bc6a.ngrok-free.app
```

**Allowed Origins (CORS)**:
```
http://localhost:8000,
http://localhost:6274,
https://43846547bc6a.ngrok-free.app
```

### Advanced Settings

Go to **Advanced Settings** → **OAuth**:

- [ ] **JsonWebToken Signature Algorithm**: RS256
- [ ] **OIDC Conformant**: Enabled (ON)

## ✅ Step 2: API Configuration

Go to [Auth0 Dashboard](https://manage.auth0.com/) → APIs

### Find or Create API

- [ ] API exists (or create one)
- [ ] **Identifier/Audience**: Should match `AUTH0_AUDIENCE` in your .env
  - Example: `https://dev-zilqiezmsk6ylig2.us.auth0.com/api/v2/`

### API Permissions/Scopes

Go to API → Permissions tab:

- [ ] `read:notes` - Read notes permission
- [ ] `write:notes` - Write notes permission  
- [ ] `use:calculator` - Calculator permission

**Add each scope:**
1. Enter permission name (e.g., `read:notes`)
2. Enter description (e.g., "Read notes")
3. Click "Add"
4. Repeat for all three scopes

### API Settings

- [ ] **Enable RBAC**: ON
- [ ] **Add Permissions in the Access Token**: ON
- [ ] **Allow Skipping User Consent**: OFF (we want consent screen)

## ✅ Step 3: Verify .env File

Your `.env` should have:

```env
AUTH0_DOMAIN=dev-zilqiezmsk6ylig2.us.auth0.com
AUTH0_CLIENT_ID=your_client_id_from_auth0
AUTH0_CLIENT_SECRET=your_client_secret_from_auth0
AUTH0_AUDIENCE=https://dev-zilqiezmsk6ylig2.us.auth0.com/api/v2/
RESOURCE_ID=https://43846547bc6a.ngrok-free.app
SERVER_HOST=0.0.0.0
SERVER_PORT=8000
```

**Verify:**
- [ ] `AUTH0_CLIENT_ID` matches Auth0 application Client ID
- [ ] `AUTH0_CLIENT_SECRET` matches Auth0 application Client Secret
- [ ] `AUTH0_AUDIENCE` matches Auth0 API Identifier
- [ ] `RESOURCE_ID` matches your current ngrok URL (no trailing slash)

## ✅ Step 4: Test Configuration

### Test OIDC Discovery

```bash
curl https://dev-zilqiezmsk6ylig2.us.auth0.com/.well-known/openid-configuration
```

Should return JSON with endpoints. If this fails, your Auth0 domain is wrong.

### Restart Server

```bash
# Stop server (Ctrl+C)
python run.py
```

Verify startup shows correct values:
```
Base URL: https://43846547bc6a.ngrok-free.app
Auth Callback: https://43846547bc6a.ngrok-free.app/auth/callback
```

## ✅ Step 5: Check Auth0 Logs

1. Go to [Auth0 Dashboard](https://manage.auth0.com/)
2. **Monitoring** → **Logs**
3. Look for recent failures (red icons)
4. Click to see detailed error

**Common errors:**

| Error Code | Meaning | Fix |
|------------|---------|-----|
| `redirect_uri_mismatch` | Callback URL not allowed | Add to Allowed Callback URLs |
| `invalid_request` | Missing required parameter | Check OAuth flow parameters |
| `access_denied` | User denied consent | Normal - user clicked "Cancel" |
| `unauthorized_client` | Client not authorized | Check application type/settings |
| `invalid_client` | Wrong client ID/secret | Verify .env credentials |

## Common Issues & Fixes

### Issue: "Callback URL mismatch"

**Fix:**
1. Go to Auth0 Application settings
2. Add exact callback URL: `https://43846547bc6a.ngrok-free.app/auth/callback`
3. Make sure no typos, no trailing slashes
4. Save Changes
5. Wait 30 seconds for changes to propagate
6. Try again

### Issue: "Invalid audience"

**Fix:**
1. Check Auth0 API Identifier matches `AUTH0_AUDIENCE`
2. Update .env if needed
3. Restart server

### Issue: "Invalid client"

**Fix:**
1. Copy Client ID from Auth0 dashboard
2. Copy Client Secret from Auth0 dashboard  
3. Update .env with exact values
4. Restart server

### Issue: Error persists after fixing

**Fix:**
1. Clear browser cookies (F12 → Application → Cookies → Clear)
2. Try in incognito/private window
3. Check Auth0 logs for specific error
4. Wait a minute and try again (Auth0 config propagation)

## Testing Checklist

After configuration:

- [ ] Server starts without errors
- [ ] Startup message shows correct ngrok URL
- [ ] Can access ngrok URL in browser
- [ ] Auth0 OIDC discovery works
- [ ] No errors in Auth0 logs
- [ ] Browser doesn't show CORS errors
- [ ] OAuth flow redirects to Auth0 login
- [ ] After login, redirects back to app

## Get Detailed Error Info

### Method 1: Auth0 Logs
Most reliable - shows exact error from Auth0's perspective

### Method 2: Browser Console
```
F12 → Console tab
```
Look for errors related to OAuth/authentication

### Method 3: Server Logs
Check terminal where server is running for error messages

### Method 4: Network Tab
```
F12 → Network tab
```
Look for failed requests (red), check their response

## Still Not Working?

If you've checked everything:

1. **Try with demo credentials** to rule out Auth0 config issues:
   ```env
   AUTH0_DOMAIN=dev-zilqiezmsk6ylig2.us.auth0.com
   AUTH0_CLIENT_ID=GsJfBMVGn5cDgWQwTiq91SIQBYxQccJA
   AUTH0_CLIENT_SECRET=Qst5RVD9Vt79F5NgM_s6ymZSvMYemKrFMykWrDOtextPC2nBeK593yBvpJBafIDl
   AUTH0_AUDIENCE=https://dev-zilqiezmsk6ylig2.us.auth0.com/api/v2/
   ```

2. **Test locally first** before using ngrok:
   ```env
   RESOURCE_ID=http://localhost:8000
   ```
   Use MCP Inspector on `http://localhost:8000/mcp`

3. **Check Auth0 tenant status**: Sometimes Auth0 has outages

4. **Create a fresh Auth0 application** and try with new credentials

## Quick Debug Script

Run this to check your configuration:

```bash
#!/bin/bash
echo "=== Auth0 Configuration Check ==="
echo ""
echo "1. Testing OIDC Discovery..."
curl -s https://dev-zilqiezmsk6ylig2.us.auth0.com/.well-known/openid-configuration | jq '.issuer, .authorization_endpoint, .token_endpoint' || echo "❌ OIDC Discovery failed"
echo ""
echo "2. Checking .env file..."
if [ -f .env ]; then
    echo "✅ .env file exists"
    grep "RESOURCE_ID" .env
    grep "AUTH0_DOMAIN" .env
else
    echo "❌ .env file not found"
fi
echo ""
echo "3. Checking if server is running..."
curl -s http://localhost:8000/ && echo "✅ Server responding" || echo "❌ Server not responding"
echo ""
echo "Done! Check Auth0 logs for detailed errors:"
echo "https://manage.auth0.com/dashboard/us/dev-zilqiezmsk6ylig2/logs"
```

Save as `check-config.sh`, make executable, and run:
```bash
chmod +x check-config.sh
./check-config.sh
```

---

**Most Important:** Check the Auth0 logs - they will tell you exactly what's wrong!


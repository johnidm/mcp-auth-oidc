#!/usr/bin/env python3
"""Debug script to check Auth0 token claims."""

import os
import sys
import json
import base64
from dotenv import load_dotenv

load_dotenv()

def decode_jwt_payload(token):
    """Decode JWT payload without verification (for debugging only)."""
    try:
        # JWT format: header.payload.signature
        parts = token.split('.')
        if len(parts) != 3:
            print("❌ Invalid token format")
            return None
        
        # Decode payload (add padding if needed)
        payload = parts[1]
        payload += '=' * (4 - len(payload) % 4)
        decoded = base64.urlsafe_b64decode(payload)
        return json.loads(decoded)
    except Exception as e:
        print(f"❌ Error decoding token: {e}")
        return None

def main():
    print("=" * 60)
    print("Auth0 Token Debugger")
    print("=" * 60)
    print()
    
    # Show current configuration
    print("Current Configuration:")
    print(f"  AUTH0_DOMAIN: {os.getenv('AUTH0_DOMAIN')}")
    print(f"  AUTH0_AUDIENCE: {os.getenv('AUTH0_AUDIENCE')}")
    print(f"  RESOURCE_ID: {os.getenv('RESOURCE_ID')}")
    print()
    
    # Check if they match
    audience = os.getenv('AUTH0_AUDIENCE')
    resource = os.getenv('RESOURCE_ID')
    
    if audience == resource:
        print("✅ AUDIENCE and RESOURCE_ID match")
    else:
        print("❌ MISMATCH FOUND!")
        print(f"   AUDIENCE:    {audience}")
        print(f"   RESOURCE_ID: {resource}")
        print()
        print("This is likely why token validation is failing!")
        print("Update your .env so both values are the same.")
    
    print()
    print("-" * 60)
    print()
    
    # Ask for token
    print("To debug a token, paste it here (or press Enter to skip):")
    token = input().strip()
    
    if not token:
        print("No token provided. Exiting.")
        return
    
    print()
    print("Decoding token...")
    print()
    
    claims = decode_jwt_payload(token)
    if not claims:
        return
    
    print("Token Claims:")
    print(json.dumps(claims, indent=2))
    print()
    
    # Check important claims
    print("-" * 60)
    print("Validation Checks:")
    print()
    
    # Check issuer
    iss = claims.get('iss', '')
    expected_iss = f"https://{os.getenv('AUTH0_DOMAIN')}/"
    if iss == expected_iss:
        print(f"✅ Issuer (iss): {iss}")
    else:
        print(f"❌ Issuer mismatch!")
        print(f"   Token has: {iss}")
        print(f"   Expected:  {expected_iss}")
    
    # Check audience
    aud = claims.get('aud', '')
    expected_aud = os.getenv('AUTH0_AUDIENCE')
    if aud == expected_aud:
        print(f"✅ Audience (aud): {aud}")
    else:
        print(f"❌ Audience mismatch!")
        print(f"   Token has: {aud}")
        print(f"   Expected:  {expected_aud}")
        print()
        print("FIX: Update AUTH0_AUDIENCE in .env to match token's aud")
    
    # Check scopes
    scope = claims.get('scope', '')
    scopes = scope.split() if scope else []
    print(f"📋 Scopes: {', '.join(scopes) if scopes else 'None'}")
    
    expected_scopes = ['read:notes', 'write:notes', 'use:calculator']
    missing = [s for s in expected_scopes if s not in scopes]
    if missing:
        print(f"⚠️  Missing scopes: {', '.join(missing)}")
        print("   Configure these in Auth0 API permissions")
    
    # Check expiration
    import time
    exp = claims.get('exp', 0)
    if exp:
        if exp > time.time():
            print(f"✅ Token valid until: {time.ctime(exp)}")
        else:
            print(f"❌ Token EXPIRED at: {time.ctime(exp)}")
    
    print()
    print("=" * 60)

if __name__ == "__main__":
    main()


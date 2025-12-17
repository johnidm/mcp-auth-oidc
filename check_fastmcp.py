"""Check FastMCP structure to debug ASGI integration."""

from fastmcp import FastMCP

# Create a simple FastMCP instance
mcp = FastMCP(name="Test", version="1.0.0")

print("FastMCP instance attributes:")
attrs = [attr for attr in dir(mcp) if not attr.startswith('__')]
for attr in sorted(attrs):
    print(f"  - {attr}")
print()

print("Checking for ASGI-related methods:")
asgi_attrs = ['_app', '_create_asgi_app', 'get_asgi_app', 'app', 'asgi_app', '__call__', 'run']
for attr in asgi_attrs:
    if hasattr(mcp, attr):
        obj = getattr(mcp, attr)
        print(f"  ✓ {attr}: {type(obj)}")
        if callable(obj):
            print(f"    (callable)")
    else:
        print(f"  ✗ {attr}: not found")

print()
print("FastMCP type:", type(mcp))
print("Is callable:", callable(mcp))


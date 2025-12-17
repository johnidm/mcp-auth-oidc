"""Convenience script to run the server."""

# Ensure .env is loaded before any imports
from dotenv import load_dotenv
load_dotenv()

from src.main import main

if __name__ == "__main__":
    main()


# ==============================================================================
# run.py - The Entry Point of the SmartFinance Backend Server
# ==============================================================================
# This is the FIRST file that runs when you start the backend with:
#   python run.py
# It creates the Flask web application and starts the server so that
# the Flutter app can send HTTP requests to it (e.g., login, add transaction).
# ==============================================================================

import os                        # 'os' module lets us read environment variables from the system
from app import create_app       # Import the 'create_app' function from the 'app' package (__init__.py)

# --- Create the Flask Application ---
# os.getenv('FLASK_ENV', 'development') reads the 'FLASK_ENV' environment variable.
# If it's not set, it defaults to 'development' (which enables debug mode).
# The create_app() function (defined in app/__init__.py) builds and configures the entire app.
app = create_app(os.getenv('FLASK_ENV', 'development'))

# --- Start the Server ---
# __name__ == '__main__' means: "Only run this block if this file is executed directly"
# (not when it's imported by another file).
if __name__ == '__main__':
    # Read the PORT environment variable, default to 5000 if not set.
    # int() converts the string to a number (e.g., "5000" -> 5000).
    port = int(os.getenv('PORT', 5000))

    # Start the Flask development server:
    # - host='0.0.0.0' means the server listens on ALL network interfaces
    #   (so other devices on the same WiFi can access it, not just localhost).
    # - port=5000 means it runs on http://localhost:5000
    # - debug=True enables auto-reload when you change code, and shows detailed errors.
    app.run(host='0.0.0.0', port=port, debug=True)

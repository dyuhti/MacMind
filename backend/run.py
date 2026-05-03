"""
Main entry point for the MacMind Flask application
Run this file to start the server
"""
import os
from dotenv import load_dotenv
from app import create_app

# Load environment variables from .env file
load_dotenv()

# Get Flask environment configuration
flask_env = os.getenv('FLASK_ENV', 'development')

# Create Flask app with appropriate config
app = create_app(flask_env)

if __name__ == '__main__':
    """
    Start the Flask development server
    
    The server will run on:
    - Host: 0.0.0.0 (all interfaces - localhost + network)
    - Port: 5000
    - Debug mode: Enabled in development
    - Auto-reload: Enabled in development
    
    To access the API:
    - Localhost: http://127.0.0.1:5000
    - Network: http://YOUR_MACHINE_IP:5000
    - Health check: http://0.0.0.0:5000/api/health
    - Register: POST http://0.0.0.0:5000/api/auth/register
    - Login: POST http://0.0.0.0:5000/api/auth/login
    """
    host = os.getenv('FLASK_HOST', '0.0.0.0')
    port = int(os.getenv('PORT', 5000))
    debug = flask_env == 'development'
    
    print(f"""
    ╔════════════════════════════════════════════╗
    ║     MacMind Medical Calculator Backend     ║
    ╚════════════════════════════════════════════╝
    
    🚀 Server starting on http://{host}:{port}
    🔧 Environment: {flask_env.upper()}
    🐛 Debug Mode: {'ON' if debug else 'OFF'}
    📦 Database: MySQL
    🔐 CORS: Enabled
    🌐 Accepting connections from: ALL INTERFACES
    
    ✅ Server is ready!
    Press CTRL+C to stop.
    """)
    
    app.run(
        host=host,
        port=port,
        debug=debug,
        use_reloader=False
    )

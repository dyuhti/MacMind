"""
Health check endpoint blueprint
Simple status endpoint to verify server is running
"""
from flask import Blueprint

# Create blueprint for health routes
health_bp = Blueprint('health', __name__)


@health_bp.route('/health', methods=['GET'])
def health_check():
    """
    Health check endpoint
    
    Returns:
        JSON with server status and timestamp
    """
    from datetime import datetime
    return {
        'status': 'healthy',
        'message': 'Server is running',
        'timestamp': datetime.utcnow().isoformat()
    }, 200

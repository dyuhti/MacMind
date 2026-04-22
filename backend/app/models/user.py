"""
User model for database interactions using SQLAlchemy
Handles user creation, validation, and password operations
"""
from app import db
from app.utils.security import hash_password, verify_password
from datetime import datetime, timedelta
import random
import string


class User(db.Model):
    """User model for managing user data in MySQL"""
    
    __tablename__ = 'users'
    
    # Columns
    id = db.Column(db.Integer, primary_key=True)
    full_name = db.Column(db.String(255), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False, index=True)
    password = db.Column(db.String(255), nullable=False)
    otp = db.Column(db.String(10), nullable=True)
    otp_expiry = db.Column(db.DateTime, nullable=True)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    
    def __repr__(self):
        return f'<User {self.full_name}>'
    
    def to_dict(self, include_password=False):
        """
        Convert user object to dictionary
        
        Args:
            include_password: Whether to include hashed password in output
        
        Returns:
            Dictionary representation of user
        """
        data = {
            'id': self.id,
            'full_name': self.full_name,
            'email': self.email,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }
        
        if include_password:
            data['password'] = self.password
        
        return data
    
    @staticmethod
    def create(full_name, email, password):
        """
        Create a new user in the database
        
        Args:
            full_name: User's full name
            email: User's email address
            password: User's password (will be hashed)
        
        Returns:
            Dictionary with user data or error information
        """
        # Check if email already exists
        existing_user = User.query.filter_by(email=email).first()
        
        if existing_user:
            return {'success': False, 'error': 'Email already registered'}
        
        try:
            # Create new user
            new_user = User(
                full_name=full_name,
                email=email,
                password=hash_password(password)
            )
            
            # Add to database session
            db.session.add(new_user)
            db.session.commit()
            
            return {
                'success': True,
                'id': new_user.id,
                'email': new_user.email,
                'full_name': new_user.full_name
            }
        
        except Exception as e:
            db.session.rollback()
            return {
                'success': False,
                'error': f'Error creating user: {str(e)}'
            }
    
    @staticmethod
    def find_by_email(email):
        """
        Find user by email
        
        Args:
            email: User's email address
        
        Returns:
            User object or None
        """
        return User.query.filter_by(email=email).first()
    
    @staticmethod
    def find_by_id(user_id):
        """
        Find user by ID
        
        Args:
            user_id: User's database ID
        
        Returns:
            User object or None
        """
        return User.query.get(user_id)
    
    @staticmethod
    def verify_password(email, password):
        """
        Verify user's password
        
        Args:
            email: User's email
            password: Password to verify
        
        Returns:
            Dictionary with success status and user data
        """
        user = User.find_by_email(email)
        
        if not user:
            return {'success': False, 'error': 'User not found'}
        
        if verify_password(password, user.password):
            return {
                'success': True,
                'id': user.id,
                'email': user.email,
                'full_name': user.full_name
            }
        else:
            return {'success': False, 'error': 'Invalid password'}
    
    @staticmethod
    def generate_otp():
        """
        Generate a 6-digit OTP
        
        Returns:
            6-digit OTP as string
        """
        return ''.join(random.choices(string.digits, k=6))
    
    @staticmethod
    def store_otp(email, otp_duration_minutes=5):
        """
        Store OTP and expiry for a user
        
        Args:
            email: User's email address
            otp_duration_minutes: How long OTP is valid (default 5 minutes)
        
        Returns:
            Dictionary with success status and OTP
        """
        user = User.find_by_email(email)
        
        if not user:
            return {'success': False, 'error': 'User not found'}
        
        try:
            otp = User.generate_otp()
            user.otp = otp
            user.otp_expiry = datetime.utcnow() + timedelta(minutes=otp_duration_minutes)
            db.session.commit()
            
            return {'success': True, 'otp': otp}
        
        except Exception as e:
            db.session.rollback()
            return {'success': False, 'error': f'Error storing OTP: {str(e)}'}
    
    @staticmethod
    def verify_otp(email, otp):
        """
        Verify OTP for a user
        
        Args:
            email: User's email address
            otp: OTP to verify
        
        Returns:
            Dictionary with success status
        """
        user = User.find_by_email(email)
        
        if not user:
            return {'success': False, 'error': 'User not found'}
        
        if not user.otp:
            return {'success': False, 'error': 'No OTP generated for this user'}
        
        if user.otp != otp:
            return {'success': False, 'error': 'Invalid OTP'}
        
        if datetime.utcnow() > user.otp_expiry:
            return {'success': False, 'error': 'OTP has expired'}
        
        return {'success': True, 'message': 'OTP verified successfully'}
    
    @staticmethod
    def reset_password(email, new_password):
        """
        Reset user's password and clear OTP
        
        Args:
            email: User's email address
            new_password: New password (will be hashed)
        
        Returns:
            Dictionary with success status
        """
        user = User.find_by_email(email)
        
        if not user:
            return {'success': False, 'error': 'User not found'}
        
        try:
            user.password = hash_password(new_password)
            user.otp = None
            user.otp_expiry = None
            db.session.commit()
            
            return {'success': True, 'message': 'Password reset successfully'}
        
        except Exception as e:
            db.session.rollback()
            return {'success': False, 'error': f'Error resetting password: {str(e)}'}



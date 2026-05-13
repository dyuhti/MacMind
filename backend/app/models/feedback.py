"""
Feedback model for database interactions using SQLAlchemy
Handles feedback submission and storage
"""
from app import db
from datetime import datetime


class Feedback(db.Model):
    """Feedback model for managing feedback data with SQLAlchemy"""
    
    __tablename__ = 'feedback'
    
    # Columns
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, nullable=False, index=True)
    user_name = db.Column(db.String(255), nullable=False)
    user_email = db.Column(db.String(120), nullable=False)
    rating = db.Column(db.Integer, nullable=False)  # 1-5
    category = db.Column(db.String(50), nullable=False)  # Bug Report, Feature Request, etc.
    feedback_message = db.Column(db.Text, nullable=False)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    
    def __repr__(self):
        return f'<Feedback {self.id} by {self.user_name}>'
    
    def to_dict(self):
        """
        Convert feedback object to dictionary
        
        Returns:
            Dictionary representation of feedback
        """
        return {
            'id': self.id,
            'user_id': self.user_id,
            'user_name': self.user_name,
            'user_email': self.user_email,
            'rating': self.rating,
            'category': self.category,
            'feedback_message': self.feedback_message,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }
    
    @staticmethod
    def create(user_id, user_name, user_email, rating, category, feedback_message):
        """
        Create a new feedback entry in the database
        
        Args:
            user_id: ID of the user submitting feedback
            user_name: Name of the user
            user_email: Email of the user
            rating: Rating (1-5)
            category: Feedback category
            feedback_message: The feedback message text
        
        Returns:
            Dictionary with feedback data or error information
        """
        try:
            # Validate rating
            if not isinstance(rating, int) or rating < 1 or rating > 5:
                return {'success': False, 'error': 'Rating must be between 1 and 5'}
            
            # Validate message
            if not feedback_message or feedback_message.strip() == '':
                return {'success': False, 'error': 'Feedback message cannot be empty'}
            
            # Create new feedback
            new_feedback = Feedback(
                user_id=user_id,
                user_name=user_name,
                user_email=user_email,
                rating=rating,
                category=category,
                feedback_message=feedback_message.strip()
            )
            
            # Add to database session
            db.session.add(new_feedback)
            db.session.commit()
            
            return {
                'success': True,
                'message': 'Feedback submitted successfully',
                'feedback': new_feedback.to_dict()
            }
        
        except Exception as e:
            db.session.rollback()
            return {'success': False, 'error': str(e)}
    
    @staticmethod
    def find_by_id(feedback_id):
        """
        Find feedback by ID
        
        Args:
            feedback_id: Feedback ID
        
        Returns:
            Feedback object or None
        """
        return Feedback.query.filter_by(id=feedback_id).first()
    
    @staticmethod
    def find_by_user_id(user_id):
        """
        Find all feedback by user ID
        
        Args:
            user_id: User ID
        
        Returns:
            List of Feedback objects
        """
        return Feedback.query.filter_by(user_id=user_id).order_by(Feedback.created_at.desc()).all()
    
    @staticmethod
    def get_all():
        """
        Get all feedback
        
        Returns:
            List of all Feedback objects
        """
        return Feedback.query.order_by(Feedback.created_at.desc()).all()

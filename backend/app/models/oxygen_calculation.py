"""
Oxygen calculation model for database interactions using SQLAlchemy.
Stores cylinder type, pressure, and computed oxygen content.
"""
from datetime import datetime

from app import db
from app.utils.timezone_utils import datetime_to_ist_isoformat


class OxygenCalculation(db.Model):
    """Persisted oxygen cylinder calculation record."""

    __tablename__ = 'oxygen_calculations'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    cylinder_type = db.Column(db.String(50), nullable=False, index=True)
    pressure_psi = db.Column(db.Float, nullable=False)
    total_oxygen_content = db.Column(db.Float, nullable=False)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)

    user = db.relationship('User', backref='oxygen_calculations')

    def __repr__(self):
        return f'<OxygenCalculation {self.id} {self.cylinder_type}>'

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'cylinder_type': self.cylinder_type,
            'pressure_psi': self.pressure_psi,
            'total_oxygen_content': self.total_oxygen_content,
            'created_at': datetime_to_ist_isoformat(self.created_at) if self.created_at else None,
            'created_by': {
                'id': self.user.id,
                'name': self.user.full_name,
                'email': self.user.email
            } if self.user else None
        }
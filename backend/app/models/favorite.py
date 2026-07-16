from datetime import datetime

from app import db


class Favorite(db.Model):
    __tablename__ = 'favorites'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    calculator_name = db.Column(db.String(100), nullable=False)
    order = db.Column(db.Integer, nullable=False, default=0)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)

    user = db.relationship('User', backref='favorites')

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'calculator_name': self.calculator_name,
            'order': self.order,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }

from datetime import datetime

from app import db
from app.utils.timezone_utils import datetime_to_ist_isoformat


class AdminNote(db.Model):
    __tablename__ = 'admin_notes'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    admin_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    note = db.Column(db.Text, nullable=False)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, nullable=True, onupdate=datetime.utcnow)

    user = db.relationship('User', foreign_keys=[user_id], backref='admin_notes')
    admin = db.relationship('User', foreign_keys=[admin_id], backref='written_notes')

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'admin_id': self.admin_id,
            'admin_name': self.admin.full_name if self.admin else None,
            'note': self.note,
            'created_at': datetime_to_ist_isoformat(self.created_at) if self.created_at else None,
            'updated_at': datetime_to_ist_isoformat(self.updated_at) if self.updated_at else None,
        }

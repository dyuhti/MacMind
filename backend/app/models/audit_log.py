from datetime import datetime

from app import db


class AuditLog(db.Model):
    __tablename__ = 'audit_logs'

    id = db.Column(db.Integer, primary_key=True)
    target_user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True, index=True)
    admin_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    action = db.Column(db.String(100), nullable=False)
    old_value = db.Column(db.Text, nullable=True)
    new_value = db.Column(db.Text, nullable=True)
    timestamp = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)

    target_user = db.relationship('User', foreign_keys=[target_user_id], backref='audit_logs')
    admin = db.relationship('User', foreign_keys=[admin_id], backref='admin_audit_actions')

    def to_dict(self):
        return {
            'id': self.id,
            'target_user_id': self.target_user_id,
            'admin_id': self.admin_id,
            'admin_name': self.admin.full_name if self.admin else None,
            'admin_email': self.admin.email if self.admin else None,
            'action': self.action,
            'old_value': self.old_value,
            'new_value': self.new_value,
            'timestamp': self.timestamp.isoformat() if self.timestamp else None,
        }

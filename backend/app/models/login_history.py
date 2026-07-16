from datetime import datetime

from app import db


class LoginHistory(db.Model):
    __tablename__ = 'login_history'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    login_time = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    logout_time = db.Column(db.DateTime, nullable=True)
    session_duration = db.Column(db.Integer, nullable=True)
    platform = db.Column(db.String(50), nullable=True)
    device = db.Column(db.String(100), nullable=True)
    browser = db.Column(db.String(100), nullable=True)
    ip_address = db.Column(db.String(45), nullable=True)
    status = db.Column(db.String(20), nullable=False, default='success')
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)

    user = db.relationship('User', backref='login_history')

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'login_time': self.login_time.isoformat() if self.login_time else None,
            'logout_time': self.logout_time.isoformat() if self.logout_time else None,
            'session_duration': self.session_duration,
            'platform': self.platform,
            'device': self.device,
            'browser': self.browser,
            'ip_address': self.ip_address,
            'status': self.status,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }

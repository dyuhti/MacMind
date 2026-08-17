"""
Oxygen timer history model for database interactions using SQLAlchemy.
Maps the existing oxygen_timer_history PostgreSQL table exactly.
"""
from datetime import datetime

from app import db
from app.utils.timezone_utils import datetime_to_ist_isoformat


class OxygenTimerHistory(db.Model):
    """Persisted oxygen timer lifecycle record."""

    __tablename__ = 'oxygen_timer_history'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    cylinder_type = db.Column(db.String(100), nullable=True)
    pressure_psi = db.Column(db.Float, nullable=True)
    total_oxygen_content = db.Column(db.Float, nullable=True)

    selected_flow_rate = db.Column(db.Float, nullable=True)
    duration_seconds = db.Column(db.Integer, nullable=True)
    duration_text = db.Column(db.String(50), nullable=True)

    timer_status = db.Column(db.String(20), nullable=True)

    started_at = db.Column(db.DateTime, nullable=True)
    paused_at = db.Column(db.DateTime, nullable=True)
    resumed_at = db.Column(db.DateTime, nullable=True)
    stopped_at = db.Column(db.DateTime, nullable=True)
    completed_at = db.Column(db.DateTime, nullable=True)

    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)

    user = db.relationship('User', backref='oxygen_timer_history')

    def __repr__(self):
        return f'<OxygenTimerHistory {self.id} {self.timer_status}>'

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'cylinder_type': self.cylinder_type,
            'pressure_psi': self.pressure_psi,
            'total_oxygen_content': self.total_oxygen_content,
            'selected_flow_rate': self.selected_flow_rate,
            'duration_seconds': self.duration_seconds,
            'duration_text': self.duration_text,
            'timer_status': self.timer_status,
            'started_at': datetime_to_ist_isoformat(self.started_at) if self.started_at else None,
            'paused_at': datetime_to_ist_isoformat(self.paused_at) if self.paused_at else None,
            'resumed_at': datetime_to_ist_isoformat(self.resumed_at) if self.resumed_at else None,
            'stopped_at': datetime_to_ist_isoformat(self.stopped_at) if self.stopped_at else None,
            'completed_at': datetime_to_ist_isoformat(self.completed_at) if self.completed_at else None,
            'created_at': datetime_to_ist_isoformat(self.created_at) if self.created_at else None,
        }
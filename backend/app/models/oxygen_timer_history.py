"""
Oxygen timer history model for database interactions using SQLAlchemy.
Maps the existing oxygen_timer_history PostgreSQL table exactly.
"""
from datetime import datetime

from app import db


class OxygenTimerHistory(db.Model):
    """Persisted oxygen timer lifecycle record."""

    __tablename__ = 'oxygen_timer_history'

    id = db.Column(db.Integer, primary_key=True)
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

    def __repr__(self):
        return f'<OxygenTimerHistory {self.id} {self.timer_status}>'

    def to_dict(self):
        return {
            'id': self.id,
            'cylinder_type': self.cylinder_type,
            'pressure_psi': self.pressure_psi,
            'total_oxygen_content': self.total_oxygen_content,
            'selected_flow_rate': self.selected_flow_rate,
            'duration_seconds': self.duration_seconds,
            'duration_text': self.duration_text,
            'timer_status': self.timer_status,
            'started_at': self.started_at.isoformat() if self.started_at else None,
            'paused_at': self.paused_at.isoformat() if self.paused_at else None,
            'resumed_at': self.resumed_at.isoformat() if self.resumed_at else None,
            'stopped_at': self.stopped_at.isoformat() if self.stopped_at else None,
            'completed_at': self.completed_at.isoformat() if self.completed_at else None,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }
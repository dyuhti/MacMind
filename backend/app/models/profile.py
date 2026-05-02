"""
Profile model for storing editable profile details.
Uses a separate table so profile fields can be added without migrating users.
Links to User model via user_id foreign key.
"""
from datetime import datetime

from app import db


class Profile(db.Model):
    __tablename__ = 'profiles'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True, unique=True, index=True)
    name = db.Column(db.String(255), nullable=False, default='')
    email = db.Column(db.String(120), nullable=False, default='')
    role = db.Column(db.String(120), nullable=False, default='Doctor')
    hospital = db.Column(db.String(255), nullable=False, default='')
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            'name': self.name,
            'email': self.email,
            'role': self.role,
            'hospital': self.hospital,
        }

    @staticmethod
    def get_single_profile():
        """Return the single editable profile row if it exists."""
        return Profile.query.order_by(Profile.id.asc()).first()

    @staticmethod
    def upsert(data, user=None):
        profile = Profile.get_single_profile()

        if profile is None:
            profile = Profile(
                user_id=user.id if user else None,
                name=data.get('name') or (user.full_name if user else ''),
                email=data.get('email') or (user.email if user else ''),
                role=data.get('role') or 'Doctor',
                hospital=data.get('hospital') or '',
            )
            db.session.add(profile)
        else:
            profile.name = data.get('name', profile.name)
            profile.email = data.get('email', profile.email)
            profile.role = data.get('role', profile.role or 'Doctor')
            profile.hospital = data.get('hospital', profile.hospital)

            if user and profile.user_id is None:
                profile.user_id = user.id

        db.session.commit()
        return profile

import sys
import os
from dotenv import load_dotenv

load_dotenv()

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import create_app, db
from app.models.user import User

app = create_app('development')

with app.app_context():
    existing = User.query.filter_by(email='admin123@macmind.com').first()
    if existing:
        if existing.role != User.ROLE_ADMIN:
            existing.role = User.ROLE_ADMIN
            db.session.commit()
            print(f"Updated '{existing.email}' role to admin")
        else:
            print(f"Admin user already exists: {existing.email}")
    else:
        result = User.create(
            full_name='Admin',
            email='admin123@macmind.com',
            password='12345Dyu!',
            role=User.ROLE_ADMIN
        )
        if result.get('success'):
            print(f"Admin user created: {result['email']} (ID: {result['id']})")
        else:
            print(f"Failed: {result}")

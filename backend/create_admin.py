"""
Secure admin creation script.
Usage:
  python create_admin.py --name "Admin User" --email admin@example.com --password "StrongPass123"
If --password is omitted, a secure prompt is shown.
"""
import argparse
import getpass
import os
import re
import sys

from dotenv import load_dotenv

# Ensure backend package imports work
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import create_app
from app.models.user import User


EMAIL_PATTERN = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'


def validate_inputs(name, email, password):
    if not name or len(name.strip()) < 2:
        return False, 'Name must be at least 2 characters'

    if not re.match(EMAIL_PATTERN, email or ''):
        return False, 'Invalid email format'

    if not password or len(password) < 8:
        return False, 'Password must be at least 8 characters'

    return True, None


def create_admin(name, email, password):
    app = create_app('development')

    with app.app_context():
        existing = User.find_by_email(email)
        if existing:
            if existing.role != User.ROLE_ADMIN:
                return False, f'User {email} already exists as role={existing.role}. Update role manually in DB if needed.'
            return False, f'Admin user {email} already exists'

        result = User.create(
            full_name=name.strip(),
            email=email.strip().lower(),
            password=password,
            role=User.ROLE_ADMIN,
        )

        if not result.get('success'):
            return False, result.get('error', 'Unknown error')

        return True, f"Admin created: id={result['id']} email={result['email']} role={result.get('role')}"


def main():
    load_dotenv()

    parser = argparse.ArgumentParser(description='Create an admin user securely')
    parser.add_argument('--name', required=True, help='Admin full name')
    parser.add_argument('--email', required=True, help='Admin email')
    parser.add_argument('--password', help='Admin password (omit to use secure prompt)')
    args = parser.parse_args()

    password = args.password
    if not password:
        password = getpass.getpass('Admin password: ')

    is_valid, error = validate_inputs(args.name, args.email, password)
    if not is_valid:
        print(f'❌ {error}')
        sys.exit(1)

    success, message = create_admin(args.name, args.email, password)
    if success:
        print(f'✅ {message}')
        sys.exit(0)

    print(f'❌ {message}')
    sys.exit(1)


if __name__ == '__main__':
    main()

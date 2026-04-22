"""
Database initialization and migration script
Helps set up and verify the database schema
"""
import os
import sys
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import create_app, db
from app.models.user import User


def init_db():
    """Initialize the database with tables"""
    app = create_app('development')
    
    with app.app_context():
        try:
            # Create all tables
            print("🔄 Creating database tables...")
            db.create_all()
            print("✅ Database tables created successfully!")
            
            # Verify the users table exists
            inspector = db.inspect(db.engine)
            tables = inspector.get_table_names()
            
            if 'users' in tables:
                columns = [col['name'] for col in inspector.get_columns('users')]
                print(f"✅ Users table columns: {', '.join(columns)}")
                print("\n📋 Table schema verified:")
                for col in inspector.get_columns('users'):
                    nullable = "NULL" if col['nullable'] else "NOT NULL"
                    col_type = str(col['type'])
                    print(f"   - {col['name']}: {col_type} {nullable}")
            else:
                print("❌ Users table not found!")
                return False
            
            return True
        
        except Exception as e:
            print(f"❌ Error initializing database: {str(e)}")
            return False


def test_user_operations():
    """Test basic user operations"""
    app = create_app('development')
    
    with app.app_context():
        try:
            print("\n🧪 Testing user operations...")
            
            # Test data
            test_email = "test@example.com"
            test_password = "testpassword123"
            test_name = "Test User"
            
            # Check if test user exists
            existing = User.find_by_email(test_email)
            if existing:
                print(f"ℹ️  Test user already exists, skipping creation...")
                return True
            
            # Create test user
            print(f"📝 Creating test user: {test_name}")
            result = User.create(
                full_name=test_name,
                email=test_email,
                password=test_password
            )
            
            if not result['success']:
                print(f"❌ Failed to create test user: {result['error']}")
                return False
            
            print(f"✅ Test user created successfully!")
            print(f"   - ID: {result['id']}")
            print(f"   - Email: {result['email']}")
            print(f"   - Full Name: {result['full_name']}")
            
            # Test password verification
            print(f"\n🔐 Testing password verification...")
            verify_result = User.verify_password(test_email, test_password)
            
            if not verify_result['success']:
                print(f"❌ Password verification failed: {verify_result['error']}")
                return False
            
            print(f"✅ Password verification successful!")
            print(f"   - ID: {verify_result['id']}")
            print(f"   - Email: {verify_result['email']}")
            print(f"   - Full Name: {verify_result['full_name']}")
            
            # Test with wrong password
            print(f"\n🔐 Testing with wrong password...")
            wrong_result = User.verify_password(test_email, "wrongpassword")
            
            if wrong_result['success']:
                print(f"❌ Should have rejected wrong password!")
                return False
            
            print(f"✅ Correctly rejected wrong password: {wrong_result['error']}")
            
            return True
        
        except Exception as e:
            print(f"❌ Error testing user operations: {str(e)}")
            import traceback
            traceback.print_exc()
            return False


def cleanup_test_data():
    """Clean up test data"""
    app = create_app('development')
    
    with app.app_context():
        try:
            test_email = "test@example.com"
            user = User.find_by_email(test_email)
            
            if user:
                db.session.delete(user)
                db.session.commit()
                print(f"🗑️  Test user deleted successfully!")
            
            return True
        
        except Exception as e:
            print(f"❌ Error cleaning up test data: {str(e)}")
            db.session.rollback()
            return False


if __name__ == '__main__':
    import argparse
    
    parser = argparse.ArgumentParser(description='Database initialization and migration')
    parser.add_argument('command', nargs='?', default='init', 
                       help='Command to run: init, test, or cleanup')
    
    args = parser.parse_args()
    
    if args.command == 'init':
        success = init_db()
    elif args.command == 'test':
        success = test_user_operations()
    elif args.command == 'cleanup':
        success = cleanup_test_data()
    else:
        print(f"Unknown command: {args.command}")
        print("Available commands: init, test, cleanup")
        success = False
    
    sys.exit(0 if success else 1)

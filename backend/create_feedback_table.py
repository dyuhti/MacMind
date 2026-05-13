"""
Script to create the feedback table in the database
Run this after deploying the new Feedback model
"""
import os
import sys
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import create_app, db
from app.models.feedback import Feedback


def create_feedback_table():
    """Create the feedback table in the database"""
    app = create_app('development')
    
    with app.app_context():
        try:
            print("🔄 Creating feedback table...")
            
            # Create the table
            db.create_all()
            
            # Verify the feedback table exists
            inspector = db.inspect(db.engine)
            tables = inspector.get_table_names()
            
            if 'feedback' in tables:
                columns = [col['name'] for col in inspector.get_columns('feedback')]
                print(f"✅ Feedback table created successfully!")
                print(f"✅ Table columns: {', '.join(columns)}")
                print("\n📋 Table schema:")
                for col in inspector.get_columns('feedback'):
                    nullable = "NULL" if col['nullable'] else "NOT NULL"
                    col_type = str(col['type'])
                    print(f"   - {col['name']}: {col_type} {nullable}")
                return True
            else:
                print("❌ Feedback table not found!")
                return False
        
        except Exception as e:
            print(f"❌ Error creating feedback table: {str(e)}")
            return False


if __name__ == '__main__':
    success = create_feedback_table()
    sys.exit(0 if success else 1)

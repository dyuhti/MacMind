"""
Initialize cases table in database
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import create_app, db
from app.models.case import Case

app = create_app()


def ensure_cases_columns():
    """Add missing columns to cases table for full case payload storage."""
    alter_statements = [
        "ALTER TABLE cases ADD COLUMN IF NOT EXISTS fresh_gas_flow DOUBLE NULL",
        "ALTER TABLE cases ADD COLUMN IF NOT EXISTS dial_concentration DOUBLE NULL",
        "ALTER TABLE cases ADD COLUMN IF NOT EXISTS time_minutes DOUBLE NULL",
        "ALTER TABLE cases ADD COLUMN IF NOT EXISTS initial_weight DOUBLE NULL",
        "ALTER TABLE cases ADD COLUMN IF NOT EXISTS final_weight DOUBLE NULL",
        "ALTER TABLE cases ADD COLUMN IF NOT EXISTS biro_formula DOUBLE NULL",
        "ALTER TABLE cases ADD COLUMN IF NOT EXISTS dion_formula DOUBLE NULL",
        "ALTER TABLE cases ADD COLUMN IF NOT EXISTS weight_based DOUBLE NULL",
        "ALTER TABLE cases ADD COLUMN IF NOT EXISTS notes TEXT NULL",
        "ALTER TABLE cases ADD COLUMN IF NOT EXISTS induction_fgf DOUBLE NULL",
        "ALTER TABLE cases ADD COLUMN IF NOT EXISTS induction_concentration DOUBLE NULL",
        "ALTER TABLE cases ADD COLUMN IF NOT EXISTS induction_time DOUBLE NULL",
        "ALTER TABLE cases ADD COLUMN IF NOT EXISTS induction_biro DOUBLE NULL",
        "ALTER TABLE cases ADD COLUMN IF NOT EXISTS induction_dion DOUBLE NULL",
        "ALTER TABLE cases ADD COLUMN IF NOT EXISTS final_biro DOUBLE NULL",
        "ALTER TABLE cases ADD COLUMN IF NOT EXISTS final_dion DOUBLE NULL",
        "ALTER TABLE cases ADD COLUMN IF NOT EXISTS maintenance_rows LONGTEXT NULL",
        "ALTER TABLE cases ADD COLUMN IF NOT EXISTS maintenance_calculations LONGTEXT NULL",
    ]

    for statement in alter_statements:
        db.session.execute(db.text(statement))
    db.session.commit()

with app.app_context():
    try:
        print("🔧 Creating cases table...")
        
        # Create all tables
        db.create_all()

        # Ensure table has newly required columns when table already exists
        ensure_cases_columns()
        
        # Check if table exists
        inspector = db.inspect(db.engine)
        tables = inspector.get_table_names()
        
        if 'cases' in tables:
            print("✅ Cases table created successfully!")
            columns = [col['name'] for col in inspector.get_columns('cases')]
            print(f"📋 Columns: {', '.join(columns)}")
        else:
            print("❌ Cases table was not created")
            
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()

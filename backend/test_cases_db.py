from app import create_app
from app.models.case import Case

app = create_app('development')

with app.app_context():
    rows = Case.query.order_by(Case.created_at.desc()).limit(5).all()

    print('Recent cases in database:')
    print(f'Total records: {len(rows)}')
    for row in rows:
        print(f"ID: {row.id}, Patient: {row.patient_name}, Agent: {row.anesthetic_agent}")

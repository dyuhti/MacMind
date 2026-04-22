import mysql.connector

conn = mysql.connector.connect(
    host='localhost',
    user='root',
    password='root123',
    database='med_calci_app'
)

cursor = conn.cursor(dictionary=True)
cursor.execute('SELECT * FROM cases ORDER BY created_at DESC LIMIT 5')
rows = cursor.fetchall()

print('Recent cases in database:')
print(f'Total records: {len(rows)}')
for row in rows:
    print(f"ID: {row['id']}, Patient: {row['patient_name']}, Agent: {row['anesthetic_agent']}")

cursor.close()
conn.close()

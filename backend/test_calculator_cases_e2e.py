import os
import time
from dotenv import load_dotenv

from app import create_app


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


def main() -> None:
    load_dotenv()

    app = create_app('production')

    db_uri = app.config.get('SQLALCHEMY_DATABASE_URI', '')
    print(f"DB URI prefix: {db_uri.split('://')[0]}://")
    if not (db_uri.startswith('postgresql://') or db_uri.startswith('postgresql+psycopg://') or db_uri.startswith('sqlite://')):
        fail(f"Unexpected SQLALCHEMY_DATABASE_URI: {db_uri}")

    client = app.test_client()

    stamp = int(time.time())
    payload = {
        'patient_name': f'E2E Patient {stamp}',
        'patient_id': f'E2E-{stamp}',
        'date': '2026-05-03',
        'surgery_type': 'General Anesthesia',
        'anesthetic_agent': 'Sevoflurane',
        'molecular_mass': '200.05',
        'vapor_constant': '184',
        'density': '1.52',
        'notes': 'Created by E2E test'
    }

    # POST
    post_resp = client.post('/api/calculator/cases', json=payload)
    print(f"POST status: {post_resp.status_code}")
    if post_resp.status_code != 201:
        fail(f"POST failed: {post_resp.get_data(as_text=True)}")

    post_data = post_resp.get_json(silent=True) or {}
    case_id = ((post_data.get('case') or {}).get('id'))
    if not case_id:
        fail(f"POST missing case id: {post_data}")
    print(f"Created case_id: {case_id}")

    # GET all
    get_all_resp = client.get('/api/calculator/cases')
    print(f"GET all status: {get_all_resp.status_code}")
    if get_all_resp.status_code != 200:
        fail(f"GET all failed: {get_all_resp.get_data(as_text=True)}")

    get_all_data = get_all_resp.get_json(silent=True) or {}
    ids = [c.get('id') for c in get_all_data.get('cases', []) if isinstance(c, dict)]
    if case_id not in ids:
        fail(f"Created case id {case_id} not found in GET all")

    # PUT
    update_payload = {
        'notes': 'Updated by E2E test',
        'density': '1.53'
    }
    put_resp = client.put(f'/api/calculator/cases/{case_id}', json=update_payload)
    print(f"PUT status: {put_resp.status_code}")
    if put_resp.status_code != 200:
        fail(f"PUT failed: {put_resp.get_data(as_text=True)}")

    # GET by id
    get_one_resp = client.get(f'/api/calculator/cases/{case_id}')
    print(f"GET by id status: {get_one_resp.status_code}")
    if get_one_resp.status_code != 200:
        fail(f"GET by id failed: {get_one_resp.get_data(as_text=True)}")

    get_one_data = get_one_resp.get_json(silent=True) or {}
    case = get_one_data.get('case') or {}
    if case.get('notes') != 'Updated by E2E test':
        fail(f"Update not persisted for notes: {case}")
    if str(case.get('density')) not in ('1.53', '1.530000', '1.53'):
        fail(f"Update not persisted for density: {case}")

    # DELETE
    del_resp = client.delete(f'/api/calculator/cases/{case_id}')
    print(f"DELETE status: {del_resp.status_code}")
    if del_resp.status_code != 200:
        fail(f"DELETE failed: {del_resp.get_data(as_text=True)}")

    # GET after delete
    get_deleted_resp = client.get(f'/api/calculator/cases/{case_id}')
    print(f"GET after delete status: {get_deleted_resp.status_code}")
    if get_deleted_resp.status_code != 404:
        fail(f"Expected 404 after delete, got: {get_deleted_resp.status_code}")

    print('PASS: Full /api/calculator/cases CRUD E2E flow succeeded')


if __name__ == '__main__':
    main()

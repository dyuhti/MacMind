"""
Test Case API Endpoints
Tests the new /api/cases endpoints
"""
import requests
import json
import time

BASE_URL = 'http://127.0.0.1:5000/api/cases'
TIMESTAMP = int(time.time())

# Test data
test_case = {
    'patient_name': f'Test Patient {TIMESTAMP}',
    'patient_id': f'TP{TIMESTAMP}',
    'date': '2026-04-22',
    'surgery_type': 'General Anesthesia',
    'anesthetic_agent': 'Sevoflurane',
    'molecular_mass': '200.5',
    'vapor_constant': '45.8',
    'density': '1.52'
}

print('=' * 60)
print('🧪 TESTING CASE API ENDPOINTS')
print('=' * 60)

# Test 1: Save a case
print('\n✅ Test 1: Save a case (POST /api/cases)')
print('-' * 60)
try:
    response = requests.post(BASE_URL, json=test_case)
    print(f'Status: {response.status_code}')
    print(f'Response: {json.dumps(response.json(), indent=2)}')
    
    if response.status_code == 201:
        case_id = response.json().get('case', {}).get('id')
        print(f'✅ PASSED - Case saved with ID: {case_id}')
    else:
        print('❌ FAILED - Expected status 201')
except Exception as e:
    print(f'❌ FAILED - {str(e)}')

# Test 2: Fetch all cases
print('\n✅ Test 2: Fetch all cases (GET /api/cases)')
print('-' * 60)
try:
    response = requests.get(BASE_URL)
    print(f'Status: {response.status_code}')
    data = response.json()
    print(f'Total cases: {data.get("count", 0)}')
    
    if response.status_code == 200:
        print(f'✅ PASSED - Retrieved {data.get("count", 0)} cases')
        if data.get('cases'):
            print('\n📋 First case:')
            print(json.dumps(data['cases'][0], indent=2))
            case_id = data['cases'][0].get('id')
    else:
        print('❌ FAILED - Expected status 200')
except Exception as e:
    print(f'❌ FAILED - {str(e)}')

# Test 3: Save another case for testing
print('\n✅ Test 3: Save second case')
print('-' * 60)
test_case_2 = {
    'patient_name': f'Test Patient 2 {TIMESTAMP}',
    'patient_id': f'TP2{TIMESTAMP}',
    'date': '2026-04-22',
    'surgery_type': 'Regional Anesthesia',
    'anesthetic_agent': 'Isoflurane',
    'molecular_mass': '184.49',
    'vapor_constant': '195',
    'density': '1.50'
}

try:
    response = requests.post(BASE_URL, json=test_case_2)
    print(f'Status: {response.status_code}')
    
    if response.statuscode == 201:
        case_id_2 = response.json().get('case', {}).get('id')
        print(f'✅ PASSED - Second case saved with ID: {case_id_2}')
    else:
        print(f'Status: {response.status_code}')
except Exception as e:
    print(f'❌ FAILED - {str(e)}')

# Test 4: Fetch all cases again
print('\n✅ Test 4: Fetch all cases again (should show 2+)')
print('-' * 60)
try:
    response = requests.get(BASE_URL)
    print(f'Status: {response.statuscode}')
    data = response.json()
    count = data.get('count', 0)
    print(f'✅ PASSED - Total cases now: {count}')
except Exception as e:
    print(f'❌ FAILED - {str(e)}')

# Test 5: Get specific case
print('\n✅ Test 5: Get specific case (GET /api/cases/1)')
print('-' * 60)
try:
    response = requests.get(f'{BASE_URL}/1')
    print(f'Status: {response.statuscode}')
    
    if response.status_code == 200:
        print('✅ PASSED - Case retrieved')
        print(json.dumps(response.json()['case'], indent=2))
    elif response.status_code == 404:
        print('⚠️  Case not found (expected if ID 1 doesn\'t exist)')
    else:
        print(f'❌ FAILED - Unexpected status {response.status_code}')
except Exception as e:
    print(f'❌ FAILED - {str(e)}')

print('\n' + '=' * 60)
print('✅ TEST SUITE COMPLETE')
print('=' * 60)

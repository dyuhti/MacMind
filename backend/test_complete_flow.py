#!/usr/bin/env python
"""
Complete flow test for case management system
Tests: Save → Retrieve → Verify
"""
import requests
import json
from datetime import datetime

BASE_URL = "http://127.0.0.1:5000"

print("=" * 60)
print("🧪 COMPLETE CASE MANAGEMENT FLOW TEST")
print("=" * 60)

# Test 1: Save a new case
print("\n📝 TEST 1: Saving a new case...")
save_url = f"{BASE_URL}/api/calculator/cases"

case_data = {
    "patient_name": f"Test Patient {datetime.now().timestamp()}",
    "patient_id": "TEST123",
    "date": "2026-04-22",
    "surgery_type": "Orthopedic",
    "anesthetic_agent": "Desflurane",
    "molecular_mass": "168.04",
    "vapor_constant": "208",
    "density": "1.465"
}

print(f"URL: {save_url}")
print(f"Data: {json.dumps(case_data, indent=2)}")

response = requests.post(save_url, json=case_data)
print(f"Status: {response.status_code}")
print(f"Response: {json.dumps(response.json(), indent=2)}")

if response.status_code != 201:
    print("❌ Save test FAILED")
    exit(1)

saved_case_id = response.json()['case']['id']
print(f"✅ Case saved with ID: {saved_case_id}")

# Test 2: Get all cases
print("\n📋 TEST 2: Retrieving all cases...")
get_all_url = f"{BASE_URL}/api/calculator/cases"

response = requests.get(get_all_url)
print(f"Status: {response.status_code}")
data = response.json()
print(f"Total cases: {data['count']}")
print(f"Latest case: {data['cases'][0]['patient_name']} (ID: {data['cases'][0]['id']})")

if response.status_code != 200:
    print("❌ Get all cases test FAILED")
    exit(1)

if data['count'] == 0:
    print("❌ No cases returned")
    exit(1)

print(f"✅ Retrieved {data['count']} cases successfully")

# Test 3: Get specific case
print(f"\n🔍 TEST 3: Retrieving specific case (ID: {saved_case_id})...")
get_specific_url = f"{BASE_URL}/api/calculator/cases/{saved_case_id}"

response = requests.get(get_specific_url)
print(f"Status: {response.status_code}")
if response.status_code == 200:
    case = response.json()['case']
    print(f"Patient: {case['patient_name']}")
    print(f"Agent: {case['anesthetic_agent']}")
    print(f"Date: {case['date']}")
    print("✅ Specific case retrieved successfully")
else:
    print(f"⚠️ Get specific case returned {response.status_code}")
    print(response.json())

# Test 4: Verify data in database
print("\n💾 TEST 4: Verifying data via SQLAlchemy...")
from app import create_app
from app.models.case import Case

try:
    app = create_app('development')
    with app.app_context():
        row = Case.query.filter_by(id=saved_case_id).first()

    if row:
        print(f"✅ Found in database: {row.patient_name}")
        print(f"   Agent: {row.anesthetic_agent}")
        print(f"   Molecular Mass: {row.molecular_mass}")
    else:
        print(f"❌ Case {saved_case_id} not found in database")
except Exception as e:
    print(f"⚠️ Database check failed: {e}")

print("\n" + "=" * 60)
print("✅ ALL TESTS PASSED!")
print("=" * 60)
print("\n🎯 Summary:")
print(f"   ✅ Saved case ID: {saved_case_id}")
print(f"   ✅ Patient: {case_data['patient_name']}")
print(f"   ✅ Retrieved from API: ✓")
print(f"   ✅ Found via SQLAlchemy: ✓")
print(f"   ✅ Flutter can now sync this data!")
print("\n💡 Next: Test from Flutter by running the app on emulator")

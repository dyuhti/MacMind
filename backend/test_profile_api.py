#!/usr/bin/env python3
"""
Direct API Test - Verify profile endpoint returns user data
Run this AFTER backend is started: python test_profile_api.py
"""

import requests
import json
from app import create_app, db
from app.models.user import User
from app.utils.security import create_token

def test_profile_api():
    """Test the profile API endpoint directly"""
    app = create_app('development')
    
    with app.app_context():
        print("\n" + "="*70)
        print("🧪 PROFILE API TEST")
        print("="*70)
        
        # Step 1: Create test user
        print("\n1️⃣  Creating test user...")
        test_email = "profileapitest@example.com"
        
        # Clean up if exists
        existing = User.query.filter_by(email=test_email).first()
        if existing:
            db.session.delete(existing)
            db.session.commit()
        
        # Create new user
        result = User.create(
            full_name="Dr. API Test User",
            email=test_email,
            password="TestPass123"
        )
        
        if not result['success']:
            print(f"   ❌ Failed to create user: {result['error']}")
            return False
        
        user_id = result['id']
        print(f"   ✅ User created (ID: {user_id})")
        
        # Step 2: Generate token
        print("\n2️⃣  Generating JWT token...")
        token = create_token(user_id, test_email)
        print(f"   ✅ Token: {token[:40]}...")
        
        # Step 3: Test GET /api/profile endpoint
        print("\n3️⃣  Testing GET /api/profile endpoint...")
        print(f"   📡 URL: http://localhost:5000/api/profile")
        print(f"   🔑 Authorization: Bearer {token[:40]}...")
        
        # Simulate the API call
        with app.test_client() as client:
            response = client.get(
                '/api/profile',
                headers={
                    'Authorization': f'Bearer {token}',
                    'Content-Type': 'application/json'
                }
            )
        
        print(f"   ✅ Response Status: {response.status_code}")
        print(f"   📦 Response Body: {response.get_json()}")
        
        if response.status_code == 200:
            data = response.get_json()
            print(f"\n   ✅ API WORKING CORRECTLY!")
            print(f"      - Name: {data.get('name')}")
            print(f"      - Email: {data.get('email')}")
            
            # Verify data
            if data.get('name') == "Dr. API Test User" and data.get('email') == test_email:
                print(f"\n   ✅ DATA MATCHES!")
                print(f"\n   ✅ Flutter should receive this exact data:")
                print(f"      {json.dumps(data, indent=6)}")
            else:
                print(f"\n   ⚠️  Data mismatch!")
                print(f"      Expected name: Dr. API Test User")
                print(f"      Got: {data.get('name')}")
        else:
            print(f"\n   ❌ API FAILED!")
            if response.status_code == 401:
                print(f"      Reason: Token authentication failed")
            elif response.status_code == 404:
                print(f"      Reason: User not found")
            elif response.status_code == 500:
                print(f"      Reason: Server error")
            
        # Step 4: Test PUT /api/profile endpoint
        print("\n4️⃣  Testing PUT /api/profile endpoint...")
        update_data = {
            'name': 'Dr. Updated API Test',
            'email': 'updated@example.com',
            'role': 'Cardiologist',
            'hospital': 'Test Hospital'
        }
        
        print(f"   📤 Sending data: {update_data}")
        
        with app.test_client() as client:
            response = client.put(
                '/api/profile',
                headers={
                    'Authorization': f'Bearer {token}',
                    'Content-Type': 'application/json'
                },
                json=update_data
            )
        
        print(f"   ✅ Response Status: {response.status_code}")
        print(f"   📦 Response Body: {response.get_json()}")
        
        if response.status_code == 200:
            print(f"\n   ✅ UPDATE WORKING!")
            data = response.get_json()
            print(f"      Profile returned: {data.get('profile')}")
        else:
            print(f"\n   ❌ UPDATE FAILED!")
        
        # Clean up
        User.query.filter_by(email="updated@example.com").delete()
        User.query.filter_by(email=test_email).delete()
        db.session.commit()
        
        print("\n" + "="*70)
        print("✅ TEST COMPLETE")
        print("="*70)
        print("\nIF BOTH TESTS PASSED:")
        print("   ✅ Backend is working correctly")
        print("   ✅ Flutter should be able to fetch profile")
        print("   ✅ Check Flutter logs for any errors")
        print("\nIF TESTS FAILED:")
        print("   ❌ Backend API has issues")
        print("   ❌ Check console above for error messages")
        print("\n")

if __name__ == '__main__':
    test_profile_api()

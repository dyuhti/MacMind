"""
Test script for the feedback API
Tests the complete feedback submission flow
"""
import requests
import json
from datetime import datetime

# Configuration
BASE_URL = "http://localhost:5000"  # Change to your Render URL: https://your-app.onrender.com
EMAIL = "test@example.com"
PASSWORD = "testpassword123"


def test_login():
    """Test user login to get token"""
    print("\n" + "="*60)
    print("TEST 1: User Login")
    print("="*60)
    
    url = f"{BASE_URL}/api/auth/login"
    payload = {
        "email": EMAIL,
        "password": PASSWORD
    }
    
    print(f"POST {url}")
    print(f"Payload: {json.dumps(payload, indent=2)}")
    
    try:
        response = requests.post(url, json=payload, timeout=10)
        print(f"\nStatus: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        if response.status_code == 200:
            token = response.json().get('token')
            print(f"\n✅ Login successful!")
            print(f"Token: {token[:20]}...")
            return token
        else:
            print(f"\n❌ Login failed!")
            return None
    except Exception as e:
        print(f"\n❌ Error: {e}")
        return None


def test_submit_feedback(token):
    """Test feedback submission"""
    print("\n" + "="*60)
    print("TEST 2: Submit Feedback")
    print("="*60)
    
    url = f"{BASE_URL}/api/submit_feedback"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    payload = {
        "rating": 5,
        "category": "Bug Report",
        "feedback_message": "Test feedback from API - " + datetime.now().isoformat()
    }
    
    print(f"POST {url}")
    print(f"Headers: Authorization: Bearer {token[:20]}...")
    print(f"Payload: {json.dumps(payload, indent=2)}")
    
    try:
        response = requests.post(url, json=payload, headers=headers, timeout=10)
        print(f"\nStatus: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        if response.status_code == 200:
            print(f"\n✅ Feedback submitted successfully!")
            feedback_id = response.json().get('feedback', {}).get('id')
            return feedback_id
        else:
            print(f"\n❌ Feedback submission failed!")
            return None
    except Exception as e:
        print(f"\n❌ Error: {e}")
        return None


def test_get_user_feedback(token):
    """Test retrieving user's feedback"""
    print("\n" + "="*60)
    print("TEST 3: Get User's Feedback")
    print("="*60)
    
    url = f"{BASE_URL}/api/feedback"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    print(f"GET {url}")
    print(f"Headers: Authorization: Bearer {token[:20]}...")
    
    try:
        response = requests.get(url, headers=headers, timeout=10)
        print(f"\nStatus: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        if response.status_code == 200:
            count = response.json().get('count', 0)
            print(f"\n✅ Retrieved {count} feedback entries!")
            return True
        else:
            print(f"\n❌ Failed to retrieve feedback!")
            return False
    except Exception as e:
        print(f"\n❌ Error: {e}")
        return False


def test_get_specific_feedback(token, feedback_id):
    """Test retrieving specific feedback"""
    print("\n" + "="*60)
    print("TEST 4: Get Specific Feedback")
    print("="*60)
    
    url = f"{BASE_URL}/api/feedback/{feedback_id}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    print(f"GET {url}")
    print(f"Headers: Authorization: Bearer {token[:20]}...")
    
    try:
        response = requests.get(url, headers=headers, timeout=10)
        print(f"\nStatus: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        if response.status_code == 200:
            print(f"\n✅ Retrieved feedback successfully!")
            return True
        else:
            print(f"\n❌ Failed to retrieve feedback!")
            return False
    except Exception as e:
        print(f"\n❌ Error: {e}")
        return False


def test_get_all_feedback(token):
    """Test retrieving all feedback (admin)"""
    print("\n" + "="*60)
    print("TEST 5: Get All Feedback (Admin)")
    print("="*60)
    
    url = f"{BASE_URL}/api/admin/feedback"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    print(f"GET {url}")
    print(f"Headers: Authorization: Bearer {token[:20]}...")
    
    try:
        response = requests.get(url, headers=headers, timeout=10)
        print(f"\nStatus: {response.status_code}")
        
        # Only print first 2 feedback entries to keep output readable
        data = response.json()
        if 'feedbacks' in data:
            feedbacks = data['feedbacks'][:2]
            count = data.get('count', 0)
            print(f"Total feedbacks: {count}")
            print(f"Sample feedbacks:")
            for f in feedbacks:
                print(f"  - {f.get('user_name')} ({f.get('rating')} ⭐): {f.get('category')}")
        
        if response.status_code == 200:
            print(f"\n✅ Retrieved all feedback successfully!")
            return True
        else:
            print(f"\n❌ Failed to retrieve all feedback!")
            return False
    except Exception as e:
        print(f"\n❌ Error: {e}")
        return False


def run_all_tests():
    """Run all feedback tests"""
    print("\n" + "🧪 FEEDBACK SYSTEM TEST SUITE 🧪".center(60, "="))
    print(f"Base URL: {BASE_URL}")
    print(f"Timestamp: {datetime.now().isoformat()}")
    
    # Test 1: Login
    token = test_login()
    if not token:
        print("\n❌ Cannot proceed without token!")
        return False
    
    # Test 2: Submit feedback
    feedback_id = test_submit_feedback(token)
    if not feedback_id:
        print("\n⚠️  Warning: Feedback submission failed, skipping retrieval tests")
        return False
    
    # Test 3: Get user feedback
    test_get_user_feedback(token)
    
    # Test 4: Get specific feedback
    test_get_specific_feedback(token, feedback_id)
    
    # Test 5: Get all feedback
    test_get_all_feedback(token)
    
    print("\n" + "="*60)
    print("✅ ALL TESTS COMPLETED!")
    print("="*60)
    return True


if __name__ == "__main__":
    print("\n📝 Feedback API Test Script")
    print("Update BASE_URL if testing against Render deployment")
    print("Make sure to replace EMAIL and PASSWORD with valid test credentials\n")
    
    run_all_tests()

"""
API Testing Script for Authentication Endpoints
Tests register, login, and profile endpoints
"""
import requests
import json
import sys
from typing import Dict, Any

# Configuration
BASE_URL = "http://127.0.0.1:5000/api/auth"
HEADERS = {"Content-Type": "application/json"}

# Generate unique test emails to avoid conflicts
import time
TIMESTAMP = int(time.time())

# Test data
TEST_USER = {
    "full_name": "John Doe",
    "email": f"john.doe.{TIMESTAMP}@example.com",
    "password": "Test1234",
    "confirm_password": "Test1234"
}

TEST_USER_2 = {
    "full_name": "Jane Smith",
    "email": f"jane.smith.{TIMESTAMP}@example.com",
    "password": "Test5678",
    "confirm_password": "Test5678"
}


def print_response(title: str, method: str, endpoint: str, status: int, data: Dict[Any, Any]):
    """Pretty print API response"""
    print(f"\n{'='*60}")
    print(f"📝 {title}")
    print(f"{'='*60}")
    print(f"Request:  {method} {endpoint}")
    print(f"Status:   {status}")
    print(f"Response: {json.dumps(data, indent=2)}")
    
    success = data.get('success', False)
    status_icon = "✅" if (success and status < 400) else "❌"
    print(f"{status_icon} Result: {'PASSED' if (success and status < 400) else 'FAILED'}")


def test_register() -> tuple[bool, str, str]:
    """Test user registration"""
    print("\n\n🔄 TEST 1: USER REGISTRATION")
    print("="*60)
    
    endpoint = f"{BASE_URL}/register"
    
    print(f"📤 Sending registration request...")
    print(f"   Full Name: {TEST_USER['full_name']}")
    print(f"   Email: {TEST_USER['email']}")
    
    try:
        response = requests.post(endpoint, json=TEST_USER, headers=HEADERS)
        data = response.json()
        
        print_response("Registration Response", "POST", "/register", response.status_code, data)
        
        if response.status_code == 201 and data.get('success'):
            token = data.get('token')
            user_id = data.get('user', {}).get('id')
            return True, token, user_id
        else:
            return False, None, None
    
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return False, None, None


def test_register_duplicate_email() -> bool:
    """Test registration with duplicate email"""
    print("\n\n🔄 TEST 2: DUPLICATE EMAIL VALIDATION")
    print("="*60)
    
    endpoint = f"{BASE_URL}/register"
    
    print(f"📤 Trying to register with existing email...")
    
    try:
        response = requests.post(endpoint, json=TEST_USER, headers=HEADERS)
        data = response.json()
        
        print_response("Duplicate Email Response", "POST", "/register", response.status_code, data)
        
        # Should fail because email already exists
        return response.status_code == 400 and not data.get('success')
    
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return False


def test_register_password_mismatch() -> bool:
    """Test registration with mismatched passwords"""
    print("\n\n🔄 TEST 3: PASSWORD MISMATCH VALIDATION")
    print("="*60)
    
    endpoint = f"{BASE_URL}/register"
    
    bad_data = {
        "full_name": "Test User",
        "email": "test@example.com",
        "password": "Test1234",
        "confirm_password": "Different1234"
    }
    
    print(f"📤 Trying to register with mismatched passwords...")
    
    try:
        response = requests.post(endpoint, json=bad_data, headers=HEADERS)
        data = response.json()
        
        print_response("Password Mismatch Response", "POST", "/register", response.status_code, data)
        
        return response.status_code == 400 and not data.get('success')
    
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return False


def test_register_missing_fields() -> bool:
    """Test registration with missing fields"""
    print("\n\n🔄 TEST 4: MISSING FIELDS VALIDATION")
    print("="*60)
    
    endpoint = f"{BASE_URL}/register"
    
    incomplete_data = {
        "full_name": "Test User",
        "email": "test@example.com"
        # Missing password and confirm_password
    }
    
    print(f"📤 Trying to register with missing fields...")
    
    try:
        response = requests.post(endpoint, json=incomplete_data, headers=HEADERS)
        data = response.json()
        
        print_response("Missing Fields Response", "POST", "/register", response.status_code, data)
        
        return response.status_code == 400
    
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return False


def test_login(email: str = TEST_USER['email'], password: str = TEST_USER['password']) -> tuple[bool, str]:
    """Test user login"""
    print("\n\n🔄 TEST 5: USER LOGIN")
    print("="*60)
    
    endpoint = f"{BASE_URL}/login"
    login_data = {"email": email, "password": password}
    
    print(f"📤 Sending login request...")
    print(f"   Email: {email}")
    print(f"   Password: {'*' * len(password)}")
    
    try:
        response = requests.post(endpoint, json=login_data, headers=HEADERS)
        data = response.json()
        
        print_response("Login Response", "POST", "/login", response.status_code, data)
        
        if response.status_code == 200 and data.get('success'):
            token = data.get('token')
            return True, token
        else:
            return False, None
    
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return False, None


def test_login_wrong_password() -> bool:
    """Test login with wrong password"""
    print("\n\n🔄 TEST 6: WRONG PASSWORD VALIDATION")
    print("="*60)
    
    endpoint = f"{BASE_URL}/login"
    login_data = {"email": TEST_USER['email'], "password": "WrongPassword123"}
    
    print(f"📤 Trying to login with wrong password...")
    
    try:
        response = requests.post(endpoint, json=login_data, headers=HEADERS)
        data = response.json()
        
        print_response("Wrong Password Response", "POST", "/login", response.status_code, data)
        
        return response.status_code == 401 and not data.get('success')
    
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return False


def test_login_nonexistent_user() -> bool:
    """Test login with non-existent email"""
    print("\n\n🔄 TEST 7: NON-EXISTENT USER VALIDATION")
    print("="*60)
    
    endpoint = f"{BASE_URL}/login"
    login_data = {"email": "nonexistent@example.com", "password": "AnyPassword123"}
    
    print(f"📤 Trying to login with non-existent email...")
    
    try:
        response = requests.post(endpoint, json=login_data, headers=HEADERS)
        data = response.json()
        
        print_response("Non-existent User Response", "POST", "/login", response.status_code, data)
        
        return response.status_code == 401 and not data.get('success')
    
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return False


def test_profile(token: str) -> bool:
    """Test get profile endpoint"""
    print("\n\n🔄 TEST 8: GET USER PROFILE")
    print("="*60)
    
    endpoint = f"{BASE_URL}/profile"
    headers = {**HEADERS, "Authorization": f"Bearer {token}"}
    
    print(f"📤 Sending profile request with token...")
    
    try:
        response = requests.get(endpoint, headers=headers)
        data = response.json()
        
        print_response("Profile Response", "GET", "/profile", response.status_code, data)
        
        return response.status_code == 200 and data.get('success')
    
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return False


def test_profile_no_token() -> bool:
    """Test profile endpoint without token"""
    print("\n\n🔄 TEST 9: PROFILE WITHOUT TOKEN")
    print("="*60)
    
    endpoint = f"{BASE_URL}/profile"
    
    print(f"📤 Trying to get profile without token...")
    
    try:
        response = requests.get(endpoint, headers=HEADERS)
        data = response.json()
        
        print_response("No Token Response", "GET", "/profile", response.status_code, data)
        
        return response.status_code == 401
    
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return False


def test_verify_token(token: str) -> bool:
    """Test verify token endpoint"""
    print("\n\n🔄 TEST 10: VERIFY TOKEN")
    print("="*60)
    
    endpoint = f"{BASE_URL}/verify-token"
    headers = {**HEADERS, "Authorization": f"Bearer {token}"}
    
    print(f"📤 Sending token verification request...")
    
    try:
        response = requests.post(endpoint, headers=headers)
        data = response.json()
        
        print_response("Verify Token Response", "POST", "/verify-token", response.status_code, data)
        
        return response.status_code == 200 and data.get('success')
    
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return False


def main():
    """Run all tests"""
    print("\n")
    print("╔═══════════════════════════════════════════════════════════╗")
    print("║          AUTH API ENDPOINT TESTING SUITE                 ║")
    print("╚═══════════════════════════════════════════════════════════╝")
    
    # Check if server is running
    try:
        response = requests.get(f"{BASE_URL}/register", timeout=2)
    except requests.exceptions.ConnectionError:
        print("❌ ERROR: Cannot connect to server at http://127.0.0.1:5000")
        print("   Please start the Flask server first:")
        print("   cd backend && python run.py")
        return False
    except:
        pass
    
    results = {}
    token = None
    
    # Test 1: Registration
    success, token, user_id = test_register()
    results['Registration'] = success
    
    if not success:
        print("\n⚠️  Registration failed, skipping dependent tests...")
        return False
    
    # Test 2: Duplicate email
    results['Duplicate Email Validation'] = test_register_duplicate_email()
    
    # Test 3: Password mismatch
    results['Password Mismatch Validation'] = test_register_password_mismatch()
    
    # Test 4: Missing fields
    results['Missing Fields Validation'] = test_register_missing_fields()
    
    # Test 5: Login
    success, token = test_login()
    results['Login'] = success
    
    if not token:
        print("\n⚠️  Login failed, skipping token-dependent tests...")
    else:
        # Test 6: Wrong password
        results['Wrong Password Validation'] = test_login_wrong_password()
        
        # Test 7: Non-existent user
        results['Non-existent User Validation'] = test_login_nonexistent_user()
        
        # Test 8: Get profile
        results['Get Profile'] = test_profile(token)
        
        # Test 9: Profile without token
        results['Profile Without Token'] = test_profile_no_token()
        
        # Test 10: Verify token
        results['Verify Token'] = test_verify_token(token)
    
    # Print summary
    print("\n\n")
    print("╔═══════════════════════════════════════════════════════════╗")
    print("║                    TEST SUMMARY                          ║")
    print("╚═══════════════════════════════════════════════════════════╝")
    
    passed = sum(1 for v in results.values() if v)
    total = len(results)
    
    for test_name, result in results.items():
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status}: {test_name}")
    
    print(f"\n📊 Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed!")
        return True
    else:
        print(f"⚠️  {total - passed} test(s) failed!")
        return False


if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)

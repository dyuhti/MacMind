"""
Test script for MacMind Backend Auth Endpoints
Tests the full login flow: Register → Login → Verify Token
Run this to verify your backend is working correctly!
"""

import requests
import json
from datetime import datetime

# Configuration
BASE_URL = "http://127.0.0.1:5000/api"
HEADERS = {"Content-Type": "application/json"}

# Colors for output
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    END = '\033[0m'

def print_section(title):
    """Print a formatted section header"""
    print(f"\n{Colors.BOLD}{Colors.BLUE}{'='*60}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.BLUE}  {title}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.BLUE}{'='*60}{Colors.END}\n")

def print_success(msg):
    """Print success message"""
    print(f"{Colors.GREEN}✅ {msg}{Colors.END}")

def print_error(msg):
    """Print error message"""
    print(f"{Colors.RED}❌ {msg}{Colors.END}")

def print_info(msg):
    """Print info message"""
    print(f"{Colors.YELLOW}ℹ️  {msg}{Colors.END}")

def test_health():
    """Test health endpoint"""
    print_section("Testing Health Endpoint")
    try:
        response = requests.get(f"{BASE_URL}/health")
        if response.status_code == 200:
            print_success("Server is running!")
            print(f"Response: {json.dumps(response.json(), indent=2)}")
            return True
        else:
            print_error(f"Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print_error(f"Could not connect to server: {e}")
        print_info("Make sure Flask server is running: python run.py")
        return False

def test_register():
    """Test user registration"""
    print_section("Testing User Registration")
    
    # Create unique user for testing
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    test_user = {
        "email": f"test_{timestamp}@example.com",
        "password": "TestPass123!",
        "username": f"testuser_{timestamp}",
        "hospital_id": "HOSP_TEST_001"
    }
    
    print_info(f"Registering user: {test_user['username']}")
    
    try:
        response = requests.post(
            f"{BASE_URL}/auth/register",
            json=test_user,
            headers=HEADERS
        )
        
        if response.status_code == 201:
            data = response.json()
            print_success("Registration successful!")
            print(f"Response:\n{json.dumps(data, indent=2)}")
            return {
                'success': True,
                'user': test_user,
                'user_id': data.get('user').get('user_id'),
                'token': data.get('token')
            }
        else:
            print_error(f"Registration failed: {response.status_code}")
            print(f"Response: {response.text}")
            return {'success': False}
    
    except Exception as e:
        print_error(f"Registration error: {e}")
        return {'success': False}

def test_login(user_email, user_password):
    """Test user login"""
    print_section("Testing User Login")
    
    login_data = {
        "email": user_email,
        "password": user_password
    }
    
    print_info(f"Logging in with email: {user_email}")
    
    try:
        response = requests.post(
            f"{BASE_URL}/auth/login",
            json=login_data,
            headers=HEADERS
        )
        
        if response.status_code == 200:
            data = response.json()
            print_success("Login successful!")
            print(f"Response:\n{json.dumps(data, indent=2)}")
            return {
                'success': True,
                'token': data.get('token'),
                'user_id': data.get('user').get('user_id')
            }
        else:
            print_error(f"Login failed: {response.status_code}")
            print(f"Response: {response.text}")
            return {'success': False}
    
    except Exception as e:
        print_error(f"Login error: {e}")
        return {'success': False}

def test_verify_token(token):
    """Test token verification"""
    print_section("Testing Token Verification")
    
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {token}"
    }
    
    print_info(f"Token: {token[:50]}...")
    
    try:
        response = requests.post(
            f"{BASE_URL}/auth/verify-token",
            headers=headers
        )
        
        if response.status_code == 200:
            data = response.json()
            print_success("Token is valid!")
            print(f"Response:\n{json.dumps(data, indent=2)}")
            return {'success': True}
        else:
            print_error(f"Token verification failed: {response.status_code}")
            print(f"Response: {response.text}")
            return {'success': False}
    
    except Exception as e:
        print_error(f"Token verification error: {e}")
        return {'success': False}

def test_profile(token):
    """Test profile retrieval"""
    print_section("Testing Profile Retrieval")
    
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {token}"
    }
    
    try:
        response = requests.get(
            f"{BASE_URL}/auth/profile",
            headers=headers
        )
        
        if response.status_code == 200:
            data = response.json()
            print_success("Profile retrieved successfully!")
            print(f"Response:\n{json.dumps(data, indent=2)}")
            return {'success': True}
        else:
            print_error(f"Profile retrieval failed: {response.status_code}")
            print(f"Response: {response.text}")
            return {'success': False}
    
    except Exception as e:
        print_error(f"Profile retrieval error: {e}")
        return {'success': False}

def test_invalid_credentials():
    """Test login with invalid credentials"""
    print_section("Testing Invalid Login (Should Fail)")
    
    login_data = {
        "email": "nonexistent@example.com",
        "password": "wrongpassword"
    }
    
    print_info("Attempting login with non-existent user...")
    
    try:
        response = requests.post(
            f"{BASE_URL}/auth/login",
            json=login_data,
            headers=HEADERS
        )
        
        if response.status_code == 401:
            print_success("Correctly rejected invalid credentials!")
            print(f"Response: {json.dumps(response.json(), indent=2)}")
            return {'success': True}
        else:
            print_error(f"Unexpected status code: {response.status_code}")
            return {'success': False}
    
    except Exception as e:
        print_error(f"Error: {e}")
        return {'success': False}

def run_all_tests():
    """Run complete test suite"""
    print(f"\n{Colors.BOLD}{Colors.BLUE}")
    print("╔════════════════════════════════════════════════════════╗")
    print("║  MacMind Backend Authentication Test Suite              ║")
    print("║  Testing: Register → Login → Token Verification         ║")
    print("╚════════════════════════════════════════════════════════╝")
    print(f"{Colors.END}")
    
    results = {
        'health': False,
        'register': False,
        'login': False,
        'verify_token': False,
        'profile': False,
        'invalid_credentials': False
    }
    
    # Test 1: Health Check
    if not test_health():
        print_error("Cannot proceed - server is not running!")
        return results
    results['health'] = True
    
    # Test 2: Registration
    reg_result = test_register()
    if not reg_result['success']:
        print_error("Registration failed - stopping tests")
        return results
    results['register'] = True
    
    # Test 3: Login
    login_result = test_login(reg_result['user']['email'], reg_result['user']['password'])
    if not login_result['success']:
        print_error("Login failed - stopping tests")
        return results
    results['login'] = True
    
    # Test 4: Verify Token
    if not test_verify_token(login_result['token'])['success']:
        print_error("Token verification failed")
    else:
        results['verify_token'] = True
    
    # Test 5: Get Profile
    if not test_profile(login_result['token'])['success']:
        print_error("Profile retrieval failed")
    else:
        results['profile'] = True
    
    # Test 6: Invalid Credentials
    if not test_invalid_credentials()['success']:
        print_error("Invalid credential handling failed")
    else:
        results['invalid_credentials'] = True
    
    # Print summary
    print_section("Test Summary")
    total = len(results)
    passed = sum(results.values())
    
    for test_name, passed_status in results.items():
        status = f"{Colors.GREEN}✅ PASSED{Colors.END}" if passed_status else f"{Colors.RED}❌ FAILED{Colors.END}"
        print(f"  {test_name.replace('_', ' ').title():.<40} {status}")
    
    print(f"\n{Colors.BOLD}Total: {passed}/{total} tests passed{Colors.END}")
    
    if passed == total:
        print(f"\n{Colors.GREEN}{Colors.BOLD}🎉 All tests passed! Backend is working correctly!{Colors.END}")
    else:
        print(f"\n{Colors.YELLOW}{Colors.BOLD}⚠️  Some tests failed. Please check the errors above.{Colors.END}")
    
    return results

if __name__ == "__main__":
    run_all_tests()

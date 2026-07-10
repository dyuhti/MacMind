import os
import sys
import unittest

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app import create_app, db


class DeleteAccountRouteTests(unittest.TestCase):
    def setUp(self):
        self.app = create_app('testing')
        self.app.config['TESTING'] = True
        self.client = self.app.test_client()
        with self.app.app_context():
            db.drop_all()
            db.create_all()

    def tearDown(self):
        with self.app.app_context():
            db.session.remove()
            db.drop_all()

    def _register_user(self):
        register_resp = self.client.post('/api/auth/register', json={
            'full_name': 'Delete Me',
            'email': 'delete@example.com',
            'password': 'StrongPass123',
            'confirm_password': 'StrongPass123',
        })
        self.assertEqual(register_resp.status_code, 201)
        return register_resp.get_json()['user']['email']

    def test_delete_account_removes_user_and_returns_success(self):
        email = self._register_user()
        delete_resp = self.client.delete('/api/auth/delete-account', headers={
            'Content-Type': 'application/json',
        }, json={
            'email': email,
            'password': 'StrongPass123',
            'confirm_password': 'StrongPass123',
        })

        self.assertEqual(delete_resp.status_code, 200)
        payload = delete_resp.get_json()
        self.assertTrue(payload['success'])
        self.assertIn('deleted', payload['message'].lower())

        login_resp = self.client.post('/api/auth/login', json={
            'email': email,
            'password': 'StrongPass123',
        })
        self.assertEqual(login_resp.status_code, 401)

    def test_delete_account_requires_matching_password_confirmation(self):
        email = self._register_user()
        delete_resp = self.client.delete('/api/auth/delete-account', json={
            'email': email,
            'password': 'StrongPass123',
            'confirm_password': 'WrongPass123',
        })

        self.assertEqual(delete_resp.status_code, 400)
        self.assertIn('match', delete_resp.get_json()['message'].lower())

    def test_delete_account_options_preflight_is_allowed(self):
        response = self.client.options('/api/auth/delete-account', headers={
            'Origin': 'https://example.github.io',
            'Access-Control-Request-Method': 'DELETE',
            'Access-Control-Request-Headers': 'Content-Type,Authorization',
        })

        self.assertEqual(response.status_code, 200)
        self.assertIn('DELETE', response.headers.get('Allow', ''))


if __name__ == '__main__':
    unittest.main()

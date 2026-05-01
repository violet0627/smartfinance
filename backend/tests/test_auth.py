# test_auth.py - Tests for /api/auth routes
#
# Each function is one test case. pytest discovers them by the 'test_' prefix.
# We use the 'client' fixture from conftest.py to send HTTP requests.
# We use the 'db' and 'sample_user' fixtures to set up test data.
#
# Pattern: Arrange (set up data) -> Act (call the API) -> Assert (check the result)

import json


# ---------------------------------------------------------------------------
# POST /api/auth/register
# ---------------------------------------------------------------------------

def test_register_success(client, db):
    # Happy path — valid data should create a user and return 201
    response = client.post('/api/auth/register', json={
        'email': 'newuser@example.com',
        'password': 'NewPass123!',
        'fullName': 'New User'
    })
    assert response.status_code == 201
    data = response.get_json()
    assert data['message'] == 'User registered successfully. Please verify your email.'
    assert 'accessToken' in data
    assert 'refreshToken' in data


def test_register_missing_field(client):
    # Missing 'fullName' should return 400 Bad Request
    response = client.post('/api/auth/register', json={
        'email': 'missing@example.com',
        'password': 'Pass123!'
        # fullName is intentionally missing
    })
    assert response.status_code == 400
    assert 'fullName' in response.get_json()['error']


def test_register_invalid_email(client):
    # Malformed email should be rejected before touching the database
    response = client.post('/api/auth/register', json={
        'email': 'not-an-email',
        'password': 'Pass123!',
        'fullName': 'Test'
    })
    assert response.status_code == 400
    assert 'email' in response.get_json()['error'].lower()


def test_register_weak_password(client):
    # Password with no uppercase should fail validation
    response = client.post('/api/auth/register', json={
        'email': 'weakpass@example.com',
        'password': 'alllowercase1!',
        'fullName': 'Weak Pass'
    })
    assert response.status_code == 400
    assert 'uppercase' in response.get_json()['error'].lower()


def test_register_duplicate_email(client, sample_user):
    # Registering with an already-used email should return 409 Conflict
    response = client.post('/api/auth/register', json={
        'email': 'testuser@example.com',   # same as sample_user
        'password': 'AnotherPass123!',
        'fullName': 'Duplicate User'
    })
    assert response.status_code == 409
    assert 'already registered' in response.get_json()['error'].lower()


# ---------------------------------------------------------------------------
# POST /api/auth/login
# ---------------------------------------------------------------------------

def test_login_success(client, sample_user):
    # Correct credentials should return 200 with tokens
    response = client.post('/api/auth/login', json={
        'email': 'testuser@example.com',
        'password': 'TestPass123!'
    })
    assert response.status_code == 200
    data = response.get_json()
    assert 'accessToken' in data
    assert 'refreshToken' in data
    assert data['message'] == 'Login successful'


def test_login_wrong_password(client, sample_user):
    # Wrong password should return 401 Unauthorized
    response = client.post('/api/auth/login', json={
        'email': 'testuser@example.com',
        'password': 'WrongPassword!'
    })
    assert response.status_code == 401
    assert 'Invalid' in response.get_json()['error']


def test_login_nonexistent_user(client):
    # Email not in database should also return 401 (same message — no info leak)
    response = client.post('/api/auth/login', json={
        'email': 'ghost@example.com',
        'password': 'AnyPass123!'
    })
    assert response.status_code == 401


def test_login_missing_fields(client):
    # Empty body should return 400
    response = client.post('/api/auth/login', json={})
    assert response.status_code == 400


# ---------------------------------------------------------------------------
# POST /api/auth/refresh
# ---------------------------------------------------------------------------

def test_refresh_token_success(client, sample_user):
    # First login to get a real refresh token, then use it to get a new access token
    login_response = client.post('/api/auth/login', json={
        'email': 'testuser@example.com',
        'password': 'TestPass123!'
    })
    refresh_token = login_response.get_json()['refreshToken']

    response = client.post('/api/auth/refresh', json={
        'refreshToken': refresh_token
    })
    assert response.status_code == 200
    assert 'accessToken' in response.get_json()


def test_refresh_token_invalid(client):
    # A garbage token should return 401
    response = client.post('/api/auth/refresh', json={
        'refreshToken': 'this.is.not.a.real.token'
    })
    assert response.status_code == 401


def test_refresh_token_missing(client):
    # No token at all should return 400
    response = client.post('/api/auth/refresh', json={})
    assert response.status_code == 400


# ---------------------------------------------------------------------------
# GET /api/auth/user/<user_id>
# ---------------------------------------------------------------------------

def test_get_user_success(client, sample_user):
    response = client.get(f'/api/auth/user/{sample_user.UserId}')
    assert response.status_code == 200
    data = response.get_json()
    assert data['user']['email'] == 'testuser@example.com'


def test_get_user_not_found(client):
    # User ID 99999 doesn't exist
    response = client.get('/api/auth/user/99999')
    assert response.status_code == 404


# ---------------------------------------------------------------------------
# POST /api/auth/forgot-password
# ---------------------------------------------------------------------------

def test_forgot_password_existing_email(client, sample_user):
    # Always returns 200 regardless of whether the email exists (anti-enumeration)
    response = client.post('/api/auth/forgot-password', json={
        'email': 'testuser@example.com'
    })
    assert response.status_code == 200


def test_forgot_password_nonexistent_email(client):
    # Should still return 200 — never reveal whether email is registered
    response = client.post('/api/auth/forgot-password', json={
        'email': 'nobody@example.com'
    })
    assert response.status_code == 200


def test_forgot_password_invalid_email(client):
    # Malformed email should return 400
    response = client.post('/api/auth/forgot-password', json={
        'email': 'notanemail'
    })
    assert response.status_code == 400

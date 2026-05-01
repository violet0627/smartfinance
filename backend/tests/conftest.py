# conftest.py - pytest shared fixtures
# pytest automatically loads this file before running any test.
# Fixtures defined here are available to every test file without importing.

import pytest
from app import create_app, db as _db
from app.models.user import User


@pytest.fixture(scope='function')
def app():
    # scope='function' means a FRESH in-memory SQLite database for EVERY test.
    # This avoids cross-test contamination — no shared state between tests.
    # Slightly slower (creates tables 27 times) but completely clean.
    test_app = create_app('testing')
    with test_app.app_context():
        _db.create_all()
        yield test_app
        _db.drop_all()     # destroy all tables after each test


@pytest.fixture(scope='function')
def client(app):
    # Flask test client lets us send HTTP requests without running a real server.
    return app.test_client()


@pytest.fixture(scope='function')
def db(app):
    # Yields the database instance. Each test already has a fresh DB from the
    # app fixture above, so no manual cleanup is needed here.
    with app.app_context():
        yield _db
        _db.session.rollback()


@pytest.fixture
def sample_user(db):
    # Creates a real User row for tests that need an existing user.
    # No manual teardown needed — the app fixture drops all tables after each test.
    user = User(
        Email='testuser@example.com',
        FullName='Test User',
        PhoneNumber=None
    )
    user.set_password('TestPass123!')
    db.session.add(user)
    db.session.commit()
    yield user

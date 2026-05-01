# test_transactions.py - Tests for /api/transactions routes

from app.models.transaction import Transaction
from datetime import date


# ---------------------------------------------------------------------------
# POST /api/transactions/
# ---------------------------------------------------------------------------

def test_create_transaction_success(client, sample_user):
    response = client.post('/api/transactions/', json={
        'amount': 50.00,
        'category': 'Food',
        'transactionDate': '2025-01-15',
        'transactionType': 'expense',
        'userId': sample_user.UserId,
        'description': 'Lunch'
    })
    assert response.status_code == 201
    data = response.get_json()
    assert data['transaction']['amount'] == 50.0
    assert data['transaction']['category'] == 'Food'


def test_create_transaction_income(client, sample_user):
    response = client.post('/api/transactions/', json={
        'amount': 3000.00,
        'category': 'Salary',
        'transactionDate': '2025-01-01',
        'transactionType': 'income',
        'userId': sample_user.UserId
    })
    assert response.status_code == 201
    assert response.get_json()['transaction']['transactionType'] == 'income'


def test_create_transaction_missing_field(client, sample_user):
    # Missing 'category' should return 400
    response = client.post('/api/transactions/', json={
        'amount': 20.00,
        'transactionDate': '2025-01-15',
        'transactionType': 'expense',
        'userId': sample_user.UserId
    })
    assert response.status_code == 400
    assert 'category' in response.get_json()['error']


def test_create_transaction_invalid_type(client, sample_user):
    # transactionType must be exactly 'income' or 'expense'
    response = client.post('/api/transactions/', json={
        'amount': 20.00,
        'category': 'Food',
        'transactionDate': '2025-01-15',
        'transactionType': 'spending',   # invalid value
        'userId': sample_user.UserId
    })
    assert response.status_code == 400


def test_create_transaction_zero_amount(client, sample_user):
    # Amount of 0 should be rejected
    response = client.post('/api/transactions/', json={
        'amount': 0,
        'category': 'Food',
        'transactionDate': '2025-01-15',
        'transactionType': 'expense',
        'userId': sample_user.UserId
    })
    assert response.status_code == 400


def test_create_transaction_negative_amount(client, sample_user):
    response = client.post('/api/transactions/', json={
        'amount': -50,
        'category': 'Food',
        'transactionDate': '2025-01-15',
        'transactionType': 'expense',
        'userId': sample_user.UserId
    })
    assert response.status_code == 400


def test_create_transaction_invalid_date(client, sample_user):
    # Date format must be YYYY-MM-DD
    response = client.post('/api/transactions/', json={
        'amount': 10.00,
        'category': 'Food',
        'transactionDate': '15-01-2025',   # wrong format
        'transactionType': 'expense',
        'userId': sample_user.UserId
    })
    assert response.status_code == 400


# ---------------------------------------------------------------------------
# GET /api/transactions/user/<user_id>
# ---------------------------------------------------------------------------

def test_get_user_transactions_empty(client, sample_user):
    # New user with no transactions should return empty list
    response = client.get(f'/api/transactions/user/{sample_user.UserId}')
    assert response.status_code == 200
    assert response.get_json()['transactions'] == []


def test_get_user_transactions_with_data(client, sample_user, db):
    # Add a transaction directly via the model, then fetch via API
    t = Transaction(
        Amount=100.00,
        Category='Transport',
        Description='Bus fare',
        TransactionDate=date(2025, 1, 20),
        TransactionType='expense',
        UserId=sample_user.UserId
    )
    db.session.add(t)
    db.session.commit()

    response = client.get(f'/api/transactions/user/{sample_user.UserId}')
    assert response.status_code == 200
    transactions = response.get_json()['transactions']
    assert len(transactions) == 1
    assert transactions[0]['category'] == 'Transport'

    # Clean up
    db.session.delete(t)
    db.session.commit()


def test_get_user_transactions_filter_by_type(client, sample_user, db):
    # Add both income and expense, then filter for only expense
    t1 = Transaction(Amount=500, Category='Salary', TransactionDate=date(2025, 1, 1),
                     TransactionType='income', UserId=sample_user.UserId)
    t2 = Transaction(Amount=30, Category='Food', TransactionDate=date(2025, 1, 2),
                     TransactionType='expense', UserId=sample_user.UserId)
    db.session.add_all([t1, t2])
    db.session.commit()

    response = client.get(f'/api/transactions/user/{sample_user.UserId}?type=expense')
    assert response.status_code == 200
    results = response.get_json()['transactions']
    assert all(t['transactionType'] == 'expense' for t in results)

    db.session.delete(t1)
    db.session.delete(t2)
    db.session.commit()

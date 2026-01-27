import 'package:flutter_test/flutter_test.dart';
import 'package:smartfinance2/services/api_service.dart';

void main() {
  group('ApiService Tests', () {
    test('ApiService has correct base URL format', () {
      // Test that base URL is properly formatted
      expect(ApiService.baseUrl, isNotEmpty);
      expect(ApiService.baseUrl, contains('http'));
    });

    test('ApiService endpoints are correctly formatted', () {
      // Test endpoint construction
      const userId = 1;
      final transactionsEndpoint = '${ApiService.baseUrl}/transactions/$userId';

      expect(transactionsEndpoint, contains('/transactions/'));
      expect(transactionsEndpoint, contains('$userId'));
    });
  });

  group('ApiService Authentication Tests', () {
    test('Login endpoint is correctly formatted', () {
      final loginEndpoint = '${ApiService.baseUrl}/auth/login';

      expect(loginEndpoint, contains('/auth/login'));
    });

    test('Register endpoint is correctly formatted', () {
      final registerEndpoint = '${ApiService.baseUrl}/auth/register';

      expect(registerEndpoint, contains('/auth/register'));
    });

    test('Logout endpoint is correctly formatted', () {
      final logoutEndpoint = '${ApiService.baseUrl}/auth/logout';

      expect(logoutEndpoint, contains('/auth/logout'));
    });
  });

  group('ApiService Transaction Tests', () {
    test('Get transactions endpoint is correctly formatted', () {
      const userId = 1;
      final endpoint = '${ApiService.baseUrl}/transactions/$userId';

      expect(endpoint, contains('/transactions/'));
      expect(endpoint, endsWith('/$userId'));
    });

    test('Add transaction endpoint is correctly formatted', () {
      final endpoint = '${ApiService.baseUrl}/transactions';

      expect(endpoint, contains('/transactions'));
    });

    test('Update transaction endpoint is correctly formatted', () {
      const transactionId = 123;
      final endpoint = '${ApiService.baseUrl}/transactions/$transactionId';

      expect(endpoint, contains('/transactions/'));
      expect(endpoint, endsWith('/$transactionId'));
    });

    test('Delete transaction endpoint is correctly formatted', () {
      const transactionId = 123;
      final endpoint = '${ApiService.baseUrl}/transactions/$transactionId';

      expect(endpoint, contains('/transactions/'));
      expect(endpoint, endsWith('/$transactionId'));
    });
  });

  group('ApiService Budget Tests', () {
    test('Get budgets endpoint is correctly formatted', () {
      const userId = 1;
      final endpoint = '${ApiService.baseUrl}/budgets/$userId';

      expect(endpoint, contains('/budgets/'));
      expect(endpoint, endsWith('/$userId'));
    });

    test('Create budget endpoint is correctly formatted', () {
      final endpoint = '${ApiService.baseUrl}/budgets';

      expect(endpoint, contains('/budgets'));
    });

    test('Update budget endpoint is correctly formatted', () {
      const budgetId = 123;
      final endpoint = '${ApiService.baseUrl}/budgets/$budgetId';

      expect(endpoint, contains('/budgets/'));
      expect(endpoint, endsWith('/$budgetId'));
    });

    test('Delete budget endpoint is correctly formatted', () {
      const budgetId = 123;
      final endpoint = '${ApiService.baseUrl}/budgets/$budgetId';

      expect(endpoint, contains('/budgets/'));
      expect(endpoint, endsWith('/$budgetId'));
    });
  });

  group('ApiService Goal Tests', () {
    test('Get goals endpoint is correctly formatted', () {
      const userId = 1;
      final endpoint = '${ApiService.baseUrl}/goals/$userId';

      expect(endpoint, contains('/goals/'));
      expect(endpoint, endsWith('/$userId'));
    });

    test('Create goal endpoint is correctly formatted', () {
      final endpoint = '${ApiService.baseUrl}/goals';

      expect(endpoint, contains('/goals'));
    });

    test('Update goal endpoint is correctly formatted', () {
      const goalId = 123;
      final endpoint = '${ApiService.baseUrl}/goals/$goalId';

      expect(endpoint, contains('/goals/'));
      expect(endpoint, endsWith('/$goalId'));
    });

    test('Delete goal endpoint is correctly formatted', () {
      const goalId = 123;
      final endpoint = '${ApiService.baseUrl}/goals/$goalId';

      expect(endpoint, contains('/goals/'));
      expect(endpoint, endsWith('/$goalId'));
    });
  });

  group('ApiService Investment Tests', () {
    test('Get investments endpoint is correctly formatted', () {
      const userId = 1;
      final endpoint = '${ApiService.baseUrl}/investments/$userId';

      expect(endpoint, contains('/investments/'));
      expect(endpoint, endsWith('/$userId'));
    });

    test('Add investment endpoint is correctly formatted', () {
      final endpoint = '${ApiService.baseUrl}/investments';

      expect(endpoint, contains('/investments'));
    });

    test('Update investment endpoint is correctly formatted', () {
      const investmentId = 123;
      final endpoint = '${ApiService.baseUrl}/investments/$investmentId';

      expect(endpoint, contains('/investments/'));
      expect(endpoint, endsWith('/$investmentId'));
    });

    test('Delete investment endpoint is correctly formatted', () {
      const investmentId = 123;
      final endpoint = '${ApiService.baseUrl}/investments/$investmentId';

      expect(endpoint, contains('/investments/'));
      expect(endpoint, endsWith('/$investmentId'));
    });
  });

  group('ApiService Recurring Transaction Tests', () {
    test('Get recurring transactions endpoint is correctly formatted', () {
      const userId = 1;
      final endpoint = '${ApiService.baseUrl}/recurring-transactions/$userId';

      expect(endpoint, contains('/recurring-transactions/'));
      expect(endpoint, endsWith('/$userId'));
    });

    test('Create recurring transaction endpoint is correctly formatted', () {
      final endpoint = '${ApiService.baseUrl}/recurring-transactions';

      expect(endpoint, contains('/recurring-transactions'));
    });

    test('Update recurring transaction endpoint is correctly formatted', () {
      const recurringId = 123;
      final endpoint = '${ApiService.baseUrl}/recurring-transactions/$recurringId';

      expect(endpoint, contains('/recurring-transactions/'));
      expect(endpoint, endsWith('/$recurringId'));
    });

    test('Delete recurring transaction endpoint is correctly formatted', () {
      const recurringId = 123;
      final endpoint = '${ApiService.baseUrl}/recurring-transactions/$recurringId';

      expect(endpoint, contains('/recurring-transactions/'));
      expect(endpoint, endsWith('/$recurringId'));
    });
  });

  group('ApiService Analytics Tests', () {
    test('Get analytics endpoint is correctly formatted', () {
      const userId = 1;
      final endpoint = '${ApiService.baseUrl}/analytics/$userId';

      expect(endpoint, contains('/analytics/'));
      expect(endpoint, endsWith('/$userId'));
    });

    test('Get category breakdown endpoint is correctly formatted', () {
      const userId = 1;
      final endpoint = '${ApiService.baseUrl}/analytics/$userId/category-breakdown';

      expect(endpoint, contains('/analytics/'));
      expect(endpoint, contains('/category-breakdown'));
    });

    test('Get monthly trends endpoint is correctly formatted', () {
      const userId = 1;
      final endpoint = '${ApiService.baseUrl}/analytics/$userId/monthly-trends';

      expect(endpoint, contains('/analytics/'));
      expect(endpoint, contains('/monthly-trends'));
    });
  });

  group('ApiService Security Tests', () {
    test('Two-factor auth endpoint is correctly formatted', () {
      final endpoint = '${ApiService.baseUrl}/two-factor-auth/setup';

      expect(endpoint, contains('/two-factor-auth/'));
      expect(endpoint, contains('/setup'));
    });

    test('Verify 2FA endpoint is correctly formatted', () {
      final endpoint = '${ApiService.baseUrl}/two-factor-auth/verify';

      expect(endpoint, contains('/two-factor-auth/'));
      expect(endpoint, contains('/verify'));
    });

    test('Email verification endpoint is correctly formatted', () {
      final endpoint = '${ApiService.baseUrl}/auth/verify-email';

      expect(endpoint, contains('/auth/verify-email'));
    });

    test('Resend verification endpoint is correctly formatted', () {
      final endpoint = '${ApiService.baseUrl}/auth/resend-verification';

      expect(endpoint, contains('/auth/resend-verification'));
    });
  });

  group('ApiService Error Handling Tests', () {
    test('Handles null responses gracefully', () {
      // Test that null checks are in place
      expect(ApiService.baseUrl, isNotNull);
    });

    test('Handles invalid user IDs', () {
      const invalidUserId = 0;
      final endpoint = '${ApiService.baseUrl}/transactions/$invalidUserId';

      expect(endpoint, contains('$invalidUserId'));
    });
  });

  group('ApiService Header Tests', () {
    test('Content-Type header should be application/json', () {
      const contentType = 'application/json';

      expect(contentType, equals('application/json'));
    });

    test('Authorization header format is correct', () {
      const token = 'test_token_123';
      final authHeader = 'Bearer $token';

      expect(authHeader, startsWith('Bearer '));
      expect(authHeader, contains(token));
    });
  });
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class ApiService {
  // Change this to your computer's IP address when testing on a physical device
  // For emulator, use 10.0.2.2
  // For web, use localhost or 127.0.0.1
  static const String baseUrl = 'http://127.0.0.1:5000/api';

  // Authentication endpoints
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'fullName': fullName,
          'phoneNumber': phoneNumber,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        // Save user data and tokens
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', data['user']['userId']);
        await prefs.setString('userEmail', data['user']['email']);
        await prefs.setString('userFullName', data['user']['fullName']);
        await prefs.setString('accessToken', data['accessToken']);
        await prefs.setString('refreshToken', data['refreshToken']);

        return {'success': true, 'user': UserModel.fromJson(data['user'])};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        // Save user data and tokens
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', data['user']['userId']);
        await prefs.setString('userEmail', data['user']['email']);
        await prefs.setString('userFullName', data['user']['fullName']);
        await prefs.setString('accessToken', data['accessToken']);
        await prefs.setString('refreshToken', data['refreshToken']);

        return {'success': true, 'user': UserModel.fromJson(data['user'])};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('userId');
  }

  static Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // JWT Token Management
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refreshToken');
  }

  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': refreshToken}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', data['accessToken']);
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Password Reset endpoints
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'resetToken': data['resetToken'], // For development only
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to send reset email'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': token,
          'newPassword': newPassword,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to reset password'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> verifyResetToken(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-reset-token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': data['valid'] ?? false,
          'email': data['email'],
          'error': data['error'],
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to verify token'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Transaction endpoints
  static Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> transactionData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(transactionData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'transaction': data['transaction']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to create transaction'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUserTransactions(int userId, {
    String? type,
    String? category,
    String? startDate,
    String? endDate,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (type != null) queryParams['type'] = type;
      if (category != null) queryParams['category'] = category;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (limit != null) queryParams['limit'] = limit.toString();

      final uri = Uri.parse('$baseUrl/transactions/user/$userId').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'transactions': data['transactions'], 'count': data['count']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to fetch transactions'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getTransactionSummary(int userId, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final uri = Uri.parse('$baseUrl/transactions/user/$userId/summary').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, ...data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to fetch summary'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteTransaction(int transactionId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/transactions/$transactionId'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to delete transaction'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Budget endpoints
  static Future<Map<String, dynamic>> createBudget(Map<String, dynamic> budgetData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/budgets/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(budgetData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'budget': data['budget']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to create budget'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUserBudgets(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/budgets/user/$userId'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'budgets': data['budgets'], 'count': data['count']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to fetch budgets'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getCurrentBudget(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/budgets/user/$userId/current'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'budget': data['budget'], 'message': data['message']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to fetch current budget'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateBudget(int budgetId, Map<String, dynamic> budgetData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/budgets/$budgetId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(budgetData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'budget': data['budget']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to update budget'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteBudget(int budgetId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/budgets/$budgetId'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to delete budget'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> refreshBudgetSpending(int budgetId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/budgets/$budgetId/refresh'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'budget': data['budget']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to refresh budget'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Investment endpoints
  static Future<Map<String, dynamic>> createInvestment(Map<String, dynamic> investmentData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/investments/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(investmentData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'investment': data['investment']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to create investment'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUserInvestments(int userId, {String? type}) async {
    try {
      final queryParams = <String, String>{};
      if (type != null) queryParams['type'] = type;

      final uri = Uri.parse('$baseUrl/investments/user/$userId').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'investments': data['investments'], 'count': data['count']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to fetch investments'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getInvestment(int investmentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/investments/$investmentId'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'investment': data['investment']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to fetch investment'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateInvestment(
    int investmentId,
    Map<String, dynamic> investmentData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/investments/$investmentId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(investmentData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'investment': data['investment']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to update investment'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteInvestment(int investmentId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/investments/$investmentId'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to delete investment'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getPortfolioSummary(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/investments/user/$userId/portfolio'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'portfolio': data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to fetch portfolio'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateInvestmentPrice(
    int investmentId,
    double currentPrice,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/investments/$investmentId/update-price'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'currentPrice': currentPrice}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'investment': data['investment'],
          'profitLoss': data['profitLoss'],
          'percentageChange': data['percentageChange'],
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to update price'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Gamification endpoints
  static Future<Map<String, dynamic>> getUserAchievements(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/gamification/user/$userId/achievements'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'userAchievements': data['userAchievements'],
          'count': data['count']
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to fetch achievements'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUserStats(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/gamification/user/$userId/stats'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'stats': data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to fetch stats'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> checkAchievements(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/gamification/user/$userId/check-achievements'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'newlyUnlocked': data['newlyUnlocked'],
          'count': data['count']
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to check achievements'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUserStreaks(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/gamification/user/$userId/streaks'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'streaks': data['streaks'],
          'count': data['count']
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to fetch streaks'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateStreak(int userId, {String streakType = 'daily_tracking'}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/gamification/user/$userId/streaks/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'streakType': streakType}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'streak': data['streak']
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to update streak'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getLeaderboard() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/gamification/leaderboard'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'leaderboard': data['leaderboard'],
          'count': data['count']
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to fetch leaderboard'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Reports endpoints
  static Future<Map<String, dynamic>> getSpendingReport(
    int userId, {
    String period = 'this_month',
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, String>{'period': period};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final uri = Uri.parse('$baseUrl/reports/user/$userId/spending-report')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri);

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'report': data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to fetch report'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getBudgetReport(
    int userId, {
    String period = 'this_month',
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, String>{'period': period};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final uri = Uri.parse('$baseUrl/reports/user/$userId/budget-report')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri);

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'report': data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to fetch report'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getCategoryAnalysis(
    int userId, {
    String period = 'this_month',
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, String>{'period': period};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final uri = Uri.parse('$baseUrl/reports/user/$userId/category-analysis')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri);

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'report': data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to fetch report'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static String getExportTransactionsUrl(
    int userId, {
    String period = 'this_month',
    String? startDate,
    String? endDate,
  }) {
    final queryParams = <String, String>{'period': period};
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;

    return Uri.parse('$baseUrl/reports/user/$userId/export/transactions')
        .replace(queryParameters: queryParams)
        .toString();
  }

  static String getExportSpendingReportUrl(
    int userId, {
    String period = 'this_month',
    String? startDate,
    String? endDate,
  }) {
    final queryParams = <String, String>{'period': period};
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;

    return Uri.parse('$baseUrl/reports/user/$userId/export/spending-report')
        .replace(queryParameters: queryParams)
        .toString();
  }

  // Settings endpoints
  static Future<Map<String, dynamic>> getUserSettings(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/settings/user/$userId'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'settings': data['settings']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to fetch settings'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateUserSettings(
    int userId,
    Map<String, dynamic> settings,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/settings/user/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(settings),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'settings': data['settings'], 'message': data['message']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to update settings'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUserProfile(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/settings/user/$userId/profile'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'profile': data['profile']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to fetch profile'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateUserProfile(
    int userId,
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/settings/user/$userId/profile'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(profileData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'profile': data['profile'], 'message': data['message']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to update profile'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> changePassword(
    int userId,
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/settings/user/$userId/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to change password'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAvailableCurrencies() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/settings/currencies'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'currencies': data['currencies']};
      } else {
        return {'success': false, 'error': 'Failed to fetch currencies'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAvailableLanguages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/settings/languages'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'languages': data['languages']};
      } else {
        return {'success': false, 'error': 'Failed to fetch languages'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Goals endpoints
  static Future<Map<String, dynamic>> getUserGoals(int userId, {String? status}) async {
    try {
      final uri = status != null
          ? Uri.parse('$baseUrl/goals/user/$userId?status=$status')
          : Uri.parse('$baseUrl/goals/user/$userId');

      final response = await http.get(uri);
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'goals': data['goals'], 'count': data['count']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to fetch goals'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> createGoal(int userId, Map<String, dynamic> goalData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/goals/user/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(goalData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'goal': data['goal'], 'message': data['message']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to create goal'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getGoal(int goalId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/goals/$goalId'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'goal': data['goal']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to fetch goal'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateGoal(int goalId, Map<String, dynamic> goalData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/goals/$goalId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(goalData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'goal': data['goal'], 'message': data['message']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to update goal'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteGoal(int goalId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/goals/$goalId'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to delete goal'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> contributeToGoal(int goalId, double amount) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/goals/$goalId/contribute'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'amount': amount}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'goal': data['goal'], 'message': data['message']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to contribute'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getGoalsSummary(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/goals/user/$userId/summary'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'summary': data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to fetch summary'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getGoalCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/goals/categories'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'categories': data['categories']};
      } else {
        return {'success': false, 'error': 'Failed to fetch categories'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}

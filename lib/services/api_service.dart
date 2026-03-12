// ==============================================================================
// api_service.dart - Central API Communication Service
// ==============================================================================
// This is the MAIN service file that handles ALL communication between the
// Flutter app and the Python Flask backend server.
//
// Every API call in the app goes through this file. It contains static methods
// for each API endpoint (authentication, transactions, budgets, investments,
// goals, gamification, settings, reports, 2FA, recurring transactions, security).
//
// Pattern used in every method:
// 1. Build the HTTP request (GET/POST/PUT/DELETE)
// 2. Send it to the backend server
// 3. Parse the JSON response
// 4. Return a Map with 'success': true/false and the relevant data
//
// Key concepts:
// - "static" methods: Can be called without creating an ApiService instance
//   Usage: ApiService.login(...) instead of ApiService().login(...)
// - "async/await": These methods are asynchronous (non-blocking)
//   They wait for the server response without freezing the UI
// - "Future<>": Return type for async methods (a promise of a future value)
// - "json.encode/decode": Converts between Dart objects and JSON strings
// ==============================================================================

import 'dart:convert';                                    // For json.encode() and json.decode()
import 'package:http/http.dart' as http;                  // HTTP client for making API requests
import 'package:shared_preferences/shared_preferences.dart'; // Local device storage for tokens/user data
import '../models/user_model.dart';                       // User data model

class ApiService {
  // ==============================================================================
  // Base URL Configuration
  // ==============================================================================
  // This is the root URL for ALL API calls. Every endpoint URL is built from this.
  //
  // HOW TO FIND YOUR IP (Windows): Open Command Prompt → type "ipconfig"
  //                                Look for "IPv4 Address" under your Wi-Fi adapter
  // HOW TO FIND YOUR IP (Mac/Linux): Open Terminal → type "ifconfig" or "ip addr"
  //
  // - For Android emulator: use 10.0.2.2 (maps to host machine localhost)
  // - For physical device:  use your computer's local IP (e.g., 192.168.x.x)
  //                         *** Device and computer must be on the SAME Wi-Fi ***
  // - For iOS simulator:    use localhost or 127.0.0.1
  //
  // ⚠️  UPDATE THIS IP before running on a new network or different device
  // ==============================================================================
  static const String baseUrl = 'http://192.168.1.38:5000/api';

  // ============================================================================
  // AUTHENTICATION ENDPOINTS
  // ============================================================================
  // These methods handle user registration, login, logout, and session management.
  // ============================================================================

  // ==============================================================================
  // register - Create a New User Account
  // ==============================================================================
  // Sends user registration data to POST /api/auth/register
  // On success (201): Returns the new user object
  // On failure: Returns the error message from the server
  //
  // Note: Does NOT auto-login after registration - user must login manually
  // .timeout() cancels the request if the server doesn't respond within 10 seconds
  // ==============================================================================
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,             // Optional phone number
  }) async {
    try {
      // Send POST request to the register endpoint
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),                // Build full URL: http://...//api/auth/register
        headers: {'Content-Type': 'application/json'},      // Tell server we're sending JSON
        body: json.encode({                                 // Convert Dart Map to JSON string
          'email': email,
          'password': password,
          'fullName': fullName,
          'phoneNumber': phoneNumber,
        }),
      ).timeout(const Duration(seconds: 10));               // Cancel if no response in 10 seconds

      final data = json.decode(response.body);              // Parse JSON response string to Dart Map

      if (response.statusCode == 201) {                     // 201 = Created (success)
        // Don't auto-login on registration - user should login manually
        return {'success': true, 'user': UserModel.fromJson(data['user'])};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Registration failed'};
      }
    } catch (e) {
      // Network errors (no internet, server down, timeout, etc.)
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ==============================================================================
  // login - Authenticate User and Get Tokens
  // ==============================================================================
  // Sends credentials to POST /api/auth/login
  // On success (200): Saves user data and JWT tokens to SharedPreferences,
  //   then returns the user object
  // On failure: Returns the error message
  //
  // SharedPreferences stores:
  // - userId, userEmail, userFullName: User identity info
  // - accessToken: Short-lived JWT for API authentication (expires in 1 hour)
  // - refreshToken: Long-lived JWT for getting new access tokens (expires in 30 days)
  // ==============================================================================
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
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {                     // 200 = OK (success)
        // Save user data and tokens to device storage for future use
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', data['user']['userId']);        // Save user ID
        await prefs.setString('userEmail', data['user']['email']);   // Save email
        await prefs.setString('userFullName', data['user']['fullName']); // Save name
        await prefs.setString('accessToken', data['accessToken']);   // Save access token
        await prefs.setString('refreshToken', data['refreshToken']); // Save refresh token

        return {'success': true, 'user': UserModel.fromJson(data['user'])};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ==============================================================================
  // Session Management Methods
  // ==============================================================================
  // These check login status, get user ID, and handle logout.
  // All use SharedPreferences (local device storage) to check saved data.
  // ==============================================================================

  // Check if user is currently logged in (has a saved userId)
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('userId');  // Returns true if userId key exists
  }

  // Get the current user's ID from device storage (returns null if not logged in)
  static Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');       // Returns null if key doesn't exist
  }

  // Logout by clearing ALL saved data (user info, tokens, everything)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();                // Removes all key-value pairs from storage
  }

  // ============================================================================
  // JWT TOKEN MANAGEMENT
  // ============================================================================
  // These methods manage JWT (JSON Web Token) authentication tokens.
  // - Access Token: Sent with each API request to prove identity (short-lived)
  // - Refresh Token: Used to get a new access token when the old one expires
  // - Auth Headers: Builds the HTTP headers needed for authenticated requests
  // ============================================================================

  // Get the saved access token from device storage
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  // Get the saved refresh token from device storage
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refreshToken');
  }

  // Build HTTP headers with the access token for authenticated API requests
  // The "Bearer" format is a standard way to send JWT tokens:
  // Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',  // Only add if token exists
      // This uses "collection if" - the key-value pair is only included when condition is true
    };
  }

  // ==============================================================================
  // refreshAccessToken - Get a New Access Token Using the Refresh Token
  // ==============================================================================
  // When the access token expires (after 1 hour), this method sends the
  // refresh token to get a new access token without requiring the user to
  // login again. Returns true if successful, false if refresh token is also
  // expired (user must login again).
  // ==============================================================================
  static Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;    // No refresh token = can't refresh

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': refreshToken}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        // Save the new access token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', data['accessToken']);
        return true;                             // Successfully refreshed
      }

      return false;                              // Server rejected the refresh token
    } catch (e) {
      return false;                              // Network error
    }
  }

  // ============================================================================
  // PASSWORD RESET ENDPOINTS
  // ============================================================================
  // These handle the "forgot password" flow:
  // 1. User enters email -> forgotPassword() sends reset email
  // 2. User gets token from email -> verifyResetToken() checks it's valid
  // 3. User enters new password -> resetPassword() changes it
  // ============================================================================

  // Step 1: Request a password reset email
  // Sends POST /api/auth/forgot-password with the user's email
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
          'resetToken': data['resetToken'], // For development only (wouldn't be in production)
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to send reset email'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Step 3: Reset the password using the token from the email
  // Sends POST /api/auth/reset-password with the token and new password
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

  // Step 2: Verify that the reset token is valid (not expired, not used)
  // Sends POST /api/auth/verify-reset-token
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
          'success': data['valid'] ?? false,    // Whether token is valid
          'email': data['email'],                // Email associated with the token
          'error': data['error'],
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to verify token'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ============================================================================
  // EMAIL VERIFICATION ENDPOINTS
  // ============================================================================
  // These handle verifying the user's email address after registration:
  // 1. verifyEmail() - Verify using token from email
  // 2. resendVerification() - Resend the verification email
  // 3. checkVerificationStatus() - Check if email is already verified
  // ============================================================================

  // Verify email using the token sent to the user's email
  static Future<Map<String, dynamic>> verifyEmail(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'], 'user': data['user']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to verify email'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Resend the verification email to the user's email address
  static Future<Map<String, dynamic>> resendVerification(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-verification'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'verificationToken': data['verificationToken'], // For development only
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to resend verification'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Check if a user's email is verified (GET request with userId in URL)
  static Future<Map<String, dynamic>> checkVerificationStatus(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/check-verification/$userId'),
        // No body needed for GET requests - userId is in the URL path
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'emailVerified': data['emailVerified'],  // true or false
          'email': data['email'],
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to check status'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ============================================================================
  // TRANSACTION ENDPOINTS
  // ============================================================================
  // CRUD operations for financial transactions (income and expenses).
  // - Create: POST /api/transactions/
  // - Read:   GET /api/transactions/user/{userId}
  // - Update: PUT /api/transactions/{transactionId}
  // - Delete: DELETE /api/transactions/{transactionId}
  // - Summary: GET /api/transactions/user/{userId}/summary
  // ============================================================================

  // Create a new transaction (POST)
  // transactionData is a Map with: amount, category, transactionType, transactionDate, userId, etc.
  static Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> transactionData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(transactionData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {          // 201 = Created
        return {'success': true, 'transaction': data['transaction']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to create transaction'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Update an existing transaction (PUT)
  // transactionId identifies which transaction to update
  static Future<Map<String, dynamic>> updateTransaction(int transactionId, Map<String, dynamic> transactionData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/transactions/$transactionId'),   // ID in URL path
        headers: {'Content-Type': 'application/json'},
        body: json.encode(transactionData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'transaction': data['transaction']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to update transaction'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ==============================================================================
  // getUserTransactions - Get All Transactions for a User (with Optional Filters)
  // ==============================================================================
  // Sends GET /api/transactions/user/{userId}?type=expense&category=Food&...
  //
  // Query parameters are optional filters:
  // - type: "income" or "expense"
  // - category: Filter by category name (e.g., "Food")
  // - startDate/endDate: Date range filter (YYYY-MM-DD)
  // - limit: Maximum number of results
  //
  // Uri.replace(queryParameters: ...) builds the URL with query string:
  // /api/transactions/user/1?type=expense&category=Food
  // ==============================================================================
  static Future<Map<String, dynamic>> getUserTransactions(int userId, {
    String? type,           // Optional: filter by "income" or "expense"
    String? category,       // Optional: filter by category name
    String? startDate,      // Optional: start of date range
    String? endDate,        // Optional: end of date range
    int? limit,             // Optional: max number of results
  }) async {
    try {
      // Build query parameters map (only include non-null values)
      final queryParams = <String, String>{};
      if (type != null) queryParams['type'] = type;
      if (category != null) queryParams['category'] = category;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (limit != null) queryParams['limit'] = limit.toString();  // Convert int to String for URL

      // Build URL with query parameters
      final uri = Uri.parse('$baseUrl/transactions/user/$userId').replace(queryParameters: queryParams);
      final response = await http.get(uri);                        // GET request (no body needed)

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

  // Get transaction summary (totals for income, expense, by category)
  // Similar to getUserTransactions but returns aggregated data instead of individual transactions
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
        return {'success': true, ...data};   // Spread operator: merge all data fields into result
        // ...data adds all key-value pairs from data into this map
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to fetch summary'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Delete a transaction (DELETE request)
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

  // ============================================================================
  // BUDGET ENDPOINTS
  // ============================================================================
  // CRUD operations for monthly budgets.
  // - Create: POST /api/budgets/
  // - Read all: GET /api/budgets/user/{userId}
  // - Read current: GET /api/budgets/user/{userId}/current
  // - Update: PUT /api/budgets/{budgetId}
  // - Delete: DELETE /api/budgets/{budgetId}
  // - Refresh spending: POST /api/budgets/{budgetId}/refresh
  // ============================================================================

  // Create a new budget
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

  // Get all budgets for a user (all months)
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

  // Get the budget for the current month
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

  // Update an existing budget
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

  // Delete a budget
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

  // Refresh budget spending amounts by recalculating from actual transactions
  // This recalculates how much has been spent in each budget category
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

  // ============================================================================
  // INVESTMENT ENDPOINTS
  // ============================================================================
  // CRUD operations for investment portfolio management.
  // - Create: POST /api/investments/
  // - Read all: GET /api/investments/user/{userId}
  // - Read one: GET /api/investments/{investmentId}
  // - Update: PUT /api/investments/{investmentId}
  // - Delete: DELETE /api/investments/{investmentId}
  // - Portfolio: GET /api/investments/user/{userId}/portfolio
  // - Update price: POST /api/investments/{investmentId}/update-price
  // ============================================================================

  // Create a new investment
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

  // Get all investments for a user, optionally filtered by asset type
  static Future<Map<String, dynamic>> getUserInvestments(int userId, {String? type}) async {
    try {
      final queryParams = <String, String>{};
      if (type != null) queryParams['type'] = type;        // Filter by asset type (e.g., "stocks")

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

  // Get a single investment by ID
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

  // Update an existing investment
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

  // Delete an investment
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

  // Get portfolio summary (total invested, current value, profit/loss, top/bottom performers)
  static Future<Map<String, dynamic>> getPortfolioSummary(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/investments/user/$userId/portfolio'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'portfolio': data};  // Entire response IS the portfolio data
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to fetch portfolio'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Update the current market price of an investment
  // Returns updated profit/loss calculations
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
          'profitLoss': data['profitLoss'],                // Updated profit/loss amount
          'percentageChange': data['percentageChange'],    // Updated percentage change
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to update price'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ============================================================================
  // GAMIFICATION ENDPOINTS
  // ============================================================================
  // These manage the rewards system: achievements, XP, levels, streaks, leaderboard.
  // - Achievements: GET /api/gamification/user/{userId}/achievements
  // - Stats: GET /api/gamification/user/{userId}/stats
  // - Check achievements: POST /api/gamification/user/{userId}/check-achievements
  // - Streaks: GET/POST /api/gamification/user/{userId}/streaks
  // - Leaderboard: GET /api/gamification/leaderboard
  // ============================================================================

  // Get all achievements and their unlock status for a user
  static Future<Map<String, dynamic>> getUserAchievements(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/gamification/user/$userId/achievements'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'userAchievements': data['userAchievements'],   // List of achievement progress
          'count': data['count']
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to fetch achievements'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get gamification stats (XP, level, streaks, achievement counts)
  static Future<Map<String, dynamic>> getUserStats(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/gamification/user/$userId/stats'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'stats': data};   // Entire response IS the stats
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to fetch stats'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Trigger achievement checking (called after user actions like adding transactions)
  // The backend evaluates all achievement criteria and returns any newly unlocked ones
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
          'newlyUnlocked': data['newlyUnlocked'],   // List of newly unlocked achievements
          'count': data['count']                      // How many new achievements
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to check achievements'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get all streaks for a user (daily tracking, budget adherence, etc.)
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

  // Update (increment) a streak for the user
  // Default streak type is "daily_tracking" (logging transactions daily)
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

  // Get the XP leaderboard (all users ranked by XP)
  static Future<Map<String, dynamic>> getLeaderboard() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/gamification/leaderboard'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'leaderboard': data['leaderboard'],  // List of users with XP/level
          'count': data['count']
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to fetch leaderboard'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ============================================================================
  // REPORTS ENDPOINTS
  // ============================================================================
  // These generate financial reports and CSV exports.
  // - Spending report: GET /api/reports/user/{userId}/spending-report
  // - Budget report: GET /api/reports/user/{userId}/budget-report
  // - Category analysis: GET /api/reports/user/{userId}/category-analysis
  // - Export URLs: Build URLs for CSV download (opened in browser/WebView)
  // ============================================================================

  // Get spending report (total income/expense, category breakdown, daily averages)
  // period: "this_month", "last_month", "3_months", "6_months", "1_year", "custom"
  static Future<Map<String, dynamic>> getSpendingReport(
    int userId, {
    String period = 'this_month',    // Default: current month
    String? startDate,                // For custom date range
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

  // Get budget adherence report (how well the user stuck to their budget)
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

  // Get detailed category analysis (spending per category with percentages)
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

  // ==============================================================================
  // Export URL Builders
  // ==============================================================================
  // These don't make API calls - they just build URLs for CSV download.
  // The URLs are used to open the export endpoint in a browser or WebView,
  // which triggers a file download from the backend.
  // ==============================================================================

  // Build URL for exporting transactions as CSV
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
        .toString();    // Convert Uri object to URL string
  }

  // Build URL for exporting spending report as CSV
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

  // ============================================================================
  // SETTINGS ENDPOINTS
  // ============================================================================
  // User settings, profile management, and password changes.
  // - Get settings: GET /api/settings/user/{userId}
  // - Update settings: PUT /api/settings/user/{userId}
  // - Get profile: GET /api/settings/user/{userId}/profile
  // - Update profile: PUT /api/settings/user/{userId}/profile
  // - Change password: POST /api/settings/user/{userId}/change-password
  // - Get currencies/languages: GET /api/settings/currencies, /languages
  // ============================================================================

  // Get user settings (currency, language, notification preferences, etc.)
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

  // Update user settings
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

  // Get user profile (name, email, phone, etc.)
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

  // Update user profile (name, phone number, etc.)
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

  // Change user password (requires current password for verification)
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

  // Get list of available currencies (e.g., MYR, USD, EUR)
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

  // Get list of available languages (e.g., English, Malay, Chinese)
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

  // ============================================================================
  // GOALS ENDPOINTS
  // ============================================================================
  // CRUD operations for savings goals + contribute and summary.
  // - Get all: GET /api/goals/user/{userId}
  // - Create: POST /api/goals/user/{userId}
  // - Get one: GET /api/goals/{goalId}
  // - Update: PUT /api/goals/{goalId}
  // - Delete: DELETE /api/goals/{goalId}
  // - Contribute: POST /api/goals/{goalId}/contribute
  // - Summary: GET /api/goals/user/{userId}/summary
  // - Categories: GET /api/goals/categories
  // ============================================================================

  // Get all goals for a user, optionally filtered by status
  // status can be: "active", "completed", "cancelled"
  static Future<Map<String, dynamic>> getUserGoals(int userId, {String? status}) async {
    try {
      // Build URL with optional status query parameter
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

  // Create a new savings goal
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

  // Get a single goal by ID
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

  // Update an existing goal
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

  // Delete a goal
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

  // Contribute money toward a savings goal
  // Adds the specified amount to the goal's current savings
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

  // Get goals summary (active count, completed count, total saved, closest deadline)
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

  // Get available goal categories (e.g., "Emergency Fund", "Vacation", "Education")
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

  // ============================================================================
  // TWO-FACTOR AUTHENTICATION (2FA) ENDPOINTS
  // ============================================================================
  // These handle setting up and using 2FA with TOTP (Time-based One-Time Password).
  // Flow: setup2FA -> scan QR code -> verify2FASetup -> 2FA is enabled
  // Login flow with 2FA: login -> verify2FACode or verify2FABackupCode
  // ============================================================================

  // Step 1: Initialize 2FA setup (generates secret key and QR code)
  static Future<Map<String, dynamic>> setup2FA(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/2fa/setup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'qrCode': data['qrCode'],            // Base64-encoded QR code image
          'secret': data['secret'],             // TOTP secret key (for manual entry)
          'backupCodes': data['backupCodes'],   // One-time backup codes
          'message': data['message']
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to setup 2FA'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Step 2: Verify 2FA setup by entering a code from the authenticator app
  // This confirms the user has correctly set up their authenticator app
  static Future<Map<String, dynamic>> verify2FASetup(int userId, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/2fa/verify-setup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId, 'code': code}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'user': data['user']
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Invalid verification code'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Verify a 2FA code during login
  // User enters the 6-digit code from their authenticator app
  static Future<Map<String, dynamic>> verify2FACode(int userId, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/2fa/verify'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId, 'code': code}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'verified': data['verified'],    // true if code is correct
          'message': data['message']
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to verify code'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Verify using a backup code (when user can't access their authenticator app)
  // Each backup code can only be used ONCE
  static Future<Map<String, dynamic>> verify2FABackupCode(int userId, String backupCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/2fa/verify-backup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId, 'backupCode': backupCode}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'verified': data['verified'],
          'message': data['message']
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Invalid backup code'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Disable 2FA (requires password confirmation for security)
  static Future<Map<String, dynamic>> disable2FA(int userId, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/2fa/disable'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId, 'password': password}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'user': data['user']
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to disable 2FA'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get the current 2FA status (enabled/disabled, has backup codes, last used)
  static Future<Map<String, dynamic>> get2FAStatus(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/2fa/status/$userId'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'twoFactorEnabled': data['twoFactorEnabled'],   // Is 2FA currently on?
          'hasBackupCodes': data['hasBackupCodes'],        // Are backup codes available?
          'lastUsedAt': data['lastUsedAt']                 // When was 2FA last used?
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to get 2FA status'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Generate new backup codes (invalidates old ones, requires password)
  static Future<Map<String, dynamic>> regenerateBackupCodes(int userId, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/2fa/regenerate-backup-codes'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId, 'password': password}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'backupCodes': data['backupCodes'],   // New set of backup codes
          'message': data['message']
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to regenerate backup codes'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ============================================================================
  // RECURRING TRANSACTIONS ENDPOINTS
  // ============================================================================
  // These manage recurring (repeating) transactions like monthly bills or salary.
  // - Create: POST /api/recurring/user/{userId}
  // - Get all: GET /api/recurring/user/{userId}
  // - Update: PUT /api/recurring/{recurringId}
  // - Delete: DELETE /api/recurring/{recurringId}
  // - Toggle: POST /api/recurring/{recurringId}/toggle (activate/deactivate)
  // - Execute one: POST /api/recurring/{recurringId}/execute
  // - Execute due: POST /api/recurring/user/{userId}/execute-due
  // ============================================================================

  // Create a new recurring transaction template
  // frequency: "daily", "weekly", "monthly", "yearly"
  static Future<Map<String, dynamic>> createRecurringTransaction({
    required int userId,
    required String name,              // e.g., "Netflix Subscription"
    required String transactionType,   // "income" or "expense"
    required String category,          // e.g., "Entertainment"
    required double amount,            // e.g., 49.90
    String? description,               // Optional description
    required String frequency,         // "daily", "weekly", "monthly", "yearly"
    required String startDate,         // When to start (YYYY-MM-DD)
    String? endDate,                   // Optional end date
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recurring/user/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'transactionType': transactionType,
          'category': category,
          'amount': amount,
          'description': description,
          'frequency': frequency,
          'startDate': startDate,
          'endDate': endDate,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'recurring': data['recurring']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to create recurring transaction'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get all recurring transactions for a user
  static Future<Map<String, dynamic>> getRecurringTransactions(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/recurring/user/$userId'),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'recurring': data['recurring']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to fetch recurring transactions'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Update a recurring transaction template
  // Only non-null fields are sent (uses collection-if in the JSON body)
  static Future<Map<String, dynamic>> updateRecurringTransaction({
    required int recurringId,
    String? name,
    String? category,
    double? amount,
    String? description,
    String? frequency,
    String? endDate,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/recurring/$recurringId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          // Only include fields that are not null (collection-if syntax)
          if (name != null) 'name': name,
          if (category != null) 'category': category,
          if (amount != null) 'amount': amount,
          if (description != null) 'description': description,
          if (frequency != null) 'frequency': frequency,
          if (endDate != null) 'endDate': endDate,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'recurring': data['recurring']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to update recurring transaction'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Delete a recurring transaction template
  static Future<Map<String, dynamic>> deleteRecurringTransaction(int recurringId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/recurring/$recurringId'),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to delete recurring transaction'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Toggle a recurring transaction active/inactive
  // Returns the new active status
  static Future<Map<String, dynamic>> toggleRecurringTransaction(int recurringId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recurring/$recurringId/toggle'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'recurring': data['recurring'], 'isActive': data['isActive']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to toggle recurring transaction'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Manually execute a single recurring transaction (creates a real transaction from template)
  static Future<Map<String, dynamic>> executeRecurringTransaction(int recurringId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recurring/$recurringId/execute'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 201) {       // 201 = transaction was created
        return {
          'success': true,
          'transaction': data['transaction'],  // The new transaction that was created
          'recurring': data['recurring'],      // Updated recurring template
          'message': data['message']
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to execute recurring transaction'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Execute all due recurring transactions for a user
  // Finds all active recurring transactions that are past their next execution date
  // and creates the corresponding real transactions
  static Future<Map<String, dynamic>> executeDueRecurringTransactions(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recurring/user/$userId/execute-due'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'executed': data['executed'],    // List of transactions that were created
          'count': data['count'],          // How many were executed
          'message': data['message']
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to execute due transactions'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ============================================================================
  // SECURITY ENDPOINTS
  // ============================================================================
  // Session management, activity logging, and account deletion.
  // - Sessions: GET/POST for viewing and revoking login sessions
  // - Activity log: GET security activity history
  // - Account deletion: POST with password confirmation
  // ============================================================================

  // Get all active login sessions for a user
  static Future<Map<String, dynamic>> getActiveSessions(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/security/sessions/user/$userId'),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'sessions': data['sessions']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to fetch sessions'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Revoke (end) a specific login session
  static Future<Map<String, dynamic>> revokeSession(int sessionId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/security/sessions/$sessionId/revoke'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId}),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to revoke session'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Revoke all login sessions except the current one
  static Future<Map<String, dynamic>> revokeAllSessions(int userId, int? currentSessionId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/security/sessions/user/$userId/revoke-all'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'currentSessionId': currentSessionId}),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'], 'revokedCount': data['revokedCount']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to revoke all sessions'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get security activity log (login attempts, password changes, 2FA usage, etc.)
  // Supports pagination with limit and offset
  static Future<Map<String, dynamic>> getSecurityActivityLog(int userId, {int limit = 20, int offset = 0}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/security/activity/user/$userId?limit=$limit&offset=$offset'),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'logs': data['logs']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to fetch activity log'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Permanently delete user account (requires password confirmation)
  // Also clears all local data from SharedPreferences
  static Future<Map<String, dynamic>> deleteAccount(int userId, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/security/account/delete'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        // Clear all stored data from device after successful account deletion
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to delete account'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}

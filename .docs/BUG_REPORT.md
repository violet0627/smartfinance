# Bug & Issue Report — SmartFinance

> Scanned: All 92 source files (55 .dart + 33 .py)
> Total Issues Found: 30

---

## Critical Issues

### 1. Sensitive Tokens Returned in API Responses
- **File**: `backend/app/routes/auth.py` (lines 185, 361, 555)
- **Issue**: `verificationToken` and `resetToken` are returned directly in the API response body with a comment "For development only (remove in production!)". If deployed, attackers can intercept these tokens and bypass email verification or hijack password resets.
- **Fix**: Remove token fields from all API responses. Tokens should only be delivered via secure email links — never returned to the client.

### 2. Secret Key Committed to Git
- **File**: `backend/.env`
- **Issue**: `SECRET_KEY = 'smartfinance-dev-secret-key-2025'` is hardcoded and committed to the repository. Anyone with repo access can forge valid JWT tokens and impersonate any user.
- **Fix**: Remove `.env` from git tracking, add it to `.gitignore`, rotate the secret key immediately, and load it from a secure environment variable.

### 3. Flask Debug Mode Enabled by Default
- **File**: `backend/run.py` (line 32)
- **Issue**: `debug=True` is hardcoded. This exposes full Python stack traces to users on errors and enables the interactive debugger — both are serious security risks in production.
- **Fix**:
  ```python
  import os
  debug = os.getenv('FLASK_ENV') == 'development'
  app.run(debug=debug)
  ```

### 4. Unprotected `json.decode()` Throughout API Service
- **File**: `lib/services/api_service.dart` (throughout)
- **Issue**: Every API call calls `json.decode(response.body)` directly with no try-catch. If the server returns an HTML error page, a timeout, or a malformed response, the app crashes with an unhandled `FormatException`.
- **Fix**: Wrap all `json.decode` calls in try-catch, or validate `Content-Type: application/json` before decoding:
  ```dart
  try {
    final data = json.decode(response.body);
  } catch (e) {
    return {'success': false, 'error': 'Invalid server response'};
  }
  ```

---

## Medium Severity Issues

### 5. Password Reset Email Not Actually Sent
- **File**: `backend/app/routes/auth.py` (line 357)
- **Issue**: A TODO comment marks that the reset token is returned in the API response instead of being sent via email. This completely bypasses the purpose of email-based password reset.
- **Fix**: Implement `email_service.send_password_reset_email(email, token)` and remove the token from the API response.

### 6. Scheduled Notifications Use `show()` Instead of `zonedSchedule()`
- **File**: `lib/services/notification_service.dart` (line 476)
- **Issue**: A TODO confirms that bill reminders and recurring transaction notifications fire immediately using `show()` instead of at the scheduled time. Scheduled delivery requires `zonedSchedule()` with timezone support.
- **Fix**: Replace `_notifications.show(...)` with `_notifications.zonedSchedule(...)` using the `timezone` package.

### 7. Account Deletion Not Implemented
- **File**: `lib/screens/settings/security_settings_screen.dart` (line 653)
- **Issue**: The "Delete My Account" button exists in the Danger Zone but the actual API call is replaced with a snackbar saying "will be available in next update".
- **Fix**: Connect the button to `ApiService.deleteAccount()` (the method exists) and handle navigation to login screen on success.

### 8. Backup Codes Print Not Implemented
- **File**: `lib/screens/settings/backup_codes_screen.dart` (line 354)
- **Issue**: The print button for backup codes is a TODO — tapping it does nothing.
- **Fix**: Implement using the `printing` package or format codes as a shareable text file.

### 9. Inconsistent `mounted` Checks After `await`
- **File**: `lib/screens/transactions/transaction_history_screen.dart` (lines ~300, ~1011, ~1051)
- **Issue**: Some async gaps correctly check `if (!mounted) return` but the pattern is inconsistently applied. Missing checks can cause `setState()` calls on disposed widgets, leading to crashes.
- **Fix**: Add `if (!mounted) return;` after every `await` that is followed by a UI update.

### 10. Potential Field Name Mismatch Between Frontend and Backend
- **Files**: `lib/models/user_model.dart` vs `backend/app/models/user.py`
- **Issue**: Dart models expect camelCase fields (`userId`, `fullName`, `emailVerified`) but SQLAlchemy models use PascalCase column names (`UserId`, `FullName`). If `to_dict()` returns PascalCase, Dart model parsing silently sets all fields to null.
- **Fix**: Verify that `user.to_dict()` explicitly maps to camelCase keys to match the Dart model.

### 11. No Empty State on Some List Screens
- **Files**: `lib/screens/goals/goals_screen.dart`, `lib/screens/transactions/transaction_history_screen.dart`
- **Issue**: When the API returns an empty list, some screens show a blank page with no message, making it look like a loading failure.
- **Fix**: Add an empty state widget (icon + message + CTA) when list is empty but no error occurred.

### 12. Type Cast Failures Not Caught
- **File**: `lib/screens/settings/security_settings_screen.dart` (lines 107, 114)
- **Issue**: `List<Map<String, dynamic>>.from(...)` will throw if the API returns an unexpected type. There is no try-catch around these casts.
- **Fix**: Wrap in try-catch and fall back to an empty list on failure.

---

## Low Severity Issues

### 13. Hardcoded Base URL
- **File**: `lib/services/api_service.dart` (line 40)
- **Issue**: `static const String baseUrl = 'http://192.168.1.38:5000/api';` is a local IP address. This breaks for any other developer or device on a different network.
- **Fix**: Load from a config file or environment variable with a documented setup step.

### 14. `print()` Statements Left in Production Code
- **Files**: `lib/services/notification_service.dart` (line 489), `lib/screens/dashboard/dashboard_screen.dart` (line 174), and others
- **Issue**: `print()` outputs debug info to the console in release builds, potentially exposing internal logic.
- **Fix**: Replace with a proper logger (`logger` package) or remove debug prints entirely.

### 15. Phone Validation Logic Inconsistency
- **File**: `lib/screens/auth/register_screen.dart` (line 411)
- **Issue**: The phone field is described as optional in a comment, but the validator returns an error if it is empty. The regex only accepts Malaysian format (`01[0-9]-?[0-9]{7,8}`).
- **Fix**: If the field is optional, change the validator to only run when the field is non-empty.

### 16. No Retry Logic for Transient Network Failures
- **Issue**: All API calls fail immediately on network error with no retry. A single momentary connectivity drop causes the user to see an error screen.
- **Fix**: Implement 1–2 automatic retries with short delay for GET requests on network timeout.

### 17. No Rate Limiting on Sensitive Endpoints
- **File**: `backend/app/routes/auth.py`
- **Issue**: Login, registration, and 2FA endpoints have no rate limiting, making them vulnerable to brute-force and enumeration attacks.
- **Fix**: Add `Flask-Limiter` with limits such as `"5 per minute"` on login and `"3 per minute"` on 2FA.

### 18. No CSRF Protection
- **Issue**: Flask backend has no CSRF token validation on POST/PUT/DELETE endpoints.
- **Fix**: Add `Flask-WTF` CSRF protection, or ensure all state-changing requests require the JWT token (which acts as CSRF mitigation for mobile apps).

### 19. Inconsistent Error Response Format
- **Issue**: Some endpoints return `{'error': '...'}`, others return `{'message': '...'}`, some return both. The frontend checks different keys in different places, making it easy to miss errors.
- **Fix**: Standardise all error responses to `{'success': False, 'error': 'message here'}`.

### 20. No Pagination on Transaction and Session Endpoints
- **Files**: `backend/app/routes/transactions.py`, `backend/app/routes/security.py`
- **Issue**: List endpoints return all records without pagination. A user with 1000+ transactions will experience slow loads and high memory usage.
- **Fix**: Add `?page=1&limit=20` query parameters with sensible defaults.

### 21. No Input Sanitization on User-Supplied Text
- **Issue**: Fields like transaction description and goal name are stored and displayed without sanitization. If a web dashboard is added later, this creates XSS risk.
- **Fix**: Strip or escape HTML characters from user text inputs on the backend before storage.

### 22. Transaction Search Not Fully Implemented
- **File**: `lib/screens/transactions/transaction_history_screen.dart` (line 77)
- **Issue**: A `SearchController` is initialised but the search/filter functionality is incomplete per a TODO comment.
- **Fix**: Wire up the search field to filter the transaction list by description or category.

### 23. No Loading Spinner Inside Contribute Dialog
- **File**: `lib/screens/goals/goals_screen.dart` (lines 159–172)
- **Issue**: `isLoading` is set to true and the button is disabled during the API call, but no spinner is shown inside the dialog. The dialog appears frozen to the user.
- **Fix**: Replace the button label with a `CircularProgressIndicator` while `isLoading` is true (same pattern used in the change password dialog in `settings_screen.dart`).

### 24. Budget Comparison Chart Has No Data Validation
- **File**: `lib/widgets/charts/budget_comparison_chart.dart`
- **Issue**: The chart assumes all entries have `'budgeted'` and `'actual'` keys. If the API returns partial data, the chart crashes.
- **Fix**: Use `categoryData['budgeted'] ?? 0.0` (already done for actual; apply consistently).

### 25. No Security Event Logging Consistency
- **Issue**: Some authentication events (login, 2FA toggle) log to `SecurityLog` but password reset and email verification events may not be logged consistently.
- **Fix**: Ensure all security-sensitive operations write to the `SecurityLog` table.

---

## Summary

| Severity | Count |
|----------|-------|
| Critical | 4 |
| Medium | 8 |
| Low | 13 |
| **Total** | **25** |

### Recommended Fix Priority

1. **Do immediately**: Issues 1–4 (security — tokens, secret key, debug mode, JSON crash)
2. **Before FYP demo**: Issues 5–8 (unfinished features — email, notifications, account delete, backup codes print)
3. **Before production**: Issues 9–25 (stability, UX polish, backend hardening)

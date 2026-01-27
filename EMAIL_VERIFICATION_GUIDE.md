# Email Verification Guide

## Overview

SmartFinance now includes a complete email verification system to ensure that user email addresses are valid and owned by the registering user. This guide explains how the system works and how to configure it.

## Features

### Backend Features
- ✅ **Automatic Email Sending** on registration
- ✅ **24-Hour Token Expiry** for security
- ✅ **HTML Email Templates** with professional design
- ✅ **Resend Verification** functionality
- ✅ **Email Verification Status Tracking** in User model
- ✅ **Token-Based Verification** using JWT
- ✅ **Email Enumeration Prevention**

### Frontend Features (Flutter)
- ✅ **Email Verification Screen** with token input
- ✅ **Verification Banner** on dashboard for unverified users
- ✅ **Registration Flow Integration** with verification prompt
- ✅ **Login Screen Link** to verification
- ✅ **Resend Email Functionality** with loading states
- ✅ **Success/Error Feedback** with dialogs and snackbars

## Architecture

### Backend Components

1. **EmailVerification Model** (`backend/app/models/email_verification.py`)
   - Stores verification tokens
   - Tracks verification status
   - Manages token expiry (24 hours)

2. **Email Service** (`backend/app/utils/email_service.py`)
   - `send_verification_email()` - Sends HTML verification email
   - `send_password_reset_email()` - Sends password reset email
   - Professional HTML templates with branding

3. **JWT Utils** (`backend/app/utils/jwt_utils.py`)
   - `generate_email_verification_token()` - Creates 24-hour token
   - `verify_email_verification_token()` - Validates token

4. **Auth Endpoints** (`backend/app/routes/auth.py`)
   - `POST /api/auth/register` - Now sends verification email
   - `POST /api/auth/verify-email` - Verify email with token
   - `POST /api/auth/resend-verification` - Resend verification email
   - `GET /api/auth/check-verification/<user_id>` - Check verification status

### Database Schema

**EmailVerifications Table:**
```sql
CREATE TABLE EmailVerifications (
    VerificationId INT PRIMARY KEY AUTO_INCREMENT,
    UserId INT NOT NULL,
    Token VARCHAR(500) NOT NULL UNIQUE,
    ExpiresAt DATETIME NOT NULL,
    Verified BOOLEAN DEFAULT FALSE,
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE
);
```

**Users Table Addition:**
```sql
ALTER TABLE Users ADD COLUMN EmailVerified BOOLEAN DEFAULT FALSE;
```

## Configuration

### 1. Email Server Setup (Gmail Example)

Create a `.env` file in the `backend` directory:

```env
# Flask-Mail Configuration
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=True
MAIL_USE_SSL=False
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password
MAIL_DEFAULT_SENDER=noreply@smartfinance.com

# Frontend URL (for email links)
FRONTEND_URL=http://localhost:3000
```

### 2. Gmail App Password Setup

1. Go to your Google Account settings
2. Navigate to **Security** → **2-Step Verification**
3. Scroll down to **App passwords**
4. Generate a new app password for "Mail"
5. Use this password in `MAIL_PASSWORD`

### 3. Alternative Email Providers

**SendGrid:**
```env
MAIL_SERVER=smtp.sendgrid.net
MAIL_PORT=587
MAIL_USERNAME=apikey
MAIL_PASSWORD=your-sendgrid-api-key
```

**Mailgun:**
```env
MAIL_SERVER=smtp.mailgun.org
MAIL_PORT=587
MAIL_USERNAME=postmaster@your-domain.com
MAIL_PASSWORD=your-mailgun-password
```

**AWS SES:**
```env
MAIL_SERVER=email-smtp.us-east-1.amazonaws.com
MAIL_PORT=587
MAIL_USERNAME=your-ses-username
MAIL_PASSWORD=your-ses-password
```

## API Endpoints

### 1. Register (Modified)

**POST** `/api/auth/register`

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "fullName": "John Doe",
  "phoneNumber": "+60123456789"
}
```

**Response:**
```json
{
  "message": "User registered successfully. Please verify your email.",
  "user": {
    "userId": 1,
    "email": "user@example.com",
    "fullName": "John Doe",
    "emailVerified": false,
    ...
  },
  "accessToken": "eyJ0eXAiOiJKV1QiLCJ...",
  "refreshToken": "eyJ0eXAiOiJKV1QiLCJ...",
  "verificationToken": "eyJ0eXAiOiJKV1QiLCJ..."  // Development only
}
```

### 2. Verify Email

**POST** `/api/auth/verify-email`

**Request:**
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJ..."
}
```

**Response:**
```json
{
  "message": "Email verified successfully",
  "user": {
    "userId": 1,
    "email": "user@example.com",
    "emailVerified": true,
    ...
  }
}
```

### 3. Resend Verification

**POST** `/api/auth/resend-verification`

**Request:**
```json
{
  "email": "user@example.com"
}
```

**Response:**
```json
{
  "message": "Verification email sent successfully",
  "verificationToken": "eyJ0eXAiOiJKV1QiLCJ..."  // Development only
}
```

### 4. Check Verification Status

**GET** `/api/auth/check-verification/<user_id>`

**Response:**
```json
{
  "emailVerified": true,
  "email": "user@example.com"
}
```

## Email Templates

### Verification Email

The system sends a professionally designed HTML email with:

- **Welcome Header** with SmartFinance branding
- **Personalized Greeting** with user's name
- **Clear Call-to-Action** button
- **Fallback Link** for manual copy/paste
- **24-Hour Expiry Warning**
- **Security Notice** if user didn't register
- **Professional Footer** with copyright

**Subject:** "Verify Your SmartFinance Account"

### Password Reset Email

Similar professional template with:

- **Password Reset Header** in warning color (orange)
- **Reset Password Button**
- **1-Hour Expiry Warning** (security-focused)
- **Security notice** about ignoring if not requested

**Subject:** "Reset Your SmartFinance Password"

## Security Features

### 1. Token Expiry
- Verification tokens expire after **24 hours**
- Password reset tokens expire after **1 hour**
- Expired tokens cannot be used

### 2. Single-Use Tokens
- Each token can only be used once
- After verification, token is marked as "Verified"
- Cannot verify with the same token twice

### 3. Email Enumeration Prevention
- Resend endpoint returns success even for non-existent emails
- Prevents attackers from discovering valid email addresses

### 4. Secure Token Generation
- Uses JWT with cryptographic signing
- Includes user ID and email in payload
- Type field prevents token reuse across different purposes

## Development vs Production

### Development Mode

Current implementation includes:
- Token returned in API response (for testing without email server)
- Console logging of email sending errors
- Can test verification flow without SMTP setup

### Production Checklist

Before deploying to production:

1. ✅ **Remove** `verificationToken` from registration response
2. ✅ **Remove** `resetToken` from forgot-password response
3. ✅ **Configure** proper SMTP server
4. ✅ **Set** `FRONTEND_URL` to actual domain
5. ✅ **Enable** background task queue for emails (Celery/RQ)
6. ✅ **Add** error monitoring for email failures
7. ✅ **Implement** rate limiting on resend endpoint
8. ✅ **Configure** email bounce handling

## Testing

### Manual Testing Without Email Server

1. Register a new user
2. Copy the `verificationToken` from the response
3. Call verify-email endpoint with the token
4. Check user's `emailVerified` status

### With Email Server

1. Configure SMTP settings in `.env`
2. Register with your real email
3. Check inbox for verification email
4. Click the verification link
5. Verify account is activated

## Troubleshooting

### Email Not Sending

**Problem:** No verification email received

**Solutions:**
1. Check SMTP configuration in `.env`
2. Verify Gmail app password (if using Gmail)
3. Check spam/junk folder
4. Review Flask console for error messages
5. Test SMTP credentials manually

### Token Expired

**Problem:** "Invalid or expired verification token"

**Solutions:**
1. Request new verification email via resend endpoint
2. Check token wasn't already used
3. Verify token is for correct user

### Gmail Blocking Emails

**Problem:** Gmail security blocks less secure apps

**Solutions:**
1. Enable 2-Factor Authentication on Gmail
2. Generate App Password (not regular password)
3. Use App Password in `MAIL_PASSWORD`
4. Alternative: Use SendGrid/Mailgun

## Best Practices

1. **Always use HTTPS** for verification links in production
2. **Monitor email bounce rates** and invalid addresses
3. **Implement rate limiting** on resend (max 3 per hour)
4. **Log verification events** for audit trail
5. **Clean up expired tokens** periodically (cron job)
6. **Use professional email domain** (not @gmail.com)
7. **Test emails** before deploying to production

## Future Enhancements

Potential improvements:

- **Email Change Verification** - Verify new email when user changes it
- **Welcome Email** after successful verification
- **Email Reminders** for unverified accounts (after 48 hours)
- **Admin Dashboard** to view verification statistics
- **Bulk Email Sending** for announcements
- **Email Template Management** via database
- **Localization** of emails based on user language preference

## Flutter Integration

### Frontend Components

The Flutter app now includes complete email verification UI integration:

#### 1. **Email Verification Screen** (`lib/screens/auth/verify_email_screen.dart`)

Full-featured verification screen with:
- Multi-line token input field
- Form validation
- Verify button with loading state
- Resend verification functionality
- Instructions panel with step-by-step guide
- Success dialog navigating to Dashboard
- Auto-fill token from resend response (development)

**Usage:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => VerifyEmailScreen(email: userEmail),
  ),
);
```

#### 2. **Email Verification Banner** (`lib/widgets/email_verification_banner.dart`)

Persistent warning banner for unverified users:
- Orange warning styling with icon
- "Resend Email" button - sends new verification email
- "Verify Now" button - navigates to verification screen
- Callback for refresh after verification
- Material Design with rounded corners

**Integration in Dashboard:**
```dart
if (!_emailVerified && _userEmail.isNotEmpty) ...[
  EmailVerificationBanner(
    userId: userId,
    email: _userEmail,
    onVerified: _loadData,
  ),
],
```

#### 3. **API Service Methods** (`lib/services/api_service.dart`)

Three new methods for email verification:

```dart
// Verify email with token
static Future<Map<String, dynamic>> verifyEmail(String token)

// Resend verification email
static Future<Map<String, dynamic>> resendVerification(String email)

// Check verification status
static Future<Map<String, dynamic>> checkVerificationStatus(int userId)
```

#### 4. **Registration Flow Integration**

Updated `register_screen.dart` to:
- Show success dialog after registration
- Offer "Skip for now" or "Verify Now" options
- Display user's email in dialog
- Navigate to verification screen with email pre-filled

#### 5. **Login Screen Enhancement**

Added verification link to `login_screen.dart`:
- "Need to verify your email?" text
- "Verify Now" button navigates to verification screen
- Positioned below Sign Up link for easy access

#### 6. **Dashboard Integration**

Updated `dashboard_screen.dart` to:
- Load email verification status on dashboard load
- Display banner for unverified users
- Refresh status after verification
- Conditional rendering based on verification state

### User Flow

1. **Registration:**
   - User registers → Backend sends verification email
   - Dialog appears: "Skip for now" or "Verify Now"
   - Can access dashboard but sees warning banner

2. **Verification:**
   - User opens verification email
   - Copies token from email
   - Pastes in verification screen
   - Clicks "Verify Email"
   - Success dialog → Navigate to dashboard
   - Banner disappears

3. **Resend:**
   - User clicks "Resend Email" button
   - New email sent with fresh token
   - Token auto-filled in development mode
   - Can verify with new token

### Development Testing

To test without email server:

1. Register a new user in the app
2. Copy `verificationToken` from backend console logs
3. Paste token in verification screen
4. Click verify
5. Dashboard banner should disappear

### Production Deployment

Before production:

1. Remove `verificationToken` from API responses
2. Configure proper SMTP server in backend
3. Test complete email flow end-to-end
4. Verify banner appears/disappears correctly
5. Test resend functionality with rate limiting

---

**Status:** ✅ Email verification feature is now **fully complete** with both backend and frontend implementation.

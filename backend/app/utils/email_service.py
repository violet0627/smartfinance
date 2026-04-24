# ==============================================================================
# email_service.py - Email Sending Service
# ==============================================================================
# This file handles sending emails from the SmartFinance backend.
# It uses Flask-Mail to send HTML emails for:
#
# 1. EMAIL VERIFICATION: Sent after registration to verify the user's email
# 2. PASSWORD RESET: Sent when the user clicks "Forgot Password"
#
# Each email includes:
# - An HTML version (styled, with buttons and formatting)
# - A plain text version (fallback for email clients that don't support HTML)
#
# Configuration (set in config.py):
# - MAIL_SERVER: SMTP server address (e.g., smtp.gmail.com)
# - MAIL_PORT: SMTP port (usually 587 for TLS)
# - MAIL_USERNAME: Email account to send from
# - MAIL_PASSWORD: Email account password or app password
# ==============================================================================

from flask_mail import Message       # Message class for creating emails
from app import mail                  # Flask-Mail instance (initialized in app/__init__.py)


# ==============================================================================
# FUNCTION: send_verification_email
# ==============================================================================
# Sends a verification email to a newly registered user.
# The email contains a link that the user clicks to verify their email address.
#
# Args:
#     user_email (str): The user's email address (recipient)
#     user_name (str): The user's full name (for personalization)
#     verification_token (str): The JWT token for verification
#
# Returns:
#     bool: True if email was sent successfully, False if an error occurred
# ==============================================================================
def send_verification_email(user_email, user_name, verification_token):
    """Send email verification email"""
    try:
        # --- Step 1: Email subject line ---
        subject = "Verify Your SmartFinance Account"

        # --- Step 2: HTML email body ---
        # Shows the raw verification token prominently so the user can copy-paste it
        # into the SmartFinance mobile app's Verify Email screen.
        #
        # We do NOT embed a localhost URL here because:
        # - localhost links are flagged as spam by email providers
        # - The Flutter mobile app cannot open a localhost web link anyway
        # - The app expects the raw JWT token to be pasted directly
        html_body = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{
                    font-family: Arial, sans-serif;
                    line-height: 1.6;
                    color: #333;
                }}
                .container {{
                    max-width: 600px;
                    margin: 0 auto;
                    padding: 20px;
                }}
                .header {{
                    background-color: #4CAF50;
                    color: white;
                    padding: 20px;
                    text-align: center;
                    border-radius: 5px 5px 0 0;
                }}
                .content {{
                    background-color: #f9f9f9;
                    padding: 30px;
                    border-radius: 0 0 5px 5px;
                }}
                .token-box {{
                    background-color: #e8f5e9;
                    border: 2px solid #4CAF50;
                    padding: 16px;
                    border-radius: 6px;
                    font-family: monospace;
                    font-size: 13px;
                    word-break: break-all;
                    margin: 20px 0;
                }}
                .steps {{
                    background-color: #f1f8e9;
                    border-left: 4px solid #4CAF50;
                    padding: 12px 16px;
                    margin: 16px 0;
                }}
                .footer {{
                    text-align: center;
                    margin-top: 20px;
                    color: #666;
                    font-size: 12px;
                }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>Welcome to SmartFinance!</h1>
                </div>
                <div class="content">
                    <h2>Hi {user_name},</h2>
                    <p>Thank you for registering with SmartFinance. To complete your registration, copy the verification token below and paste it into the SmartFinance app.</p>

                    <p><strong>Your verification token:</strong></p>
                    <div class="token-box">{verification_token}</div>

                    <div class="steps">
                        <strong>How to verify:</strong><br>
                        1. Open the SmartFinance app<br>
                        2. Go to the <em>Verify Email</em> screen<br>
                        3. Copy the token above and paste it into the token field<br>
                        4. Tap <strong>Verify Email</strong>
                    </div>

                    <p><strong>This token will expire in 24 hours.</strong></p>

                    <p>If you didn't create an account with SmartFinance, please ignore this email.</p>

                    <p>Best regards,<br>The SmartFinance Team</p>
                </div>
                <div class="footer">
                    <p>This is an automated email. Please do not reply to this message.</p>
                    <p>&copy; 2026 SmartFinance. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
        """

        # --- Step 3: Plain text fallback ---
        # For email clients that can't display HTML
        text_body = f"""
Hi {user_name},

Thank you for registering with SmartFinance. To verify your email, copy the token below and paste it into the Verify Email screen in the SmartFinance app.

Your verification token:
{verification_token}

Steps:
1. Open the SmartFinance app
2. Go to the Verify Email screen
3. Paste the token above into the token field
4. Tap Verify Email

This token will expire in 24 hours.

If you didn't create an account with SmartFinance, please ignore this email.

Best regards,
The SmartFinance Team
        """

        # --- Step 5: Create the email message ---
        # Message() creates an email with:
        # - subject: Email subject line
        # - recipients: List of email addresses to send to
        # - body: Plain text version
        # - html: HTML version (email client picks the best one to display)
        msg = Message(
            subject=subject,
            recipients=[user_email],       # List of recipients (just one user)
            body=text_body,                 # Plain text fallback
            html=html_body                  # HTML version (preferred)
        )

        # --- Step 6: Send the email ---
        # mail.send() uses Flask-Mail to connect to the SMTP server and send
        mail.send(msg)
        return True       # Email sent successfully

    except Exception as e:
        # If sending fails (e.g., SMTP server down, wrong credentials), log the error
        print(f"Error sending verification email: {str(e)}")
        return False       # Email failed to send


# ==============================================================================
# FUNCTION: send_password_reset_email
# ==============================================================================
# Sends a password reset email when the user requests to reset their password.
# The email contains a link with a reset token that expires in 1 hour.
#
# Args:
#     user_email (str): The user's email address (recipient)
#     user_name (str): The user's full name (for personalization)
#     reset_token (str): The JWT token for password reset
#
# Returns:
#     bool: True if email was sent successfully, False if an error occurred
# ==============================================================================
def send_password_reset_email(user_email, user_name, reset_token):
    """Send password reset email"""
    try:
        subject = "Reset Your SmartFinance Password"

        # --- HTML email body ---
        # Shows the raw reset token so the user can copy-paste it into the app.
        # We do NOT use a localhost URL here — it triggers spam filters and
        # cannot be opened on a mobile device.
        html_body = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{
                    font-family: Arial, sans-serif;
                    line-height: 1.6;
                    color: #333;
                }}
                .container {{
                    max-width: 600px;
                    margin: 0 auto;
                    padding: 20px;
                }}
                .header {{
                    background-color: #FF9800;
                    color: white;
                    padding: 20px;
                    text-align: center;
                    border-radius: 5px 5px 0 0;
                }}
                .content {{
                    background-color: #f9f9f9;
                    padding: 30px;
                    border-radius: 0 0 5px 5px;
                }}
                .token-box {{
                    background-color: #fff8e1;
                    border: 2px solid #FF9800;
                    padding: 16px;
                    border-radius: 6px;
                    font-family: monospace;
                    font-size: 13px;
                    word-break: break-all;
                    margin: 20px 0;
                }}
                .steps {{
                    background-color: #fff3e0;
                    border-left: 4px solid #FF9800;
                    padding: 12px 16px;
                    margin: 16px 0;
                }}
                .warning {{
                    background-color: #fff3cd;
                    border-left: 4px solid #FF9800;
                    padding: 10px;
                    margin: 15px 0;
                }}
                .footer {{
                    text-align: center;
                    margin-top: 20px;
                    color: #666;
                    font-size: 12px;
                }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>Password Reset Request</h1>
                </div>
                <div class="content">
                    <h2>Hi {user_name},</h2>
                    <p>We received a request to reset your SmartFinance password. Copy the reset token below and paste it into the SmartFinance app.</p>

                    <p><strong>Your password reset token:</strong></p>
                    <div class="token-box">{reset_token}</div>

                    <div class="steps">
                        <strong>How to reset your password:</strong><br>
                        1. Open the SmartFinance app<br>
                        2. Go to <em>Forgot Password</em> → <em>Reset Password</em> screen<br>
                        3. Copy the token above and paste it into the token field<br>
                        4. Enter your new password and tap <strong>Reset Password</strong>
                    </div>

                    <div class="warning">
                        <strong>Important:</strong> This token will expire in 1 hour for security reasons.
                    </div>

                    <p>If you didn't request a password reset, please ignore this email. Your password will remain unchanged.</p>

                    <p>Best regards,<br>The SmartFinance Team</p>
                </div>
                <div class="footer">
                    <p>This is an automated email. Please do not reply to this message.</p>
                    <p>&copy; 2026 SmartFinance. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
        """

        # --- Plain text fallback ---
        text_body = f"""
Hi {user_name},

We received a request to reset your SmartFinance password.

Your password reset token:
{reset_token}

Steps:
1. Open the SmartFinance app
2. Go to Forgot Password -> Reset Password screen
3. Paste the token above into the token field
4. Enter your new password and tap Reset Password

This token will expire in 1 hour for security reasons.

If you didn't request a password reset, please ignore this email.

Best regards,
The SmartFinance Team
        """

        # --- Create and send the email ---
        msg = Message(
            subject=subject,
            recipients=[user_email],
            body=text_body,
            html=html_body
        )

        mail.send(msg)
        return True

    except Exception as e:
        print(f"Error sending password reset email: {str(e)}")
        return False

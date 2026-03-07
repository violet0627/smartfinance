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
from flask import render_template_string  # For rendering HTML templates (not used here but imported)
import os                             # For reading environment variables


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
        # --- Step 1: Build the verification link ---
        # FRONTEND_URL is where the Flutter web app or verification page is hosted.
        # The token is passed as a query parameter in the URL.
        frontend_url = os.getenv('FRONTEND_URL', 'http://localhost:3000')
        verification_link = f"{frontend_url}/verify-email?token={verification_token}"

        # --- Step 2: Email subject line ---
        subject = "Verify Your SmartFinance Account"

        # --- Step 3: HTML email body ---
        # This is a full HTML page with CSS styling that will display in the user's email.
        # Note: {{ and }} are escaped as {{ }} in f-strings (double braces = literal brace)
        # The f-string variables ({user_name}, {verification_link}) are inserted into the HTML.
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
                .button {{
                    display: inline-block;
                    padding: 12px 30px;
                    background-color: #4CAF50;
                    color: white;
                    text-decoration: none;
                    border-radius: 5px;
                    margin: 20px 0;
                }}
                .footer {{
                    text-align: center;
                    margin-top: 20px;
                    color: #666;
                    font-size: 12px;
                }}
                .code {{
                    background-color: #e0e0e0;
                    padding: 10px;
                    border-radius: 3px;
                    font-family: monospace;
                    word-break: break-all;
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
                    <p>Thank you for registering with SmartFinance. To complete your registration, please verify your email address by clicking the button below:</p>

                    <div style="text-align: center;">
                        <a href="{verification_link}" class="button">Verify Email Address</a>
                    </div>

                    <p>Or copy and paste this link into your browser:</p>
                    <div class="code">{verification_link}</div>

                    <p><strong>This link will expire in 24 hours.</strong></p>

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

        # --- Step 4: Plain text fallback ---
        # For email clients that can't display HTML (rare but important for accessibility)
        text_body = f"""
        Hi {user_name},

        Thank you for registering with SmartFinance. To complete your registration, please verify your email address by clicking the link below:

        {verification_link}

        This link will expire in 24 hours.

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
        # --- Build the reset link ---
        frontend_url = os.getenv('FRONTEND_URL', 'http://localhost:3000')
        reset_link = f"{frontend_url}/reset-password?token={reset_token}"

        subject = "Reset Your SmartFinance Password"

        # --- HTML email body ---
        # Similar structure to the verification email but with different colors (orange)
        # and different messaging (password reset instead of welcome)
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
                .button {{
                    display: inline-block;
                    padding: 12px 30px;
                    background-color: #FF9800;
                    color: white;
                    text-decoration: none;
                    border-radius: 5px;
                    margin: 20px 0;
                }}
                .footer {{
                    text-align: center;
                    margin-top: 20px;
                    color: #666;
                    font-size: 12px;
                }}
                .code {{
                    background-color: #e0e0e0;
                    padding: 10px;
                    border-radius: 3px;
                    font-family: monospace;
                    word-break: break-all;
                }}
                .warning {{
                    background-color: #fff3cd;
                    border-left: 4px solid #FF9800;
                    padding: 10px;
                    margin: 15px 0;
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
                    <p>We received a request to reset your SmartFinance password. Click the button below to set a new password:</p>

                    <div style="text-align: center;">
                        <a href="{reset_link}" class="button">Reset Password</a>
                    </div>

                    <p>Or copy and paste this link into your browser:</p>
                    <div class="code">{reset_link}</div>

                    <div class="warning">
                        <strong>Important:</strong> This link will expire in 1 hour for security reasons.
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

        We received a request to reset your SmartFinance password. Click the link below to set a new password:

        {reset_link}

        This link will expire in 1 hour for security reasons.

        If you didn't request a password reset, please ignore this email. Your password will remain unchanged.

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

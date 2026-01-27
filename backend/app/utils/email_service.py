from flask_mail import Message
from app import mail
from flask import render_template_string
import os

def send_verification_email(user_email, user_name, verification_token):
    """Send email verification email"""
    try:
        # Frontend URL (should be in environment variable in production)
        frontend_url = os.getenv('FRONTEND_URL', 'http://localhost:3000')
        verification_link = f"{frontend_url}/verify-email?token={verification_token}"

        # Email subject
        subject = "Verify Your SmartFinance Account"

        # HTML email body
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

        # Plain text fallback
        text_body = f"""
        Hi {user_name},

        Thank you for registering with SmartFinance. To complete your registration, please verify your email address by clicking the link below:

        {verification_link}

        This link will expire in 24 hours.

        If you didn't create an account with SmartFinance, please ignore this email.

        Best regards,
        The SmartFinance Team
        """

        # Create message
        msg = Message(
            subject=subject,
            recipients=[user_email],
            body=text_body,
            html=html_body
        )

        # Send email
        mail.send(msg)
        return True

    except Exception as e:
        print(f"Error sending verification email: {str(e)}")
        return False


def send_password_reset_email(user_email, user_name, reset_token):
    """Send password reset email"""
    try:
        # Frontend URL
        frontend_url = os.getenv('FRONTEND_URL', 'http://localhost:3000')
        reset_link = f"{frontend_url}/reset-password?token={reset_token}"

        # Email subject
        subject = "Reset Your SmartFinance Password"

        # HTML email body
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

        # Plain text fallback
        text_body = f"""
        Hi {user_name},

        We received a request to reset your SmartFinance password. Click the link below to set a new password:

        {reset_link}

        This link will expire in 1 hour for security reasons.

        If you didn't request a password reset, please ignore this email. Your password will remain unchanged.

        Best regards,
        The SmartFinance Team
        """

        # Create message
        msg = Message(
            subject=subject,
            recipients=[user_email],
            body=text_body,
            html=html_body
        )

        # Send email
        mail.send(msg)
        return True

    except Exception as e:
        print(f"Error sending password reset email: {str(e)}")
        return False

# Tokens are shown as raw strings for copy-paste — no localhost URLs,
# as they trigger spam filters and cannot be opened on mobile.

from flask_mail import Message
from app import mail


def send_verification_email(user_email, user_name, verification_token):
    try:
        html_body = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background-color: #4CAF50; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }}
                .content {{ background-color: #f9f9f9; padding: 30px; border-radius: 0 0 5px 5px; }}
                .token-box {{ background-color: #e8f5e9; border: 2px solid #4CAF50; padding: 16px; border-radius: 6px; font-family: monospace; font-size: 13px; word-break: break-all; margin: 20px 0; }}
                .steps {{ background-color: #f1f8e9; border-left: 4px solid #4CAF50; padding: 12px 16px; margin: 16px 0; }}
                .footer {{ text-align: center; margin-top: 20px; color: #666; font-size: 12px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header"><h1>Welcome to SmartFinance!</h1></div>
                <div class="content">
                    <h2>Hi {user_name},</h2>
                    <p>Thank you for registering with SmartFinance. Copy the verification token below and paste it into the SmartFinance app.</p>
                    <p><strong>Your verification token:</strong></p>
                    <div class="token-box">{verification_token}</div>
                    <div class="steps">
                        <strong>How to verify:</strong><br>
                        1. Open the SmartFinance app<br>
                        2. Go to the <em>Verify Email</em> screen<br>
                        3. Paste the token above into the token field<br>
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

        msg = Message(
            subject="Verify Your SmartFinance Account",
            recipients=[user_email],
            body=text_body,
            html=html_body
        )
        mail.send(msg)
        return True

    except Exception as e:
        print(f"Error sending verification email: {str(e)}")
        return False


def send_password_reset_email(user_email, user_name, reset_token):
    try:
        html_body = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background-color: #FF9800; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }}
                .content {{ background-color: #f9f9f9; padding: 30px; border-radius: 0 0 5px 5px; }}
                .token-box {{ background-color: #fff8e1; border: 2px solid #FF9800; padding: 16px; border-radius: 6px; font-family: monospace; font-size: 13px; word-break: break-all; margin: 20px 0; }}
                .steps {{ background-color: #fff3e0; border-left: 4px solid #FF9800; padding: 12px 16px; margin: 16px 0; }}
                .warning {{ background-color: #fff3cd; border-left: 4px solid #FF9800; padding: 10px; margin: 15px 0; }}
                .footer {{ text-align: center; margin-top: 20px; color: #666; font-size: 12px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header"><h1>Password Reset Request</h1></div>
                <div class="content">
                    <h2>Hi {user_name},</h2>
                    <p>We received a request to reset your SmartFinance password. Copy the reset token below and paste it into the SmartFinance app.</p>
                    <p><strong>Your password reset token:</strong></p>
                    <div class="token-box">{reset_token}</div>
                    <div class="steps">
                        <strong>How to reset your password:</strong><br>
                        1. Open the SmartFinance app<br>
                        2. Go to <em>Forgot Password</em> &rarr; <em>Reset Password</em> screen<br>
                        3. Paste the token above into the token field<br>
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

        msg = Message(
            subject="Reset Your SmartFinance Password",
            recipients=[user_email],
            body=text_body,
            html=html_body
        )
        mail.send(msg)
        return True

    except Exception as e:
        print(f"Error sending password reset email: {str(e)}")
        return False

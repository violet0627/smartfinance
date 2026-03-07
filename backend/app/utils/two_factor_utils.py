# ==============================================================================
# two_factor_utils.py - Two-Factor Authentication (2FA) Utility Functions
# ==============================================================================
# This file provides utility functions for Two-Factor Authentication (2FA).
#
# What is 2FA?
# Two-Factor Authentication adds an extra security layer beyond just a password.
# After entering their password, the user must also provide a 6-digit code from
# an authenticator app (like Google Authenticator or Microsoft Authenticator).
#
# How TOTP works:
# TOTP = Time-based One-Time Password
# 1. The server generates a random SECRET KEY
# 2. The secret is shared with the authenticator app (via QR code)
# 3. Both the server and app use the SAME secret + CURRENT TIME to generate
#    a 6-digit code that changes every 30 seconds
# 4. Since both sides have the same secret and time, they generate matching codes
# 5. The user enters the code from their app, and the server verifies it matches
#
# Backup codes are one-time-use emergency codes for when the user can't access
# their authenticator app (e.g., lost phone).
# ==============================================================================

import pyotp           # Python One-Time Password library (generates/verifies TOTP codes)
import qrcode          # QR code generator (for creating scannable QR codes)
import io              # For in-memory file operations (creating images in memory)
import base64          # For encoding binary data as text (QR code image -> base64 string)
import json            # For converting lists to/from JSON strings
import secrets         # For generating cryptographically secure random values
from datetime import datetime  # For timestamps


class TwoFactorUtils:
    """
    Utility class for Two-Factor Authentication operations.

    All methods are @staticmethod - they don't need an instance of the class.
    You call them directly like: TwoFactorUtils.generate_secret()
    """

    @staticmethod
    def generate_secret():
        """
        Generate a random base32 secret for TOTP.

        Base32 is an encoding that uses characters A-Z and 2-7.
        This secret is shared between the server and the authenticator app.
        Example output: "JBSWY3DPEHPK3PXP"

        Returns:
            str: A random base32-encoded secret string
        """
        return pyotp.random_base32()   # pyotp handles generating a secure random secret

    @staticmethod
    def get_totp_uri(secret, email, issuer="SmartFinance"):
        """
        Generate a TOTP URI for QR code generation.

        A TOTP URI is a special URL format that authenticator apps understand:
        otpauth://totp/SmartFinance:user@email.com?secret=JBSWY3DPEHPK3PXP&issuer=SmartFinance

        When an authenticator app reads this URI (from a QR code), it automatically
        sets up the account with the correct secret, name, and issuer.

        Args:
            secret (str): The base32 secret key
            email (str): User's email address (used as the account name)
            issuer (str): Application name shown in the authenticator app

        Returns:
            str: A TOTP provisioning URI
        """
        totp = pyotp.TOTP(secret)        # Create a TOTP object with the secret
        return totp.provisioning_uri(
            name=email,                    # Account name shown in the app
            issuer_name=issuer             # App name shown in the app (e.g., "SmartFinance")
        )

    @staticmethod
    def generate_qr_code(secret, email, issuer="SmartFinance"):
        """
        Generate a QR code image as a base64-encoded string.

        The QR code contains the TOTP URI that authenticator apps can scan.
        The image is returned as a base64 string that can be displayed in HTML/Flutter
        using: <img src="data:image/png;base64,..." />

        Steps:
        1. Generate the TOTP URI
        2. Create a QR code image from the URI
        3. Save the image to memory (not a file)
        4. Convert the image bytes to a base64 string

        Args:
            secret (str): The base32 secret key
            email (str): User's email address
            issuer (str): Application name

        Returns:
            str: Base64-encoded QR code image with data URI prefix
                 (e.g., "data:image/png;base64,iVBOR...")
        """
        # --- Step 1: Get the TOTP URI ---
        uri = TwoFactorUtils.get_totp_uri(secret, email, issuer)

        # --- Step 2: Create the QR code ---
        qr = qrcode.QRCode(
            version=1,                                        # QR code version (1 = smallest)
            error_correction=qrcode.constants.ERROR_CORRECT_L, # Low error correction (faster)
            box_size=10,                                       # Size of each QR "pixel" in real pixels
            border=4,                                          # White border around the QR code
        )
        qr.add_data(uri)       # Add the TOTP URI as the QR code's data
        qr.make(fit=True)      # Generate the QR code (fit=True adjusts size automatically)

        # --- Step 3: Create the QR code image ---
        img = qr.make_image(fill_color="black", back_color="white")

        # --- Step 4: Convert image to base64 string ---
        buffer = io.BytesIO()              # Create an in-memory bytes buffer (like a virtual file)
        img.save(buffer, format='PNG')     # Save the image to the buffer as PNG
        buffer.seek(0)                      # Go back to the beginning of the buffer
        img_base64 = base64.b64encode(buffer.getvalue()).decode()  # Encode bytes as base64 text

        # Return with the data URI prefix so it can be used directly in <img> tags
        return f"data:image/png;base64,{img_base64}"

    @staticmethod
    def verify_totp(secret, code):
        """
        Verify a TOTP code entered by the user.

        The code changes every 30 seconds. We allow a "window" of 1, meaning
        the code from the previous 30 seconds or next 30 seconds is also accepted.
        This accounts for small clock differences between the user's phone and server.

        Args:
            secret (str): The base32 secret key (stored in the database)
            code (str): The 6-digit code the user entered

        Returns:
            bool: True if the code matches, False if it doesn't
        """
        totp = pyotp.TOTP(secret)
        # valid_window=1 means accept codes from 30 seconds before/after current time
        return totp.verify(code, valid_window=1)

    @staticmethod
    def generate_backup_codes(count=8):
        """
        Generate backup codes for 2FA recovery.

        Backup codes are emergency one-time-use codes that users can use if they
        can't access their authenticator app (e.g., lost phone, app deleted).
        Each code can only be used ONCE.

        Format: XXXX-XXXX (8 hex characters with a hyphen in the middle)
        Example: "A1B2-C3D4"

        Args:
            count (int): Number of backup codes to generate (default: 8)

        Returns:
            list: List of formatted backup code strings
        """
        codes = []
        for _ in range(count):
            # secrets.token_hex(4) generates 4 random bytes as 8 hex characters
            # .upper() converts to uppercase for readability
            code = secrets.token_hex(4).upper()
            # Format as XXXX-XXXX for easier reading/typing
            formatted_code = f"{code[:4]}-{code[4:]}"
            codes.append(formatted_code)
        return codes

    @staticmethod
    def hash_backup_codes(codes):
        """
        Hash backup codes before storing them in the database.

        Like passwords, backup codes should NEVER be stored in plain text.
        We use SHA-256 hashing (one-way) so that even if the database is compromised,
        the actual backup codes can't be recovered.

        Args:
            codes (list): List of plain-text backup codes

        Returns:
            str: JSON string of hashed codes (for storing in a database text field)
        """
        import hashlib        # Python's built-in hashing library
        hashed_codes = []
        for code in codes:
            clean_code = code.replace('-', '')     # Remove the hyphen before hashing
            # hashlib.sha256() creates a SHA-256 hash (one-way, irreversible)
            # .encode() converts string to bytes (required by hashlib)
            # .hexdigest() returns the hash as a hexadecimal string
            hashed = hashlib.sha256(clean_code.encode()).hexdigest()
            hashed_codes.append(hashed)
        return json.dumps(hashed_codes)    # Convert list to JSON string for database storage

    @staticmethod
    def verify_backup_code(code, hashed_codes_json):
        """
        Verify a backup code against stored hashed codes.

        Steps:
        1. Hash the input code the same way we hashed the stored codes
        2. Check if the hash exists in the stored hashes list
        3. If found, remove it (backup codes are ONE-TIME USE)
        4. Return whether it was valid and the updated codes list

        Args:
            code (str): The backup code entered by the user (e.g., "A1B2-C3D4")
            hashed_codes_json (str): JSON string of hashed backup codes from database

        Returns:
            tuple: (is_valid: bool, updated_hashed_codes_json: str)
                   - is_valid: True if the code matched
                   - updated_hashed_codes_json: Updated codes with the used one removed
        """
        import hashlib

        try:
            hashed_codes = json.loads(hashed_codes_json)   # Parse JSON string to list
        except:
            return False, hashed_codes_json    # If JSON is invalid, return False

        # Hash the input code the same way (remove hyphen, uppercase, then SHA-256)
        clean_code = code.replace('-', '').upper()
        input_hash = hashlib.sha256(clean_code.encode()).hexdigest()

        # Check if the hash exists in our stored hashes
        if input_hash in hashed_codes:
            hashed_codes.remove(input_hash)    # Remove the used code (one-time use!)
            return True, json.dumps(hashed_codes)   # Return True with updated list

        return False, hashed_codes_json    # Code not found, return False

    @staticmethod
    def get_current_totp_code(secret):
        """
        Get the current TOTP code.

        THIS IS FOR DEVELOPMENT/TESTING ONLY!
        In production, only the user's authenticator app should generate codes.
        This function is useful for testing 2FA without an actual authenticator app.

        Args:
            secret (str): The base32 secret key

        Returns:
            str: Current 6-digit TOTP code
        """
        totp = pyotp.TOTP(secret)
        return totp.now()    # Returns the current 6-digit code as a string

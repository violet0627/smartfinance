import pyotp
import qrcode
import io
import base64
import json
import secrets
from datetime import datetime

class TwoFactorUtils:
    """Utility class for Two-Factor Authentication operations"""

    @staticmethod
    def generate_secret():
        """Generate a random base32 secret for TOTP"""
        return pyotp.random_base32()

    @staticmethod
    def get_totp_uri(secret, email, issuer="SmartFinance"):
        """
        Generate a TOTP URI for QR code generation

        Args:
            secret: The base32 secret key
            email: User's email address
            issuer: Application name (default: SmartFinance)

        Returns:
            TOTP provisioning URI
        """
        totp = pyotp.TOTP(secret)
        return totp.provisioning_uri(
            name=email,
            issuer_name=issuer
        )

    @staticmethod
    def generate_qr_code(secret, email, issuer="SmartFinance"):
        """
        Generate QR code image as base64 string

        Args:
            secret: The base32 secret key
            email: User's email address
            issuer: Application name

        Returns:
            Base64 encoded QR code image
        """
        # Get TOTP URI
        uri = TwoFactorUtils.get_totp_uri(secret, email, issuer)

        # Generate QR code
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_L,
            box_size=10,
            border=4,
        )
        qr.add_data(uri)
        qr.make(fit=True)

        # Create image
        img = qr.make_image(fill_color="black", back_color="white")

        # Convert to base64
        buffer = io.BytesIO()
        img.save(buffer, format='PNG')
        buffer.seek(0)
        img_base64 = base64.b64encode(buffer.getvalue()).decode()

        return f"data:image/png;base64,{img_base64}"

    @staticmethod
    def verify_totp(secret, code):
        """
        Verify a TOTP code

        Args:
            secret: The base32 secret key
            code: The 6-digit code to verify

        Returns:
            Boolean indicating if code is valid
        """
        totp = pyotp.TOTP(secret)
        # Allow 1 window (30 seconds) before/after for clock drift
        return totp.verify(code, valid_window=1)

    @staticmethod
    def generate_backup_codes(count=8):
        """
        Generate backup codes for 2FA recovery

        Args:
            count: Number of backup codes to generate (default: 8)

        Returns:
            List of backup codes
        """
        codes = []
        for _ in range(count):
            # Generate 8-character alphanumeric code
            code = secrets.token_hex(4).upper()
            # Format as XXXX-XXXX for readability
            formatted_code = f"{code[:4]}-{code[4:]}"
            codes.append(formatted_code)
        return codes

    @staticmethod
    def hash_backup_codes(codes):
        """
        Hash backup codes before storing (one-way hash)

        Args:
            codes: List of backup codes

        Returns:
            JSON string of hashed codes
        """
        import hashlib
        hashed_codes = []
        for code in codes:
            # Remove hyphen and hash
            clean_code = code.replace('-', '')
            hashed = hashlib.sha256(clean_code.encode()).hexdigest()
            hashed_codes.append(hashed)
        return json.dumps(hashed_codes)

    @staticmethod
    def verify_backup_code(code, hashed_codes_json):
        """
        Verify a backup code against stored hashes

        Args:
            code: The backup code to verify
            hashed_codes_json: JSON string of hashed backup codes

        Returns:
            Tuple of (is_valid, updated_hashed_codes_json)
        """
        import hashlib

        try:
            hashed_codes = json.loads(hashed_codes_json)
        except:
            return False, hashed_codes_json

        # Remove hyphen and hash the input code
        clean_code = code.replace('-', '').upper()
        input_hash = hashlib.sha256(clean_code.encode()).hexdigest()

        # Check if hash exists in the list
        if input_hash in hashed_codes:
            # Remove the used code
            hashed_codes.remove(input_hash)
            return True, json.dumps(hashed_codes)

        return False, hashed_codes_json

    @staticmethod
    def get_current_totp_code(secret):
        """
        Get the current TOTP code (for development/testing only)

        Args:
            secret: The base32 secret key

        Returns:
            Current 6-digit TOTP code
        """
        totp = pyotp.TOTP(secret)
        return totp.now()

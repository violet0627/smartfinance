import pyotp
import qrcode
import io
import base64
import json
import secrets
from datetime import datetime


class TwoFactorUtils:
    @staticmethod
    def generate_secret():
        return pyotp.random_base32()

    @staticmethod
    def get_totp_uri(secret, email, issuer="SmartFinance"):
        totp = pyotp.TOTP(secret)
        return totp.provisioning_uri(name=email, issuer_name=issuer)

    @staticmethod
    def generate_qr_code(secret, email, issuer="SmartFinance"):
        uri = TwoFactorUtils.get_totp_uri(secret, email, issuer)
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_L,
            box_size=10,
            border=4,
        )
        qr.add_data(uri)
        qr.make(fit=True)
        img = qr.make_image(fill_color="black", back_color="white")
        buffer = io.BytesIO()
        img.save(buffer, format='PNG')
        buffer.seek(0)
        img_base64 = base64.b64encode(buffer.getvalue()).decode()
        return f"data:image/png;base64,{img_base64}"

    @staticmethod
    def verify_totp(secret, code):
        # valid_window=1 tolerates ±30-second clock skew between server and authenticator app
        totp = pyotp.TOTP(secret)
        return totp.verify(code, valid_window=1)

    @staticmethod
    def generate_backup_codes(count=8):
        codes = []
        for _ in range(count):
            code = secrets.token_hex(4).upper()
            codes.append(f"{code[:4]}-{code[4:]}")
        return codes

    @staticmethod
    def hash_backup_codes(codes):
        import hashlib
        hashed_codes = [
            hashlib.sha256(code.replace('-', '').encode()).hexdigest()
            for code in codes
        ]
        return json.dumps(hashed_codes)

    @staticmethod
    def verify_backup_code(code, hashed_codes_json):
        # Returns (is_valid: bool, updated_hashed_codes_json: str) — used code is removed from the list
        import hashlib
        try:
            hashed_codes = json.loads(hashed_codes_json)
        except Exception:
            return False, hashed_codes_json

        input_hash = hashlib.sha256(code.replace('-', '').upper().encode()).hexdigest()
        if input_hash in hashed_codes:
            hashed_codes.remove(input_hash)
            return True, json.dumps(hashed_codes)
        return False, hashed_codes_json

    @staticmethod
    def get_current_totp_code(secret):
        # For development/testing only
        return pyotp.TOTP(secret).now()

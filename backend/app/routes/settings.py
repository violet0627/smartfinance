# ==============================================================================
# settings.py - Settings Routes (API Endpoints for User Settings & Profile)
# ==============================================================================
# This file defines API endpoints for managing user settings and profile.
#
# Features:
# - Get/update notification preferences (budget alerts, achievement alerts, etc.)
# - Get/update display preferences (currency, theme, language)
# - Get/update user profile (name, email, phone)
# - Change password
# - Get available currencies and languages
#
# URL prefix: /api/settings (set in app/__init__.py)
# ==============================================================================

from flask import Blueprint, request, jsonify      # Blueprint for grouping, request for input, jsonify for output
from app import db                                  # Database instance
from app.models.user import User                    # User model
from app.models.user_settings import UserSettings   # UserSettings model
from datetime import datetime, time                 # For timestamps and quiet hours

# --- Create the Blueprint ---
settings_bp = Blueprint('settings', __name__)


# ==============================================================================
# ROUTE: GET /api/settings/user/<user_id>
# ==============================================================================
# Called to fetch the user's settings.
# If no settings exist yet (first time), creates default settings automatically.
# ==============================================================================
@settings_bp.route('/user/<int:user_id>', methods=['GET'])
def get_user_settings(user_id):
    """Get user settings"""
    try:
        # Look up existing settings for this user
        settings = UserSettings.query.filter_by(UserId=user_id).first()

        if not settings:
            # No settings found - create default settings
            # This happens the first time a user accesses their settings
            settings = UserSettings(UserId=user_id)   # All defaults are set in the model
            db.session.add(settings)
            db.session.commit()

        return jsonify({
            'settings': settings.to_dict()
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ==============================================================================
# ROUTE: PUT /api/settings/user/<user_id>
# ==============================================================================
# Called when the user changes any setting in the Settings screen.
# Only the fields included in the request will be updated.
# ==============================================================================
@settings_bp.route('/user/<int:user_id>', methods=['PUT'])
def update_user_settings(user_id):
    """Update user settings"""
    try:
        data = request.get_json()

        # Get existing settings or create new ones
        settings = UserSettings.query.filter_by(UserId=user_id).first()

        if not settings:
            settings = UserSettings(UserId=user_id)
            db.session.add(settings)

        # --- Update notification preferences ---
        if 'enableNotifications' in data:
            settings.EnableNotifications = data['enableNotifications']          # True/False
        if 'enableBudgetAlerts' in data:
            settings.EnableBudgetAlerts = data['enableBudgetAlerts']            # True/False
        if 'enableAchievementAlerts' in data:
            settings.EnableAchievementAlerts = data['enableAchievementAlerts']  # True/False
        if 'enableStreakAlerts' in data:
            settings.EnableStreakAlerts = data['enableStreakAlerts']             # True/False

        # --- Update quiet hours (no notifications during these hours) ---
        if 'quietHoursStart' in data and data['quietHoursStart']:
            try:
                # Parse time string like "22:00" into a Python time object
                time_obj = datetime.strptime(data['quietHoursStart'], '%H:%M').time()
                settings.QuietHoursStart = time_obj
            except ValueError:
                pass   # Ignore invalid time format
        if 'quietHoursEnd' in data and data['quietHoursEnd']:
            try:
                time_obj = datetime.strptime(data['quietHoursEnd'], '%H:%M').time()
                settings.QuietHoursEnd = time_obj
            except ValueError:
                pass

        # --- Update display preferences ---
        if 'currency' in data:
            settings.Currency = data['currency']       # e.g., "RM", "USD", "EUR"
        if 'themeMode' in data:
            settings.ThemeMode = data['themeMode']     # "light", "dark", or "system"
        if 'language' in data:
            settings.Language = data['language']        # e.g., "en", "ms", "zh"

        # --- Update budget alert thresholds ---
        # These determine when color-coded warnings appear (green -> yellow -> red)
        if 'budgetWarningThreshold' in data:
            settings.BudgetWarningThreshold = data['budgetWarningThreshold']     # e.g., 70 (70%)
        if 'budgetDangerThreshold' in data:
            settings.BudgetDangerThreshold = data['budgetDangerThreshold']       # e.g., 85 (85%)
        if 'budgetCriticalThreshold' in data:
            settings.BudgetCriticalThreshold = data['budgetCriticalThreshold']   # e.g., 95 (95%)

        # --- Update privacy settings ---
        if 'showInLeaderboard' in data:
            settings.ShowInLeaderboard = data['showInLeaderboard']   # True/False

        settings.UpdatedAt = datetime.utcnow()   # Record when settings were last changed
        db.session.commit()

        return jsonify({
            'message': 'Settings updated successfully',
            'settings': settings.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


# ==============================================================================
# ROUTE: GET /api/settings/user/<user_id>/profile
# ==============================================================================
# Called to fetch the user's profile information (name, email, phone).
# ==============================================================================
@settings_bp.route('/user/<int:user_id>/profile', methods=['GET'])
def get_user_profile(user_id):
    """Get user profile information"""
    try:
        user = User.query.get(user_id)

        if not user:
            return jsonify({'error': 'User not found'}), 404

        # Return only the profile-related fields (not password, etc.)
        return jsonify({
            'profile': {
                'userId': user.UserId,
                'email': user.Email,
                'fullName': user.FullName,
                'phoneNumber': user.PhoneNumber,
                'createdAt': user.CreatedAt.isoformat() if user.CreatedAt else None
            }
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ==============================================================================
# ROUTE: PUT /api/settings/user/<user_id>/profile
# ==============================================================================
# Called when the user edits their profile (name, email, phone).
# If the user changes their email, checks that the new email isn't already taken.
# ==============================================================================
@settings_bp.route('/user/<int:user_id>/profile', methods=['PUT'])
def update_user_profile(user_id):
    """Update user profile information"""
    try:
        data = request.get_json()
        user = User.query.get(user_id)

        if not user:
            return jsonify({'error': 'User not found'}), 404

        # --- Update profile fields if provided ---
        if 'fullName' in data:
            user.FullName = data['fullName']
        if 'phoneNumber' in data:
            user.PhoneNumber = data['phoneNumber']
        if 'email' in data:
            # Check if the new email is already used by ANOTHER user
            existing_user = User.query.filter(
                User.Email == data['email'],       # Find users with this email
                User.UserId != user_id              # But not the current user
            ).first()
            if existing_user:
                return jsonify({'error': 'Email already in use'}), 400
            user.Email = data['email']

        db.session.commit()

        return jsonify({
            'message': 'Profile updated successfully',
            'profile': {
                'userId': user.UserId,
                'email': user.Email,
                'fullName': user.FullName,
                'phoneNumber': user.PhoneNumber
            }
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


# ==============================================================================
# ROUTE: POST /api/settings/user/<user_id>/change-password
# ==============================================================================
# Called when the user changes their password from the Settings screen.
# Requires the current password for security (proves it's the account owner).
# ==============================================================================
@settings_bp.route('/user/<int:user_id>/change-password', methods=['POST'])
def change_password(user_id):
    """Change user password"""
    try:
        data = request.get_json()
        user = User.query.get(user_id)

        if not user:
            return jsonify({'error': 'User not found'}), 404

        # --- Verify current password first ---
        # The user must know their current password to change it
        if not user.check_password(data.get('currentPassword', '')):
            return jsonify({'error': 'Current password is incorrect'}), 400

        # --- Validate the new password ---
        new_password = data.get('newPassword', '')
        if len(new_password) < 6:
            return jsonify({'error': 'New password must be at least 6 characters'}), 400

        # --- Update password ---
        user.set_password(new_password)   # Hash and save the new password
        db.session.commit()

        return jsonify({
            'message': 'Password changed successfully'
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


# ==============================================================================
# ROUTE: GET /api/settings/currencies
# ==============================================================================
# Returns a list of available currencies for the user to choose from.
# The Flutter app displays this in a dropdown in the Settings screen.
# ==============================================================================
@settings_bp.route('/currencies', methods=['GET'])
def get_available_currencies():
    """Get list of available currencies"""
    currencies = [
        {'code': 'RM', 'name': 'Malaysian Ringgit', 'symbol': 'RM'},    # Default
        {'code': 'USD', 'name': 'US Dollar', 'symbol': '$'},
        {'code': 'EUR', 'name': 'Euro', 'symbol': '\u20ac'},            # Euro symbol
        {'code': 'GBP', 'name': 'British Pound', 'symbol': '\u00a3'},   # Pound symbol
        {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '\u00a5'},    # Yen symbol
        {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': '\u00a5'},    # Yuan symbol
        {'code': 'SGD', 'name': 'Singapore Dollar', 'symbol': 'S$'},
        {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': 'A$'},
        {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': 'C$'},
        {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '\u20b9'},    # Rupee symbol
    ]

    return jsonify({
        'currencies': currencies
    }), 200


# ==============================================================================
# ROUTE: GET /api/settings/languages
# ==============================================================================
# Returns a list of available languages.
# Supports Malaysian market languages: English, Malay, Chinese, Tamil.
# ==============================================================================
@settings_bp.route('/languages', methods=['GET'])
def get_available_languages():
    """Get list of available languages"""
    languages = [
        {'code': 'en', 'name': 'English'},
        {'code': 'ms', 'name': 'Bahasa Melayu'},
        {'code': 'zh', 'name': '中文 (Chinese)'},
        {'code': 'ta', 'name': 'தமிழ் (Tamil)'},
    ]

    return jsonify({
        'languages': languages
    }), 200

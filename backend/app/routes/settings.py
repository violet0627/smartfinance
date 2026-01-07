from flask import Blueprint, request, jsonify
from app import db
from app.models.user import User
from app.models.user_settings import UserSettings
from datetime import datetime, time

settings_bp = Blueprint('settings', __name__)


@settings_bp.route('/user/<int:user_id>', methods=['GET'])
def get_user_settings(user_id):
    """Get user settings"""
    try:
        settings = UserSettings.query.filter_by(UserId=user_id).first()

        if not settings:
            # Create default settings if not exists
            settings = UserSettings(UserId=user_id)
            db.session.add(settings)
            db.session.commit()

        return jsonify({
            'settings': settings.to_dict()
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@settings_bp.route('/user/<int:user_id>', methods=['PUT'])
def update_user_settings(user_id):
    """Update user settings"""
    try:
        data = request.get_json()

        settings = UserSettings.query.filter_by(UserId=user_id).first()

        if not settings:
            settings = UserSettings(UserId=user_id)
            db.session.add(settings)

        # Update notification preferences
        if 'enableNotifications' in data:
            settings.EnableNotifications = data['enableNotifications']
        if 'enableBudgetAlerts' in data:
            settings.EnableBudgetAlerts = data['enableBudgetAlerts']
        if 'enableAchievementAlerts' in data:
            settings.EnableAchievementAlerts = data['enableAchievementAlerts']
        if 'enableStreakAlerts' in data:
            settings.EnableStreakAlerts = data['enableStreakAlerts']

        # Update quiet hours
        if 'quietHoursStart' in data and data['quietHoursStart']:
            try:
                time_obj = datetime.strptime(data['quietHoursStart'], '%H:%M').time()
                settings.QuietHoursStart = time_obj
            except ValueError:
                pass
        if 'quietHoursEnd' in data and data['quietHoursEnd']:
            try:
                time_obj = datetime.strptime(data['quietHoursEnd'], '%H:%M').time()
                settings.QuietHoursEnd = time_obj
            except ValueError:
                pass

        # Update display preferences
        if 'currency' in data:
            settings.Currency = data['currency']
        if 'themeMode' in data:
            settings.ThemeMode = data['themeMode']
        if 'language' in data:
            settings.Language = data['language']

        # Update alert thresholds
        if 'budgetWarningThreshold' in data:
            settings.BudgetWarningThreshold = data['budgetWarningThreshold']
        if 'budgetDangerThreshold' in data:
            settings.BudgetDangerThreshold = data['budgetDangerThreshold']
        if 'budgetCriticalThreshold' in data:
            settings.BudgetCriticalThreshold = data['budgetCriticalThreshold']

        # Update privacy settings
        if 'showInLeaderboard' in data:
            settings.ShowInLeaderboard = data['showInLeaderboard']

        settings.UpdatedAt = datetime.utcnow()
        db.session.commit()

        return jsonify({
            'message': 'Settings updated successfully',
            'settings': settings.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@settings_bp.route('/user/<int:user_id>/profile', methods=['GET'])
def get_user_profile(user_id):
    """Get user profile information"""
    try:
        user = User.query.get(user_id)

        if not user:
            return jsonify({'error': 'User not found'}), 404

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


@settings_bp.route('/user/<int:user_id>/profile', methods=['PUT'])
def update_user_profile(user_id):
    """Update user profile information"""
    try:
        data = request.get_json()
        user = User.query.get(user_id)

        if not user:
            return jsonify({'error': 'User not found'}), 404

        # Update profile fields
        if 'fullName' in data:
            user.FullName = data['fullName']
        if 'phoneNumber' in data:
            user.PhoneNumber = data['phoneNumber']
        if 'email' in data:
            # Check if email already exists for another user
            existing_user = User.query.filter(
                User.Email == data['email'],
                User.UserId != user_id
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


@settings_bp.route('/user/<int:user_id>/change-password', methods=['POST'])
def change_password(user_id):
    """Change user password"""
    try:
        data = request.get_json()
        user = User.query.get(user_id)

        if not user:
            return jsonify({'error': 'User not found'}), 404

        # Verify current password
        if not user.check_password(data.get('currentPassword', '')):
            return jsonify({'error': 'Current password is incorrect'}), 400

        # Validate new password
        new_password = data.get('newPassword', '')
        if len(new_password) < 6:
            return jsonify({'error': 'New password must be at least 6 characters'}), 400

        # Update password
        user.set_password(new_password)
        db.session.commit()

        return jsonify({
            'message': 'Password changed successfully'
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@settings_bp.route('/currencies', methods=['GET'])
def get_available_currencies():
    """Get list of available currencies"""
    currencies = [
        {'code': 'RM', 'name': 'Malaysian Ringgit', 'symbol': 'RM'},
        {'code': 'USD', 'name': 'US Dollar', 'symbol': '$'},
        {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
        {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
        {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥'},
        {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': '¥'},
        {'code': 'SGD', 'name': 'Singapore Dollar', 'symbol': 'S$'},
        {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': 'A$'},
        {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': 'C$'},
        {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹'},
    ]

    return jsonify({
        'currencies': currencies
    }), 200


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

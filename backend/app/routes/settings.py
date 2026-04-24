# Currency (RM), theme (light), and language (English) are fixed for this app — not stored in settings

from flask import Blueprint, request, jsonify
from app import db
from app.models.user import User
from app.models.user_settings import UserSettings
from datetime import datetime, time

settings_bp = Blueprint('settings', __name__)


@settings_bp.route('/user/<int:user_id>', methods=['GET'])
def get_user_settings(user_id):
    try:
        settings = UserSettings.query.filter_by(UserId=user_id).first()

        if not settings:
            settings = UserSettings(UserId=user_id)
            db.session.add(settings)
            db.session.commit()

        return jsonify({'settings': settings.to_dict()}), 200
    except Exception as e:
        return jsonify({'error': 'Failed to fetch settings'}), 500


@settings_bp.route('/user/<int:user_id>', methods=['PUT'])
def update_user_settings(user_id):
    try:
        data = request.get_json()

        settings = UserSettings.query.filter_by(UserId=user_id).first()

        if not settings:
            settings = UserSettings(UserId=user_id)
            db.session.add(settings)

        if 'enableNotifications' in data:
            settings.EnableNotifications = data['enableNotifications']
        if 'enableBudgetAlerts' in data:
            settings.EnableBudgetAlerts = data['enableBudgetAlerts']
        if 'enableAchievementAlerts' in data:
            settings.EnableAchievementAlerts = data['enableAchievementAlerts']
        if 'enableStreakAlerts' in data:
            settings.EnableStreakAlerts = data['enableStreakAlerts']

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

        if 'budgetWarningThreshold' in data:
            settings.BudgetWarningThreshold = data['budgetWarningThreshold']
        if 'budgetDangerThreshold' in data:
            settings.BudgetDangerThreshold = data['budgetDangerThreshold']
        if 'budgetCriticalThreshold' in data:
            settings.BudgetCriticalThreshold = data['budgetCriticalThreshold']

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
        return jsonify({'error': 'Failed to update settings'}), 500


@settings_bp.route('/user/<int:user_id>/profile', methods=['GET'])
def get_user_profile(user_id):
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
        return jsonify({'error': 'Failed to fetch profile'}), 500


@settings_bp.route('/user/<int:user_id>/profile', methods=['PUT'])
def update_user_profile(user_id):
    try:
        data = request.get_json()
        user = User.query.get(user_id)

        if not user:
            return jsonify({'error': 'User not found'}), 404

        if 'fullName' in data:
            user.FullName = data['fullName']
        if 'phoneNumber' in data:
            user.PhoneNumber = data['phoneNumber']
        if 'email' in data:
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
        return jsonify({'error': 'Failed to update profile'}), 500


@settings_bp.route('/user/<int:user_id>/change-password', methods=['POST'])
def change_password(user_id):
    try:
        data = request.get_json()
        user = User.query.get(user_id)

        if not user:
            return jsonify({'error': 'User not found'}), 404

        if not user.check_password(data.get('currentPassword', '')):
            return jsonify({'error': 'Current password is incorrect'}), 400

        new_password = data.get('newPassword', '')
        if len(new_password) < 6:
            return jsonify({'error': 'New password must be at least 6 characters'}), 400

        user.set_password(new_password)
        db.session.commit()

        return jsonify({'message': 'Password changed successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to change password'}), 500

from flask import Blueprint, request, jsonify
from app import db
from app.models.user import User
from app.models.session import UserSession
from app.models.security_log import SecurityLog
from app.models.achievement import UserAchievement, HabitStreak
from app.models.user_settings import UserSettings
from app.models.password_reset import PasswordReset
from app.models.two_factor_auth import TwoFactorAuth
from app.models.email_verification import EmailVerification
from app.models.recurring_transaction import RecurringTransaction
from app.models.transaction import Transaction
from app.models.budget import Budget, BudgetCategory
from app.models.investment import Investment
from app.models.goal import Goal
from datetime import datetime

security_bp = Blueprint('security', __name__)


@security_bp.route('/sessions/user/<int:user_id>', methods=['GET'])
def get_user_sessions(user_id):
    try:
        sessions = UserSession.query.filter_by(
            UserId=user_id,
            IsActive=True
        ).order_by(UserSession.LastActiveAt.desc()).all()

        return jsonify({
            'sessions': [session.to_dict() for session in sessions],
            'total': len(sessions)
        }), 200
    except Exception as e:
        return jsonify({'error': 'Failed to fetch sessions'}), 500


@security_bp.route('/sessions/<int:session_id>/revoke', methods=['POST'])
def revoke_session(session_id):
    try:
        data = request.get_json()
        user_id = data.get('userId')

        session = UserSession.query.filter_by(
            SessionId=session_id,
            UserId=user_id
        ).first()

        if not session:
            return jsonify({'error': 'Session not found'}), 404

        session.IsActive = False
        db.session.commit()

        log_security_event(
            user_id=user_id,
            event_type='session_revoked',
            description=f'Session {session_id} revoked',
            ip_address=request.remote_addr,
            device_info=request.headers.get('User-Agent')
        )

        return jsonify({'message': 'Session revoked successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to revoke session'}), 500


@security_bp.route('/sessions/user/<int:user_id>/revoke-all', methods=['POST'])
def revoke_all_sessions(user_id):
    try:
        data = request.get_json()
        current_session_id = data.get('currentSessionId')

        if current_session_id:
            UserSession.query.filter(
                UserSession.UserId == user_id,
                UserSession.SessionId != current_session_id,
                UserSession.IsActive == True
            ).update({UserSession.IsActive: False})
        else:
            UserSession.query.filter_by(
                UserId=user_id,
                IsActive=True
            ).update({UserSession.IsActive: False})

        db.session.commit()

        log_security_event(
            user_id=user_id,
            event_type='all_sessions_revoked',
            description='All sessions revoked',
            ip_address=request.remote_addr,
            device_info=request.headers.get('User-Agent')
        )

        return jsonify({'message': 'All sessions revoked successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to revoke sessions'}), 500


@security_bp.route('/activity/user/<int:user_id>', methods=['GET'])
def get_security_activity(user_id):
    try:
        limit = request.args.get('limit', 50, type=int)
        offset = request.args.get('offset', 0, type=int)

        logs = SecurityLog.query.filter_by(
            UserId=user_id
        ).order_by(SecurityLog.CreatedAt.desc()).limit(limit).offset(offset).all()

        total = SecurityLog.query.filter_by(UserId=user_id).count()

        return jsonify({
            'logs': [log.to_dict() for log in logs],
            'total': total,
            'limit': limit,
            'offset': offset
        }), 200
    except Exception as e:
        return jsonify({'error': 'Failed to fetch activity log'}), 500


@security_bp.route('/activity/log', methods=['POST'])
def create_security_log():
    try:
        data = request.get_json()

        log = SecurityLog(
            UserId=data.get('userId'),
            EventType=data.get('eventType'),
            EventDescription=data.get('description'),
            IpAddress=request.remote_addr,
            DeviceInfo=request.headers.get('User-Agent'),
            Success=data.get('success', True)
        )

        db.session.add(log)
        db.session.commit()

        return jsonify({
            'message': 'Security log created',
            'log': log.to_dict()
        }), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to create security log'}), 500


@security_bp.route('/account/delete', methods=['POST'])
def delete_account():
    try:
        data = request.get_json()
        user_id = data.get('userId')
        password = data.get('password')

        if not user_id or not password:
            return jsonify({'error': 'User ID and password are required'}), 400

        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        if not user.check_password(password):
            log_security_event(
                user_id=user_id,
                event_type='account_deletion_failed',
                description='Failed account deletion attempt - wrong password',
                ip_address=request.remote_addr,
                device_info=request.headers.get('User-Agent'),
                success=False
            )
            return jsonify({'error': 'Incorrect password'}), 401

        log_security_event(
            user_id=user_id,
            event_type='account_deleted',
            description='Account permanently deleted',
            ip_address=request.remote_addr,
            device_info=request.headers.get('User-Agent')
        )

        # Explicit delete of every related table — SQLAlchemy cascade can nullify instead of delete
        # when UserId is non-nullable, causing IntegrityError. Explicit order avoids FK violations.
        PasswordReset.query.filter_by(UserId=user_id).delete()
        TwoFactorAuth.query.filter_by(UserId=user_id).delete()
        EmailVerification.query.filter_by(UserId=user_id).delete()
        UserSession.query.filter_by(UserId=user_id).delete()
        SecurityLog.query.filter_by(UserId=user_id).delete()
        UserAchievement.query.filter_by(UserId=user_id).delete()
        HabitStreak.query.filter_by(UserId=user_id).delete()
        UserSettings.query.filter_by(UserId=user_id).delete()
        RecurringTransaction.query.filter_by(UserId=user_id).delete()
        Transaction.query.filter_by(UserId=user_id).delete()
        Investment.query.filter_by(UserId=user_id).delete()
        Goal.query.filter_by(UserId=user_id).delete()

        budget_ids = [b.BudgetId for b in Budget.query.filter_by(UserId=user_id).all()]
        if budget_ids:
            BudgetCategory.query.filter(BudgetCategory.BudgetId.in_(budget_ids)).delete(synchronize_session=False)
        Budget.query.filter_by(UserId=user_id).delete()

        db.session.flush()  # send all DELETEs to MySQL before removing the user row
        db.session.delete(user)
        db.session.commit()

        return jsonify({'message': 'Account deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to delete account'}), 500


def log_security_event(user_id, event_type, description, ip_address=None, device_info=None, success=True):
    try:
        log = SecurityLog(
            UserId=user_id,
            EventType=event_type,
            EventDescription=description,
            IpAddress=ip_address,
            DeviceInfo=device_info,
            Success=success
        )
        db.session.add(log)
        db.session.commit()
    except Exception as e:
        db.session.rollback()
        print(f"Error logging security event: {e}")

from flask import Blueprint, request, jsonify
from app import db
from app.models.user import User
from app.models.session import UserSession
from app.models.security_log import SecurityLog
from datetime import datetime

security_bp = Blueprint('security', __name__)

# ==================== ACTIVE SESSIONS ====================

@security_bp.route('/sessions/user/<int:user_id>', methods=['GET'])
def get_user_sessions(user_id):
    """Get all active sessions for a user"""
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
        return jsonify({'error': f'Failed to fetch sessions: {str(e)}'}), 500


@security_bp.route('/sessions/<int:session_id>/revoke', methods=['POST'])
def revoke_session(session_id):
    """Revoke a specific session"""
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

        # Log security event
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
        return jsonify({'error': f'Failed to revoke session: {str(e)}'}), 500


@security_bp.route('/sessions/user/<int:user_id>/revoke-all', methods=['POST'])
def revoke_all_sessions(user_id):
    """Revoke all sessions except current one"""
    try:
        data = request.get_json()
        current_session_id = data.get('currentSessionId')

        # Revoke all sessions except the current one
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

        # Log security event
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
        return jsonify({'error': f'Failed to revoke sessions: {str(e)}'}), 500


# ==================== SECURITY ACTIVITY LOG ====================

@security_bp.route('/activity/user/<int:user_id>', methods=['GET'])
def get_security_activity(user_id):
    """Get security activity log for a user"""
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
        return jsonify({'error': f'Failed to fetch activity log: {str(e)}'}), 500


@security_bp.route('/activity/log', methods=['POST'])
def create_security_log():
    """Create a new security log entry"""
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
        return jsonify({'error': f'Failed to create security log: {str(e)}'}), 500


# ==================== ACCOUNT DELETION ====================

@security_bp.route('/account/delete', methods=['POST'])
def delete_account():
    """Delete user account (requires password confirmation)"""
    try:
        data = request.get_json()
        user_id = data.get('userId')
        password = data.get('password')

        if not user_id or not password:
            return jsonify({'error': 'User ID and password are required'}), 400

        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        # Verify password
        if not user.check_password(password):
            # Log failed attempt
            log_security_event(
                user_id=user_id,
                event_type='account_deletion_failed',
                description='Failed account deletion attempt - wrong password',
                ip_address=request.remote_addr,
                device_info=request.headers.get('User-Agent'),
                success=False
            )
            return jsonify({'error': 'Incorrect password'}), 401

        # Log successful deletion before deleting
        log_security_event(
            user_id=user_id,
            event_type='account_deleted',
            description='Account permanently deleted',
            ip_address=request.remote_addr,
            device_info=request.headers.get('User-Agent')
        )

        # Delete user (cascade will delete all related data)
        db.session.delete(user)
        db.session.commit()

        return jsonify({'message': 'Account deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to delete account: {str(e)}'}), 500


# ==================== HELPER FUNCTIONS ====================

def log_security_event(user_id, event_type, description, ip_address=None, device_info=None, success=True):
    """Helper function to log security events"""
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
        print(f"Error logging security event: {str(e)}")

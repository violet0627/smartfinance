# ==============================================================================
# security.py - Security Routes (API Endpoints for Sessions, Activity Log, Account)
# ==============================================================================
# This file defines API endpoints for security-related features:
#
# 1. ACTIVE SESSIONS: View and manage devices logged into the account
#    - See all active sessions (device, IP, login time)
#    - Revoke (log out) a specific session
#    - Revoke all sessions except the current one
#
# 2. SECURITY ACTIVITY LOG: Audit trail of security events
#    - View history of logins, password changes, 2FA events, etc.
#    - Create new log entries
#
# 3. ACCOUNT DELETION: Permanently delete a user account
#    - Requires password confirmation
#    - Cascading delete removes all user data
#
# URL prefix: /api/security (set in app/__init__.py)
# ==============================================================================

from flask import Blueprint, request, jsonify      # Blueprint for grouping, request for input, jsonify for output
from app import db                                  # Database instance
from app.models.user import User                    # User model
from app.models.session import UserSession          # UserSession model (active login sessions)
from app.models.security_log import SecurityLog     # SecurityLog model (audit trail)
from app.models.achievement import UserAchievement, HabitStreak  # Gamification models — no DB-level cascade, must delete manually
from app.models.user_settings import UserSettings   # User settings — no DB-level cascade, must delete manually
from datetime import datetime                        # For timestamps

# --- Create the Blueprint ---
security_bp = Blueprint('security', __name__)


# ==================== ACTIVE SESSIONS ====================

# ==============================================================================
# ROUTE: GET /api/security/sessions/user/<user_id>
# ==============================================================================
# Called to show the user what devices are currently logged into their account.
# Displays in the "Active Sessions" section of the Security settings screen.
# ==============================================================================
@security_bp.route('/sessions/user/<int:user_id>', methods=['GET'])
def get_user_sessions(user_id):
    """Get all active sessions for a user"""
    try:
        # Find all ACTIVE sessions for this user, sorted by most recent activity
        sessions = UserSession.query.filter_by(
            UserId=user_id,
            IsActive=True            # Only get sessions that are still active (not logged out)
        ).order_by(UserSession.LastActiveAt.desc()).all()

        return jsonify({
            'sessions': [session.to_dict() for session in sessions],
            'total': len(sessions)
        }), 200
    except Exception as e:
        return jsonify({'error': f'Failed to fetch sessions: {str(e)}'}), 500


# ==============================================================================
# ROUTE: POST /api/security/sessions/<session_id>/revoke
# ==============================================================================
# Called when the user clicks "Log Out" on a specific session.
# This deactivates the session, effectively logging out that device.
# Also creates a security log entry for auditing.
# ==============================================================================
@security_bp.route('/sessions/<int:session_id>/revoke', methods=['POST'])
def revoke_session(session_id):
    """Revoke a specific session"""
    try:
        data = request.get_json()
        user_id = data.get('userId')

        # Find the session (must belong to this user for security)
        session = UserSession.query.filter_by(
            SessionId=session_id,
            UserId=user_id            # Verify ownership - can only revoke your own sessions
        ).first()

        if not session:
            return jsonify({'error': 'Session not found'}), 404

        # Deactivate the session (mark as logged out)
        session.IsActive = False
        db.session.commit()

        # Log this security event for the audit trail
        log_security_event(
            user_id=user_id,
            event_type='session_revoked',
            description=f'Session {session_id} revoked',
            ip_address=request.remote_addr,                    # IP address of the person who revoked it
            device_info=request.headers.get('User-Agent')      # Browser/device info
        )

        return jsonify({'message': 'Session revoked successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to revoke session: {str(e)}'}), 500


# ==============================================================================
# ROUTE: POST /api/security/sessions/user/<user_id>/revoke-all
# ==============================================================================
# Called when the user clicks "Log Out All Devices".
# Deactivates all sessions except optionally the current one.
# This is a security measure if the user suspects unauthorized access.
# ==============================================================================
@security_bp.route('/sessions/user/<int:user_id>/revoke-all', methods=['POST'])
def revoke_all_sessions(user_id):
    """Revoke all sessions except current one"""
    try:
        data = request.get_json()
        current_session_id = data.get('currentSessionId')   # Keep this session active (optional)

        if current_session_id:
            # Revoke all sessions EXCEPT the current one
            # .update() is a bulk update - changes all matching rows at once
            UserSession.query.filter(
                UserSession.UserId == user_id,
                UserSession.SessionId != current_session_id,    # Exclude current session
                UserSession.IsActive == True
            ).update({UserSession.IsActive: False})
        else:
            # Revoke ALL sessions (including current)
            UserSession.query.filter_by(
                UserId=user_id,
                IsActive=True
            ).update({UserSession.IsActive: False})

        db.session.commit()

        # Log this security event
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

# ==============================================================================
# ROUTE: GET /api/security/activity/user/<user_id>
# ==============================================================================
# Called to show the security activity log (audit trail).
# Displays events like logins, password changes, 2FA changes, etc.
# Supports pagination with limit and offset parameters.
# ==============================================================================
@security_bp.route('/activity/user/<int:user_id>', methods=['GET'])
def get_security_activity(user_id):
    """Get security activity log for a user"""
    try:
        # Pagination parameters
        limit = request.args.get('limit', 50, type=int)       # How many entries per page (default: 50)
        offset = request.args.get('offset', 0, type=int)      # How many entries to skip (default: 0)

        # Get logs sorted by newest first, with pagination
        logs = SecurityLog.query.filter_by(
            UserId=user_id
        ).order_by(SecurityLog.CreatedAt.desc()).limit(limit).offset(offset).all()

        # Get total count for pagination info
        total = SecurityLog.query.filter_by(UserId=user_id).count()

        return jsonify({
            'logs': [log.to_dict() for log in logs],
            'total': total,          # Total number of log entries
            'limit': limit,          # Entries per page
            'offset': offset         # Current offset
        }), 200
    except Exception as e:
        return jsonify({'error': f'Failed to fetch activity log: {str(e)}'}), 500


# ==============================================================================
# ROUTE: POST /api/security/activity/log
# ==============================================================================
# Called to create a new security log entry.
# This can be called from the Flutter app when security events happen.
# ==============================================================================
@security_bp.route('/activity/log', methods=['POST'])
def create_security_log():
    """Create a new security log entry"""
    try:
        data = request.get_json()

        # Create a new log entry
        log = SecurityLog(
            UserId=data.get('userId'),
            EventType=data.get('eventType'),           # e.g., "login", "password_change"
            EventDescription=data.get('description'),   # Human-readable description
            IpAddress=request.remote_addr,               # Auto-detect IP address
            DeviceInfo=request.headers.get('User-Agent'),# Auto-detect device info from HTTP headers
            Success=data.get('success', True)            # Was the event successful? (default: True)
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

# ==============================================================================
# ROUTE: POST /api/security/account/delete
# ==============================================================================
# Called when the user wants to permanently delete their account.
# This is a DESTRUCTIVE action - it deletes the user and ALL their data.
#
# Safety measures:
# - Requires password confirmation
# - Logs the event before deleting (for audit purposes)
# - Cascade delete removes all related data (transactions, budgets, etc.)
# ==============================================================================
@security_bp.route('/account/delete', methods=['POST'])
def delete_account():
    """Delete user account (requires password confirmation)"""
    try:
        data = request.get_json()
        user_id = data.get('userId')
        password = data.get('password')      # Must confirm password

        if not user_id or not password:
            return jsonify({'error': 'User ID and password are required'}), 400

        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        # --- Verify password ---
        if not user.check_password(password):
            # Log the failed attempt (someone might be trying to delete without authorization)
            log_security_event(
                user_id=user_id,
                event_type='account_deletion_failed',
                description='Failed account deletion attempt - wrong password',
                ip_address=request.remote_addr,
                device_info=request.headers.get('User-Agent'),
                success=False
            )
            return jsonify({'error': 'Incorrect password'}), 401

        # --- Log the deletion BEFORE actually deleting ---
        # (The log will be deleted by cascade, but it's good practice to record it)
        log_security_event(
            user_id=user_id,
            event_type='account_deleted',
            description='Account permanently deleted',
            ip_address=request.remote_addr,
            device_info=request.headers.get('User-Agent')
        )

        # --- Manually delete records without DB-level CASCADE first ---
        # UserAchievements and HabitStreaks have no ON DELETE CASCADE on their foreign keys,
        # so MySQL will throw a constraint error if we try to delete the user without clearing these first.
        # UserSettings also has no cascade — must be removed before the user row is deleted.
        UserAchievement.query.filter_by(UserId=user_id).delete()  # Remove all earned achievements
        HabitStreak.query.filter_by(UserId=user_id).delete()      # Remove streak record
        UserSettings.query.filter_by(UserId=user_id).delete()     # Remove user settings
        db.session.flush()  # Send the above DELETEs to MySQL before deleting the user row

        # --- Delete the user ---
        # SQLAlchemy cascade='all, delete-orphan' on the User relationships will automatically
        # clean up: transactions, budgets (+ categories), investments, goals.
        # DB-level ON DELETE CASCADE handles: sessions, security logs, 2FA, password resets,
        # email verifications, recurring transactions.
        db.session.delete(user)
        db.session.commit()

        return jsonify({'message': 'Account deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to delete account: {str(e)}'}), 500


# ==================== HELPER FUNCTIONS ====================

def log_security_event(user_id, event_type, description, ip_address=None, device_info=None, success=True):
    """
    Helper function to create security log entries.

    Called by other functions in this file (and potentially other routes)
    to record security-related events in the audit trail.

    Args:
        user_id (int): The user's ID
        event_type (str): Type of event (e.g., "login", "session_revoked")
        description (str): Human-readable description of what happened
        ip_address (str): IP address where the event originated (optional)
        device_info (str): Device/browser information (optional)
        success (bool): Whether the action was successful (default: True)
    """
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
        print(f"Error logging security event: {str(e)}")   # Print error but don't crash

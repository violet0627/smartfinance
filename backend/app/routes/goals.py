# ==============================================================================
# goals.py - Financial Goals Routes (API Endpoints for Savings Goals)
# ==============================================================================
# This file defines ALL the goal-related API endpoints.
# Goals let users set financial targets and track their progress.
#
# Examples:
# - "Emergency Fund" - Save RM10,000 by December 2025
# - "Vacation to Japan" - Save RM5,000 by June 2025
# - "New Laptop" - Save RM3,000 by March 2025
#
# Users can contribute money toward their goals and the app shows progress.
#
# URL prefix: /api/goals (set in app/__init__.py)
# ==============================================================================

from flask import Blueprint, request, jsonify      # Blueprint for grouping, request for input, jsonify for output
from app import db                                  # Database instance
from app.models.goal import Goal                    # Goal model (database table)
from datetime import datetime                       # For date operations
import logging                                      # Standard Python logging

logger = logging.getLogger(__name__)

# --- Create the Blueprint ---
goals_bp = Blueprint('goals', __name__)


# ==============================================================================
# ROUTE: GET /api/goals/user/<user_id>
# ==============================================================================
# Called to fetch all goals for a user.
# Supports optional filtering by status (active, completed, paused).
# Results are sorted by priority (highest first), then by deadline (soonest first).
# ==============================================================================
@goals_bp.route('/user/<int:user_id>', methods=['GET'])
def get_user_goals(user_id):
    """Get all goals for a user"""
    try:
        # Optional status filter from query parameter
        # Example: GET /api/goals/user/1?status=active
        status_filter = request.args.get('status', None)

        # Build query starting with all goals for this user
        query = Goal.query.filter_by(UserId=user_id)

        # Add status filter if provided
        if status_filter:
            query = query.filter_by(Status=status_filter)

        # Sort: highest priority first, then earliest deadline first
        # .desc() = descending (high to low), .asc() = ascending (low to high)
        goals = query.order_by(Goal.Priority.desc(), Goal.Deadline.asc()).all()

        return jsonify({
            'goals': [goal.to_dict() for goal in goals],   # Convert each goal to dict
            'count': len(goals)
        }), 200
    except Exception as e:
        logger.error(str(e))
        return jsonify({'error': 'Failed to fetch goals'}), 500


# ==============================================================================
# ROUTE: POST /api/goals/user/<user_id>
# ==============================================================================
# Called when the user creates a new savings goal.
# ==============================================================================
@goals_bp.route('/user/<int:user_id>', methods=['POST'])
def create_goal(user_id):
    """Create a new goal"""
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'Request body is required'}), 400

        # --- Step 1: Validate required fields ---
        if not data.get('goalName') or not str(data.get('goalName', '')).strip():
            return jsonify({'error': 'goalName is required'}), 400
        if not data.get('targetAmount'):
            return jsonify({'error': 'targetAmount is required'}), 400
        if not data.get('deadline'):
            return jsonify({'error': 'deadline is required'}), 400

        # --- Validate targetAmount is a positive number ---
        try:
            target_amount = float(data['targetAmount'])
            if target_amount <= 0:
                return jsonify({'error': 'targetAmount must be greater than 0'}), 400
        except (ValueError, TypeError):
            return jsonify({'error': 'Invalid targetAmount format'}), 400

        # --- Step 2: Parse the deadline date ---
        try:
            deadline = datetime.strptime(data['deadline'], '%Y-%m-%d').date()
        except ValueError:
            return jsonify({'error': 'Invalid deadline format. Use YYYY-MM-DD'}), 400

        # --- Step 3: Create the Goal record ---
        new_goal = Goal(
            UserId=user_id,                                      # Which user owns this goal
            GoalName=data['goalName'],                           # e.g., "Emergency Fund"
            Description=data.get('description', ''),             # Optional description
            TargetAmount=data['targetAmount'],                   # How much to save (e.g., 10000)
            CurrentAmount=data.get('currentAmount', 0),          # How much saved so far (default: 0)
            StartDate=datetime.now().date(),                     # Today's date
            Deadline=deadline,                                   # When the goal should be achieved
            Category=data.get('category', 'Other'),              # e.g., "Emergency Fund", "Vacation"
            Priority=data.get('priority', 'medium'),             # "low", "medium", or "high"
            Status='active'                                      # New goals start as active
        )

        # --- Step 4: Save to database ---
        db.session.add(new_goal)
        db.session.commit()

        return jsonify({
            'message': 'Goal created successfully',
            'goal': new_goal.to_dict()
        }), 201
    except Exception as e:
        logger.error(str(e))
        db.session.rollback()
        return jsonify({'error': 'Failed to create goal'}), 500


# ==============================================================================
# ROUTE: GET /api/goals/<goal_id>
# ==============================================================================
# Called to fetch a single goal by its ID.
# ==============================================================================
@goals_bp.route('/<int:goal_id>', methods=['GET'])
def get_goal(goal_id):
    """Get a specific goal by ID"""
    try:
        goal = Goal.query.get(goal_id)

        if not goal:
            return jsonify({'error': 'Goal not found'}), 404

        return jsonify({'goal': goal.to_dict()}), 200
    except Exception as e:
        logger.error(str(e))
        return jsonify({'error': 'Failed to fetch goal'}), 500


# ==============================================================================
# ROUTE: PUT /api/goals/<goal_id>
# ==============================================================================
# Called when the user edits an existing goal.
# Special feature: If currentAmount reaches targetAmount, the goal is
# automatically marked as "completed".
# ==============================================================================
@goals_bp.route('/<int:goal_id>', methods=['PUT'])
def update_goal(goal_id):
    """Update an existing goal"""
    try:
        goal = Goal.query.get(goal_id)

        if not goal:
            return jsonify({'error': 'Goal not found'}), 404

        data = request.get_json()
        if not data:
            return jsonify({'error': 'Request body is required'}), 400

        # --- Update each field if provided ---
        if 'goalName' in data:
            goal.GoalName = data['goalName']
        if 'description' in data:
            goal.Description = data['description']
        if 'targetAmount' in data:
            goal.TargetAmount = data['targetAmount']
        if 'currentAmount' in data:
            goal.CurrentAmount = data['currentAmount']
            # AUTO-COMPLETE: If the user has saved enough, mark the goal as completed
            if float(goal.CurrentAmount) >= float(goal.TargetAmount) and goal.Status == 'active':
                goal.Status = 'completed'
        if 'deadline' in data:
            goal.Deadline = datetime.strptime(data['deadline'], '%Y-%m-%d').date()
        if 'category' in data:
            goal.Category = data['category']
        if 'priority' in data:
            goal.Priority = data['priority']
        if 'status' in data:
            goal.Status = data['status']

        goal.UpdatedAt = datetime.utcnow()   # Record when the update happened
        db.session.commit()

        return jsonify({
            'message': 'Goal updated successfully',
            'goal': goal.to_dict()
        }), 200
    except Exception as e:
        logger.error(str(e))
        db.session.rollback()
        return jsonify({'error': 'Failed to update goal'}), 500


# ==============================================================================
# ROUTE: DELETE /api/goals/<goal_id>
# ==============================================================================
# Called when the user deletes a goal.
# ==============================================================================
@goals_bp.route('/<int:goal_id>', methods=['DELETE'])
def delete_goal(goal_id):
    """Delete a goal"""
    try:
        goal = Goal.query.get(goal_id)

        if not goal:
            return jsonify({'error': 'Goal not found'}), 404

        db.session.delete(goal)
        db.session.commit()

        return jsonify({'message': 'Goal deleted successfully'}), 200
    except Exception as e:
        logger.error(str(e))
        db.session.rollback()
        return jsonify({'error': 'Failed to delete goal'}), 500


# ==============================================================================
# ROUTE: POST /api/goals/<goal_id>/contribute
# ==============================================================================
# Called when the user adds money toward a goal.
# This is a convenience endpoint that adds to CurrentAmount.
#
# Example: User contributes RM500 to their "Emergency Fund" goal.
# If this brings them to the target, the goal auto-completes.
# ==============================================================================
@goals_bp.route('/<int:goal_id>/contribute', methods=['POST'])
def contribute_to_goal(goal_id):
    """Add contribution to a goal"""
    try:
        goal = Goal.query.get(goal_id)

        if not goal:
            return jsonify({'error': 'Goal not found'}), 404

        data = request.get_json()
        if not data:
            return jsonify({'error': 'Request body is required'}), 400
        amount = data.get('amount', 0)

        # Validate contribution amount
        if amount <= 0:
            return jsonify({'error': 'Contribution amount must be positive'}), 400

        # Validate that contribution does not exceed remaining amount
        remaining = float(goal.TargetAmount) - float(goal.CurrentAmount)
        if float(amount) > remaining:
            return jsonify({'error': 'Contribution exceeds remaining amount'}), 400

        # Add the contribution to the current amount
        goal.CurrentAmount = float(goal.CurrentAmount) + float(amount)

        # AUTO-COMPLETE: Check if the goal has been reached
        if float(goal.CurrentAmount) >= float(goal.TargetAmount) and goal.Status == 'active':
            goal.Status = 'completed'

        goal.UpdatedAt = datetime.utcnow()
        db.session.commit()

        return jsonify({
            'message': 'Contribution added successfully',
            'goal': goal.to_dict()
        }), 200
    except Exception as e:
        logger.error(str(e))
        db.session.rollback()
        return jsonify({'error': 'Failed to process contribution'}), 500


# ==============================================================================
# ROUTE: GET /api/goals/user/<user_id>/summary
# ==============================================================================
# Called to get an overview of all the user's goals.
# Returns counts, total target/saved amounts, overall progress percentage,
# and the goal with the closest deadline.
# Used by the dashboard screen.
# ==============================================================================
@goals_bp.route('/user/<int:user_id>/summary', methods=['GET'])
def get_goals_summary(user_id):
    """Get summary of user's goals"""
    try:
        # Get all goals for this user
        goals = Goal.query.filter_by(UserId=user_id).all()

        # Separate active and completed goals using list comprehension
        active_goals = [g for g in goals if g.Status == 'active']
        completed_goals = [g for g in goals if g.Status == 'completed']

        # Calculate totals for active goals only
        total_target = sum(float(g.TargetAmount) for g in active_goals)     # Total target amount
        total_saved = sum(float(g.CurrentAmount) for g in active_goals)     # Total saved so far
        total_remaining = total_target - total_saved                         # How much more to save

        # Overall progress as a percentage
        overall_progress = (total_saved / total_target * 100) if total_target > 0 else 0

        # Find the goal with the closest (nearest) deadline
        closest_goal = None
        if active_goals:
            # min() with key=lambda finds the goal with the smallest (earliest) deadline
            closest_goal = min(active_goals, key=lambda g: g.Deadline)

        return jsonify({
            'totalGoals': len(goals),                                           # Total number of goals
            'activeGoals': len(active_goals),                                   # Number of active goals
            'completedGoals': len(completed_goals),                             # Number completed
            'totalTargetAmount': round(total_target, 2),                        # Total target
            'totalSavedAmount': round(total_saved, 2),                          # Total saved
            'totalRemainingAmount': round(total_remaining, 2),                  # Total remaining
            'overallProgress': round(overall_progress, 2),                      # Overall % progress
            'closestDeadline': closest_goal.to_dict() if closest_goal else None # Nearest deadline goal
        }), 200
    except Exception as e:
        logger.error(str(e))
        return jsonify({'error': 'Failed to fetch goals summary'}), 500


# ==============================================================================
# ROUTE: GET /api/goals/categories
# ==============================================================================
# Returns a list of predefined goal categories with their icons.
# The Flutter app uses this to display category options when creating a goal.
# The 'icon' values correspond to Flutter Material Icons.
# ==============================================================================
@goals_bp.route('/categories', methods=['GET'])
def get_goal_categories():
    """Get available goal categories"""
    categories = [
        {'name': 'Emergency Fund', 'icon': 'emergency'},     # For rainy days
        {'name': 'Vacation', 'icon': 'flight'},               # Travel goals
        {'name': 'Home', 'icon': 'home'},                     # House purchase/renovation
        {'name': 'Education', 'icon': 'school'},              # Tuition, courses
        {'name': 'Car', 'icon': 'directions_car'},            # Vehicle purchase
        {'name': 'Wedding', 'icon': 'favorite'},              # Wedding expenses
        {'name': 'Retirement', 'icon': 'elderly'},            # Retirement savings
        {'name': 'Business', 'icon': 'business'},             # Business investment
        {'name': 'Investment', 'icon': 'trending_up'},        # Investment capital
        {'name': 'Other', 'icon': 'savings'}                  # Anything else
    ]
    return jsonify({'categories': categories}), 200

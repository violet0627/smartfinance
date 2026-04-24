from flask import Blueprint, request, jsonify
from app import db
from app.models.goal import Goal
from datetime import datetime

goals_bp = Blueprint('goals', __name__)


@goals_bp.route('/user/<int:user_id>', methods=['GET'])
def get_user_goals(user_id):
    try:
        status_filter = request.args.get('status', None)
        query = Goal.query.filter_by(UserId=user_id)

        if status_filter:
            query = query.filter_by(Status=status_filter)

        goals = query.order_by(Goal.Priority.desc(), Goal.Deadline.asc()).all()

        return jsonify({
            'goals': [goal.to_dict() for goal in goals],
            'count': len(goals)
        }), 200
    except Exception as e:
        return jsonify({'error': 'Failed to fetch goals'}), 500


@goals_bp.route('/user/<int:user_id>', methods=['POST'])
def create_goal(user_id):
    try:
        data = request.get_json()

        if not data.get('goalName') or not str(data.get('goalName', '')).strip():
            return jsonify({'error': 'goalName is required'}), 400
        if not data.get('targetAmount'):
            return jsonify({'error': 'targetAmount is required'}), 400
        if not data.get('deadline'):
            return jsonify({'error': 'deadline is required'}), 400

        try:
            target_amount = float(data['targetAmount'])
            if target_amount <= 0:
                return jsonify({'error': 'targetAmount must be greater than 0'}), 400
        except (ValueError, TypeError):
            return jsonify({'error': 'Invalid targetAmount format'}), 400

        try:
            deadline = datetime.strptime(data['deadline'], '%Y-%m-%d').date()
        except ValueError:
            return jsonify({'error': 'Invalid deadline format. Use YYYY-MM-DD'}), 400

        new_goal = Goal(
            UserId=user_id,
            GoalName=data['goalName'],
            Description=data.get('description', ''),
            TargetAmount=data['targetAmount'],
            CurrentAmount=data.get('currentAmount', 0),
            StartDate=datetime.now().date(),
            Deadline=deadline,
            Category=data.get('category', 'Other'),
            Priority=data.get('priority', 'medium'),
            Status='active'
        )

        db.session.add(new_goal)
        db.session.commit()

        return jsonify({
            'message': 'Goal created successfully',
            'goal': new_goal.to_dict()
        }), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to create goal'}), 500


@goals_bp.route('/<int:goal_id>', methods=['GET'])
def get_goal(goal_id):
    try:
        goal = Goal.query.get(goal_id)

        if not goal:
            return jsonify({'error': 'Goal not found'}), 404

        return jsonify({'goal': goal.to_dict()}), 200
    except Exception as e:
        return jsonify({'error': 'Failed to fetch goal'}), 500


@goals_bp.route('/<int:goal_id>', methods=['PUT'])
def update_goal(goal_id):
    try:
        goal = Goal.query.get(goal_id)

        if not goal:
            return jsonify({'error': 'Goal not found'}), 404

        data = request.get_json()

        if 'goalName' in data:
            goal.GoalName = data['goalName']
        if 'description' in data:
            goal.Description = data['description']
        if 'targetAmount' in data:
            goal.TargetAmount = data['targetAmount']
        if 'currentAmount' in data:
            goal.CurrentAmount = data['currentAmount']
            # Auto-complete when the saved amount reaches the target
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

        goal.UpdatedAt = datetime.utcnow()
        db.session.commit()

        return jsonify({
            'message': 'Goal updated successfully',
            'goal': goal.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to update goal'}), 500


@goals_bp.route('/<int:goal_id>', methods=['DELETE'])
def delete_goal(goal_id):
    try:
        goal = Goal.query.get(goal_id)

        if not goal:
            return jsonify({'error': 'Goal not found'}), 404

        db.session.delete(goal)
        db.session.commit()

        return jsonify({'message': 'Goal deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to delete goal'}), 500


@goals_bp.route('/<int:goal_id>/contribute', methods=['POST'])
def contribute_to_goal(goal_id):
    try:
        goal = Goal.query.get(goal_id)

        if not goal:
            return jsonify({'error': 'Goal not found'}), 404

        data = request.get_json()
        amount = data.get('amount', 0)

        if amount <= 0:
            return jsonify({'error': 'Contribution amount must be positive'}), 400

        remaining = float(goal.TargetAmount) - float(goal.CurrentAmount)
        if float(amount) > remaining:
            return jsonify({'error': 'Contribution exceeds remaining amount'}), 400

        goal.CurrentAmount = float(goal.CurrentAmount) + float(amount)

        # Auto-complete when the saved amount reaches the target
        if float(goal.CurrentAmount) >= float(goal.TargetAmount) and goal.Status == 'active':
            goal.Status = 'completed'

        goal.UpdatedAt = datetime.utcnow()
        db.session.commit()

        return jsonify({
            'message': 'Contribution added successfully',
            'goal': goal.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to process contribution'}), 500


@goals_bp.route('/user/<int:user_id>/summary', methods=['GET'])
def get_goals_summary(user_id):
    try:
        goals = Goal.query.filter_by(UserId=user_id).all()

        active_goals = [g for g in goals if g.Status == 'active']
        completed_goals = [g for g in goals if g.Status == 'completed']

        total_target = sum(float(g.TargetAmount) for g in active_goals)
        total_saved = sum(float(g.CurrentAmount) for g in active_goals)
        total_remaining = total_target - total_saved
        overall_progress = (total_saved / total_target * 100) if total_target > 0 else 0

        closest_goal = min(active_goals, key=lambda g: g.Deadline) if active_goals else None

        return jsonify({
            'totalGoals': len(goals),
            'activeGoals': len(active_goals),
            'completedGoals': len(completed_goals),
            'totalTargetAmount': round(total_target, 2),
            'totalSavedAmount': round(total_saved, 2),
            'totalRemainingAmount': round(total_remaining, 2),
            'overallProgress': round(overall_progress, 2),
            'closestDeadline': closest_goal.to_dict() if closest_goal else None
        }), 200
    except Exception as e:
        return jsonify({'error': 'Failed to fetch goals summary'}), 500


@goals_bp.route('/categories', methods=['GET'])
def get_goal_categories():
    categories = [
        {'name': 'Emergency Fund', 'icon': 'emergency'},
        {'name': 'Vacation', 'icon': 'flight'},
        {'name': 'Home', 'icon': 'home'},
        {'name': 'Education', 'icon': 'school'},
        {'name': 'Car', 'icon': 'directions_car'},
        {'name': 'Wedding', 'icon': 'favorite'},
        {'name': 'Retirement', 'icon': 'elderly'},
        {'name': 'Business', 'icon': 'business'},
        {'name': 'Investment', 'icon': 'trending_up'},
        {'name': 'Other', 'icon': 'savings'}
    ]
    return jsonify({'categories': categories}), 200

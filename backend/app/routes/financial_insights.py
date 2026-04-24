from flask import Blueprint, jsonify
from app import db
from app.models.transaction import Transaction
from app.models.budget import Budget
from app.models.goal import Goal
from datetime import datetime, date
from collections import defaultdict
from sqlalchemy import extract

insights_bp = Blueprint('insights', __name__)


@insights_bp.route('/user/<int:user_id>', methods=['GET'])
def get_financial_insights(user_id):
    try:
        today = date.today()
        current_year = today.year
        current_month = today.month

        # Handle January → December wraparound for previous month
        if current_month == 1:
            prev_month = 12
            prev_year = current_year - 1
        else:
            prev_month = current_month - 1
            prev_year = current_year

        current_txns = Transaction.query.filter(
            Transaction.UserId == user_id,
            extract('year', Transaction.TransactionDate) == current_year,
            extract('month', Transaction.TransactionDate) == current_month,
        ).all()

        prev_txns = Transaction.query.filter(
            Transaction.UserId == user_id,
            extract('year', Transaction.TransactionDate) == prev_year,
            extract('month', Transaction.TransactionDate) == prev_month,
        ).all()

        def _aggregate(txns):
            income = 0.0
            expense = 0.0
            by_cat = defaultdict(float)

            for t in txns:
                amt = float(t.Amount)
                if t.TransactionType == 'income':
                    income += amt
                else:
                    expense += amt
                    by_cat[t.Category] += amt

            return {'income': income, 'expense': expense, 'by_cat': dict(by_cat)}

        cur = _aggregate(current_txns)
        prev = _aggregate(prev_txns)

        cur_income = cur['income']
        cur_expense = cur['expense']
        prev_expense = prev['expense']

        current_month_str = f"{current_year}-{current_month:02d}"
        budget = Budget.query.filter(
            Budget.UserId == user_id,
            Budget.MonthYear == current_month_str,
        ).first()

        budget_limit = float(budget.TotalBudget) if budget else None

        goals = Goal.query.filter_by(UserId=user_id).all()
        total_goals = len(goals)
        goals_completed = sum(1 for g in goals if float(g.CurrentAmount) >= float(g.TargetAmount))

        # Pillar A: Savings rate — 20%+ income saved → full 25 pts
        if cur_income > 0:
            savings_rate = max(0.0, (cur_income - cur_expense) / cur_income * 100)
            pillar_a = min(25, (savings_rate / 20.0) * 25)
        else:
            savings_rate = 0.0
            pillar_a = 12.5  # neutral when no income recorded

        # Pillar B: Budget adherence — sliding scale; 50%+ over budget → 0 pts
        if budget_limit and budget_limit > 0:
            over_ratio = max(0.0, (cur_expense - budget_limit) / budget_limit)
            pillar_b = max(0.0, 25 - (over_ratio * 50))
        else:
            pillar_b = 12.5  # neutral when no budget set

        # Pillar C: Spending consistency — within 10% of last month → 25 pts; each 2% over → −1 pt
        if prev_expense > 0 and cur_expense > 0:
            change_ratio = (cur_expense - prev_expense) / prev_expense
            if change_ratio <= 0.10:
                pillar_c = 25.0
            else:
                excess = change_ratio - 0.10
                pillar_c = max(0.0, 25.0 - (excess * 50))
        else:
            pillar_c = 12.5  # neutral when insufficient data

        # Pillar D: Goal progress — proportional to completed goals
        if total_goals > 0:
            pillar_d = (goals_completed / total_goals) * 25
        else:
            pillar_d = 12.5  # neutral when no goals set

        total_score = int(round(pillar_a + pillar_b + pillar_c + pillar_d))
        total_score = max(0, min(100, total_score))

        insights = []

        if cur_income > 0:
            savings_amount = cur_income - cur_expense
            if savings_rate >= 20:
                insights.append({
                    'type': 'positive',
                    'icon': 'savings',
                    'title': 'Strong savings rate',
                    'message': f"You're saving {savings_rate:.1f}% of your income this month "
                               f"(RM {savings_amount:.2f}). Financial experts recommend at least 20%.",
                })
            elif savings_rate >= 10:
                insights.append({
                    'type': 'info',
                    'icon': 'savings',
                    'title': 'Moderate savings rate',
                    'message': f"You're saving {savings_rate:.1f}% of your income (RM {savings_amount:.2f}). "
                               f"Try to reach 20% — reduce one discretionary category to get there.",
                })
            elif savings_amount > 0:
                insights.append({
                    'type': 'warning',
                    'icon': 'warning_amber',
                    'title': 'Low savings rate',
                    'message': f"You're only saving {savings_rate:.1f}% of your income this month. "
                               f"Aim for at least 20% — that's RM {cur_income * 0.2:.2f} based on your income.",
                })
            else:
                insights.append({
                    'type': 'danger',
                    'icon': 'trending_down',
                    'title': 'Spending exceeds income',
                    'message': f"Your expenses (RM {cur_expense:.2f}) exceed income "
                               f"(RM {cur_income:.2f}) by RM {abs(savings_amount):.2f} this month. "
                               f"Review your spending immediately.",
                })

        if budget_limit:
            remaining = budget_limit - cur_expense
            used_pct = (cur_expense / budget_limit) * 100
            if remaining >= 0:
                insights.append({
                    'type': 'positive' if used_pct <= 80 else 'info',
                    'icon': 'account_balance_wallet',
                    'title': 'Within budget' if used_pct <= 80 else 'Budget nearly full',
                    'message': f"You've used {used_pct:.1f}% of your monthly budget. "
                               f"RM {remaining:.2f} remaining for the rest of the month.",
                })
            else:
                insights.append({
                    'type': 'danger',
                    'icon': 'money_off',
                    'title': 'Over budget',
                    'message': f"You've exceeded your budget by RM {abs(remaining):.2f} "
                               f"({used_pct:.1f}% of your limit). Consider cutting back on non-essentials.",
                })
        else:
            insights.append({
                'type': 'info',
                'icon': 'account_balance_wallet',
                'title': 'No budget set',
                'message': "You haven't created a monthly budget yet. "
                           "Setting a budget is the single most effective way to control spending.",
            })

        if prev_expense > 0 and cur_expense > 0:
            diff = cur_expense - prev_expense
            pct = (diff / prev_expense) * 100
            if diff > 0:
                insight_type = 'warning' if pct > 15 else 'info'
                insights.append({
                    'type': insight_type,
                    'icon': 'trending_up',
                    'title': f"Spending up {pct:.1f}% vs last month",
                    'message': f"You spent RM {cur_expense:.2f} this month vs RM {prev_expense:.2f} "
                               f"last month — an increase of RM {diff:.2f}.",
                })
            else:
                insights.append({
                    'type': 'positive',
                    'icon': 'trending_down',
                    'title': f"Spending down {abs(pct):.1f}% vs last month",
                    'message': f"Great discipline! You reduced spending by RM {abs(diff):.2f} "
                               f"compared to last month.",
                })

        if cur['by_cat']:
            top_cat = max(cur['by_cat'], key=lambda k: cur['by_cat'][k])
            top_amt = cur['by_cat'][top_cat]
            top_pct = (top_amt / cur_expense * 100) if cur_expense > 0 else 0

            if top_pct > 50:
                insights.append({
                    'type': 'warning',
                    'icon': 'pie_chart',
                    'title': f'{top_cat} dominates spending',
                    'message': f"{top_cat} accounts for {top_pct:.1f}% of all expenses "
                               f"(RM {top_amt:.2f}). Consider whether this aligns with your priorities.",
                })
            else:
                insights.append({
                    'type': 'info',
                    'icon': 'pie_chart',
                    'title': f'Top category: {top_cat}',
                    'message': f"Your biggest expense this month is {top_cat} "
                               f"at RM {top_amt:.2f} ({top_pct:.1f}% of total spending).",
                })

        if cur['by_cat'] and prev['by_cat']:
            biggest_spike_cat = None
            biggest_spike_pct = 0.0
            for cat, amt in cur['by_cat'].items():
                if cat in prev['by_cat'] and prev['by_cat'][cat] > 0:
                    spike = (amt - prev['by_cat'][cat]) / prev['by_cat'][cat] * 100
                    if spike > 50 and spike > biggest_spike_pct:
                        biggest_spike_pct = spike
                        biggest_spike_cat = cat

            if biggest_spike_cat:
                prev_amt = prev['by_cat'][biggest_spike_cat]
                cur_amt = cur['by_cat'][biggest_spike_cat]
                insights.append({
                    'type': 'warning',
                    'icon': 'notification_important',
                    'title': f'{biggest_spike_cat} spending spiked',
                    'message': f"{biggest_spike_cat} jumped {biggest_spike_pct:.0f}% this month "
                               f"(RM {prev_amt:.2f} → RM {cur_amt:.2f}). Was this planned?",
                })

        if total_goals > 0:
            if goals_completed == total_goals:
                insights.append({
                    'type': 'positive',
                    'icon': 'emoji_events',
                    'title': 'All goals achieved!',
                    'message': f"Outstanding! You've completed all {total_goals} of your financial goals. "
                               f"Set new goals to keep the momentum going.",
                })
            else:
                in_progress = total_goals - goals_completed
                insights.append({
                    'type': 'info',
                    'icon': 'flag',
                    'title': f'{in_progress} goal{"s" if in_progress > 1 else ""} in progress',
                    'message': f"You have {in_progress} active goal{"s" if in_progress > 1 else ""} "
                               f"and {goals_completed} completed. Keep contributing to stay on track.",
                })
        else:
            insights.append({
                'type': 'info',
                'icon': 'flag',
                'title': 'No savings goals',
                'message': "You haven't set any financial goals yet. "
                           "Goals give your saving a purpose and keep you motivated.",
            })

        if total_score >= 80:
            score_label = 'Excellent'
            score_color = 'green'
        elif total_score >= 60:
            score_label = 'Good'
            score_color = 'teal'
        elif total_score >= 40:
            score_label = 'Fair'
            score_color = 'orange'
        else:
            score_label = 'Needs Work'
            score_color = 'red'

        return jsonify({
            'score': total_score,
            'scoreLabel': score_label,
            'scoreColor': score_color,
            'pillars': {
                'savingsRate': round(pillar_a, 1),
                'budgetAdherence': round(pillar_b, 1),
                'spendingConsistency': round(pillar_c, 1),
                'goalProgress': round(pillar_d, 1),
            },
            'summary': {
                'currentMonthIncome': round(cur_income, 2),
                'currentMonthExpense': round(cur_expense, 2),
                'savingsAmount': round(cur_income - cur_expense, 2),
                'savingsRate': round(savings_rate, 1),
            },
            'insights': insights,
        }), 200

    except Exception as e:
        return jsonify({'error': 'Failed to generate insights'}), 500

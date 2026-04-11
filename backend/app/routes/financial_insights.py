# ==============================================================================
# financial_insights.py - Financial Health & Insights API Routes
# ==============================================================================
# This blueprint provides a single endpoint that analyses a user's transaction
# history and returns personalised financial insights plus a health score.
#
# How it works:
# 1. Pull all transactions for the current and previous calendar months
# 2. Compare spending across categories month-over-month
# 3. Calculate a Financial Health Score (0–100) from four pillars:
#      - Savings rate (how much of income is saved)
#      - Budget adherence (how close actual spend is to budget)
#      - Spending consistency (month-over-month stability)
#      - Goal progress (are savings goals on track?)
# 4. Generate 4–6 human-readable insight messages ranked by importance
# 5. Return everything as JSON to the Flutter app
#
# Endpoint:
#   GET /api/insights/user/<user_id>   → full report for that user
# ==============================================================================

from flask import Blueprint, jsonify      # Blueprint groups routes; jsonify converts dict → JSON
from app import db                        # SQLAlchemy database instance (shared across the app)
from app.models.transaction import Transaction   # ORM model for the Transactions table
from app.models.budget import Budget             # ORM model for the Budgets table
from app.models.goal import Goal                 # ORM model for the Goals table
from datetime import datetime, date              # For working with dates and the current month
from collections import defaultdict              # defaultdict(float) avoids KeyError on missing keys
from sqlalchemy import extract                   # SQLAlchemy helper to filter by year/month

# --- Create the Blueprint ---
# All routes in this file are grouped under the name 'insights'.
# In __init__.py this will be registered with url_prefix='/api/insights'.
insights_bp = Blueprint('insights', __name__)


# ==============================================================================
# ROUTE: GET /api/insights/user/<user_id>
# ==============================================================================
# Returns a complete financial health report for the given user.
# Called every time the Financial Insights screen is opened or refreshed.
# ==============================================================================
@insights_bp.route('/user/<int:user_id>', methods=['GET'])
def get_financial_insights(user_id):
    """Generate a personalised financial health report for the user."""
    try:
        # --- Date Setup ---
        today = date.today()
        current_year = today.year
        current_month = today.month

        # Calculate previous month (handle January → December wrap-around)
        # If today is January (month 1) the previous month is December (month 12) of last year.
        if current_month == 1:
            prev_month = 12
            prev_year = current_year - 1
        else:
            prev_month = current_month - 1
            prev_year = current_year

        # --- Step 1: Fetch This Month's Transactions ---
        # extract() lets SQLAlchemy filter by specific parts of a date column.
        # We only want rows where the year AND month match the current month.
        current_txns = Transaction.query.filter(
            Transaction.UserId == user_id,
            extract('year', Transaction.TransactionDate) == current_year,
            extract('month', Transaction.TransactionDate) == current_month,
        ).all()

        # --- Step 2: Fetch Last Month's Transactions ---
        prev_txns = Transaction.query.filter(
            Transaction.UserId == user_id,
            extract('year', Transaction.TransactionDate) == prev_year,
            extract('month', Transaction.TransactionDate) == prev_month,
        ).all()

        # --- Step 3: Aggregate Totals ---
        # _aggregate() separates income from expenses and groups expenses by category.
        def _aggregate(txns):
            """
            Summarise a list of Transaction objects into totals.

            Returns a dict with:
              income  — total income amount
              expense — total expense amount
              by_cat  — dict of category → total expense for that category
            """
            income = 0.0
            expense = 0.0
            by_cat = defaultdict(float)   # Automatically initialises missing keys to 0.0

            for t in txns:
                amt = float(t.Amount)
                if t.TransactionType == 'income':
                    income += amt
                else:
                    expense += amt
                    by_cat[t.Category] += amt   # Accumulate spend per category

            return {'income': income, 'expense': expense, 'by_cat': dict(by_cat)}

        cur = _aggregate(current_txns)    # Current month summary
        prev = _aggregate(prev_txns)      # Previous month summary

        # Shorthand variables for readability
        cur_income = cur['income']
        cur_expense = cur['expense']
        prev_expense = prev['expense']

        # --- Step 4: Fetch Active Budget (if any) ---
        # Budgets are identified by MonthYear (format "YYYY-MM", e.g. "2026-03").
        # We look for a budget whose MonthYear matches the current calendar month.
        current_month_str = f"{current_year}-{current_month:02d}"  # e.g. "2026-03"
        budget = Budget.query.filter(
            Budget.UserId == user_id,
            Budget.MonthYear == current_month_str,   # Match this month's budget only
        ).first()

        # TotalBudget is the column name in the Budgets table (not 'Amount' or 'EndDate')
        budget_limit = float(budget.TotalBudget) if budget else None

        # --- Step 5: Fetch Goals ---
        goals = Goal.query.filter_by(UserId=user_id).all()
        total_goals = len(goals)
        # A goal is "on track" if its current amount is >= expected progress.
        # Expected progress = (days elapsed this month / days in month) × target.
        # For simplicity, we compare CurrentAmount vs TargetAmount directly.
        goals_completed = sum(1 for g in goals if float(g.CurrentAmount) >= float(g.TargetAmount))

        # --- Step 6: Calculate Financial Health Score ---
        # The score is built from four independent pillars, each worth up to 25 points.
        # This gives a 0–100 composite score shown as a circle on the screen.

        score = 0

        # PILLAR A — Savings Rate (0–25 pts)
        # Savings rate = (income − expense) / income × 100
        # 20%+ savings → full 25 pts; 0% savings → 0 pts; proportional in between.
        if cur_income > 0:
            savings_rate = max(0.0, (cur_income - cur_expense) / cur_income * 100)
            # Scale: 20% rate → 25 pts, capped at 25
            pillar_a = min(25, (savings_rate / 20.0) * 25)
        else:
            # No income recorded this month → neutral score (12.5 = half marks)
            savings_rate = 0.0
            pillar_a = 12.5

        # PILLAR B — Budget Adherence (0–25 pts)
        # Full 25 pts if within budget, sliding scale down to 0 if 50%+ over budget.
        if budget_limit and budget_limit > 0:
            over_ratio = max(0.0, (cur_expense - budget_limit) / budget_limit)
            # over_ratio 0 → 25 pts; over_ratio 0.5 (50% over) → 0 pts
            pillar_b = max(0.0, 25 - (over_ratio * 50))
        else:
            # No budget set → neutral (12.5)
            pillar_b = 12.5

        # PILLAR C — Spending Consistency (0–25 pts)
        # Penalises large month-over-month spending spikes.
        # If spending is within 10% of last month → 25 pts.
        # Each 10% increase above that → −5 pts, floored at 0.
        if prev_expense > 0 and cur_expense > 0:
            change_ratio = (cur_expense - prev_expense) / prev_expense   # +0.2 = 20% increase
            if change_ratio <= 0.10:
                pillar_c = 25.0                            # Within 10% → perfect
            else:
                excess = change_ratio - 0.10               # Amount above the 10% tolerance
                pillar_c = max(0.0, 25.0 - (excess * 50)) # Each 2% excess → −1 pt
        else:
            pillar_c = 12.5    # Not enough data → neutral

        # PILLAR D — Goal Progress (0–25 pts)
        # If all goals are completed → 25 pts.
        # Proportional based on how many goals are completed.
        if total_goals > 0:
            pillar_d = (goals_completed / total_goals) * 25
        else:
            pillar_d = 12.5    # No goals set → neutral

        # Sum all pillars and round to the nearest integer for display.
        total_score = int(round(pillar_a + pillar_b + pillar_c + pillar_d))
        total_score = max(0, min(100, total_score))   # Clamp between 0 and 100

        # --- Step 7: Generate Insight Messages ---
        # Each insight is a dict with:
        #   type    — 'positive' | 'warning' | 'danger' | 'info'
        #   icon    — Material icon name (used by the Flutter UI)
        #   title   — Short headline
        #   message — One-sentence explanation
        insights = []

        # ── Insight 1: Savings Rate ────────────────────────────────────────────
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

        # ── Insight 2: Budget Adherence ────────────────────────────────────────
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

        # ── Insight 3: Month-over-Month Spending Change ────────────────────────
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

        # ── Insight 4: Top Spending Category ──────────────────────────────────
        if cur['by_cat']:
            # Find the category with the highest spending this month
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

        # ── Insight 5: Category Spike Detection ───────────────────────────────
        # Find a category that spiked more than 50% compared to last month.
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

        # ── Insight 6: Goals Progress ──────────────────────────────────────────
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

        # --- Step 8: Determine Score Label ---
        # Human-readable label for the score range shown below the circle.
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

        # --- Step 9: Build and Return the Response ---
        return jsonify({
            'score': total_score,            # 0–100 health score
            'scoreLabel': score_label,       # 'Excellent' | 'Good' | 'Fair' | 'Needs Work'
            'scoreColor': score_color,       # Hint for the Flutter UI colour
            'pillars': {                     # Individual pillar scores (each 0–25)
                'savingsRate': round(pillar_a, 1),
                'budgetAdherence': round(pillar_b, 1),
                'spendingConsistency': round(pillar_c, 1),
                'goalProgress': round(pillar_d, 1),
            },
            'summary': {                     # High-level numbers for the summary row
                'currentMonthIncome': round(cur_income, 2),
                'currentMonthExpense': round(cur_expense, 2),
                'savingsAmount': round(cur_income - cur_expense, 2),
                'savingsRate': round(savings_rate, 1),
            },
            'insights': insights,            # List of insight dicts (type, icon, title, message)
        }), 200

    except Exception as e:
        # Return a structured error — never let unhandled exceptions reach the client
        return jsonify({'error': 'Failed to generate insights'}), 500

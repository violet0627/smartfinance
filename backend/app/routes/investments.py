# ==============================================================================
# investments.py - Investment Routes (API Endpoints for Portfolio Management)
# ==============================================================================
# This file defines ALL the investment-related API endpoints.
# Users can track their investment portfolio including stocks, crypto,
# mutual funds, bonds, and other asset types.
#
# Features:
# - Add/edit/delete investments
# - Track current prices and profit/loss
# - View portfolio summary with asset breakdown
# - Identify top and bottom performing investments
#
# URL prefix: /api/investments (set in app/__init__.py)
# ==============================================================================

from flask import Blueprint, request, jsonify      # Blueprint for grouping, request for input, jsonify for output
from app import db                                  # Database instance
from app.models.investment import Investment        # Investment model (database table)
from datetime import datetime                       # For timestamps
import logging                                      # Standard Python logging

logger = logging.getLogger(__name__)

# --- Create the Blueprint ---
investments_bp = Blueprint('investments', __name__)


# ==============================================================================
# ROUTE: POST /api/investments/
# ==============================================================================
# Called when the user adds a new investment to their portfolio.
# Example: User buys 100 shares of Maybank at RM9.50 each.
# ==============================================================================
@investments_bp.route('/', methods=['POST'])
def create_investment():
    """Create a new investment entry"""
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'Request body is required'}), 400

        # --- Step 1: Validate required fields ---
        required_fields = ['assetName', 'assetsType', 'quantity', 'purchasePrice', 'purchaseDate', 'userId']
        for field in required_fields:
            if field not in data or data[field] is None:
                return jsonify({'error': f'{field} is required'}), 400

        # --- Validate quantity is a positive number ---
        try:
            quantity = float(data['quantity'])
            if quantity <= 0:
                return jsonify({'error': 'quantity must be greater than 0'}), 400
        except (ValueError, TypeError):
            return jsonify({'error': 'Invalid quantity format'}), 400

        # --- Validate purchasePrice is a positive number ---
        try:
            purchase_price = float(data['purchasePrice'])
            if purchase_price <= 0:
                return jsonify({'error': 'purchasePrice must be greater than 0'}), 400
        except (ValueError, TypeError):
            return jsonify({'error': 'Invalid purchasePrice format'}), 400

        # --- Step 2: Parse the purchase date ---
        try:
            purchase_date = datetime.strptime(data['purchaseDate'], '%Y-%m-%d').date()
        except ValueError:
            return jsonify({'error': 'Invalid date format. Use YYYY-MM-DD'}), 400

        # --- Step 3: Create the Investment record ---
        new_investment = Investment(
            AssetName=data['assetName'],                     # e.g., "Maybank", "Bitcoin"
            AssetsType=data['assetsType'],                   # e.g., "stocks", "crypto", "mutual_funds"
            StockSymbol=data.get('stockSymbol'),             # Optional stock ticker (e.g., "MAYBANK")
            Quantity=quantity,                               # Validated positive number
            PurchasePrice=purchase_price,                    # Validated positive number
            PurchaseDate=purchase_date,                      # When the purchase was made
            CurrentPrice=data.get('currentPrice', purchase_price),  # Default to purchase price if not provided
            Notes=data.get('notes'),                         # Optional notes
            UserId=data['userId']                            # Which user owns this investment
        )

        # --- Step 4: Save to database ---
        db.session.add(new_investment)
        db.session.commit()

        return jsonify({
            'message': 'Investment created successfully',
            'investment': new_investment.to_dict()
        }), 201

    except Exception as e:
        logger.error(str(e))
        db.session.rollback()
        return jsonify({'error': 'Failed to create investment'}), 500


# ==============================================================================
# ROUTE: GET /api/investments/user/<user_id>
# ==============================================================================
# Called to fetch all investments for a user.
# Supports optional filtering by asset type.
# Example: GET /api/investments/user/1?type=stocks
# ==============================================================================
@investments_bp.route('/user/<int:user_id>', methods=['GET'])
def get_user_investments(user_id):
    """Get all investments for a user with optional filtering"""
    try:
        query = Investment.query.filter_by(UserId=user_id)

        # --- Optional filter by asset type ---
        asset_type = request.args.get('type')    # e.g., "stocks", "crypto"
        if asset_type:
            query = query.filter_by(AssetsType=asset_type)

        # Order by purchase date (newest first)
        investments = query.order_by(Investment.PurchaseDate.desc()).all()

        return jsonify({
            'investments': [inv.to_dict() for inv in investments],
            'count': len(investments)
        }), 200

    except Exception as e:
        logger.error(str(e))
        return jsonify({'error': 'Failed to fetch investments'}), 500


# ==============================================================================
# ROUTE: GET /api/investments/<investment_id>
# ==============================================================================
# Called to fetch a single investment by its ID.
# ==============================================================================
@investments_bp.route('/<int:investment_id>', methods=['GET'])
def get_investment(investment_id):
    """Get a specific investment by ID"""
    try:
        investment = Investment.query.get(investment_id)

        if not investment:
            return jsonify({'error': 'Investment not found'}), 404

        return jsonify({'investment': investment.to_dict()}), 200

    except Exception as e:
        logger.error(str(e))
        return jsonify({'error': 'Failed to fetch investment'}), 500


# ==============================================================================
# ROUTE: PUT /api/investments/<investment_id>
# ==============================================================================
# Called when the user edits an investment (e.g., updating the current price).
# Only the provided fields will be updated.
# ==============================================================================
@investments_bp.route('/<int:investment_id>', methods=['PUT'])
def update_investment(investment_id):
    """Update an investment (mainly for updating current price)"""
    try:
        investment = Investment.query.get(investment_id)

        if not investment:
            return jsonify({'error': 'Investment not found'}), 404

        data = request.get_json()
        if not data:
            return jsonify({'error': 'Request body is required'}), 400

        # --- Update only the fields that were provided ---
        if 'currentPrice' in data:
            investment.CurrentPrice = data['currentPrice']      # Update current market price
        if 'quantity' in data:
            investment.Quantity = data['quantity']               # Update quantity held
        if 'notes' in data:
            investment.Notes = data['notes']                    # Update notes
        if 'assetName' in data:
            investment.AssetName = data['assetName']            # Update asset name

        investment.LastUpdated = datetime.utcnow()   # Record when this update happened
        db.session.commit()

        return jsonify({
            'message': 'Investment updated successfully',
            'investment': investment.to_dict()
        }), 200

    except Exception as e:
        logger.error(str(e))
        db.session.rollback()
        return jsonify({'error': 'Failed to update investment'}), 500


# ==============================================================================
# ROUTE: DELETE /api/investments/<investment_id>
# ==============================================================================
# Called when the user deletes an investment from their portfolio.
# ==============================================================================
@investments_bp.route('/<int:investment_id>', methods=['DELETE'])
def delete_investment(investment_id):
    """Delete an investment"""
    try:
        investment = Investment.query.get(investment_id)

        if not investment:
            return jsonify({'error': 'Investment not found'}), 404

        db.session.delete(investment)
        db.session.commit()

        return jsonify({'message': 'Investment deleted successfully'}), 200

    except Exception as e:
        logger.error(str(e))
        db.session.rollback()
        return jsonify({'error': 'Failed to delete investment'}), 500


# ==============================================================================
# ROUTE: GET /api/investments/user/<user_id>/portfolio
# ==============================================================================
# Called to get a comprehensive portfolio summary.
# This calculates total invested, current value, profit/loss for each investment,
# groups them by asset type, and identifies top/bottom performers.
#
# This is the most complex endpoint in investments - it performs multiple
# calculations to give the user a complete overview of their portfolio.
# ==============================================================================
@investments_bp.route('/user/<int:user_id>/portfolio', methods=['GET'])
def get_portfolio_summary(user_id):
    """Get portfolio summary with profit/loss calculations"""
    try:
        # --- Step 1: Get all investments for this user ---
        investments = Investment.query.filter_by(UserId=user_id).all()

        # If user has no investments, return empty portfolio
        if not investments:
            return jsonify({
                'totalInvested': 0.0,
                'currentValue': 0.0,
                'totalProfitLoss': 0.0,
                'percentageChange': 0.0,
                'assetBreakdown': [],
                'topPerformers': [],
                'bottomPerformers': [],
                'totalAssets': 0          # Must match the non-empty response shape so fromJson doesn't crash
            }), 200

        # --- Step 2: Calculate totals for each investment ---
        total_invested = 0.0           # Total money put in (purchase price * quantity)
        current_value = 0.0            # Total current value (current price * quantity)
        asset_breakdown = {}           # Group by asset type (stocks, crypto, etc.)
        all_investments_data = []      # Store calculated data for ranking later

        for inv in investments:
            # Calculate values for this investment
            purchase_value = float(inv.Quantity) * float(inv.PurchasePrice)   # What you paid
            current_price = float(inv.CurrentPrice) if inv.CurrentPrice else float(inv.PurchasePrice)
            current_val = float(inv.Quantity) * current_price                 # What it's worth now
            profit_loss = current_val - purchase_value                         # Gain or loss
            # Percentage change: how much the value has changed as a percentage
            percentage_change = ((current_val - purchase_value) / purchase_value * 100) if purchase_value > 0 else 0.0

            # Add to running totals
            total_invested += purchase_value
            current_value += current_val

            # --- Step 3: Group by asset type ---
            # Creates/updates a summary for each asset type (stocks, crypto, etc.)
            if inv.AssetsType not in asset_breakdown:
                asset_breakdown[inv.AssetsType] = {
                    'type': inv.AssetsType,
                    'invested': 0.0,
                    'currentValue': 0.0,
                    'profitLoss': 0.0,
                    'count': 0
                }

            asset_breakdown[inv.AssetsType]['invested'] += purchase_value
            asset_breakdown[inv.AssetsType]['currentValue'] += current_val
            asset_breakdown[inv.AssetsType]['profitLoss'] += profit_loss
            asset_breakdown[inv.AssetsType]['count'] += 1

            # Store data for ranking top/bottom performers
            all_investments_data.append({
                'investmentId': inv.InvestmentId,
                'assetName': inv.AssetName,
                'assetsType': inv.AssetsType,
                'profitLoss': profit_loss,
                'percentageChange': percentage_change,
                'currentValue': current_val
            })

        # --- Step 4: Calculate overall metrics ---
        total_profit_loss = current_value - total_invested
        overall_percentage_change = ((current_value - total_invested) / total_invested * 100) if total_invested > 0 else 0.0

        # --- Step 5: Add percentage change to each asset type ---
        for asset_type in asset_breakdown:
            asset_breakdown[asset_type]['percentageChange'] = (
                (asset_breakdown[asset_type]['profitLoss'] / asset_breakdown[asset_type]['invested'] * 100)
                if asset_breakdown[asset_type]['invested'] > 0 else 0.0
            )

        # --- Step 6: Identify top and bottom performers ---
        # Sort by percentage change (highest first)
        sorted_by_performance = sorted(all_investments_data, key=lambda x: x['percentageChange'], reverse=True)
        top_performers = sorted_by_performance[:3]        # Best 3 investments
        bottom_performers = sorted_by_performance[-3:] if len(sorted_by_performance) > 3 else []  # Worst 3

        # --- Step 7: Return the portfolio summary ---
        return jsonify({
            'totalInvested': round(total_invested, 2),                # Total money put in
            'currentValue': round(current_value, 2),                  # Total current worth
            'totalProfitLoss': round(total_profit_loss, 2),           # Total gain/loss
            'percentageChange': round(overall_percentage_change, 2),  # Overall % change
            'assetBreakdown': list(asset_breakdown.values()),         # Breakdown by type
            'topPerformers': top_performers,                          # Best performing investments
            'bottomPerformers': bottom_performers,                    # Worst performing investments
            'totalAssets': len(investments)                            # Total number of investments
        }), 200

    except Exception as e:
        logger.error(str(e))
        return jsonify({'error': 'Failed to fetch portfolio summary'}), 500


# ==============================================================================
# ROUTE: POST /api/investments/<investment_id>/update-price
# ==============================================================================
# Called for a quick price update on a single investment.
# Returns the updated investment along with profit/loss calculations.
# ==============================================================================
@investments_bp.route('/<int:investment_id>/update-price', methods=['POST'])
def update_investment_price(investment_id):
    """Quick update for just the current price"""
    try:
        investment = Investment.query.get(investment_id)

        if not investment:
            return jsonify({'error': 'Investment not found'}), 404

        data = request.get_json()
        if not data:
            return jsonify({'error': 'Request body is required'}), 400

        if 'currentPrice' not in data:
            return jsonify({'error': 'currentPrice is required'}), 400

        # --- Update the price ---
        investment.CurrentPrice = data['currentPrice']
        investment.LastUpdated = datetime.utcnow()
        db.session.commit()

        # --- Calculate profit/loss for the response ---
        purchase_value = float(investment.Quantity) * float(investment.PurchasePrice)
        current_value = float(investment.Quantity) * float(investment.CurrentPrice)
        profit_loss = current_value - purchase_value
        percentage_change = ((current_value - purchase_value) / purchase_value * 100) if purchase_value > 0 else 0.0

        return jsonify({
            'message': 'Price updated successfully',
            'investment': investment.to_dict(),
            'profitLoss': round(profit_loss, 2),
            'percentageChange': round(percentage_change, 2)
        }), 200

    except Exception as e:
        logger.error(str(e))
        db.session.rollback()
        return jsonify({'error': 'Failed to update investment price'}), 500

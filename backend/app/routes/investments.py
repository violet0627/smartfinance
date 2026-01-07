from flask import Blueprint, request, jsonify
from app import db
from app.models.investment import Investment
from datetime import datetime
from sqlalchemy import func

investments_bp = Blueprint('investments', __name__)

@investments_bp.route('/', methods=['POST'])
def create_investment():
    """Create a new investment entry"""
    try:
        data = request.get_json()

        # Validate required fields
        required_fields = ['assetName', 'assetsType', 'quantity', 'purchasePrice', 'purchaseDate', 'userId']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'{field} is required'}), 400

        # Parse purchase date
        try:
            purchase_date = datetime.strptime(data['purchaseDate'], '%Y-%m-%d').date()
        except ValueError:
            return jsonify({'error': 'Invalid date format. Use YYYY-MM-DD'}), 400

        # Create new investment
        new_investment = Investment(
            AssetName=data['assetName'],
            AssetsType=data['assetsType'],
            StockSymbol=data.get('stockSymbol'),
            Quantity=data['quantity'],
            PurchasePrice=data['purchasePrice'],
            PurchaseDate=purchase_date,
            CurrentPrice=data.get('currentPrice', data['purchasePrice']),  # Default to purchase price
            Notes=data.get('notes'),
            UserId=data['userId']
        )

        db.session.add(new_investment)
        db.session.commit()

        return jsonify({
            'message': 'Investment created successfully',
            'investment': new_investment.to_dict()
        }), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@investments_bp.route('/user/<int:user_id>', methods=['GET'])
def get_user_investments(user_id):
    """Get all investments for a user with optional filtering"""
    try:
        query = Investment.query.filter_by(UserId=user_id)

        # Filter by asset type if provided
        asset_type = request.args.get('type')
        if asset_type:
            query = query.filter_by(AssetsType=asset_type)

        # Order by purchase date (newest first)
        investments = query.order_by(Investment.PurchaseDate.desc()).all()

        return jsonify({
            'investments': [inv.to_dict() for inv in investments],
            'count': len(investments)
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@investments_bp.route('/<int:investment_id>', methods=['GET'])
def get_investment(investment_id):
    """Get a specific investment by ID"""
    try:
        investment = Investment.query.get(investment_id)

        if not investment:
            return jsonify({'error': 'Investment not found'}), 404

        return jsonify({'investment': investment.to_dict()}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@investments_bp.route('/<int:investment_id>', methods=['PUT'])
def update_investment(investment_id):
    """Update an investment (mainly for updating current price)"""
    try:
        investment = Investment.query.get(investment_id)

        if not investment:
            return jsonify({'error': 'Investment not found'}), 404

        data = request.get_json()

        # Update allowed fields
        if 'currentPrice' in data:
            investment.CurrentPrice = data['currentPrice']
        if 'quantity' in data:
            investment.Quantity = data['quantity']
        if 'notes' in data:
            investment.Notes = data['notes']
        if 'assetName' in data:
            investment.AssetName = data['assetName']

        investment.LastUpdated = datetime.utcnow()
        db.session.commit()

        return jsonify({
            'message': 'Investment updated successfully',
            'investment': investment.to_dict()
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

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
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@investments_bp.route('/user/<int:user_id>/portfolio', methods=['GET'])
def get_portfolio_summary(user_id):
    """Get portfolio summary with profit/loss calculations"""
    try:
        investments = Investment.query.filter_by(UserId=user_id).all()

        if not investments:
            return jsonify({
                'totalInvested': 0.0,
                'currentValue': 0.0,
                'totalProfitLoss': 0.0,
                'percentageChange': 0.0,
                'assetBreakdown': [],
                'topPerformers': [],
                'bottomPerformers': []
            }), 200

        total_invested = 0.0
        current_value = 0.0
        asset_breakdown = {}
        all_investments_data = []

        for inv in investments:
            purchase_value = float(inv.Quantity) * float(inv.PurchasePrice)
            current_price = float(inv.CurrentPrice) if inv.CurrentPrice else float(inv.PurchasePrice)
            current_val = float(inv.Quantity) * current_price
            profit_loss = current_val - purchase_value
            percentage_change = ((current_val - purchase_value) / purchase_value * 100) if purchase_value > 0 else 0.0

            total_invested += purchase_value
            current_value += current_val

            # Asset type breakdown
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

            # Store for ranking
            all_investments_data.append({
                'investmentId': inv.InvestmentId,
                'assetName': inv.AssetName,
                'assetsType': inv.AssetsType,
                'profitLoss': profit_loss,
                'percentageChange': percentage_change,
                'currentValue': current_val
            })

        # Calculate overall metrics
        total_profit_loss = current_value - total_invested
        overall_percentage_change = ((current_value - total_invested) / total_invested * 100) if total_invested > 0 else 0.0

        # Add percentage to asset breakdown
        for asset_type in asset_breakdown:
            asset_breakdown[asset_type]['percentageChange'] = (
                (asset_breakdown[asset_type]['profitLoss'] / asset_breakdown[asset_type]['invested'] * 100)
                if asset_breakdown[asset_type]['invested'] > 0 else 0.0
            )

        # Sort investments by performance
        sorted_by_performance = sorted(all_investments_data, key=lambda x: x['percentageChange'], reverse=True)
        top_performers = sorted_by_performance[:3]
        bottom_performers = sorted_by_performance[-3:] if len(sorted_by_performance) > 3 else []

        return jsonify({
            'totalInvested': round(total_invested, 2),
            'currentValue': round(current_value, 2),
            'totalProfitLoss': round(total_profit_loss, 2),
            'percentageChange': round(overall_percentage_change, 2),
            'assetBreakdown': list(asset_breakdown.values()),
            'topPerformers': top_performers,
            'bottomPerformers': bottom_performers,
            'totalAssets': len(investments)
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@investments_bp.route('/<int:investment_id>/update-price', methods=['POST'])
def update_investment_price(investment_id):
    """Quick update for just the current price"""
    try:
        investment = Investment.query.get(investment_id)

        if not investment:
            return jsonify({'error': 'Investment not found'}), 404

        data = request.get_json()

        if 'currentPrice' not in data:
            return jsonify({'error': 'currentPrice is required'}), 400

        investment.CurrentPrice = data['currentPrice']
        investment.LastUpdated = datetime.utcnow()
        db.session.commit()

        # Calculate profit/loss for response
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
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

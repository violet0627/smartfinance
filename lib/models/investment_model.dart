// ==============================================================================
// investment_model.dart - Investment Data Models
// ==============================================================================
// This file defines FOUR related models for the investment portfolio feature:
//
// 1. InvestmentModel - A single investment (e.g., "100 shares of Maybank at RM9.50")
// 2. PortfolioSummary - Overall portfolio overview (total invested, current value, P/L)
// 3. AssetBreakdown - Performance grouped by asset type (stocks, crypto, etc.)
// 4. InvestmentPerformance - Individual investment ranking data (top/bottom performers)
// ==============================================================================

// ==============================================================================
// InvestmentModel - Represents a Single Investment
// ==============================================================================
// Tracks an individual investment holding with purchase info and current value.
// Example: 100 shares of Maybank bought at RM9.50, now worth RM10.20
// ==============================================================================
class InvestmentModel {
  final int? investmentId;       // Unique ID (null for new investments)
  final String assetName;        // Name of the asset (e.g., "Maybank", "Bitcoin")
  final String assetsType;       // Type of asset (e.g., "stocks", "crypto", "mutual_funds")
  final String? stockSymbol;     // Optional stock ticker symbol (e.g., "MAYBANK", "BTC")
  final double quantity;         // Number of units held (e.g., 100 shares, 0.5 BTC)
  final double purchasePrice;    // Price per unit when purchased
  final DateTime purchaseDate;   // When the investment was made
  final double? currentPrice;    // Current market price per unit (may be null if not updated)
  final DateTime? lastUpdated;   // When the price was last updated
  final String? notes;           // Optional notes about this investment
  final int userId;              // Which user owns this investment

  // --- Constructor ---
  InvestmentModel({
    this.investmentId,
    required this.assetName,
    required this.assetsType,
    this.stockSymbol,
    required this.quantity,
    required this.purchasePrice,
    required this.purchaseDate,
    this.currentPrice,
    this.lastUpdated,
    this.notes,
    required this.userId,
  });

  // --- fromJson ---
  factory InvestmentModel.fromJson(Map<String, dynamic> json) {
    return InvestmentModel(
      investmentId: json['investmentId'],
      assetName: json['assetName'],
      assetsType: json['assetsType'],
      stockSymbol: json['stockSymbol'],
      quantity: (json['quantity'] as num).toDouble(),
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate']),
      currentPrice: json['currentPrice'] != null
          ? (json['currentPrice'] as num).toDouble()
          : null,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
      notes: json['notes'],
      userId: json['userId'],
    );
  }

  // --- toJson ---
  // .split('T')[0] extracts just the date part "YYYY-MM-DD" from the full ISO string
  Map<String, dynamic> toJson() {
    return {
      if (investmentId != null) 'investmentId': investmentId,
      'assetName': assetName,
      'assetsType': assetsType,
      if (stockSymbol != null) 'stockSymbol': stockSymbol,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'purchaseDate': purchaseDate.toIso8601String().split('T')[0],  // YYYY-MM-DD format
      if (currentPrice != null) 'currentPrice': currentPrice,
      if (notes != null) 'notes': notes,
      'userId': userId,
    };
  }

  // --- Computed Properties for Investment Performance ---

  // Total amount originally invested (quantity * purchase price)
  // The => arrow syntax is shorthand for { return quantity * purchasePrice; }
  double get purchaseValue => quantity * purchasePrice;

  // Total current market value (quantity * current price)
  // Uses purchase price as fallback if current price hasn't been set
  double get currentValue {
    final price = currentPrice ?? purchasePrice;   // ?? = use purchasePrice if currentPrice is null
    return quantity * price;
  }

  // Profit or loss amount (positive = profit, negative = loss)
  double get profitLoss => currentValue - purchaseValue;

  // Profit/loss as a percentage (e.g., +5.2% or -3.1%)
  double get percentageChange {
    if (purchaseValue == 0) return 0.0;   // Avoid division by zero
    return (profitLoss / purchaseValue) * 100;
  }

  // Quick boolean checks
  bool get isProfit => profitLoss > 0;    // True if making money
  bool get isLoss => profitLoss < 0;      // True if losing money

  // How many days the investment has been held
  int get daysHeld {
    return DateTime.now().difference(purchaseDate).inDays;
  }
}

// ==============================================================================
// PortfolioSummary - Overall Portfolio Overview
// ==============================================================================
// Contains aggregated data about the user's entire investment portfolio.
// Returned by the /api/investments/user/<id>/portfolio endpoint.
// ==============================================================================
class PortfolioSummary {
  final double totalInvested;                           // Total money put into all investments
  final double currentValue;                            // Total current market value
  final double totalProfitLoss;                         // Overall profit/loss
  final double percentageChange;                        // Overall percentage change
  final List<AssetBreakdown> assetBreakdown;            // Breakdown by asset type
  final List<InvestmentPerformance> topPerformers;      // Best performing investments
  final List<InvestmentPerformance> bottomPerformers;   // Worst performing investments
  final int totalAssets;                                // Total number of investments

  PortfolioSummary({
    required this.totalInvested,
    required this.currentValue,
    required this.totalProfitLoss,
    required this.percentageChange,
    required this.assetBreakdown,
    required this.topPerformers,
    required this.bottomPerformers,
    required this.totalAssets,
  });

  // --- fromJson ---
  // Parses nested lists of AssetBreakdown and InvestmentPerformance objects
  factory PortfolioSummary.fromJson(Map<String, dynamic> json) {
    return PortfolioSummary(
      totalInvested: (json['totalInvested'] as num).toDouble(),
      currentValue: (json['currentValue'] as num).toDouble(),
      totalProfitLoss: (json['totalProfitLoss'] as num).toDouble(),
      percentageChange: (json['percentageChange'] as num).toDouble(),
      assetBreakdown: (json['assetBreakdown'] as List)        // Parse list of asset breakdowns
          .map((item) => AssetBreakdown.fromJson(item))
          .toList(),
      topPerformers: (json['topPerformers'] as List)          // Parse list of top performers
          .map((item) => InvestmentPerformance.fromJson(item))
          .toList(),
      bottomPerformers: (json['bottomPerformers'] as List)    // Parse list of bottom performers
          .map((item) => InvestmentPerformance.fromJson(item))
          .toList(),
      totalAssets: json['totalAssets'],
    );
  }

  bool get isProfit => totalProfitLoss > 0;   // True if portfolio is profitable overall
  bool get isEmpty => totalAssets == 0;        // True if user has no investments
}

// ==============================================================================
// AssetBreakdown - Performance by Asset Type
// ==============================================================================
// Groups investments by type (stocks, crypto, etc.) with totals for each group.
// Used to show pie charts and asset allocation in the portfolio screen.
// ==============================================================================
class AssetBreakdown {
  final String type;               // Asset type (e.g., "stocks", "crypto")
  final double invested;           // Total invested in this type
  final double currentValue;       // Total current value of this type
  final double profitLoss;         // Profit/loss for this type
  final double percentageChange;   // Percentage change for this type
  final int count;                 // Number of investments of this type

  AssetBreakdown({
    required this.type,
    required this.invested,
    required this.currentValue,
    required this.profitLoss,
    required this.percentageChange,
    required this.count,
  });

  factory AssetBreakdown.fromJson(Map<String, dynamic> json) {
    return AssetBreakdown(
      type: json['type'],
      invested: (json['invested'] as num).toDouble(),
      currentValue: (json['currentValue'] as num).toDouble(),
      profitLoss: (json['profitLoss'] as num).toDouble(),
      percentageChange: (json['percentageChange'] as num).toDouble(),
      count: json['count'],
    );
  }

  bool get isProfit => profitLoss > 0;
}

// ==============================================================================
// InvestmentPerformance - Individual Investment Ranking Data
// ==============================================================================
// Used for the "Top Performers" and "Bottom Performers" lists.
// Contains just the essential data needed for ranking display.
// ==============================================================================
class InvestmentPerformance {
  final int investmentId;          // Which investment this is
  final String assetName;          // Name of the asset
  final String assetsType;         // Type of asset
  final double profitLoss;         // Profit/loss amount
  final double percentageChange;   // Percentage change
  final double currentValue;       // Current market value

  InvestmentPerformance({
    required this.investmentId,
    required this.assetName,
    required this.assetsType,
    required this.profitLoss,
    required this.percentageChange,
    required this.currentValue,
  });

  factory InvestmentPerformance.fromJson(Map<String, dynamic> json) {
    return InvestmentPerformance(
      investmentId: json['investmentId'],
      assetName: json['assetName'],
      assetsType: json['assetsType'],
      profitLoss: (json['profitLoss'] as num).toDouble(),
      percentageChange: (json['percentageChange'] as num).toDouble(),
      currentValue: (json['currentValue'] as num).toDouble(),
    );
  }

  bool get isProfit => profitLoss > 0;
}

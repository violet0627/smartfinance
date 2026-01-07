class InvestmentModel {
  final int? investmentId;
  final String assetName;
  final String assetsType;
  final String? stockSymbol;
  final double quantity;
  final double purchasePrice;
  final DateTime purchaseDate;
  final double? currentPrice;
  final DateTime? lastUpdated;
  final String? notes;
  final int userId;

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

  Map<String, dynamic> toJson() {
    return {
      if (investmentId != null) 'investmentId': investmentId,
      'assetName': assetName,
      'assetsType': assetsType,
      if (stockSymbol != null) 'stockSymbol': stockSymbol,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'purchaseDate': purchaseDate.toIso8601String().split('T')[0], // YYYY-MM-DD
      if (currentPrice != null) 'currentPrice': currentPrice,
      if (notes != null) 'notes': notes,
      'userId': userId,
    };
  }

  // Computed properties for investment performance
  double get purchaseValue => quantity * purchasePrice;

  double get currentValue {
    final price = currentPrice ?? purchasePrice;
    return quantity * price;
  }

  double get profitLoss => currentValue - purchaseValue;

  double get percentageChange {
    if (purchaseValue == 0) return 0.0;
    return (profitLoss / purchaseValue) * 100;
  }

  bool get isProfit => profitLoss > 0;

  bool get isLoss => profitLoss < 0;

  int get daysHeld {
    return DateTime.now().difference(purchaseDate).inDays;
  }
}

class PortfolioSummary {
  final double totalInvested;
  final double currentValue;
  final double totalProfitLoss;
  final double percentageChange;
  final List<AssetBreakdown> assetBreakdown;
  final List<InvestmentPerformance> topPerformers;
  final List<InvestmentPerformance> bottomPerformers;
  final int totalAssets;

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

  factory PortfolioSummary.fromJson(Map<String, dynamic> json) {
    return PortfolioSummary(
      totalInvested: (json['totalInvested'] as num).toDouble(),
      currentValue: (json['currentValue'] as num).toDouble(),
      totalProfitLoss: (json['totalProfitLoss'] as num).toDouble(),
      percentageChange: (json['percentageChange'] as num).toDouble(),
      assetBreakdown: (json['assetBreakdown'] as List)
          .map((item) => AssetBreakdown.fromJson(item))
          .toList(),
      topPerformers: (json['topPerformers'] as List)
          .map((item) => InvestmentPerformance.fromJson(item))
          .toList(),
      bottomPerformers: (json['bottomPerformers'] as List)
          .map((item) => InvestmentPerformance.fromJson(item))
          .toList(),
      totalAssets: json['totalAssets'],
    );
  }

  bool get isProfit => totalProfitLoss > 0;
  bool get isEmpty => totalAssets == 0;
}

class AssetBreakdown {
  final String type;
  final double invested;
  final double currentValue;
  final double profitLoss;
  final double percentageChange;
  final int count;

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

class InvestmentPerformance {
  final int investmentId;
  final String assetName;
  final String assetsType;
  final double profitLoss;
  final double percentageChange;
  final double currentValue;

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

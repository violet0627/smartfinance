import 'package:flutter/material.dart';

class InvestmentTypes {
  static const Map<String, AssetTypeInfo> assetTypes = {
    'Stocks': AssetTypeInfo(
      icon: Icons.trending_up,
      color: Color(0xFF2196F3),
      description: 'Company shares and equities',
    ),
    'Cryptocurrency': AssetTypeInfo(
      icon: Icons.currency_bitcoin,
      color: Color(0xFFF7931A),
      description: 'Digital currencies like Bitcoin, Ethereum',
    ),
    'Bonds': AssetTypeInfo(
      icon: Icons.account_balance,
      color: Color(0xFF4CAF50),
      description: 'Government and corporate bonds',
    ),
    'Mutual Funds': AssetTypeInfo(
      icon: Icons.pie_chart,
      color: Color(0xFF9C27B0),
      description: 'Professionally managed investment funds',
    ),
    'ETF': AssetTypeInfo(
      icon: Icons.insert_chart,
      color: Color(0xFF00BCD4),
      description: 'Exchange-traded funds',
    ),
    'Real Estate': AssetTypeInfo(
      icon: Icons.home,
      color: Color(0xFFFF5722),
      description: 'Property investments',
    ),
    'Commodities': AssetTypeInfo(
      icon: Icons.diamond,
      color: Color(0xFFFFEB3B),
      description: 'Gold, silver, oil, etc.',
    ),
    'Fixed Deposit': AssetTypeInfo(
      icon: Icons.savings,
      color: Color(0xFF8BC34A),
      description: 'Fixed deposit accounts',
    ),
    'Unit Trust': AssetTypeInfo(
      icon: Icons.folder_shared,
      color: Color(0xFF673AB7),
      description: 'Malaysian unit trust funds',
    ),
    'Other': AssetTypeInfo(
      icon: Icons.more_horiz,
      color: Color(0xFF9E9E9E),
      description: 'Other investment types',
    ),
  };

  static AssetTypeInfo getAssetTypeInfo(String assetType) {
    return assetTypes[assetType] ?? assetTypes['Other']!;
  }

  static List<String> get allTypes => assetTypes.keys.toList();

  static Color getColorForPerformance(double percentageChange) {
    if (percentageChange > 0) {
      return const Color(0xFF4CAF50); // Green for profit
    } else if (percentageChange < 0) {
      return const Color(0xFFE53935); // Red for loss
    } else {
      return const Color(0xFF9E9E9E); // Grey for no change
    }
  }

  static IconData getIconForPerformance(double percentageChange) {
    if (percentageChange > 0) {
      return Icons.trending_up;
    } else if (percentageChange < 0) {
      return Icons.trending_down;
    } else {
      return Icons.trending_flat;
    }
  }
}

class AssetTypeInfo {
  final IconData icon;
  final Color color;
  final String description;

  const AssetTypeInfo({
    required this.icon,
    required this.color,
    required this.description,
  });
}

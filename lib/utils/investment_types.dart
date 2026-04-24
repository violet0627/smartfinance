// ==============================================================================
// investment_types.dart - Investment Asset Type Definitions
// ==============================================================================
// This file defines all the available investment asset types for the portfolio
// feature. Each asset type has an icon, color, and description.
//
// Supported asset types:
// - Stocks: Company shares and equities
// - Cryptocurrency: Bitcoin, Ethereum, etc.
// - Bonds: Government and corporate bonds
// - Mutual Funds: Professionally managed funds
// - ETF: Exchange-traded funds
// - Real Estate: Property investments
// - Commodities: Gold, silver, oil, etc.
// - Fixed Deposit: Bank fixed deposit accounts
// - Unit Trust: Malaysian unit trust funds (specific to Malaysian market)
// - Other: Catch-all for unlisted types
//
// Also provides helper methods for performance-based colors and icons
// (green for profit, red for loss, grey for no change).
//
// Usage: InvestmentTypes.getAssetTypeInfo('Stocks')
//        InvestmentTypes.getColorForPerformance(5.2)
// ==============================================================================

import 'package:flutter/material.dart';   // For IconData, Color, Icons

class InvestmentTypes {
  // ==============================================================================
  // Asset Types Map
  // ==============================================================================
  // Maps asset type names to their visual properties (icon, color, description).
  // "const" means this map is created at compile time and never changes.
  //
  // Each type has a unique color to distinguish it in pie charts and lists.
  // ==============================================================================
  static const Map<String, AssetTypeInfo> assetTypes = {
    'Stocks': AssetTypeInfo(
      icon: Icons.trending_up,              // Upward trend icon
      color: Color(0xFF2196F3),             // Blue
      description: 'Company shares and equities',
    ),
    'Cryptocurrency': AssetTypeInfo(
      icon: Icons.currency_bitcoin,         // Bitcoin icon
      color: Color(0xFFF7931A),             // Bitcoin orange
      description: 'Digital currencies like Bitcoin, Ethereum',
    ),
    'Bonds': AssetTypeInfo(
      icon: Icons.account_balance,          // Bank/institution icon
      color: Color(0xFF4CAF50),             // Green
      description: 'Government and corporate bonds',
    ),
    'Mutual Funds': AssetTypeInfo(
      icon: Icons.pie_chart,                // Pie chart icon (diversified)
      color: Color(0xFF9C27B0),             // Purple
      description: 'Professionally managed investment funds',
    ),
    'ETF': AssetTypeInfo(
      icon: Icons.insert_chart,             // Bar chart icon
      color: Color(0xFF00BCD4),             // Cyan
      description: 'Exchange-traded funds',
    ),
    'Real Estate': AssetTypeInfo(
      icon: Icons.home,                     // House icon
      color: Color(0xFFFF5722),             // Deep orange
      description: 'Property investments',
    ),
    'Commodities': AssetTypeInfo(
      icon: Icons.diamond,                  // Diamond icon (precious materials)
      color: Color(0xFFFFEB3B),             // Yellow/gold
      description: 'Gold, silver, oil, etc.',
    ),
    'Fixed Deposit': AssetTypeInfo(
      icon: Icons.savings,                  // Piggy bank icon
      color: Color(0xFF8BC34A),             // Light green
      description: 'Fixed deposit accounts',
    ),
    'Unit Trust': AssetTypeInfo(
      icon: Icons.folder_shared,            // Shared folder icon
      color: Color(0xFF673AB7),             // Deep purple
      description: 'Malaysian unit trust funds',
    ),
    'Other': AssetTypeInfo(
      icon: Icons.more_horiz,               // Three dots icon (miscellaneous)
      color: Color(0xFF9E9E9E),             // Grey
      description: 'Other investment types',
    ),
  };

  // ==============================================================================
  // getAssetTypeInfo - Look Up an Asset Type's Properties
  // ==============================================================================
  // Given an asset type name, returns its icon, color, and description.
  // Falls back to "Other" if the type name isn't found in the map.
  //
  // ?? means: if lookup returns null, use this fallback
  // ! after ['Other'] asserts the key definitely exists (it does - defined above)
  // ==============================================================================
  static AssetTypeInfo getAssetTypeInfo(String assetType) {
    return assetTypes[assetType] ?? assetTypes['Other']!;
  }

  // ==============================================================================
  // allTypes - Get List of All Asset Type Names
  // ==============================================================================
  // Returns all asset type names as a list.
  // Used to populate dropdown menus when adding/editing investments.
  //
  // "get" keyword makes this a getter property (called without parentheses):
  // Usage: InvestmentTypes.allTypes (not InvestmentTypes.allTypes())
  // ==============================================================================
  static List<String> get allTypes => assetTypes.keys.toList();

  // ==============================================================================
  // getColorForPerformance - Get Color Based on Profit/Loss
  // ==============================================================================
  // Returns a color based on the percentage change:
  // - Positive (profit): Green
  // - Negative (loss): Red
  // - Zero (no change): Grey
  //
  // Used to color profit/loss text and indicators throughout the portfolio UI.
  // ==============================================================================
  static Color getColorForPerformance(double percentageChange) {
    if (percentageChange > 0) {
      return const Color(0xFF4CAF50); // Green for profit
    } else if (percentageChange < 0) {
      return const Color(0xFFE53935); // Red for loss
    } else {
      return const Color(0xFF9E9E9E); // Grey for no change
    }
  }

  // ==============================================================================
  // getIconForPerformance - Get Icon Based on Profit/Loss
  // ==============================================================================
  // Returns a trend icon based on the percentage change:
  // - Positive: Upward trend arrow (trending_up)
  // - Negative: Downward trend arrow (trending_down)
  // - Zero: Flat line (trending_flat)
  //
  // Used alongside getColorForPerformance for visual profit/loss indicators.
  // ==============================================================================
  static IconData getIconForPerformance(double percentageChange) {
    if (percentageChange > 0) {
      return Icons.trending_up;       // Arrow pointing up-right
    } else if (percentageChange < 0) {
      return Icons.trending_down;     // Arrow pointing down-right
    } else {
      return Icons.trending_flat;     // Horizontal line
    }
  }
}

// ==============================================================================
// AssetTypeInfo - Holds Icon, Color, and Description for an Asset Type
// ==============================================================================
// Simple data class that bundles the visual properties of an asset type.
// "const" constructor allows AssetTypeInfo to be used in const Maps.
// ==============================================================================
class AssetTypeInfo {
  final IconData icon;          // Material icon for this asset type
  final Color color;            // Color for charts and UI elements
  final String description;     // Human-readable description

  const AssetTypeInfo({
    required this.icon,
    required this.color,
    required this.description,
  });
}

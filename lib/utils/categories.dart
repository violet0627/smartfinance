// ==============================================================================
// categories.dart - Transaction Category Definitions
// ==============================================================================
// This file defines all the available transaction categories for the app.
// Each category has an icon and a color, used throughout the UI for:
// - Category selection dropdowns when adding/editing transactions
// - Category labels in transaction lists
// - Category-based pie charts and breakdowns
//
// There are TWO separate category sets:
// 1. Expense categories (11 categories): Food, Transport, Shopping, etc.
// 2. Income categories (7 categories): Salary, Business, Investments, etc.
//
// Usage: TransactionCategories.getCategoryInfo('Food & Dining', 'expense')
//        TransactionCategories.getCategories('expense')
// ==============================================================================

import 'package:flutter/material.dart';   // For IconData, Color, Icons

// ==============================================================================
// TransactionCategories - Category Lookup and Management
// ==============================================================================
class TransactionCategories {

  // ==============================================================================
  // Expense Categories
  // ==============================================================================
  // Map<String, CategoryInfo> maps category names to their visual properties.
  // "const" means this map is created at compile time and never changes.
  //
  // Color format: Color(0xFFRRGGBB) where RR=red, GG=green, BB=blue
  // Each color is chosen to be visually distinct for charts and icons.
  // ==============================================================================
  static const Map<String, CategoryInfo> expenseCategories = {
    'Food & Dining': CategoryInfo(
      icon: Icons.restaurant,              // Restaurant/fork-and-knife icon
      color: Color(0xFFFF6B6B),            // Coral red
    ),
    'Transportation': CategoryInfo(
      icon: Icons.directions_car,          // Car icon
      color: Color(0xFF4ECDC4),            // Teal
    ),
    'Shopping': CategoryInfo(
      icon: Icons.shopping_bag,            // Shopping bag icon
      color: Color(0xFFFFBE0B),            // Amber/gold
    ),
    'Entertainment': CategoryInfo(
      icon: Icons.movie,                   // Movie/film icon
      color: Color(0xFFB565D8),            // Purple
    ),
    'Bills & Utilities': CategoryInfo(
      icon: Icons.receipt_long,            // Receipt/bill icon
      color: Color(0xFF95E1D3),            // Mint green
    ),
    'Healthcare': CategoryInfo(
      icon: Icons.local_hospital,          // Hospital cross icon
      color: Color(0xFFFF8787),            // Light red/pink
    ),
    'Education': CategoryInfo(
      icon: Icons.school,                  // Graduation cap icon
      color: Color(0xFF38A3A5),            // Dark teal
    ),
    'Personal Care': CategoryInfo(
      icon: Icons.spa,                     // Spa/leaf icon
      color: Color(0xFFFCA5A5),            // Soft pink
    ),
    'Travel': CategoryInfo(
      icon: Icons.flight,                  // Airplane icon
      color: Color(0xFF3DDC97),            // Green
    ),
    'Gifts & Donations': CategoryInfo(
      icon: Icons.card_giftcard,           // Gift card icon
      color: Color(0xFFFD79A8),            // Pink
    ),
    'Others': CategoryInfo(
      icon: Icons.more_horiz,              // Three dots (ellipsis) icon
      color: Color(0xFF95A5A6),            // Grey (neutral for uncategorized)
    ),
  };

  // ==============================================================================
  // Income Categories
  // ==============================================================================
  // Income categories use green-ish colors to visually associate with "money in".
  // ==============================================================================
  static const Map<String, CategoryInfo> incomeCategories = {
    'Salary': CategoryInfo(
      icon: Icons.work,                    // Briefcase icon
      color: Color(0xFF27AE60),            // Green
    ),
    'Business': CategoryInfo(
      icon: Icons.business_center,         // Business briefcase icon
      color: Color(0xFF16A085),            // Dark teal
    ),
    'Investments': CategoryInfo(
      icon: Icons.trending_up,             // Upward trend icon
      color: Color(0xFF2ECC71),            // Emerald green
    ),
    'Freelance': CategoryInfo(
      icon: Icons.laptop_mac,              // Laptop icon
      color: Color(0xFF1ABC9C),            // Turquoise
    ),
    'Gifts': CategoryInfo(
      icon: Icons.redeem,                  // Gift/redeem icon
      color: Color(0xFF55EFC4),            // Light green
    ),
    'Allowance': CategoryInfo(
      icon: Icons.account_balance_wallet,  // Wallet icon
      color: Color(0xFF00B894),            // Mint green
    ),
    'Others': CategoryInfo(
      icon: Icons.more_horiz,              // Three dots icon
      color: Color(0xFF95A5A6),            // Grey
    ),
  };

  // ==============================================================================
  // getCategoryInfo - Look Up a Category's Icon and Color
  // ==============================================================================
  // Given a category name and type ("expense" or "income"), returns the
  // CategoryInfo with the icon and color.
  //
  // Falls back to "Others" if the category name isn't found.
  //
  // The ?? operator means: "If the lookup returns null, use this fallback"
  // The ! after 'Others' asserts that the 'Others' key definitely exists
  //
  // Example: getCategoryInfo('Food & Dining', 'expense')
  //          Returns: CategoryInfo(icon: restaurant, color: coral red)
  // ==============================================================================
  static CategoryInfo getCategoryInfo(String category, String type) {
    if (type == 'expense') {
      return expenseCategories[category] ?? expenseCategories['Others']!;
      // Try to find the category; if not found, return "Others" category
    } else {
      return incomeCategories[category] ?? incomeCategories['Others']!;
    }
  }

  // ==============================================================================
  // getCategories - Get List of Category Names
  // ==============================================================================
  // Returns a list of all category names for the given type.
  // Used to populate category selection dropdowns.
  //
  // .keys returns all the keys (category names) from the map
  // .toList() converts the Iterable to a List
  //
  // Example: getCategories('expense')
  //          Returns: ['Food & Dining', 'Transportation', 'Shopping', ...]
  // ==============================================================================
  static List<String> getCategories(String type) {
    if (type == 'expense') {
      return expenseCategories.keys.toList();
    } else {
      return incomeCategories.keys.toList();
    }
  }
}

// ==============================================================================
// CategoryInfo - Holds Icon and Color for a Category
// ==============================================================================
// Simple data class that pairs an icon with a color.
// "const" constructor allows CategoryInfo to be used in const Maps.
// ==============================================================================
class CategoryInfo {
  final IconData icon;    // The Material icon to display (e.g., Icons.restaurant)
  final Color color;      // The color for this category in charts and UI

  const CategoryInfo({
    required this.icon,
    required this.color,
  });
}

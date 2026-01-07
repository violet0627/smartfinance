import 'package:flutter/material.dart';

class TransactionCategories {
  static const Map<String, CategoryInfo> expenseCategories = {
    'Food & Dining': CategoryInfo(
      icon: Icons.restaurant,
      color: Color(0xFFFF6B6B),
    ),
    'Transportation': CategoryInfo(
      icon: Icons.directions_car,
      color: Color(0xFF4ECDC4),
    ),
    'Shopping': CategoryInfo(
      icon: Icons.shopping_bag,
      color: Color(0xFFFFBE0B),
    ),
    'Entertainment': CategoryInfo(
      icon: Icons.movie,
      color: Color(0xFFB565D8),
    ),
    'Bills & Utilities': CategoryInfo(
      icon: Icons.receipt_long,
      color: Color(0xFF95E1D3),
    ),
    'Healthcare': CategoryInfo(
      icon: Icons.local_hospital,
      color: Color(0xFFFF8787),
    ),
    'Education': CategoryInfo(
      icon: Icons.school,
      color: Color(0xFF38A3A5),
    ),
    'Personal Care': CategoryInfo(
      icon: Icons.spa,
      color: Color(0xFFFCA5A5),
    ),
    'Travel': CategoryInfo(
      icon: Icons.flight,
      color: Color(0xFF3DDC97),
    ),
    'Gifts & Donations': CategoryInfo(
      icon: Icons.card_giftcard,
      color: Color(0xFFFD79A8),
    ),
    'Others': CategoryInfo(
      icon: Icons.more_horiz,
      color: Color(0xFF95A5A6),
    ),
  };

  static const Map<String, CategoryInfo> incomeCategories = {
    'Salary': CategoryInfo(
      icon: Icons.work,
      color: Color(0xFF27AE60),
    ),
    'Business': CategoryInfo(
      icon: Icons.business_center,
      color: Color(0xFF16A085),
    ),
    'Investments': CategoryInfo(
      icon: Icons.trending_up,
      color: Color(0xFF2ECC71),
    ),
    'Freelance': CategoryInfo(
      icon: Icons.laptop_mac,
      color: Color(0xFF1ABC9C),
    ),
    'Gifts': CategoryInfo(
      icon: Icons.redeem,
      color: Color(0xFF55EFC4),
    ),
    'Allowance': CategoryInfo(
      icon: Icons.account_balance_wallet,
      color: Color(0xFF00B894),
    ),
    'Others': CategoryInfo(
      icon: Icons.more_horiz,
      color: Color(0xFF95A5A6),
    ),
  };

  static CategoryInfo getCategoryInfo(String category, String type) {
    if (type == 'expense') {
      return expenseCategories[category] ?? expenseCategories['Others']!;
    } else {
      return incomeCategories[category] ?? incomeCategories['Others']!;
    }
  }

  static List<String> getCategories(String type) {
    if (type == 'expense') {
      return expenseCategories.keys.toList();
    } else {
      return incomeCategories.keys.toList();
    }
  }
}

class CategoryInfo {
  final IconData icon;
  final Color color;

  const CategoryInfo({
    required this.icon,
    required this.color,
  });
}

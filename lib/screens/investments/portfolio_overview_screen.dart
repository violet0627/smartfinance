// portfolio_overview_screen.dart
// This screen shows the user's investment portfolio: total value, profit/loss,
// asset type breakdown, top performers, and a list of all individual investments.
// Users can filter by asset type, add new investments, update prices, and delete investments.
// Swiping left on an investment card deletes it (with confirmation dialog).

import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:intl/intl.dart'; // DateFormat for date formatting
import '../../models/investment_model.dart'; // InvestmentModel, PortfolioSummary, InvestmentPerformance
import '../../services/api_service.dart'; // Backend API calls
import '../../utils/colors.dart'; // AppColors constants
import '../../utils/investment_types.dart'; // InvestmentTypes utility (icons, colors, performance icons)
import 'add_investment_screen.dart'; // Screen for adding new investments

// PortfolioOverviewScreen shows all investment data for the current user
class PortfolioOverviewScreen extends StatefulWidget {
  const PortfolioOverviewScreen({super.key});

  @override
  State<PortfolioOverviewScreen> createState() => _PortfolioOverviewScreenState();
}

class _PortfolioOverviewScreenState extends State<PortfolioOverviewScreen> {
  List<InvestmentModel> _investments = []; // All individual investments
  PortfolioSummary? _portfolio;            // Aggregated portfolio statistics
  bool _isLoading = true;                  // True while fetching data
  String? _filterType;                     // null = all types; otherwise e.g. "Stocks"

  @override
  void initState() {
    super.initState();
    _loadPortfolio(); // Load data when screen opens
  }

  // _loadPortfolio fetches portfolio summary and individual investments
  // Both calls are made sequentially with separate try/catch so one failure doesn't stop the other
  Future<void> _loadPortfolio() async {
    setState(() => _isLoading = true);

    try {
      final userId = await ApiService.getCurrentUserId();
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Load portfolio summary (total value, profit/loss, asset breakdown)
      try {
        final portfolioResult = await ApiService.getPortfolioSummary(userId);
        if (portfolioResult['success'] && portfolioResult['portfolio'] != null) {
          setState(() {
            // PortfolioSummary.fromJson converts JSON to a typed model object
            _portfolio = PortfolioSummary.fromJson(portfolioResult['portfolio']);
          });
        }
      } catch (e) {
        debugPrint('Error loading portfolio summary: $e'); // Debug log; not shown to user
      }

      // Load individual investments, optionally filtered by asset type
      try {
        final investmentsResult = await ApiService.getUserInvestments(userId, type: _filterType);
        if (investmentsResult['success']) {
          final investmentsList = investmentsResult['investments'] as List;
          setState(() {
            // Convert each JSON map to an InvestmentModel object
            _investments = investmentsList
                .map((json) => InvestmentModel.fromJson(json))
                .toList();
          });
        }
      } catch (e) {
        debugPrint('Error loading investments: $e');
      }
    } catch (e) {
      debugPrint('Error in _loadPortfolio: $e');
    } finally {
      // 'finally' always runs - ensures loading stops even on error
      setState(() => _isLoading = false);
    }
  }

  // _deleteInvestment removes an investment from the portfolio
  Future<void> _deleteInvestment(int investmentId) async {
    final result = await ApiService.deleteInvestment(investmentId);

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Investment deleted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadPortfolio(); // Refresh to update totals
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to delete investment'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // _showUpdatePriceDialog shows a dialog to update the current market price of an investment
  // This recalculates the profit/loss based on the new price
  void _showUpdatePriceDialog(InvestmentModel investment) {
    // Pre-fill with current price (or purchase price if no current price is set)
    final priceController = TextEditingController(
      text: investment.currentPrice?.toString() ?? investment.purchasePrice.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update ${investment.assetName} Price'),
        content: TextField(
          controller: priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Current Price',
            prefixText: 'RM ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(priceController.text);
              if (price != null && investment.investmentId != null) {
                Navigator.pop(context); // Close dialog first
                final result = await ApiService.updateInvestmentPrice(
                  investment.investmentId!,
                  price,
                );
                if (result['success']) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Price updated successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  _loadPortfolio(); // Refresh to show new profit/loss
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Investment Portfolio'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Filter button - shows a dropdown with asset type options
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                // 'All' means no filter; otherwise store the type name
                _filterType = value == 'All' ? null : value;
              });
              _loadPortfolio(); // Reload with new filter
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Types')),
              // Dynamically generate menu items from InvestmentTypes.allTypes list
              ...InvestmentTypes.allTypes.map((type) =>
                  PopupMenuItem(value: type, child: Text(type))),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          // Show empty state if no portfolio data or portfolio is empty
          : _portfolio == null || _portfolio!.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadPortfolio,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPortfolioSummaryCard(), // Gradient card with total value
                        const SizedBox(height: 24),
                        _buildAssetBreakdown(),       // Per-type breakdown section
                        const SizedBox(height: 24),
                        // Top performers section (only shown when there are performers)
                        if (_portfolio!.topPerformers.isNotEmpty) ...[
                          _buildPerformersSection(
                            'Top Performers',
                            _portfolio!.topPerformers,
                            true,
                          ),
                          const SizedBox(height: 24),
                        ],
                        Text(
                          'All Investments',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        // Build one card per investment
                        ..._investments.map((investment) {
                          return _buildInvestmentCard(investment);
                        }).toList(),
                      ],
                    ),
                  ),
                ),
      // FAB to add a new investment
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddInvestmentScreen(),
            ),
          );
          if (result == true) {
            _loadPortfolio(); // Refresh after adding
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  // _buildEmptyState shows the "no investments" prompt
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            const Text(
              'No Investments Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start building your investment portfolio',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddInvestmentScreen(),
                    ),
                  );
                  if (result == true) {
                    _loadPortfolio();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text(
                  'Add Investment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // _buildPortfolioSummaryCard creates the large gradient header card
  Widget _buildPortfolioSummaryCard() {
    final portfolio = _portfolio!;
    final profitColor = portfolio.isProfit ? AppColors.success : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Portfolio Value',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          // Current total value in large bold text
          Text(
            'RM ${portfolio.currentValue.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                'Invested',
                'RM ${portfolio.totalInvested.toStringAsFixed(2)}',
              ),
              _buildSummaryItem(
                portfolio.isProfit ? 'Profit' : 'Loss',
                // .abs() makes negative loss values positive for display
                'RM ${portfolio.totalProfitLoss.abs().toStringAsFixed(2)}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Overall percentage return/loss badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  // getIconForPerformance returns up/down arrow based on + or - change
                  InvestmentTypes.getIconForPerformance(portfolio.percentageChange),
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  // Add "+" prefix for positive values; negative values already have "-"
                  '${portfolio.percentageChange > 0 ? "+" : ""}${portfolio.percentageChange.toStringAsFixed(2)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  portfolio.isProfit ? 'Return' : 'Loss',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // _buildSummaryItem creates a label+value pair widget for the summary card
  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // _buildAssetBreakdown shows how the portfolio is distributed across asset types
  Widget _buildAssetBreakdown() {
    final portfolio = _portfolio!;

    if (portfolio.assetBreakdown.isEmpty) return const SizedBox.shrink(); // Nothing to show

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Asset Breakdown',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        // Build one row per asset type (e.g., Stocks, Crypto, Real Estate)
        ...portfolio.assetBreakdown.map((asset) {
          final typeInfo = InvestmentTypes.getAssetTypeInfo(asset.type); // Icon and color
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Asset type icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: typeInfo.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeInfo.icon, color: typeInfo.color, size: 24),
                ),
                const SizedBox(width: 12),
                // Asset type name and count/value
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.type, // e.g., "Stocks"
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        // Ternary for "1 asset" vs "N assets" (proper singular/plural)
                        '${asset.count} ${asset.count > 1 ? "assets" : "asset"} • RM ${asset.currentValue.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Percentage change on the right
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${asset.percentageChange > 0 ? "+" : ""}${asset.percentageChange.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: InvestmentTypes.getColorForPerformance(asset.percentageChange),
                      ),
                    ),
                    Text(
                      asset.isProfit ? 'Profit' : 'Loss',
                      style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // _buildPerformersSection shows the top-performing individual investments
  Widget _buildPerformersSection(
    String title,
    List<InvestmentPerformance> performers,
    bool isTop, // True for top performers (could be used for bottom performers too)
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...performers.map((performer) {
          final typeInfo = InvestmentTypes.getAssetTypeInfo(performer.assetsType);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: typeInfo.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(typeInfo.icon, color: typeInfo.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        performer.assetName, // e.g., "Apple Inc."
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        performer.assetsType,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${performer.percentageChange > 0 ? "+" : ""}${performer.percentageChange.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: InvestmentTypes.getColorForPerformance(performer.percentageChange),
                      ),
                    ),
                    Text(
                      // .abs() shows profit/loss as positive for display purposes
                      'RM ${performer.profitLoss.abs().toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // _buildInvestmentCard creates a swipeable card for one investment
  Widget _buildInvestmentCard(InvestmentModel investment) {
    final typeInfo = InvestmentTypes.getAssetTypeInfo(investment.assetsType);

    return Dismissible(
      // Dismissible enables swipe-to-delete
      key: Key(investment.investmentId.toString()),
      direction: DismissDirection.endToStart, // Swipe left to delete
      background: Container(
        // Red delete background revealed while swiping
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      // confirmDismiss shows a dialog before completing the swipe
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Investment'),
            content: Text('Are you sure you want to delete ${investment.assetName}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              // ElevatedButton with danger color for destructive actions (consistent with other screens)
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        if (investment.investmentId != null) {
          _deleteInvestment(investment.investmentId!);
        }
      },
      child: GestureDetector(
        onTap: () => _showUpdatePriceDialog(investment), // Tap to update price
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Asset type icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: typeInfo.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(typeInfo.icon, color: typeInfo.color, size: 28),
                  ),
                  const SizedBox(width: 12),
                  // Asset name, type, and quantity
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          investment.assetName, // e.g., "Bitcoin"
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${investment.assetsType} • ${investment.quantity} units',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        // Small hint that tapping opens the price update dialog
                        Text(
                          'Tap to update price',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary.withOpacity(0.7),
                            fontStyle: FontStyle.italic, // Italic distinguishes hint from data
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Current value and percentage change
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'RM ${investment.currentValue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            InvestmentTypes.getIconForPerformance(investment.percentageChange),
                            size: 14,
                            color: InvestmentTypes.getColorForPerformance(investment.percentageChange),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${investment.percentageChange > 0 ? "+" : ""}${investment.percentageChange.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: InvestmentTypes.getColorForPerformance(investment.percentageChange),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Bottom row: purchase date and days held
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    // DateFormat('dd MMM yyyy') formats as "15 Mar 2024"
                    'Purchased: ${DateFormat('dd MMM yyyy').format(investment.purchaseDate)}',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  Text(
                    '${investment.daysHeld} days held',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

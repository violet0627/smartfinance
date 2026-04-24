// ==============================================================================
// portfolio_overview_screen.dart - Investment Portfolio Overview Screen
// ==============================================================================
// Shows the user's full investment portfolio:
//   - Portfolio Summary card: total current value, amount invested, profit/loss,
//     overall percentage return
//   - Asset Breakdown: per-type totals (e.g., Stocks 45%, Crypto 20%, ...)
//   - Top Performers: individual investments with the highest % gain
//   - All Investments: swipeable cards showing each investment with current price,
//     P&L, days held, and a "tap to update price" hint
//
// App bar has a filter menu to view one asset type at a time.
// When a filter is active, a banner below the app bar shows what's being filtered
// with a "Clear" button.
//
// Key interactions:
//   - Tap investment card → _showUpdatePriceDialog (StatefulBuilder for inline errors)
//   - Swipe left → confirmDismiss dialog → _deleteInvestment
//   - FAB → AddInvestmentScreen → refresh portfolio on return
//   - Pull-to-refresh → _loadPortfolio
// ==============================================================================

import 'package:flutter/material.dart';                   // Flutter UI toolkit
import 'package:intl/intl.dart';                          // DateFormat for date formatting
import '../../models/investment_model.dart';               // InvestmentModel, PortfolioSummary, InvestmentPerformance
import '../../services/api_service.dart';                  // Backend API calls
import '../../utils/colors.dart';                          // AppColors constants
import '../../utils/investment_types.dart';                // InvestmentTypes utility (icons, colors, performance icons)
import 'add_investment_screen.dart';                       // Screen for adding new investments

// ==============================================================================
// PortfolioOverviewScreen — StatefulWidget
// ==============================================================================
// StatefulWidget because it manages:
//   - _investments: typed list of InvestmentModel objects loaded from the API
//   - _portfolio: PortfolioSummary model (total value, P&L, breakdowns)
//   - _isLoading: controls the loading spinner
//   - _filterType: null = all types; set to e.g. "Stocks" when a filter is active
// ==============================================================================
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

  // ==============================================================================
  // initState - Called Once When the Widget Is First Inserted into the Tree
  // ==============================================================================
  @override
  void initState() {
    super.initState();     // Always call super first
    _loadPortfolio();      // Fetch portfolio data immediately on screen open
  }

  // ==============================================================================
  // _loadPortfolio - Fetch Portfolio Summary and Individual Investments
  // ==============================================================================
  // Two nested try/catch blocks are intentional:
  //   - The inner try/catch for portfolio summary means a summary failure does NOT
  //     prevent investments from loading — the user still sees their investment cards.
  //   - The inner try/catch for investments is the same: isolated from the summary call.
  //   - The outer try/catch catches any unexpected error (e.g., userId fetch fails).
  //   - The 'finally' block always stops the spinner regardless of what happened.
  // _filterType is passed to getUserInvestments — null means return all types.
  // ==============================================================================
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
  // This recalculates the profit/loss based on the new price.
  // Uses StatefulBuilder so we can show inline validation errors without closing the dialog.
  void _showUpdatePriceDialog(InvestmentModel investment) {
    // Pre-fill with current price (or purchase price if no current price is set)
    final priceController = TextEditingController(
      text: investment.currentPrice?.toString() ?? investment.purchasePrice.toString(),
    );
    String? errorText; // Shown below the input when validation fails

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        // StatefulBuilder gives this dialog its own local setState (setDialogState)
        // so we can update errorText without rebuilding the whole portfolio screen
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Update ${investment.assetName} Price'),
          content: TextField(
            controller: priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Current Price',
              prefixText: 'RM ',
              border: const OutlineInputBorder(),
              // errorText shows a red error message directly below the input field
              // null = no error (field looks normal)
              errorText: errorText,
            ),
            // Clear the error as soon as the user starts typing again
            onChanged: (_) {
              if (errorText != null) {
                setDialogState(() => errorText = null);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final price = double.tryParse(priceController.text);
                // Validate — show inline error if input is not a valid number
                if (price == null || price <= 0) {
                  setDialogState(() => errorText = 'Please enter a valid price');
                  return; // Keep dialog open so user can correct the input
                }
                if (investment.investmentId == null) return;

                Navigator.pop(context); // Close dialog before the async API call
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
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['error'] ?? 'Failed to update price'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================================
  // build - Assemble the Portfolio Overview Screen
  // ==============================================================================
  // Three body states:
  //   1. _isLoading == true                      → centered spinner
  //   2. _portfolio is null OR portfolio isEmpty → _buildEmptyState() with add CTA
  //   3. Portfolio loaded                        → Column:
  //        - Optional filter banner (if _filterType != null)
  //        - Expanded RefreshIndicator > scrollable column of cards
  //
  // 'Expanded' is required around the scrollable section because the outer Column
  // cannot have unbounded height — Expanded tells it "fill whatever space is left
  // after the filter banner".
  // ==============================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Investment Portfolio'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Filter button — icon turns yellow when a filter is active so the user
          // can immediately see that results are filtered, not showing everything
          PopupMenuButton<String>(
            icon: Icon(
              _filterType != null ? Icons.filter_alt : Icons.filter_list,
              // Yellow tint when filtered, white when showing all — clear visual signal
              color: _filterType != null ? Colors.yellow : Colors.white,
            ),
            tooltip: _filterType != null ? 'Filtering: $_filterType' : 'Filter by type',
            onSelected: (value) {
              setState(() {
                // 'All' means no filter; otherwise store the type name
                _filterType = value == 'All' ? null : value;
              });
              _loadPortfolio(); // Reload with new filter
            },
            itemBuilder: (context) => [
              // 'All Types' option — clears the filter
              const PopupMenuItem(
                value: 'All',
                child: Row(
                  children: [
                    Icon(Icons.clear, size: 18),
                    SizedBox(width: 8),
                    Text('All Types'),
                  ],
                ),
              ),
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
              : Column(
                  children: [
                    // Active filter banner — only shown when a filter is selected.
                    // Lets the user immediately see what they're filtering by and
                    // tap × to clear it without opening the menu again.
                    if (_filterType != null)
                      Container(
                        width: double.infinity,
                        color: AppColors.primary.withOpacity(0.08),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.filter_alt, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Showing: $_filterType only',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(), // Push the clear button to the right
                            // × button — clears the filter and reloads all investments
                            GestureDetector(
                              onTap: () {
                                setState(() => _filterType = null);
                                _loadPortfolio();
                              },
                              child: Row(
                                children: [
                                  Text(
                                    'Clear',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(Icons.close, size: 16, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Main scrollable content — Expanded fills remaining height after the banner
                    Expanded(
                      child: RefreshIndicator(
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
              ),   // close Expanded
            ],
          ),       // close outer Column — this ends the body: parameter of Scaffold
      // FAB to add a new investment — floatingActionButton is a separate Scaffold property
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
    // profitColor is referenced in the return/rebuild, but profit/loss coloring
    // in this card is handled inline via InvestmentTypes.getColorForPerformance().
    // The variable is not needed here.

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

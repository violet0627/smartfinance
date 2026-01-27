import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/investment_model.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import '../../utils/investment_types.dart';
import 'add_investment_screen.dart';

class PortfolioOverviewScreen extends StatefulWidget {
  const PortfolioOverviewScreen({super.key});

  @override
  State<PortfolioOverviewScreen> createState() => _PortfolioOverviewScreenState();
}

class _PortfolioOverviewScreenState extends State<PortfolioOverviewScreen> {
  List<InvestmentModel> _investments = [];
  PortfolioSummary? _portfolio;
  bool _isLoading = true;
  String? _filterType;

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
  }

  Future<void> _loadPortfolio() async {
    setState(() => _isLoading = true);

    try {
      final userId = await ApiService.getCurrentUserId();
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Load portfolio summary
      try {
        final portfolioResult = await ApiService.getPortfolioSummary(userId);
        if (portfolioResult['success'] && portfolioResult['portfolio'] != null) {
          setState(() {
            _portfolio = PortfolioSummary.fromJson(portfolioResult['portfolio']);
          });
        }
      } catch (e) {
        print('Error loading portfolio summary: $e');
      }

      // Load investments
      try {
        final investmentsResult = await ApiService.getUserInvestments(userId, type: _filterType);
        if (investmentsResult['success']) {
          final investmentsList = investmentsResult['investments'] as List;
          setState(() {
            _investments = investmentsList
                .map((json) => InvestmentModel.fromJson(json))
                .toList();
          });
        }
      } catch (e) {
        print('Error loading investments: $e');
      }
    } catch (e) {
      print('Error in _loadPortfolio: $e');
    } finally {
      // Always stop loading, even if there's an error
      setState(() => _isLoading = false);
    }
  }

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
      _loadPortfolio();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to delete investment'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _showUpdatePriceDialog(InvestmentModel investment) {
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
                Navigator.pop(context);
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
                  _loadPortfolio();
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterType = value == 'All' ? null : value;
              });
              _loadPortfolio();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Types')),
              ...InvestmentTypes.allTypes.map((type) =>
                  PopupMenuItem(value: type, child: Text(type))),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                        _buildPortfolioSummaryCard(),
                        const SizedBox(height: 24),
                        _buildAssetBreakdown(),
                        const SizedBox(height: 24),
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
                        ..._investments.map((investment) {
                          return _buildInvestmentCard(investment);
                        }).toList(),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
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
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

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
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
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
                'RM ${portfolio.totalProfitLoss.abs().toStringAsFixed(2)}',
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                  InvestmentTypes.getIconForPerformance(portfolio.percentageChange),
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
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
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
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

  Widget _buildAssetBreakdown() {
    final portfolio = _portfolio!;

    if (portfolio.assetBreakdown.isEmpty) return const SizedBox.shrink();

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
        ...portfolio.assetBreakdown.map((asset) {
          final typeInfo = InvestmentTypes.getAssetTypeInfo(asset.type);
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: typeInfo.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeInfo.icon, color: typeInfo.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.type,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${asset.count} ${asset.count > 1 ? "assets" : "asset"} • RM ${asset.currentValue.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
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
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
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

  Widget _buildPerformersSection(
    String title,
    List<InvestmentPerformance> performers,
    bool isTop,
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
                        performer.assetName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        performer.assetsType,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
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
                      'RM ${performer.profitLoss.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
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

  Widget _buildInvestmentCard(InvestmentModel investment) {
    final typeInfo = InvestmentTypes.getAssetTypeInfo(investment.assetsType);

    return Dismissible(
      key: Key(investment.investmentId.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
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
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
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
        onTap: () => _showUpdatePriceDialog(investment),
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: typeInfo.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(typeInfo.icon, color: typeInfo.color, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          investment.assetName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${investment.assetsType} • ${investment.quantity} units',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Purchased: ${DateFormat('dd MMM yyyy').format(investment.purchaseDate)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${investment.daysHeld} days held',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
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

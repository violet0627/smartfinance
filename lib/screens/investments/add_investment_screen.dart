import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/investment_model.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import '../../utils/investment_types.dart';

class AddInvestmentScreen extends StatefulWidget {
  const AddInvestmentScreen({super.key});

  @override
  State<AddInvestmentScreen> createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends State<AddInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _assetNameController = TextEditingController();
  final _stockSymbolController = TextEditingController();
  final _quantityController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _currentPriceController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedAssetType;
  DateTime _purchaseDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _assetNameController.dispose();
    _stockSymbolController.dispose();
    _quantityController.dispose();
    _purchasePriceController.dispose();
    _currentPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _purchaseDate) {
      setState(() => _purchaseDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAssetType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an asset type'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final userId = await ApiService.getCurrentUserId();
    if (userId == null) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login again')),
      );
      return;
    }

    final investment = InvestmentModel(
      assetName: _assetNameController.text,
      assetsType: _selectedAssetType!,
      stockSymbol: _stockSymbolController.text.isEmpty ? null : _stockSymbolController.text,
      quantity: double.parse(_quantityController.text),
      purchasePrice: double.parse(_purchasePriceController.text),
      purchaseDate: _purchaseDate,
      currentPrice: _currentPriceController.text.isEmpty
          ? double.parse(_purchasePriceController.text)
          : double.parse(_currentPriceController.text),
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      userId: userId,
    );

    final result = await ApiService.createInvestment(investment.toJson());

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Investment added successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to add investment'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Investment'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Asset Type Selection
              Text(
                'Asset Type',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: InvestmentTypes.allTypes.length,
                itemBuilder: (context, index) {
                  final assetType = InvestmentTypes.allTypes[index];
                  final typeInfo = InvestmentTypes.getAssetTypeInfo(assetType);
                  final isSelected = _selectedAssetType == assetType;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedAssetType = assetType),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? typeInfo.color : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? typeInfo.color : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            typeInfo.icon,
                            size: 32,
                            color: isSelected ? Colors.white : typeInfo.color,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            assetType,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Asset Name
              TextFormField(
                controller: _assetNameController,
                decoration: InputDecoration(
                  labelText: 'Asset Name',
                  hintText: 'e.g., Apple Inc., Bitcoin, Gold',
                  prefixIcon: const Icon(Icons.label),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter asset name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Stock Symbol (Optional)
              TextFormField(
                controller: _stockSymbolController,
                decoration: InputDecoration(
                  labelText: 'Stock Symbol (Optional)',
                  hintText: 'e.g., AAPL, TSLA, BTC',
                  prefixIcon: const Icon(Icons.code),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),

              // Quantity and Purchase Price Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        hintText: '0.00',
                        prefixIcon: const Icon(Icons.numbers),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _purchasePriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Purchase Price',
                        hintText: '0.00',
                        prefixText: 'RM ',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Purchase Date
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Text(
                            'Purchase Date',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        DateFormat('dd MMM yyyy').format(_purchaseDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Current Price (Optional)
              TextFormField(
                controller: _currentPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Current Price (Optional)',
                  hintText: 'Leave empty if same as purchase price',
                  prefixText: 'RM ',
                  prefixIcon: const Icon(Icons.trending_up),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add any additional information...',
                  prefixIcon: const Icon(Icons.note),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Add Investment',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// add_investment_screen.dart
// This screen lets users add a new investment to their portfolio.
// Users select an asset type from a grid, then fill in details like name, quantity, and price.

import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:intl/intl.dart'; // Date formatting (e.g., "15 Mar 2024")
import '../../models/investment_model.dart'; // InvestmentModel data class
import '../../services/api_service.dart'; // Backend API calls
import '../../utils/colors.dart'; // AppColors constants
import '../../utils/investment_types.dart'; // InvestmentTypes utility with icons/colors per asset type

// AddInvestmentScreen is a StatefulWidget because form data and selected type change over time
class AddInvestmentScreen extends StatefulWidget {
  const AddInvestmentScreen({super.key});

  @override
  State<AddInvestmentScreen> createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends State<AddInvestmentScreen> {
  // GlobalKey<FormState> enables programmatic access to the Form for validation
  final _formKey = GlobalKey<FormState>();

  // TextEditingControllers manage the text content of each input field
  final _assetNameController = TextEditingController();      // e.g., "Apple Inc."
  final _stockSymbolController = TextEditingController();    // e.g., "AAPL" (optional)
  final _quantityController = TextEditingController();       // e.g., "10"
  final _purchasePriceController = TextEditingController();  // e.g., "150.00"
  final _currentPriceController = TextEditingController();   // e.g., "175.00" (optional)
  final _notesController = TextEditingController();          // Any extra notes (optional)

  String? _selectedAssetType; // Stores the selected type (e.g., "Stocks", "Crypto"); null = none selected
  DateTime _purchaseDate = DateTime.now(); // Default purchase date is today
  bool _isLoading = false; // True while submitting the investment to the API

  @override
  void dispose() {
    // Free memory by disposing all TextEditingControllers when the widget is removed
    _assetNameController.dispose();
    _stockSymbolController.dispose();
    _quantityController.dispose();
    _purchasePriceController.dispose();
    _currentPriceController.dispose();
    _notesController.dispose();
    super.dispose(); // Always call super.dispose() last
  }

  // _selectDate opens a date picker dialog so the user can choose when they bought the asset
  Future<void> _selectDate() async {
    // showDatePicker shows the system date picker dialog and returns the picked date (or null if cancelled)
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,     // Start the calendar at the current purchase date
      firstDate: DateTime(2000),      // Can't pick a date before year 2000
      lastDate: DateTime.now(),       // Can't pick a future date
    );
    // Only update if the user picked a date AND it's different from the current one
    if (picked != null && picked != _purchaseDate) {
      setState(() => _purchaseDate = picked); // Update state to trigger a rebuild with the new date
    }
  }

  // _handleSubmit validates the form and sends the investment data to the backend
  Future<void> _handleSubmit() async {
    // validate() calls each TextFormField's validator function
    // Returns false if any validator returns an error string
    if (!_formKey.currentState!.validate()) return;

    // Extra validation: asset type must be selected (it's not part of the Form widget)
    if (_selectedAssetType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an asset type'),
          backgroundColor: AppColors.danger, // Red to signal an error
        ),
      );
      return;
    }

    setState(() => _isLoading = true); // Show loading state

    final userId = await ApiService.getCurrentUserId(); // Get the logged-in user's ID
    if (userId == null) {
      setState(() => _isLoading = false);
      if (!mounted) return; // Widget might be gone after async gap
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login again')),
      );
      return;
    }

    // Build an InvestmentModel object from all the form field values
    final investment = InvestmentModel(
      assetName: _assetNameController.text,
      assetsType: _selectedAssetType!, // '!' asserts this is not null (we checked above)
      // If stockSymbol is empty, store null (optional field)
      stockSymbol: _stockSymbolController.text.isEmpty ? null : _stockSymbolController.text,
      // double.parse converts String "10.5" to double 10.5
      quantity: double.parse(_quantityController.text),
      purchasePrice: double.parse(_purchasePriceController.text),
      purchaseDate: _purchaseDate,
      // If currentPrice is not provided, use purchasePrice as the starting current price
      currentPrice: _currentPriceController.text.isEmpty
          ? double.parse(_purchasePriceController.text)
          : double.parse(_currentPriceController.text),
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      userId: userId,
    );

    // toJson() converts the InvestmentModel to a Map<String, dynamic> for the API
    final result = await ApiService.createInvestment(investment.toJson());

    setState(() => _isLoading = false);

    if (!mounted) return; // Safety check after async gap

    if (result['success']) {
      // Show SnackBar BEFORE Navigator.pop — after pop, context is deactivated
      // and ScaffoldMessenger.of(context) would throw a widget-tree error.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Investment added successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true); // 'true' tells portfolio screen to reload
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
        key: _formKey, // Attach the form key to enable form-level validation
        child: SingleChildScrollView(
          // SingleChildScrollView allows the form to scroll when the keyboard appears
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Left-align child widgets
            children: [
              // Asset Type Selection Grid
              Text(
                'Asset Type',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                // shrinkWrap: true makes the GridView only as tall as its content
                // (needed when GridView is inside a Column or ScrollView)
                physics: const NeverScrollableScrollPhysics(),
                // NeverScrollableScrollPhysics disables GridView's own scrolling
                // so the outer SingleChildScrollView handles all scrolling
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,       // 3 columns in the grid
                  childAspectRatio: 1.2,   // Width / Height ratio for each grid cell
                  crossAxisSpacing: 12,    // Horizontal gap between cells
                  mainAxisSpacing: 12,     // Vertical gap between rows
                ),
                itemCount: InvestmentTypes.allTypes.length, // Number of asset type options
                itemBuilder: (context, index) {
                  // itemBuilder is called once per grid cell to build each asset type card
                  final assetType = InvestmentTypes.allTypes[index]; // e.g., "Stocks"
                  final typeInfo = InvestmentTypes.getAssetTypeInfo(assetType); // Gets icon and color
                  final isSelected = _selectedAssetType == assetType; // Is this card selected?

                  return GestureDetector(
                    onTap: () => setState(() => _selectedAssetType = assetType),
                    // When tapped, update _selectedAssetType and rebuild to show selection
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        // Selected cards show the asset type's color; unselected are white
                        color: isSelected ? typeInfo.color : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          // Selected cards have a colored border; unselected have a grey border
                          color: isSelected ? typeInfo.color : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, // Center items vertically
                        children: [
                          Icon(
                            typeInfo.icon, // Icon specific to this asset type
                            size: 32,
                            // Selected icon is white (on colored background); unselected uses type color
                            color: isSelected ? Colors.white : typeInfo.color,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            assetType, // Display the asset type name
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,              // Allow up to 2 lines for long names
                            overflow: TextOverflow.ellipsis, // Show "..." if text is too long
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Asset Name field - required
              TextFormField(
                controller: _assetNameController,
                decoration: InputDecoration(
                  labelText: 'Asset Name',
                  hintText: 'e.g., Apple Inc., Bitcoin, Gold', // Example text in field when empty
                  prefixIcon: const Icon(Icons.label),
                  filled: true,          // Fill the field background with fillColor
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter asset name'; // Error shown below field
                  }
                  return null; // Valid
                },
              ),
              const SizedBox(height: 16),

              // Stock Symbol field - optional ticker symbol
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
                textCapitalization: TextCapitalization.characters, // Auto-capitalize to UPPERCASE
                // No validator = no validation (field is optional)
              ),
              const SizedBox(height: 16),

              // Quantity and Purchase Price - side by side in a Row
              Row(
                children: [
                  Expanded( // Expanded makes each field take equal half of the Row width
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      // numberWithOptions(decimal: true) shows a numeric keyboard with decimal point
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
                          return 'Required'; // Short error for compact field
                        }
                        // double.tryParse returns null if the string can't be parsed as a number
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12), // Gap between the two fields
                  Expanded(
                    child: TextFormField(
                      controller: _purchasePriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Purchase Price',
                        hintText: '0.00',
                        prefixText: 'RM ', // Static text shown before the input (Malaysian Ringgit)
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

              // Purchase Date picker - tapping opens a calendar dialog
              GestureDetector(
                onTap: _selectDate, // Opens the date picker when tapped
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Push label and date apart
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
                        // DateFormat('dd MMM yyyy') formats: "15 Mar 2024"
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

              // Current Price - optional; defaults to purchase price if not entered
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
                // No validator - field is optional
              ),
              const SizedBox(height: 16),

              // Notes - optional multi-line text area
              TextFormField(
                controller: _notesController,
                maxLines: 3, // Allow up to 3 lines of text
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

              // Submit button - full width, tall, shows spinner when loading
              SizedBox(
                width: double.infinity, // Stretch to full width
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  // null onPressed disables the button while submitting
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white) // Show spinner
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

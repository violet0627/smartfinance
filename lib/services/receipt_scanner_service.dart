import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ReceiptData {
  final String? merchantName;
  final double? amount;
  final DateTime? date;
  final String? category;
  final String rawText;
  final List<String> allNumbers;
  final List<String> allDates;

  ReceiptData({
    this.merchantName,
    this.amount,
    this.date,
    this.category,
    required this.rawText,
    required this.allNumbers,
    required this.allDates,
  });

  Map<String, dynamic> toJson() {
    return {
      'merchantName': merchantName,
      'amount': amount,
      'date': date?.toIso8601String(),
      'category': category,
      'rawText': rawText,
      'allNumbers': allNumbers,
      'allDates': allDates,
    };
  }
}

class ReceiptScannerService {
  static final ImagePicker _picker = ImagePicker();
  static final TextRecognizer _textRecognizer = TextRecognizer();

  /// Pick image from camera
  static Future<XFile?> captureReceipt() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Error capturing receipt: $e');
      return null;
    }
  }

  /// Pick image from gallery
  static Future<XFile?> pickReceiptFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Error picking receipt: $e');
      return null;
    }
  }

  /// Scan receipt and extract data
  static Future<ReceiptData?> scanReceipt(XFile imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      // Extract raw text
      String rawText = recognizedText.text;
      print('Extracted text: $rawText');

      // Parse the text
      final receiptData = _parseReceiptText(rawText);
      return receiptData;
    } catch (e) {
      print('Error scanning receipt: $e');
      return null;
    }
  }

  /// Parse receipt text to extract structured data
  static ReceiptData _parseReceiptText(String text) {
    // Clean and prepare text
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();

    // Extract all numbers (potential amounts)
    final allNumbers = _extractNumbers(text);

    // Extract all dates
    final allDates = _extractDates(text);

    // Extract merchant name (usually first few lines)
    final merchantName = _extractMerchantName(lines);

    // Extract amount (usually largest number or last number)
    final amount = _extractAmount(allNumbers, text);

    // Extract date
    final date = _extractDate(allDates);

    // Determine category based on merchant keywords
    final category = _guessCategory(text);

    return ReceiptData(
      merchantName: merchantName,
      amount: amount,
      date: date,
      category: category,
      rawText: text,
      allNumbers: allNumbers,
      allDates: allDates,
    );
  }

  /// Extract all numbers from text (potential amounts)
  static List<String> _extractNumbers(String text) {
    // Match patterns like: 12.34, 1234.56, 1,234.56, RM 100.00, $ 50.99
    final numberPattern = RegExp(r'(?:RM|MYR|\$|USD)?\s*(\d{1,10}(?:[,\.]\d{2,3})*(?:\.\d{2})?)');
    final matches = numberPattern.allMatches(text);

    List<String> numbers = [];
    for (var match in matches) {
      if (match.group(1) != null) {
        numbers.add(match.group(1)!);
      }
    }

    return numbers;
  }

  /// Extract all dates from text
  static List<String> _extractDates(String text) {
    List<String> dates = [];

    // Common date patterns
    final datePatterns = [
      RegExp(r'\d{1,2}[-/]\d{1,2}[-/]\d{2,4}'), // 12/31/2024, 31-12-24
      RegExp(r'\d{4}[-/]\d{1,2}[-/]\d{1,2}'), // 2024-12-31
      RegExp(r'\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{2,4}', caseSensitive: false), // 31 Dec 2024
    ];

    for (var pattern in datePatterns) {
      final matches = pattern.allMatches(text);
      for (var match in matches) {
        dates.add(match.group(0)!);
      }
    }

    return dates;
  }

  /// Extract merchant name (first meaningful line)
  static String? _extractMerchantName(List<String> lines) {
    if (lines.isEmpty) return null;

    // Usually the first 1-3 lines contain the merchant name
    // Look for lines with mostly letters (not numbers/symbols)
    for (var i = 0; i < (lines.length < 5 ? lines.length : 5); i++) {
      final line = lines[i].trim();

      // Skip lines that are mostly numbers or very short
      if (line.length < 3) continue;

      // Check if line has more letters than numbers
      final letters = line.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
      final numbers = line.replaceAll(RegExp(r'[^0-9]'), '').length;

      if (letters > numbers && line.length >= 3) {
        // Clean up the line
        String cleaned = line
            .replaceAll(RegExp(r"[^\w\s&'-]"), '')
            .trim();

        if (cleaned.length >= 3) {
          return cleaned;
        }
      }
    }

    return lines.isNotEmpty ? lines[0].trim() : null;
  }

  /// Extract amount from numbers list
  static double? _extractAmount(List<String> numbers, String fullText) {
    if (numbers.isEmpty) return null;

    // Convert all numbers to doubles
    List<double> amounts = [];
    for (var numStr in numbers) {
      try {
        // Remove commas and parse
        final cleaned = numStr.replaceAll(',', '');
        final amount = double.parse(cleaned);

        // Filter reasonable amounts (not account numbers, etc.)
        if (amount > 0.01 && amount < 100000) {
          amounts.add(amount);
        }
      } catch (e) {
        // Skip invalid numbers
      }
    }

    if (amounts.isEmpty) return null;

    // Look for keywords indicating total
    final totalKeywords = ['total', 'amount', 'grand total', 'balance', 'due'];
    final lowerText = fullText.toLowerCase();

    // Try to find amount near "total" keyword
    for (var keyword in totalKeywords) {
      if (lowerText.contains(keyword)) {
        // Get the largest amount (usually the total)
        amounts.sort((a, b) => b.compareTo(a));
        return amounts.first;
      }
    }

    // If no total keyword, return the largest amount
    amounts.sort((a, b) => b.compareTo(a));
    return amounts.first;
  }

  /// Extract date from dates list
  static DateTime? _extractDate(List<String> dates) {
    if (dates.isEmpty) return DateTime.now();

    // Try to parse the first valid date
    for (var dateStr in dates) {
      try {
        // Try various date formats
        DateTime? parsed;

        // Format: DD/MM/YYYY or DD-MM-YYYY
        if (dateStr.contains('/') || dateStr.contains('-')) {
          final parts = dateStr.split(RegExp(r'[-/]'));
          if (parts.length == 3) {
            int day, month, year;

            if (parts[2].length == 4) {
              // DD/MM/YYYY
              day = int.parse(parts[0]);
              month = int.parse(parts[1]);
              year = int.parse(parts[2]);
            } else if (parts[0].length == 4) {
              // YYYY/MM/DD
              year = int.parse(parts[0]);
              month = int.parse(parts[1]);
              day = int.parse(parts[2]);
            } else {
              // DD/MM/YY
              day = int.parse(parts[0]);
              month = int.parse(parts[1]);
              year = int.parse(parts[2]) + 2000;
            }

            parsed = DateTime(year, month, day);
          }
        }

        // Format: 31 Dec 2024
        if (parsed == null) {
          final monthPattern = RegExp(r'(\d{1,2})\s+([A-Za-z]{3,9})\s+(\d{2,4})');
          final match = monthPattern.firstMatch(dateStr);
          if (match != null) {
            final day = int.parse(match.group(1)!);
            final monthStr = match.group(2)!.toLowerCase();
            int year = int.parse(match.group(3)!);
            if (year < 100) year += 2000;

            final months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
            final month = months.indexWhere((m) => monthStr.startsWith(m)) + 1;

            if (month > 0) {
              parsed = DateTime(year, month, day);
            }
          }
        }

        if (parsed != null && parsed.year >= 2000 && parsed.year <= 2100) {
          return parsed;
        }
      } catch (e) {
        // Try next date
        continue;
      }
    }

    // Default to today if no valid date found
    return DateTime.now();
  }

  /// Guess category based on merchant name and keywords
  static String? _guessCategory(String text) {
    final lowerText = text.toLowerCase();

    // Food & Dining
    if (_containsAny(lowerText, ['restaurant', 'cafe', 'coffee', 'mcdonald', 'kfc', 'pizza', 'starbucks', 'food', 'meal', 'dining'])) {
      return 'Food & Dining';
    }

    // Groceries
    if (_containsAny(lowerText, ['supermarket', 'grocery', 'mart', 'store', 'tesco', 'aeon'])) {
      return 'Groceries';
    }

    // Transportation
    if (_containsAny(lowerText, ['grab', 'uber', 'taxi', 'fuel', 'petrol', 'parking', 'toll', 'transport'])) {
      return 'Transportation';
    }

    // Entertainment
    if (_containsAny(lowerText, ['cinema', 'movie', 'theater', 'netflix', 'spotify', 'game', 'entertainment'])) {
      return 'Entertainment';
    }

    // Shopping
    if (_containsAny(lowerText, ['mall', 'fashion', 'clothing', 'shoes', 'electronics', 'shopping'])) {
      return 'Shopping';
    }

    // Healthcare
    if (_containsAny(lowerText, ['clinic', 'hospital', 'pharmacy', 'medical', 'doctor', 'health'])) {
      return 'Healthcare';
    }

    // Utilities
    if (_containsAny(lowerText, ['electric', 'water', 'bill', 'utility', 'internet', 'phone'])) {
      return 'Utilities';
    }

    return null; // Unknown category
  }

  /// Helper: Check if text contains any of the keywords
  static bool _containsAny(String text, List<String> keywords) {
    for (var keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  /// Show source selection dialog
  static Future<XFile?> showSourceSelectionDialog(context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan Receipt'),
        content: const Text('Choose how to add your receipt:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, 'gallery'),
            icon: const Icon(Icons.photo_library),
            label: const Text('From Gallery'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, 'camera'),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take Photo'),
          ),
        ],
      ),
    );

    if (result == 'camera') {
      return await captureReceipt();
    } else if (result == 'gallery') {
      return await pickReceiptFromGallery();
    }

    return null;
  }

  /// Dispose resources
  static void dispose() {
    _textRecognizer.close();
  }
}

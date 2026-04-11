// ==============================================================================
// receipt_scanner_service.dart - Receipt OCR Scanner Service
// ==============================================================================
// This service allows users to scan paper receipts using their phone camera
// and automatically extract transaction data (merchant name, amount, date, category).
//
// How it works:
// 1. User takes a photo of a receipt (camera or gallery)
// 2. Google ML Kit's text recognition (OCR) reads all text from the image
// 3. Custom parsing logic extracts structured data:
//    - Merchant name: Usually in the first few lines
//    - Amount: Largest number, especially near "total"/"amount" keywords
//    - Date: Various date format patterns (DD/MM/YYYY, YYYY-MM-DD, etc.)
//    - Category: Guessed from keywords (e.g., "KFC" -> "Food & Dining")
// 4. Extracted data is returned as a ReceiptData object for the user to review
//
// Uses:
// - image_picker: For camera/gallery image selection
// - google_mlkit_text_recognition: For OCR (Optical Character Recognition)
// ==============================================================================

import 'package:flutter/material.dart';                          // For BuildContext (dialog)
import 'package:image_picker/image_picker.dart';                 // Camera/gallery image picker
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'; // OCR engine

// ==============================================================================
// ReceiptData - Data Extracted from a Scanned Receipt
// ==============================================================================
// Holds all the structured data parsed from the receipt image.
// Fields may be null if the parser couldn't extract them.
// ==============================================================================
class ReceiptData {
  final String? merchantName;      // Business name (e.g., "McDonald's")
  final double? amount;            // Total amount (e.g., 25.90)
  final DateTime? date;            // Transaction date
  final String? category;          // Guessed category (e.g., "Food & Dining")
  final String rawText;            // Full raw text extracted by OCR
  final List<String> allNumbers;   // All number patterns found (for user to pick from)
  final List<String> allDates;     // All date patterns found (for user to pick from)

  ReceiptData({
    this.merchantName,
    this.amount,
    this.date,
    this.category,
    required this.rawText,
    required this.allNumbers,
    required this.allDates,
  });

  // Convert to JSON for debugging or API submission
  Map<String, dynamic> toJson() {
    return {
      'merchantName': merchantName,
      'amount': amount,
      'date': date?.toIso8601String(),    // ?. only calls the method if date is not null
      'category': category,
      'rawText': rawText,
      'allNumbers': allNumbers,
      'allDates': allDates,
    };
  }
}

// ==============================================================================
// ReceiptScannerService - Main Scanner Service Class
// ==============================================================================
class ReceiptScannerService {
  // Singleton instances (created once, reused for all scans)
  static final ImagePicker _picker = ImagePicker();           // Image picker instance
  static final TextRecognizer _textRecognizer = TextRecognizer(); // ML Kit OCR engine

  // ==============================================================================
  // Image Capture Methods
  // ==============================================================================

  // Open the camera to take a photo of a receipt
  // Returns the image file (XFile) or null if cancelled
  static Future<XFile?> captureReceipt() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,    // Open camera
        maxWidth: 1920,                // Limit resolution for performance
        maxHeight: 1080,
        imageQuality: 85,             // 85% quality (good balance of quality/size)
      );
      return image;
    } catch (e) {
      debugPrint('Error capturing receipt: $e');
      return null;
    }
  }

  // Pick a receipt image from the device's photo gallery
  static Future<XFile?> pickReceiptFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,   // Open photo gallery
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('Error picking receipt: $e');
      return null;
    }
  }

  // ==============================================================================
  // scanReceipt - Main OCR Processing Method
  // ==============================================================================
  // Takes an image file and:
  // 1. Runs Google ML Kit text recognition on it
  // 2. Gets the raw text string
  // 3. Passes it to _parseReceiptText for structured data extraction
  //
  // InputImage.fromFilePath() creates an ML Kit input from a file path
  // _textRecognizer.processImage() runs the OCR engine
  // ==============================================================================
  static Future<ReceiptData?> scanReceipt(XFile imageFile) async {
    try {
      // Create an InputImage from the file path for ML Kit
      final inputImage = InputImage.fromFilePath(imageFile.path);

      // Run OCR - extract all text from the image
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      // Get the full text as a single string
      String rawText = recognizedText.text;
      debugPrint('Receipt OCR extracted ${rawText.length} characters');

      // Parse the raw text into structured receipt data
      final receiptData = _parseReceiptText(rawText);
      return receiptData;
    } catch (e) {
      debugPrint('Error scanning receipt: $e');
      return null;
    }
  }

  // ==============================================================================
  // _parseReceiptText - Extract Structured Data from Raw OCR Text
  // ==============================================================================
  // This is the main parsing engine. It takes the raw text and tries to
  // extract: merchant name, amount, date, and category.
  //
  // The _ prefix makes this method private (only callable within this class).
  // ==============================================================================
  static ReceiptData _parseReceiptText(String text) {
    // Split text into non-empty lines
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();

    // Extract all potential data points
    final allNumbers = _extractNumbers(text);     // All number patterns (potential amounts)
    final allDates = _extractDates(text);         // All date patterns
    final merchantName = _extractMerchantName(lines); // Business name from first lines
    final amount = _extractAmount(allNumbers, text);  // Best guess for total amount
    final date = _extractDate(allDates);              // Best guess for transaction date
    final category = _guessCategory(text);            // Category based on keywords

    return ReceiptData(
      merchantName: merchantName,
      amount: amount,
      date: date,
      category: category,
      rawText: text,
      allNumbers: allNumbers,     // Include all found numbers for user to choose from
      allDates: allDates,         // Include all found dates for user to choose from
    );
  }

  // ==============================================================================
  // _extractNumbers - Find All Number Patterns (Potential Amounts)
  // ==============================================================================
  // Uses regex to find patterns that look like monetary amounts.
  // Handles formats like: 12.34, 1234.56, 1,234.56, RM 100.00, $ 50.99
  //
  // RegExp breakdown: (?:RM|MYR|\$|USD)?\s*(\d{1,10}(?:[,\.]\d{2,3})*(?:\.\d{2})?)
  // - (?:RM|MYR|\$|USD)?  = optional currency prefix (non-capturing group)
  // - \s*                  = optional whitespace
  // - (\d{1,10}...)       = capturing group for the number itself
  // - (?:[,\.]\d{2,3})*   = optional thousands separators
  // - (?:\.\d{2})?        = optional decimal part (.00)
  // ==============================================================================
  static List<String> _extractNumbers(String text) {
    final numberPattern = RegExp(r'(?:RM|MYR|\$|USD)?\s*(\d{1,10}(?:[,\.]\d{2,3})*(?:\.\d{2})?)');
    final matches = numberPattern.allMatches(text);

    List<String> numbers = [];
    for (var match in matches) {
      if (match.group(1) != null) {              // group(1) = first capturing group (the number)
        numbers.add(match.group(1)!);            // ! asserts non-null (we just checked)
      }
    }

    return numbers;
  }

  // ==============================================================================
  // _extractDates - Find All Date Patterns
  // ==============================================================================
  // Uses multiple regex patterns to find dates in various formats:
  // - DD/MM/YYYY or DD-MM-YY (e.g., 31/12/2024, 15-01-25)
  // - YYYY-MM-DD (e.g., 2024-12-31) - ISO format
  // - DD Month YYYY (e.g., 31 Dec 2024, 15 January 2025)
  //
  // caseSensitive: false makes the month name pattern case-insensitive
  // ==============================================================================
  static List<String> _extractDates(String text) {
    List<String> dates = [];

    // Define multiple date patterns to match
    final datePatterns = [
      RegExp(r'\d{1,2}[-/]\d{1,2}[-/]\d{2,4}'),   // DD/MM/YYYY or DD-MM-YY
      RegExp(r'\d{4}[-/]\d{1,2}[-/]\d{1,2}'),       // YYYY-MM-DD (ISO format)
      RegExp(r'\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{2,4}',
          caseSensitive: false),                      // DD Month YYYY (e.g., "31 Dec 2024")
    ];

    // Try each pattern and collect all matches
    for (var pattern in datePatterns) {
      final matches = pattern.allMatches(text);
      for (var match in matches) {
        dates.add(match.group(0)!);                  // group(0) = the entire matched string
      }
    }

    return dates;
  }

  // ==============================================================================
  // _extractMerchantName - Find the Business Name
  // ==============================================================================
  // The merchant name is usually in the first few lines of a receipt.
  // Strategy: Look at the first 5 lines and find the first one that has
  // more letters than numbers (to skip phone numbers, addresses, etc.)
  //
  // .replaceAll(RegExp(r'[^a-zA-Z]'), '') removes everything except letters
  // to count how many letters vs numbers are in each line.
  // ==============================================================================
  static String? _extractMerchantName(List<String> lines) {
    if (lines.isEmpty) return null;

    // Check first 5 lines (or fewer if receipt is short)
    for (var i = 0; i < (lines.length < 5 ? lines.length : 5); i++) {
      final line = lines[i].trim();

      // Skip very short lines (likely not a name)
      if (line.length < 3) continue;

      // Count letters vs numbers in the line
      final letters = line.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;   // Only letters
      final numbers = line.replaceAll(RegExp(r'[^0-9]'), '').length;      // Only digits

      // If more letters than numbers, this is likely the merchant name
      if (letters > numbers && line.length >= 3) {
        // Clean up: remove special characters except letters, numbers, spaces, &, ', -
        String cleaned = line
            .replaceAll(RegExp(r"[^\w\s&'-]"), '')   // Remove unwanted special chars
            .trim();

        if (cleaned.length >= 3) {
          return cleaned;
        }
      }
    }

    // Fallback: return the very first line if nothing else matched
    return lines.isNotEmpty ? lines[0].trim() : null;
  }

  // ==============================================================================
  // _extractAmount - Determine the Total Amount
  // ==============================================================================
  // Strategy for finding the receipt total:
  // 1. Convert all found number strings to doubles
  // 2. Filter out unreasonable amounts (< 0.01 or > 100,000)
  // 3. Look for "total"/"amount" keywords in the text
  // 4. If keywords found: return the LARGEST number (usually the grand total)
  // 5. If no keywords: still return the LARGEST number (best guess)
  // ==============================================================================
  static double? _extractAmount(List<String> numbers, String fullText) {
    if (numbers.isEmpty) return null;

    // Helper: parse a string to a valid receipt amount (0.01 – 100,000)
    double? _toAmount(String s) {
      try {
        final v = double.parse(s.replaceAll(',', ''));
        return (v > 0.01 && v < 100000) ? v : null;
      } catch (_) {
        return null;
      }
    }

    // Keywords that indicate the line containing the final payable amount.
    // Ordered from most to least specific so we match "grand total" before "total".
    final totalKeywords = [
      'grand total', 'total amount', 'amount due', 'total due',
      'total payable', 'jumlah', 'jumlah keseluruhan',   // Malay
      'total', 'amount', 'balance', 'due',
    ];

    // Strategy 1: find the SPECIFIC LINE that contains a total keyword and
    // extract the LAST number on that line — this is almost always the amount.
    final lines = fullText.split('\n');
    for (var keyword in totalKeywords) {
      for (var line in lines) {
        if (line.toLowerCase().contains(keyword)) {
          // Find all numbers on this line
          final lineNumbers = RegExp(r'\d+[\.,]?\d*').allMatches(line)
              .map((m) => _toAmount(m.group(0)!))
              .whereType<double>()
              .toList();
          if (lineNumbers.isNotEmpty) {
            return lineNumbers.last; // Rightmost number on the total line
          }
        }
      }
    }

    // Strategy 2: fall back to the largest valid number in the whole receipt
    final allAmounts = numbers
        .map(_toAmount)
        .whereType<double>()
        .toList();
    if (allAmounts.isEmpty) return null;
    allAmounts.sort((a, b) => b.compareTo(a));
    return allAmounts.first;
  }

  // ==============================================================================
  // _extractDate - Parse the First Valid Date
  // ==============================================================================
  // Tries to parse each found date string into a DateTime object.
  // Handles multiple formats:
  // - DD/MM/YYYY or DD-MM-YYYY (e.g., 31/12/2024)
  // - YYYY/MM/DD or YYYY-MM-DD (e.g., 2024-12-31)
  // - DD/MM/YY (e.g., 31/12/24 -> 2024)
  // - DD Month YYYY (e.g., "31 Dec 2024")
  //
  // Returns DateTime.now() if no valid date is found (today as fallback).
  // ==============================================================================
  static DateTime? _extractDate(List<String> dates) {
    if (dates.isEmpty) return DateTime.now();     // Default to today

    for (var dateStr in dates) {
      try {
        DateTime? parsed;

        // Try numeric date formats (DD/MM/YYYY, DD-MM-YYYY, etc.)
        if (dateStr.contains('/') || dateStr.contains('-')) {
          final parts = dateStr.split(RegExp(r'[-/]'));   // Split by - or /
          if (parts.length == 3) {
            int day, month, year;

            if (parts[2].length == 4) {
              // Format: DD/MM/YYYY (last part is 4-digit year)
              day = int.parse(parts[0]);
              month = int.parse(parts[1]);
              year = int.parse(parts[2]);
            } else if (parts[0].length == 4) {
              // Format: YYYY/MM/DD (first part is 4-digit year)
              year = int.parse(parts[0]);
              month = int.parse(parts[1]);
              day = int.parse(parts[2]);
            } else {
              // Format: DD/MM/YY (2-digit year, assume 2000s)
              day = int.parse(parts[0]);
              month = int.parse(parts[1]);
              year = int.parse(parts[2]) + 2000;  // 24 -> 2024
            }

            parsed = DateTime(year, month, day);
          }
        }

        // Try written month format: "31 Dec 2024" or "15 January 2025"
        if (parsed == null) {
          final monthPattern = RegExp(r'(\d{1,2})\s+([A-Za-z]{3,9})\s+(\d{2,4})');
          final match = monthPattern.firstMatch(dateStr);
          if (match != null) {
            final day = int.parse(match.group(1)!);            // Day number
            final monthStr = match.group(2)!.toLowerCase();    // Month name
            int year = int.parse(match.group(3)!);
            if (year < 100) year += 2000;                      // 2-digit year

            // Map month name to month number (1-12)
            final months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
            final month = months.indexWhere((m) => monthStr.startsWith(m)) + 1;
            // indexWhere returns -1 if not found, +1 makes it 0 (invalid)

            if (month > 0) {
              parsed = DateTime(year, month, day);
            }
          }
        }

        // Validate: year must be reasonable (2000-2100)
        if (parsed != null && parsed.year >= 2000 && parsed.year <= 2100) {
          return parsed;
        }
      } catch (e) {
        // If parsing fails, try the next date string
        continue;
      }
    }

    // No valid date found - default to today
    return DateTime.now();
  }

  // ==============================================================================
  // _guessCategory - Determine Category from Receipt Keywords
  // ==============================================================================
  // Uses keyword matching to guess what category this receipt belongs to.
  // Checks the full receipt text for keywords associated with each category.
  //
  // Returns null if no category can be determined (user must pick manually).
  // ==============================================================================
  static String? _guessCategory(String text) {
    final lowerText = text.toLowerCase();

    // Food & Dining keywords
    if (_containsAny(lowerText, ['restaurant', 'cafe', 'coffee', 'mcdonald', 'kfc', 'pizza', 'starbucks', 'food', 'meal', 'dining'])) {
      return 'Food & Dining';
    }

    // Groceries keywords
    if (_containsAny(lowerText, ['supermarket', 'grocery', 'mart', 'store', 'tesco', 'aeon'])) {
      return 'Groceries';
    }

    // Transportation keywords
    if (_containsAny(lowerText, ['grab', 'uber', 'taxi', 'fuel', 'petrol', 'parking', 'toll', 'transport'])) {
      return 'Transportation';
    }

    // Entertainment keywords
    if (_containsAny(lowerText, ['cinema', 'movie', 'theater', 'netflix', 'spotify', 'game', 'entertainment'])) {
      return 'Entertainment';
    }

    // Shopping keywords
    if (_containsAny(lowerText, ['mall', 'fashion', 'clothing', 'shoes', 'electronics', 'shopping'])) {
      return 'Shopping';
    }

    // Healthcare keywords
    if (_containsAny(lowerText, ['clinic', 'hospital', 'pharmacy', 'medical', 'doctor', 'health'])) {
      return 'Healthcare';
    }

    // Utilities keywords
    if (_containsAny(lowerText, ['electric', 'water', 'bill', 'utility', 'internet', 'phone'])) {
      return 'Utilities';
    }

    return null; // Unknown category - user must choose manually
  }

  // ==============================================================================
  // _containsAny - Helper: Check if Text Contains Any Keyword from a List
  // ==============================================================================
  // Returns true if any of the keywords are found in the text.
  // Used by _guessCategory to check multiple keywords at once.
  // ==============================================================================
  static bool _containsAny(String text, List<String> keywords) {
    for (var keyword in keywords) {
      if (text.contains(keyword)) return true;   // Found a match!
    }
    return false;                                 // None of the keywords found
  }

  // ==============================================================================
  // showSourceSelectionDialog - Camera vs Gallery Choice Dialog
  // ==============================================================================
  // Shows a dialog asking the user whether to take a photo or pick from gallery.
  // Returns the selected image file (XFile) or null if cancelled.
  //
  // showDialog<String> means the dialog returns a String result when closed.
  // Navigator.pop(context, 'camera') closes the dialog and returns "camera".
  // ==============================================================================
  static Future<XFile?> showSourceSelectionDialog(context) async {
    // Show dialog and wait for user's choice
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan Receipt'),
        content: const Text('Choose how to add your receipt:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),   // Close with "cancel"
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, 'gallery'),  // Close with "gallery"
            icon: const Icon(Icons.photo_library),
            label: const Text('From Gallery'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, 'camera'),   // Close with "camera"
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take Photo'),
          ),
        ],
      ),
    );

    // Act on the user's choice
    if (result == 'camera') {
      return await captureReceipt();            // Open camera
    } else if (result == 'gallery') {
      return await pickReceiptFromGallery();     // Open gallery
    }

    return null;   // User cancelled
  }

  // ==============================================================================
  // dispose - Clean Up Resources
  // ==============================================================================
  // Closes the ML Kit text recognizer to free memory.
  // Should be called when the receipt scanner is no longer needed.
  // ==============================================================================
  static void dispose() {
    _textRecognizer.close();
  }
}

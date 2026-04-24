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
      debugPrint('Error capturing receipt: $e');
      return null;
    }
  }

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
      debugPrint('Error picking receipt: $e');
      return null;
    }
  }

  static Future<ReceiptData?> scanReceipt(XFile imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      String rawText = recognizedText.text;
      debugPrint('Receipt OCR extracted ${rawText.length} characters');
      return _parseReceiptText(rawText);
    } catch (e) {
      debugPrint('Error scanning receipt: $e');
      return null;
    }
  }

  static ReceiptData _parseReceiptText(String text) {
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();

    final allNumbers = _extractNumbers(text);
    final allDates = _extractDates(text);
    final merchantName = _extractMerchantName(lines);
    final amount = _extractAmount(allNumbers, text);
    final date = _extractDate(allDates);
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

  static List<String> _extractNumbers(String text) {
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

  static List<String> _extractDates(String text) {
    List<String> dates = [];

    final datePatterns = [
      RegExp(r'\d{1,2}[-/]\d{1,2}[-/]\d{2,4}'),
      RegExp(r'\d{4}[-/]\d{1,2}[-/]\d{1,2}'),
      RegExp(r'\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{2,4}',
          caseSensitive: false),
    ];

    for (var pattern in datePatterns) {
      final matches = pattern.allMatches(text);
      for (var match in matches) {
        dates.add(match.group(0)!);
      }
    }

    return dates;
  }

  static String? _extractMerchantName(List<String> lines) {
    if (lines.isEmpty) return null;

    for (var i = 0; i < (lines.length < 5 ? lines.length : 5); i++) {
      final line = lines[i].trim();
      if (line.length < 3) continue;

      final letters = line.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
      final numbers = line.replaceAll(RegExp(r'[^0-9]'), '').length;

      if (letters > numbers && line.length >= 3) {
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

  static double? _extractAmount(List<String> numbers, String fullText) {
    if (numbers.isEmpty) return null;

    double? toAmount(String s) {
      try {
        final v = double.parse(s.replaceAll(',', ''));
        return (v > 0.01 && v < 100000) ? v : null;
      } catch (_) {
        return null;
      }
    }

    // Ordered most-to-least specific so "grand total" matches before "total"
    final totalKeywords = [
      'grand total', 'total amount', 'amount due', 'total due',
      'total payable', 'jumlah', 'jumlah keseluruhan',
      'total', 'amount', 'balance', 'due',
    ];

    // Strategy 1: find the line containing a total keyword, return the last number on it
    final lines = fullText.split('\n');
    for (var keyword in totalKeywords) {
      for (var line in lines) {
        if (line.toLowerCase().contains(keyword)) {
          final lineNumbers = RegExp(r'\d+[\.,]?\d*').allMatches(line)
              .map((m) => toAmount(m.group(0)!))
              .whereType<double>()
              .toList();
          if (lineNumbers.isNotEmpty) {
            return lineNumbers.last;
          }
        }
      }
    }

    // Strategy 2: fall back to the largest valid number in the whole receipt
    final allAmounts = numbers.map(toAmount).whereType<double>().toList();
    if (allAmounts.isEmpty) return null;
    allAmounts.sort((a, b) => b.compareTo(a));
    return allAmounts.first;
  }

  static DateTime? _extractDate(List<String> dates) {
    if (dates.isEmpty) return DateTime.now();

    for (var dateStr in dates) {
      try {
        DateTime? parsed;

        if (dateStr.contains('/') || dateStr.contains('-')) {
          final parts = dateStr.split(RegExp(r'[-/]'));
          if (parts.length == 3) {
            int day, month, year;

            if (parts[2].length == 4) {
              day = int.parse(parts[0]);
              month = int.parse(parts[1]);
              year = int.parse(parts[2]);
            } else if (parts[0].length == 4) {
              year = int.parse(parts[0]);
              month = int.parse(parts[1]);
              day = int.parse(parts[2]);
            } else {
              day = int.parse(parts[0]);
              month = int.parse(parts[1]);
              year = int.parse(parts[2]) + 2000; // 2-digit year: 24 -> 2024
            }

            parsed = DateTime(year, month, day);
          }
        }

        if (parsed == null) {
          final monthPattern = RegExp(r'(\d{1,2})\s+([A-Za-z]{3,9})\s+(\d{2,4})');
          final match = monthPattern.firstMatch(dateStr);
          if (match != null) {
            final day = int.parse(match.group(1)!);
            final monthStr = match.group(2)!.toLowerCase();
            int year = int.parse(match.group(3)!);
            if (year < 100) year += 2000;

            final months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
            // indexWhere returns -1 if not found; +1 converts 0-based index to 1-based month number
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
        continue;
      }
    }

    return DateTime.now();
  }

  static String? _guessCategory(String text) {
    final lowerText = text.toLowerCase();

    if (_containsAny(lowerText, ['restaurant', 'cafe', 'coffee', 'mcdonald', 'kfc', 'pizza', 'starbucks', 'food', 'meal', 'dining'])) {
      return 'Food & Dining';
    }
    if (_containsAny(lowerText, ['supermarket', 'grocery', 'mart', 'store', 'tesco', 'aeon'])) {
      return 'Groceries';
    }
    if (_containsAny(lowerText, ['grab', 'uber', 'taxi', 'fuel', 'petrol', 'parking', 'toll', 'transport'])) {
      return 'Transportation';
    }
    if (_containsAny(lowerText, ['cinema', 'movie', 'theater', 'netflix', 'spotify', 'game', 'entertainment'])) {
      return 'Entertainment';
    }
    if (_containsAny(lowerText, ['mall', 'fashion', 'clothing', 'shoes', 'electronics', 'shopping'])) {
      return 'Shopping';
    }
    if (_containsAny(lowerText, ['clinic', 'hospital', 'pharmacy', 'medical', 'doctor', 'health'])) {
      return 'Healthcare';
    }
    if (_containsAny(lowerText, ['electric', 'water', 'bill', 'utility', 'internet', 'phone'])) {
      return 'Utilities';
    }

    return null;
  }

  static bool _containsAny(String text, List<String> keywords) {
    for (var keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }

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

  static void dispose() {
    _textRecognizer.close();
  }
}

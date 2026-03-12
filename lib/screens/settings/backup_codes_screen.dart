// backup_codes_screen.dart
// This screen displays the one-time backup codes generated after enabling 2FA.
// Users must save these codes (copy, download, or print) before leaving the screen.
// It uses WillPopScope to intercept the back button and warn if codes haven't been saved.

import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:flutter/services.dart'; // Provides Clipboard for copy-to-clipboard functionality
import 'package:share_plus/share_plus.dart'; // Allows sharing text/files via system share sheet
import '../../utils/colors.dart'; // AppColors constants

// BackupCodesScreen receives the backup codes as a parameter from the 2FA setup flow
class BackupCodesScreen extends StatefulWidget {
  final List<dynamic> backupCodes;   // The list of backup code strings from the API
  final bool isRegeneration;         // True if this is a regeneration (not the initial setup)

  const BackupCodesScreen({
    super.key,
    required this.backupCodes,       // 'required' means this parameter must be provided
    this.isRegeneration = false,     // Defaults to false (initial setup)
  });

  @override
  State<BackupCodesScreen> createState() => _BackupCodesScreenState();
}

class _BackupCodesScreenState extends State<BackupCodesScreen> {
  // _acknowledged tracks whether the user checked the "I have saved my codes" checkbox
  // The Done button stays disabled until this is true
  bool _acknowledged = false;

  // _copyAllCodes joins all codes with newlines and copies them to the clipboard
  void _copyAllCodes() {
    // .join('\n') connects all codes in the list with newline separators
    final codesText = widget.backupCodes.join('\n');
    // Clipboard.setData places text on the system clipboard
    Clipboard.setData(ClipboardData(text: codesText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All backup codes copied to clipboard'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2), // Snackbar disappears after 2 seconds
      ),
    );
  }

  // _copyCode copies a single backup code to the clipboard
  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code $code copied'), // Shows the actual code that was copied
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 1), // Short duration for individual copies
      ),
    );
  }

  // _handleDone processes the Done button press
  // Requires the acknowledgment checkbox to be checked first
  void _handleDone() {
    if (!_acknowledged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please acknowledge that you have saved your backup codes'),
          backgroundColor: AppColors.warning, // Yellow/orange warning color
        ),
      );
      return; // Exit without navigating
    }

    // popUntil navigates back through the route stack until the condition is true
    // This pops back to either the root route or the security settings page
    Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == '/security');
    Navigator.of(context).pop(); // Pop one more time to reach the settings screen
  }

  @override
  Widget build(BuildContext context) {
    // WillPopScope intercepts the device back button and hardware back gesture
    // onWillPop is called when the user tries to go back
    // Return true to allow navigation back, false to block it
    return WillPopScope(
      onWillPop: () async {
        if (!_acknowledged) {
          // Show a confirmation dialog before allowing the user to leave without saving
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Warning'),
              content: const Text(
                'Are you sure you want to leave without saving your backup codes? '
                'You will not be able to see them again.',
              ),
              actions: [
                TextButton(
                  // Returning false from Navigator.pop means "don't navigate back"
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Stay'),
                ),
                ElevatedButton(
                  // Returning true means "allow navigation back"
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Leave Anyway'),
                ),
              ],
            ),
          );
          // shouldPop is the value passed to Navigator.pop in the dialog
          // '?? false' means "use false if shouldPop is null" (user dismissed dialog)
          return shouldPop ?? false;
        }
        return true; // User acknowledged, allow going back
      },
      child: Scaffold(
        appBar: AppBar(
          // Different title for initial setup vs. regeneration
          title: Text(widget.isRegeneration ? 'New Backup Codes' : 'Save Backup Codes'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          // Hide the back arrow during the initial 2FA setup flow (force them to use Done button)
          automaticallyImplyLeading: !widget.isRegeneration,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children to full width
            children: [
              // Success checkmark icon at the top
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1), // Light green background
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 48,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Success title
              const Text(
                'Two-Factor Authentication Enabled!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Explanatory description
              Text(
                'Save these backup codes in a secure place. You can use them to access your account if you lose your authenticator device.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Red warning box about codes being single-use
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,     // Light red background
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade700, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Each code can only be used once. Keep them safe!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // White card containing the backup codes list
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4), // Shadow below the card
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: "Backup Codes" title + "Copy All" button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Backup Codes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _copyAllCodes,
                          icon: const Icon(Icons.copy_all, size: 18),
                          label: const Text('Copy All'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Build one row per backup code
                    // .asMap() converts the list to a Map<index, value>
                    // .entries gives MapEntry objects with .key (index) and .value (code)
                    ...widget.backupCodes.asMap().entries.map((entry) {
                      final index = entry.key;    // 0-based index
                      final code = entry.value.toString(); // Convert to String
                      return _buildCodeItem(index + 1, code); // Display 1-based numbers
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Blue info box with instructions on how to use backup codes
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'How to use backup codes:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Each bullet point instruction
                    _buildInstruction('Save codes in a password manager'),
                    _buildInstruction('Print and store in a safe place'),
                    _buildInstruction('Use when you lose access to authenticator'),
                    _buildInstruction('Each code works only once'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Acknowledgment checkbox - must be checked to enable the Done button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CheckboxListTile(
                  // CheckboxListTile combines a Checkbox with a label in a ListTile layout
                  value: _acknowledged,         // Current checkbox state
                  onChanged: (value) {
                    setState(() => _acknowledged = value ?? false); // Update state
                  },
                  title: const Text(
                    'I have saved my backup codes in a secure location',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  controlAffinity: ListTileControlAffinity.leading, // Checkbox on the left
                  activeColor: AppColors.success, // Green checkbox when checked
                  contentPadding: EdgeInsets.zero, // Remove default padding
                ),
              ),
              const SizedBox(height: 24),

              // Done button - enabled only after acknowledgment
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  // null onPressed disables the button; only active when acknowledged
                  onPressed: _acknowledged ? _handleDone : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success, // Green button
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Download and Print buttons side by side
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      // Currently uses copyAllCodes as a substitute for actual download
                      onPressed: _copyAllCodes,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Download'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Share the backup codes as formatted text via the system share sheet
                        // Users can save to Notes, email themselves, print from another app, etc.
                        final codesText = widget.backupCodes
                            .asMap()
                            .entries
                            .map((e) => '${e.key + 1}. ${e.value}')
                            .join('\n');
                        Share.share(
                          'SmartFinance Backup Codes\n\nKeep these safe — each code can only be used once.\n\n$codesText',
                          subject: 'SmartFinance 2FA Backup Codes',
                        );
                      },
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Share'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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

  // _buildCodeItem creates a single row for one backup code
  // number: 1-based display number (1, 2, 3, ...)
  // code: the actual backup code string
  Widget _buildCodeItem(int number, String code) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Space between code rows
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Circular number badge on the left
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number', // Display the number (1, 2, 3...)
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded( // Expanded fills remaining space so the copy button stays at the right
            child: Text(
              code,
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'monospace', // Monospace font makes codes easier to read
                fontWeight: FontWeight.bold,
                letterSpacing: 2, // Extra space between characters for readability
              ),
            ),
          ),
          // Copy button for individual code
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () => _copyCode(code),
            color: AppColors.primary,
            tooltip: 'Copy code', // Shown on long press
          ),
        ],
      ),
    );
  }

  // _buildInstruction creates a bullet point row for the instructions box
  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, top: 4), // Indent to align with title
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

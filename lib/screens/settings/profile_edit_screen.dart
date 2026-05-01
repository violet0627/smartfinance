// ==============================================================================
// profile_edit_screen.dart - User Profile Edit Screen
// ==============================================================================
// Lets users update their display name, email address, and phone number.
// Also supports changing their profile photo from the device camera or gallery.
//
// Flow:
// 1. Screen opens → _loadProfile() fetches current name/email/phone from API
//    and pre-fills the form fields
// 2. User edits any field(s) and optionally picks a new profile photo
// 3. Tapping Save → form validates → API call updates the profile
// 4. On success → updates SharedPreferences cache → pops back to SettingsScreen
//
// Profile photo handling:
// - Tapping the avatar circle shows a bottom sheet with Camera / Gallery options
// - ImagePicker returns a File, which is sent to the API as a multipart upload
// - Until the API call completes, the local File is shown optimistically
// ==============================================================================

import 'dart:io';                                             // For File class — reads image from device storage
import 'package:flutter/material.dart';                      // Flutter UI toolkit - provides all widgets
import 'package:image_picker/image_picker.dart';             // Camera / gallery image picker
import 'package:shared_preferences/shared_preferences.dart'; // Local storage for saving small data on device
import '../../services/api_service.dart';                    // Our custom API service for backend calls
import '../../utils/colors.dart';                            // Our custom color constants (AppColors.primary, etc.)

// ==============================================================================
// ProfileEditScreen — StatefulWidget
// ==============================================================================
// StatefulWidget because it manages:
//   - _formKey: validates all form fields together
//   - Text controllers: hold name, email, phone values from the loaded profile
//   - _isLoading: shows spinner while fetching or saving profile
//   - _selectedImage: the new profile photo chosen by the user (null if unchanged)
// ==============================================================================
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key}); // super.key passes the key to the parent class

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState(); // Creates the mutable state object
}

// _ProfileEditScreenState holds all the mutable state for the profile edit form
class _ProfileEditScreenState extends State<ProfileEditScreen> {
  // GlobalKey<FormState> is used to access and validate the Form widget from outside it
  final _formKey = GlobalKey<FormState>();

  // TextEditingController manages the text input for each form field
  // Each controller holds the current text value and lets us read/set it programmatically
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;  // True while fetching current profile data from server
  bool _isSaving = false;  // True while saving profile changes to server
  String? _avatarPath;     // Local file path of the user's chosen avatar image (null = not set)

  @override
  void initState() {
    super.initState(); // Always call super.initState() first
    _loadProfile(); // Load the current profile data when the screen first opens
  }

  @override
  void dispose() {
    // Always dispose TextEditingControllers when the widget is removed to free memory
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose(); // Always call super.dispose() last
  }

  // _loadProfile fetches the user's current profile data from the backend
  // and fills the form fields with it
  Future<void> _loadProfile() async {
    setState(() => _isLoading = true); // Show loading spinner

    // Get the current user's ID from local storage (returns null if not logged in)
    final userId = await ApiService.getCurrentUserId();
    if (userId == null) {
      setState(() => _isLoading = false); // Stop loading, can't proceed without a user ID
      return; // Exit the function early
    }

    // Call the API to get the user's profile data from the server
    final result = await ApiService.getUserProfile(userId);

    // Load the saved avatar path from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('avatarPath');

    if (result['success']) {
      // API call succeeded - extract the profile data
      final profile = result['profile'];
      setState(() {
        // Pre-fill the form fields with existing values
        // The ?? '' means "use empty string if the value is null"
        _fullNameController.text = profile['fullName'] ?? '';
        _emailController.text = profile['email'] ?? '';
        _phoneController.text = profile['phoneNumber'] ?? '';
        // Restore avatar if the saved file still exists on disk
        if (savedPath != null && File(savedPath).existsSync()) {
          _avatarPath = savedPath;
        }
        _isLoading = false; // Hide the loading spinner
      });
    } else {
      setState(() {
        if (savedPath != null && File(savedPath).existsSync()) {
          _avatarPath = savedPath;
        }
        _isLoading = false;
      });
    }
  }

  // _pickAvatar — opens a bottom sheet so the user can choose gallery or camera
  Future<void> _pickAvatar() async {
    final picker = ImagePicker();

    // Show a bottom sheet with two options: gallery or camera
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Sheet only as tall as its content
            children: [
              // Drag handle visual indicator
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Change Profile Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return; // User dismissed without choosing

    // Open the picker with the chosen source
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,    // Compress slightly to save storage space
      maxWidth: 512,       // Cap resolution — profile photos don't need to be huge
      maxHeight: 512,
    );

    if (picked == null) return; // User cancelled the picker

    // Save the file path to SharedPreferences so it persists across app restarts
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('avatarPath', picked.path);

    if (!mounted) return;
    setState(() => _avatarPath = picked.path); // Update the displayed image
  }

  // _saveProfile validates the form and sends updated data to the server
  Future<void> _saveProfile() async {
    // validate() checks all TextFormField validators - returns false if any fail
    if (!_formKey.currentState!.validate()) return; // Stop if form is invalid

    setState(() => _isSaving = true); // Show saving state (disables Save button)

    final userId = await ApiService.getCurrentUserId();
    if (userId == null) {
      setState(() => _isSaving = false);
      return;
    }

    // Send the updated profile data to the backend API (email is excluded — cannot be changed)
    final result = await ApiService.updateUserProfile(userId, {
      'fullName': _fullNameController.text,
      'phoneNumber': _phoneController.text,
    });

    setState(() => _isSaving = false); // Re-enable the Save button

    // mounted check: after an async operation, the widget might have been removed
    // Always check mounted before using context after await
    if (!mounted) return;

    if (result['success']) {
      // Profile saved successfully - also update the local device storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userFullName', _fullNameController.text);

      // Show snackbar BEFORE popping — context becomes invalid after Navigator.pop
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.success, // Green background for success
        ),
      );
      // Navigator.pop closes this screen and returns 'true' to the calling screen
      // The 'true' value tells the settings screen to refresh the displayed name/email
      Navigator.pop(context, true);
    } else {
      // Profile save failed - show an error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to update profile'),
          backgroundColor: AppColors.danger, // Red background for error
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white, // Makes title and back arrow white
        actions: [
          // Only show the Save button when not loading and not currently saving
          if (!_isLoading && !_isSaving)
            TextButton(
              onPressed: _saveProfile, // Calls _saveProfile when tapped
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      // Show a spinner while loading, otherwise show the form
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Full-screen loading spinner
          : SingleChildScrollView(
              // SingleChildScrollView allows the form to scroll if keyboard pushes it up
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey, // Attach the form key to enable validation
                child: Column(
                  children: [
                    // Profile Picture — tappable to change photo
                    Center(
                      child: GestureDetector(
                        // GestureDetector makes the avatar tappable
                        onTap: _pickAvatar,
                        child: Stack(
                          // Stack overlays the camera badge on top of the avatar circle
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              // If a photo has been chosen, show it; otherwise show the person icon
                              backgroundImage: _avatarPath != null
                                  ? FileImage(File(_avatarPath!)) // Local file image
                                  : null,
                              child: _avatarPath == null
                                  ? Icon(Icons.person, size: 60, color: AppColors.primary)
                                  : null, // Hide icon when photo is shown
                            ),
                            // Camera badge in the bottom-right corner
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _avatarPath != null ? 'Tap to change photo' : 'Tap to upload photo',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32), // Larger spacer before form fields

                    // Full Name text field with validation
                    TextFormField(
                      controller: _fullNameController, // Connects this field to the controller
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person), // Icon shown at the start of the field
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), // Rounded corners
                        ),
                      ),
                      validator: (value) {
                        // validator is called when _formKey.currentState!.validate() runs
                        // Return a String error message if invalid, or null if valid
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name'; // Error message shown below field
                        }
                        return null; // null means valid
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email — read-only, cannot be changed here
                    TextFormField(
                      controller: _emailController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Email (cannot be changed)',
                        prefixIcon: const Icon(Icons.email),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone Number text field - optional but validated if provided
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '01X-XXXXXXX', // Placeholder text showing expected format
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.phone, // Shows numeric keyboard
                      validator: (value) {
                        // Phone is optional - only validate if user entered something
                        if (value != null && value.isNotEmpty) {
                          // Malaysian phone format: 01X-XXXXXXX or 01XXXXXXXX
                          // replaceAll removes spaces before checking the pattern
                          final phoneRegex = RegExp(r'^01[0-9]-?[0-9]{7,8}$');
                          if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
                            return 'Please enter a valid Malaysian phone number';
                          }
                        }
                        return null; // null = valid (including empty, since phone is optional)
                      },
                    ),
                    const SizedBox(height: 32),

                    // Save Changes button at the bottom of the form
                    SizedBox(
                      width: double.infinity, // Makes button stretch to full width
                      child: ElevatedButton(
                        // When _isSaving is true, onPressed = null which disables the button
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16), // Tall button
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        // Show a spinner inside the button while saving, otherwise show text
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2, // Thin spinner ring
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  // AlwaysStoppedAnimation makes the spinner stay white (non-animated color)
                                ),
                              )
                            : const Text(
                                'Save Changes',
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

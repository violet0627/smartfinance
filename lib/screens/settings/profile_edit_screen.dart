// profile_edit_screen.dart
// This screen lets users update their profile information: name, email, and phone number.
// It loads the current profile from the server, shows a form, validates input, then saves changes.

import 'package:flutter/material.dart'; // Flutter UI toolkit - provides all widgets
import 'package:shared_preferences/shared_preferences.dart'; // Local storage for saving small data on device
import '../../services/api_service.dart'; // Our custom API service for backend calls
import '../../utils/colors.dart'; // Our custom color constants (AppColors.primary, etc.)

// ProfileEditScreen is a StatefulWidget because form data and loading state change over time
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

    if (result['success']) {
      // API call succeeded - extract the profile data
      final profile = result['profile'];
      setState(() {
        // Pre-fill the form fields with existing values
        // The ?? '' means "use empty string if the value is null"
        _fullNameController.text = profile['fullName'] ?? '';
        _emailController.text = profile['email'] ?? '';
        _phoneController.text = profile['phoneNumber'] ?? '';
        _isLoading = false; // Hide the loading spinner
      });
    } else {
      setState(() => _isLoading = false); // Stop loading even if the API call failed
    }
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

    // Send the updated profile data to the backend API
    final result = await ApiService.updateUserProfile(userId, {
      'fullName': _fullNameController.text,   // Current text in the name field
      'email': _emailController.text,          // Current text in the email field
      'phoneNumber': _phoneController.text,    // Current text in the phone field
    });

    setState(() => _isSaving = false); // Re-enable the Save button

    // mounted check: after an async operation, the widget might have been removed
    // Always check mounted before using context after await
    if (!mounted) return;

    if (result['success']) {
      // Profile saved successfully - also update the local device storage
      final prefs = await SharedPreferences.getInstance(); // Access local storage
      await prefs.setString('userFullName', _fullNameController.text); // Cache the name locally
      await prefs.setString('userEmail', _emailController.text); // Cache the email locally

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
                    // Profile Picture Placeholder - displayed at the top of the form
                    Center(
                      child: Stack(
                        // Stack overlays widgets on top of each other
                        // Used here to put the camera icon on top of the avatar
                        children: [
                          CircleAvatar(
                            radius: 60, // Diameter = 120 logical pixels
                            backgroundColor: AppColors.primary.withOpacity(0.1), // Light tinted background
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: AppColors.primary,
                            ),
                          ),
                          Positioned(
                            // Positioned widget places a child at a specific location within a Stack
                            bottom: 0, // Place at the bottom of the Stack
                            right: 0,  // Place at the right side
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle, // Makes the container a circle
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,    // How soft/blurry the shadow is
                                    offset: const Offset(0, 2), // Shadow offset (x=0, y=2 = below)
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt, // Camera icon to suggest photo upload
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8), // Small vertical spacer
                    Text(
                      'Upload Photo',
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

                    // Email text field with format validation
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress, // Shows email keyboard (with @ key)
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        // RegExp is a regular expression - a pattern for matching text
                        // This pattern checks for the format: text@text.text
                        final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
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

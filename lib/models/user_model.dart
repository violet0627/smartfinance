// ==============================================================================
// user_model.dart - User Data Model (Dart Class for User Data)
// ==============================================================================
// This file defines the UserModel class which represents a user in the Flutter app.
// It's the "client-side" version of the User model in the backend.
//
// Purpose:
// When the backend sends user data as JSON, this class converts it into a
// Dart object that's easy to work with in the Flutter app.
//
// Example JSON from backend:
// {
//   "userId": 1,
//   "email": "user@gmail.com",
//   "fullName": "John Doe",
//   "emailVerified": true,
//   ...
// }
//
// This gets converted to: UserModel(userId: 1, email: "user@gmail.com", ...)
// ==============================================================================

class UserModel {
  // --- Properties (data fields) ---
  // "final" means the value can't be changed after creation (immutable).
  // This is a common pattern in Flutter - create new objects instead of modifying existing ones.

  final int userId;                  // Unique user ID from the database
  final String email;                // User's email address
  final String fullName;             // User's full name
  final String? phoneNumber;         // Optional phone number (? means it can be null)
  final bool emailVerified;          // Has the user verified their email?
  final bool twoFactorEnabled;       // Is 2FA turned on?
  final DateTime? createdAt;         // When the account was created (nullable)
  final DateTime? lastLogin;         // When the user last logged in (nullable)
  final int experiencePts;           // Total XP from gamification
  final int currentLevel;            // Current level from gamification

  // --- Constructor ---
  // "required" means the parameter MUST be provided when creating a UserModel.
  // Parameters without "required" are optional and have default values.
  // "this.userId" is shorthand for: this.userId = userId
  UserModel({
    required this.userId,
    required this.email,
    required this.fullName,
    this.phoneNumber,                // Optional (no "required", can be null)
    this.emailVerified = false,      // Default: not verified
    this.twoFactorEnabled = false,   // Default: 2FA off
    this.createdAt,                  // Optional (can be null)
    this.lastLogin,                  // Optional (can be null)
    required this.experiencePts,
    required this.currentLevel,
  });

  // ==============================================================================
  // factory UserModel.fromJson - Create a UserModel from JSON Data
  // ==============================================================================
  // "factory" constructor creates a UserModel from a JSON Map (dictionary).
  // This is called when the Flutter app receives user data from the backend API.
  //
  // Map<String, dynamic> is Dart's equivalent of Python's dict.
  // "dynamic" means the value can be any type (int, String, null, etc.)
  //
  // The ?? operator is the "null coalescing" operator:
  // json['emailVerified'] ?? false means:
  //   "Use json['emailVerified'] if it's not null, otherwise use false"
  // ==============================================================================
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'],                              // Read userId from JSON
      email: json['email'],                                // Read email from JSON
      fullName: json['fullName'],                          // Read fullName from JSON
      phoneNumber: json['phoneNumber'],                    // May be null (that's OK)
      emailVerified: json['emailVerified'] ?? false,       // Default to false if null
      twoFactorEnabled: json['twoFactorEnabled'] ?? false, // Default to false if null
      createdAt: json['createdAt'] != null                 // Parse date string if not null
          ? DateTime.parse(json['createdAt'])               // Convert "2025-01-15T10:30:00" to DateTime
          : null,                                           // Keep as null if not provided
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'])
          : null,
      experiencePts: json['experiencePts'] ?? 0,           // Default to 0 if null
      currentLevel: json['currentLevel'] ?? 1,             // Default to level 1 if null
    );
  }

  // ==============================================================================
  // toJson - Convert UserModel Back to JSON
  // ==============================================================================
  // Converts the Dart object back to a Map (dictionary) for sending to the backend.
  // This is the reverse of fromJson.
  //
  // The ?. operator is the "null-aware" operator:
  // createdAt?.toIso8601String() means:
  //   "If createdAt is not null, call toIso8601String() on it. Otherwise, return null."
  // ==============================================================================
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'emailVerified': emailVerified,
      'twoFactorEnabled': twoFactorEnabled,
      'createdAt': createdAt?.toIso8601String(),       // Convert DateTime to ISO string (or null)
      'lastLogin': lastLogin?.toIso8601String(),
      'experiencePts': experiencePts,
      'currentLevel': currentLevel,
    };
  }
}

class UserModel {
  final int userId;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final bool emailVerified;
  final bool twoFactorEnabled;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final int experiencePts;
  final int currentLevel;

  UserModel({
    required this.userId,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.emailVerified = false,
    this.twoFactorEnabled = false,
    this.createdAt,
    this.lastLogin,
    required this.experiencePts,
    required this.currentLevel,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'],
      email: json['email'],
      fullName: json['fullName'],
      phoneNumber: json['phoneNumber'],
      emailVerified: json['emailVerified'] ?? false,
      twoFactorEnabled: json['twoFactorEnabled'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'])
          : null,
      experiencePts: json['experiencePts'] ?? 0,
      currentLevel: json['currentLevel'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'emailVerified': emailVerified,
      'twoFactorEnabled': twoFactorEnabled,
      'createdAt': createdAt?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'experiencePts': experiencePts,
      'currentLevel': currentLevel,
    };
  }
}

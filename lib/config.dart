// ==============================================================================
// config.dart - App Configuration (CHANGE THIS FILE ON DEMO DAY)
// ==============================================================================
//
// ⚠️  DEMO DAY CHECKLIST:
//   1. Connect your laptop to the university Wi-Fi
//   2. Open Command Prompt → type "ipconfig"
//   3. Find "IPv4 Address" under your Wi-Fi adapter (e.g. 192.168.x.x)
//   4. Replace the IP below with that address
//   5. Make sure the Flask backend is running (python run.py)
//   6. Hot reload or rebuild the app
//
// ⚠️  AT HOME (current):
//   IP: 192.168.1.38  ← your home network IP
//
// ⚠️  AT UNIVERSITY (demo day):
//   IP: ???.???.???.???  ← update this on the day
//
// Device-specific notes:
//   - Android emulator   → use 10.0.2.2  (maps to host machine localhost)
//   - Physical device    → use your laptop's IPv4 address (same Wi-Fi required)
//   - iOS simulator      → use 127.0.0.1 or localhost
// ==============================================================================

class AppConfig {
  // ==========================================================================
  // ⚠️  CHANGE THIS IP ON DEMO DAY
  // ==========================================================================
  static const String _serverIp = '10.0.2.2'; // Android emulator → maps to host machine (Docker runs on host)
  static const int _serverPort = 5000;

  // Full base URL — used by ApiService for all API calls
  // Do not change this line; change _serverIp above instead
  static const String baseUrl = 'http://$_serverIp:$_serverPort/api';
}

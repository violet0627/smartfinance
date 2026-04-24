// DEMO DAY: connect laptop to university Wi-Fi → run ipconfig → update _serverIp below
// HOME: use your home network IPv4 address
// Android emulator: use 10.0.2.2 (maps to host localhost)
// Physical device: use laptop's IPv4 on the same Wi-Fi

class AppConfig {
  static const String _serverIp = '192.168.1.38'; // ← UPDATE ON DEMO DAY
  static const int _serverPort = 5000;

  static const String baseUrl = 'http://$_serverIp:$_serverPort/api';
}

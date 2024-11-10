class IPAddress {
  final String ip;
  final int port;

  IPAddress(this.ip, dynamic port) : port = _parsePort(port) {
    if (!isValidIP(ip)) {
      throw ArgumentError("Invalid IP address format.");
    }
    if (this.port < 0 || this.port > 65535) {
      throw ArgumentError("Port number must be between 0 and 65535.");
    }
  }

  /// Named constructor to initialize IPAddress from a primitive map.
  IPAddress.fromMap(Map<String, dynamic> map)
      : ip = map['ip'] ?? 'localhost',
        port = _parsePort(map['port'] ?? '80') {
    if (!isValidIP(ip)) {
      throw ArgumentError("Invalid IP address format.");
    }
    if (port < 0 || port > 65535) {
      throw ArgumentError("Port number must be between 0 and 65535.");
    }
  }

  /// Validates if the given IP address string is in a correct format (IPv4, IPv6, or localhost).
  static bool isValidIP(String ip) {
    if (ip == 'localhost') return true;

    // Regular expression for IPv4 address
    final ipv4Pattern = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    // Regular expression for IPv6 address
    final ipv6Pattern = RegExp(r'^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$');

    // Check IPv4 format
    if (ipv4Pattern.hasMatch(ip)) {
      return ip.split('.').every((segment) => int.parse(segment) <= 255);
    }
    // Check IPv6 format
    if (ipv6Pattern.hasMatch(ip)) {
      return true;
    }

    return false;
  }

  /// Parses the port, allowing it to be either a String or int.
  static int _parsePort(dynamic port) {
    if (port is int) {
      return port;
    } else if (port is String) {
      return int.tryParse(port) ?? 80;
    } else {
      throw ArgumentError("Port must be an int or a string representing an integer.");
    }
  }

  /// Returns the full address in the format `ip:port`
  String get fullAddress => "$ip:$port";

  /// Returns the IP address and port in primitive map form.
  Map<String, dynamic> toMap() => {'ip': ip, 'port': port};

  /// Compares IP and port values of two IPAddress objects
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IPAddress &&
          runtimeType == other.runtimeType &&
          ip == other.ip &&
          port == other.port;

  @override
  int get hashCode => ip.hashCode ^ port.hashCode;

  @override
  String toString() => fullAddress;
}

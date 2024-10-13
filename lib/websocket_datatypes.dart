import 'package:web_socket_channel/web_socket_channel.dart';

class WsMessage {
  // Properties
  Map<String, String> source;
  dynamic message;
  String originalRequest;

  // Constructor
  WsMessage({
    required this.source, 
    required this.message, 
    required this.originalRequest
  });

  // Method to create WsMessage from a map (useful for parsing JSON)
  factory WsMessage.fromMap(Map<String, dynamic> map) {
    return WsMessage(
      source: Map<String, String>.from(map['source']),
      message: Map<String, dynamic>.from(map['message']),
      originalRequest: map['originalRequest'] ?? '',
    );
  }

  // Method to convert WsMessage to a map (useful for converting to JSON)
  Map<String, dynamic> toMap() {
    return {
      'source': source,
      'message': message,
      'originalRequest': originalRequest,
    };
  }

  @override
  String toString() {
    return 'WsMessage(source: $source, message: $message, originalRequest: $originalRequest)';
  }
}

class WsMessageList {
  // List to hold all WsMessages
  List<WsMessage> messages = [];

  // Method to add a WsMessage to the list
  void addMessage(WsMessage message) {
    messages.add(message);
  }

  // Method to search for a WsMessage starting from the most recent (last) message
  WsMessage? searchMessage(Map<String, String> source, String originalRequest) {
    for (int i = messages.length - 1; i >= 0; i--) {
      WsMessage message = messages[i];
      if (_compareSource(message.source, source) && message.originalRequest == originalRequest) {
        return message;
      }
    }
    return null; // Return null if no match is found
  }

  // Helper method to compare two source maps
  bool _compareSource(Map<String, String> source1, Map<String, String> source2) {
    if (source1.length != source2.length) return false;
    for (String key in source1.keys) {
      if (source1[key] != source2[key]) return false;
    }
    return true;
  }

  // Method to return all messages as a list
  List<WsMessage> getAllMessages() {
    return messages;
  }
}

class WsDevice {
  // Properties
  final Map<String, String> ipAddress;
  final WebSocketChannel channel;

  Map<String, dynamic>? deviceInfo;
  WsMessageList messageList;

  bool ready = false;
  

  // Constructor
  WsDevice({required this.ipAddress, required this.channel, required this.messageList}){
    _fetchDeviceInfo();
  }

  // Method to fetch device info by sending "devinfo"
  Future<void> _fetchDeviceInfo() async {
    // Send "devinfo" message
    channel.sink.add("devinfo");

    // Listen for the response
    deviceInfo = await _waitForIntroduceMessage(messageList);
    ready = true;
  }

  // Private method to wait for "devinfo" response
  Future<Map<String, dynamic>?> _waitForIntroduceMessage(WsMessageList messageList) async {
    // Try every 50ms for 40 seconds to find the devinfo message in the message list
    const int maxRetries = 40 * 1000 ~/ 50; // 40 seconds with 50ms interval
    const Duration retryInterval = Duration(milliseconds: 50);
  
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      // Search for the "devinfo" message in the message list
      WsMessage? message = messageList.searchMessage(ipAddress, "devinfo");
      
      // If message is found, return it
      if (message != null) {
        return message.message;
      }
  
      // Wait for 50ms before retrying
      await Future.delayed(retryInterval);
    }
  
    // Return null if the message was not found within the timeout period
    return null; //TODO may not want null
  }
}

class WsDeviceList {
  // List to hold WsDevice instances
  final List<WsDevice> devices = [];

  // Method to add a device to the list
  void addDevice(WsDevice device) {
    devices.add(device);
  }

  // Method to remove a device based on the IP address
  void removeDevice(Map<String, String> ipAddress) {
    devices.removeWhere((device) => 
      device.ipAddress['ip'] == ipAddress['ip'] && 
      device.ipAddress['port'] == ipAddress['port']
    );
  }

  // Optional: Method to get the list of devices
  List<WsDevice> getDevices() {
    return List.from(devices); // Return a copy of the device list
  }

  // Optional: Method to find a device by IP address
  WsDevice? findDevice(Map<String, String> ipAddress) {
    try {
      return devices.firstWhere(
        (device) => device.ipAddress['ip'] == ipAddress['ip'] && 
                    device.ipAddress['port'] == ipAddress['port'],
        orElse: () => throw Exception('Device not found') // Throw an exception instead of returning null
      );
    } catch (e) {
      // Handle the case where no device is found
      print(e); // or log it as needed
      return null; // You can still return null here if desired
    }
  }
}

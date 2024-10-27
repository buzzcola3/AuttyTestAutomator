import 'dart:io';

import 'package:attempt_two/main_screen/device_list/websocket_manager/websocket_connection.dart';

class WsMessage {
  // Properties
  Map<String, String> device;
  String message;
  String? rawResponse;
  dynamic response;
  bool fulfiled = false;

  // Constructor
  WsMessage({
    required this.device, 
    required this.message, 
  });

  @override
  String toString() {
    return 'WsMessage(source: $device, message: $message)';
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
      if (_compareSource(message.device, source) && message.message == originalRequest) {
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
  final WebSocket? socket;
  final WebSocketController? wsController;

  Map<String, dynamic>? deviceInfo;
  WsMessageList messageList;

  bool ready = false;
  

  // Constructor
  WsDevice({
    required this.ipAddress,
    this.socket,
    this.wsController,
    required this.messageList,
    this.deviceInfo
    }){
    _fetchDeviceInfo();
  }

  // Method to fetch device info by sending "devinfo"
  Future<void> _fetchDeviceInfo() async {
    // Send "devinfo" message
    

    // Listen for the response
    while(deviceInfo == null){
      wsController?.sendMessage(ipAddress, "devinfo");
      deviceInfo = await _waitForIntroduceMessage(messageList);
    }
    
    ready = true;
  }

  // Private method to wait for "devinfo" response
  Future<Map<String, dynamic>?> _waitForIntroduceMessage(WsMessageList messageList) async {
    // Try every 50ms for 4 seconds to find the devinfo message in the message list
    const int maxRetries = 4 * 1000 ~/ 50; // 4 seconds with 50ms interval
    const Duration retryInterval = Duration(milliseconds: 50);
  
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      // Search for the "devinfo" message in the message list
      WsMessage? message = messageList.searchMessage(ipAddress, "devinfo");
      
      // If message is found, return it
      if (message!.response != null) {
        return message.response['RESPONSE'];
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

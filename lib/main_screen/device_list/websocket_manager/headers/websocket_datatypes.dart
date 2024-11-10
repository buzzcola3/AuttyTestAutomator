import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:attempt_two/global_datatypes/ip_address.dart';
import 'package:attempt_two/main_screen/device_list/websocket_manager/websocket_connection.dart';
import 'package:uuid/uuid.dart';

enum MessageType { generic, response, warning, error }

class WsMessage {
  // Properties
  IPAddress deviceIp;
  String message;
  late String uuid;
  String? rawResponse;
  dynamic response;
  bool fulfilled = false;
  int resendCount = 0;  // New property to track duplicates


  MessageType messageType = MessageType.generic;

  final void Function(String)? resendRequest;
  Timer? _statusCheckTimer;
  String lastStatus = "";

  // Constructor
  WsMessage({
    required this.deviceIp, 
    required this.message, 
    this.resendRequest,
  }) {
    final messageUuid = Uuid();
    uuid = messageUuid.v1();
    _startStatusCheck();
  }

  void _startStatusCheck() {
    _statusCheckTimer = Timer.periodic(Duration(seconds: 6), (timer) async {
      if (!fulfilled) {
        resendRequest!(uuid);
        resendCount++;
      } else {
        _statusCheckTimer?.cancel();
      }
    });
  }

  @override
  String toString() {
    return 'WsMessage(source: $deviceIp, message: $message, fulfilled: $fulfilled, duplicates: $resendCount)';
  }
}


class WsMessageList {
  List<WsMessage> messages = [];

  // Method to add a WsMessage to the list, with duplicate counting
  void addMessage(WsMessage message) {
    messages.add(message);  // Add new message if no duplicate
  }

  void addError(String errorMessage){
    final WsMessage wsMessage = WsMessage(
      deviceIp: IPAddress("", 0),
      message: errorMessage,
    );

    wsMessage.fulfilled = true;
    wsMessage.response = "";
    wsMessage.rawResponse = "";
    wsMessage.messageType = MessageType.error;

    messages.add(wsMessage);
  }

  // Method to search for a WsMessage by UUID
  WsMessage? searchMessage(String messageUuid) {
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].uuid == messageUuid) {
        return messages[i];
      }
    }
    return null;
  }


  // Method to search for a WsMessage starting from the most recent (last) message
  WsMessage? searchUnfulfilledMessage(String messageUuid) {
    for (int i = messages.length - 1; i >= 0; i--) {
      WsMessage message = messages[i];
      if (message.uuid == messageUuid) {
        if(message.fulfilled == false){
          return message;
        }
        
      }
    }
    return null; // Return null if no match is found
  }

  // Method to return all messages as a list
  List<WsMessage> getAllMessages() {
    return messages;
  }
}

class WsDevice {
  // Properties
  final IPAddress ipAddress;
  final WebSocket? socket;
  final WebSocketController? wsController;

  Map<String, dynamic>? deviceInfo;
  WsMessageList messageList;
  String deviceInfoUuid = "";
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
  //  _waitForIntroduceMessage(messageList);
  }

  Future<void> _fetchDeviceInfo() async {
    const int maxRetries = 40;
    const Duration retryInterval = Duration(seconds: 1);
    int attempt = 0;
  
    WsMessage? devInfoMessage;
    
    while (deviceInfo == null && attempt < maxRetries) {
      if (deviceInfoUuid.isEmpty) {
        devInfoMessage = wsController?.sendRequest(ipAddress, "DEVINFO", []);
        if (devInfoMessage != null) {
          deviceInfoUuid = devInfoMessage.uuid;
        }
      } else {
        wsController?.resendRequest(deviceInfoUuid);
      }
  
      // Increment attempt and wait for 1 second before retrying
      attempt++;
      await Future.delayed(retryInterval);
  
      // Check if device info has been received in this attempt
      WsMessage? message = messageList.searchMessage(deviceInfoUuid);
      if (message != null && message.response != null) {
        deviceInfo = jsonDecode(message.response['RESPONSE']);
        ready = true;
        return;  // Exit once deviceInfo is set
      }
    }
  
    // If deviceInfo is still null after 40 seconds, handle the failure
    if (deviceInfo == null) {
      print("Failed to fetch device info within the timeout period.");
      // You might set a flag here or take other steps as necessary
    }
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
  void removeDevice(IPAddress ipAddress) {
    devices.removeWhere((device) => 
      device.ipAddress == ipAddress
    );
  }

  // Optional: Method to get the list of devices
  List<WsDevice> getDevices() {
    return List.from(devices); // Return a copy of the device list
  }

  // Optional: Method to find a device by IP address
  WsDevice? findDevice(IPAddress ipAddress) {
    try {
      return devices.firstWhere(
        (device) => device.ipAddress == ipAddress,
        orElse: () => throw Exception('Device not found') // Throw an exception instead of returning null
      );
    } catch (e) {
      // Handle the case where no device is found
      print(e); // or log it as needed
      return null; // You can still return null here if desired
    }
  }
}

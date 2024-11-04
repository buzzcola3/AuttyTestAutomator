import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:attempt_two/main_screen/device_list/websocket_manager/websocket_connection.dart';
import 'package:uuid/uuid.dart';


class WsMessage {
  // Properties
  Map<String, String> device;
  String message;
  late String uuid;
  String? rawResponse;
  dynamic response;
  bool fulfilled = false;

  final void Function(Map<String, String>, String, List<String>) messageSendFunction;

  Timer? _statusCheckTimer;
  String lastStatus = "";

  // Constructor
  WsMessage({
    required this.device, 
    required this.message, 
    required this.messageSendFunction
  }) {
    final messageUuid = Uuid();
    uuid = messageUuid.v1();
    _startStatusCheck();
  }

  void _startStatusCheck() {
    _statusCheckTimer = Timer.periodic(Duration(seconds: 6), (timer) async {
      if (!fulfilled) {
        // Send "GET_STATUS" request
        Map<String, dynamic> originalMessage = jsonDecode(message);
        String originalCommand = originalMessage["COMMAND"];
        List<String> originalParameters = (originalMessage["PARAMETERS"] as List<dynamic>)
          .map((item) => item.toString())
          .toList();
        messageSendFunction(device, originalCommand, originalParameters);

      } else {
        // If fulfilled, stop the timer
        _statusCheckTimer?.cancel();
      }
    });
  }

  @override
  String toString() {
    return 'WsMessage(source: $device, message: $message, fulfilled: $fulfilled)';
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
  WsMessage? searchMessage(String messageUuid) {
    for (int i = messages.length - 1; i >= 0; i--) {
      WsMessage message = messages[i];
      if (message.uuid == messageUuid) {
        return message;
      }
    }
    return null; // Return null if no match is found
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
  final Map<String, String> ipAddress;
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

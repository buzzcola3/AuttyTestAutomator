import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:attempt_two/main_screen/communication_panel/communication_panel.dart';
import 'package:attempt_two/global_datatypes/device_info.dart';
import 'package:attempt_two/global_datatypes/ip_address.dart';
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
    const messageUuid = Uuid();
    uuid = messageUuid.v1();
    _startStatusCheck();
  }

  void _startStatusCheck() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 6), (timer) async {
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
  DebugConsoleController? debugConsole;

  final IPAddress ipAddress;
  WebSocket? socket;
  DeviceInfo? deviceInfo;
  bool ready = false;
  
  WsDevice({
    this.debugConsole,
    required this.ipAddress,
    this.deviceInfo,
    }){

    _startConnection();
  }

  WsMessageList wsMessageList = WsMessageList();

  void sendMessage(){
    //TODO implement, make sending command use this??

  }

  WsMessage sendRequest(String command, List<String> parameters){
    final WsMessage wsMessage = WsMessage(
      deviceIp: ipAddress,
      message: jsonEncode({"COMMAND": command, "PARAMETERS": parameters}),
      resendRequest: resendRequest,
    );

    socket?.add(jsonEncode({"REQUEST": wsMessage.message, "UUID": wsMessage.uuid}));

    wsMessageList.addMessage(wsMessage);
    debugConsole?.addMessage(wsMessage);
    return wsMessage;
  }

  void resendRequest(String uuid){
    WsMessage? message = wsMessageList?.searchMessage(uuid);
    socket?.add(jsonEncode({"REQUEST": message?.message, "UUID": message?.uuid}));
  }

  Future<WsMessage> sendAwaitedRequest(String command, List<String> parameters) async {
    WsMessage awaitedMessage = sendRequest(command, parameters);

    while (awaitedMessage.fulfilled == false) {
      await Future.delayed(const Duration(milliseconds: 100)); // adjust delay as needed
    }

    return awaitedMessage;
  }

  void receiveResponse(String incomingMessage){
    Map<String, dynamic> decodedMessage = jsonDecode(incomingMessage);
    String messageUuid = decodedMessage["UUID"];
    WsMessage? ogMessage = wsMessageList.searchUnfulfilledMessage(messageUuid);

    ogMessage?.response = decodedMessage;
    ogMessage?.rawResponse = incomingMessage;
    ogMessage?.fulfilled = true;
  }

  Future<void> _attemptReconnection() async {
    const Duration initialDelay = Duration(seconds: 1);
    const Duration maxDelay = Duration(minutes: 2);

    deviceInfo = null;
    ready = false;
  
    Duration currentDelay = initialDelay;
  
    while (ready == false) {
      print("reconencting");
      await _startConnection();
  
      // Wait for the current delay duration before retrying
      await Future.delayed(currentDelay);
  
      // Increase the delay exponentially, but cap it at maxDelay
      currentDelay = Duration(seconds: (currentDelay.inSeconds * 2).clamp(1, maxDelay.inSeconds));
    }
  }


  Future<void> _startConnection() async {
    if(deviceInfo != null){ //TODO workarround for internal device
      ready = true; 
      return;
    }

    bool connectionFailed = true;

    try {
      socket = await WebSocket.connect('ws://$ipAddress');
      print('WebSocket connected to $ipAddress');
      connectionFailed = false;
  
      socket?.listen(
        (incomingMessage) {
          print("{___________________RXXXXXXXXXXXXXXXX}");
          receiveResponse(incomingMessage);
        },
        onDone: () async {
          print('WebSocket connection closed for $ipAddress, attemptig reconnection');
          await _attemptReconnection();
          
        },
        onError: (error) {
          print('Error occurred on WebSocket connection: $error');
        },
        cancelOnError: true,
      );
  
    } catch (e) {
      print('Failed to connect to WebSocket at $ipAddress}: $e');
      connectionFailed = true;
    }

    if(connectionFailed == false){
      WsMessage devInfoMessage = await sendAwaitedRequest("DEVINFO", []);
      deviceInfo = DeviceInfo(devInfoMessage.response["RESPONSE"]);
      ready = true; 
    }
  }




  IPAddress get getIPAddress{
    return ipAddress;
  }


  WebSocket? get getWebSocket{
    return socket;
  }

  set setWebSocket(WebSocket? newSocket){
    socket = newSocket;
  }
}

class WsDeviceList {
  // List to hold WsDevice instances
  final List<WsDevice> devices = [];

  // Method to add a device to the list
  Future<void> addDevice(WsDevice device) async {

    while (device.ready == false) {
      await Future.delayed(const Duration(milliseconds: 100)); // adjust delay as needed
    }

    WsDevice? duplicateDevice = findDevice(device.deviceInfo!.deviceUniqueId);
    if (duplicateDevice != null) {
      removeDevice(duplicateDevice.ipAddress);
    }

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

  WsDevice? findDevice(String deviceUniqueId){
    try {
      return devices.firstWhere(
        (device) => device.deviceInfo?.deviceUniqueId == deviceUniqueId,
        orElse: () => throw Exception('Device not found') // Throw an exception instead of returning null
      );
    } catch (e) {
      // Handle the case where no device is found
      print(e); // or log it as needed
      return null; // You can still return null here if desired
    }
  }
}

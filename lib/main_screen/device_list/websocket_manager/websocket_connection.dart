import 'ip_scanner/ip_scanner.dart';
import 'dart:io';
import 'dart:convert';
import 'headers/websocket_datatypes.dart';




class WebSocketController {
  late WsDeviceList wsDeviceList;
  late WsMessageList wsMessageList;
  late IPScanner ipScanner;

  void Function()? newConnectionNotifyFunction;
  void Function()? messageChangeNotifyFunction;
  void Function(bool)? scanDoneNotifyFunction;

  WebSocketController({
    this.newConnectionNotifyFunction,
    this.messageChangeNotifyFunction,
    this.scanDoneNotifyFunction,
    required this.wsDeviceList,
    required this.wsMessageList,
  }) {
    ipScanner = IPScanner(deviceChangeNotifyFunction: updateWebsocketConnections, scanDoneNotifyFunction: scanDoneNotifyFunction);
    ipScanner.ipResponding("127.0.0.1", "80");
    ipScanner.ipResponding("127.0.0.1", "81");
    ipScanner.ipResponding("127.0.0.1", "82");
    ipScanner.ipResponding("192.168.16.102", "80");
    //ipScanner.fullScan();
  }

  Future<void> updateWebsocketConnections(Map<String, String> ipAddress) async {  
    try {
      final WebSocket socket = await WebSocket.connect('ws://${ipAddress['ip']}:${ipAddress['port']}');
      print('WebSocket connected to ${ipAddress['ip']} on port ${ipAddress['port']}');

      socket.listen(
        (incomingMessage) {
          print("{___________________RXXXXXXXXXXXXXXXX}");
          receiveMessage(ipAddress, incomingMessage);
        },
        onDone: () {
          print('WebSocket connection closed for ${ipAddress['ip']} on port ${ipAddress['port']}');
          wsDeviceList.removeDevice(ipAddress);
        },
        onError: (error) {
          print('Error occurred on WebSocket connection: $error');
          wsDeviceList.removeDevice(ipAddress);
        },
        cancelOnError: true,
      );

      WsDevice newDevice = WsDevice(ipAddress: ipAddress, socket: socket, wsController: this, messageList: wsMessageList);
      wsDeviceList.addDevice(newDevice);

      while (!newDevice.ready) {
        await Future.delayed(Duration(milliseconds: 300));
      }

      newConnectionNotifyFunction?.call(); // Only call if not null
    } catch (e) {
      print('Failed to connect to WebSocket at ${ipAddress['ip']} on port ${ipAddress['port']}: $e');
    }
  }

  void receiveMessage(Map<String, String> messageSource, String incomingMessage) {
    Map<String, dynamic> decodedMessage = jsonDecode(incomingMessage);
    String ogRequest = decodedMessage["FOR_REQUEST"];
    WsMessage? ogMessage = wsMessageList.searchMessage(messageSource, ogRequest);

    ogMessage?.response = decodedMessage;
    ogMessage?.rawResponse = incomingMessage;
    ogMessage?.fulfiled = true;

    messageChangeNotifyFunction?.call();


    //check response wait list, and assign the response
  }

  WsMessage sendMessage(Map<String, String> deviceIp, String message){
    final WsMessage wsMessage = WsMessage(
      device: deviceIp,
      message: message,
    );

    for (var wsDevice in this.wsDeviceList.devices) {
      if(wsDevice.ipAddress['ip'] == deviceIp['ip'] && wsDevice.ipAddress['port'] == deviceIp['port']){
        wsDevice.socket?.add(message);
      }
      //TODO if no message gets sent, device no longer exists
    }

    wsMessageList.addMessage(wsMessage);
    messageChangeNotifyFunction?.call();
    return wsMessage;
  }

  Future<WsMessage> awaitRequest(Map<String, String> deviceIp, String message) async {
    // Send the message and get the WsMessage instance
    final WsMessage wsMessage = sendMessage(deviceIp, message);
  
    // Polling to check for a response
    while (wsMessage.rawResponse == null) {
      await Future.delayed(Duration(milliseconds: 100)); // adjust delay as needed
    }

    //TODO make it fail after 5min
  
    // Return the WsMessage with the response
    return wsMessage;
  }

  
  Map<String, String>? getDeviceIp(String deviceUniqueId){
    for (var wsDevice in wsDeviceList.devices) {
      if(wsDevice.deviceInfo?["UNIQUE_ID"] == deviceUniqueId){
        return wsDevice.ipAddress;
      }
    }
    return null;
  }

}

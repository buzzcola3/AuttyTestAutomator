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
    ipScanner.ipResponding("192.168.16.111", "80");
    ipScanner.ipResponding("192.168.16.111", "81");
    ipScanner.ipResponding("192.168.16.111", "82");
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
    String messageUuid = decodedMessage["UUID"];
    WsMessage? ogMessage = wsMessageList.searchUnfulfilledMessage(messageUuid);

    ogMessage?.response = decodedMessage;
    ogMessage?.rawResponse = incomingMessage;
    ogMessage?.fulfilled = true;

    messageChangeNotifyFunction?.call();

    //check response wait list, and assign the response
  }

  void sendMessage(Map<String, String> deviceIp, String command, List<String> parameters, String? uuid){
    final WsMessage wsMessage = WsMessage(
      device: deviceIp,
      message: jsonEncode({"COMMAND": command, "PARAMETERS": parameters}),
      messageSendFunction: sendMessage,
    );

    wsMessage.fulfilled = true;
    wsMessage.response = "";
    wsMessage.rawResponse = "";

    uuid ??= wsMessage.uuid;

    for (var wsDevice in wsDeviceList.devices) {
      if(wsDevice.ipAddress['ip'] == deviceIp['ip'] && wsDevice.ipAddress['port'] == deviceIp['port']){
        wsDevice.socket?.add(jsonEncode({"REQUEST": wsMessage.message, "UUID": uuid}));
      }
      //TODO if no message gets sent, device no longer exists
    }

    wsMessageList.addMessage(wsMessage);
    messageChangeNotifyFunction?.call();
    return;
  }

  WsMessage sendRequest(Map<String, String> deviceIp, String command, List<String> parameters){
    final WsMessage wsMessage = WsMessage(
      device: deviceIp,
      message: jsonEncode({"COMMAND": command, "PARAMETERS": parameters}),
      messageSendFunction: sendMessage,
    );

    for (var wsDevice in wsDeviceList.devices) {
      if(wsDevice.ipAddress['ip'] == deviceIp['ip'] && wsDevice.ipAddress['port'] == deviceIp['port']){
        wsDevice.socket?.add(jsonEncode({"REQUEST": wsMessage.message, "UUID": wsMessage.uuid}));
      }
      //TODO if no message gets sent, device no longer exists
    }

    wsMessageList.addMessage(wsMessage);
    messageChangeNotifyFunction?.call();
    return wsMessage;
  }

  void resendRequest(String uuid){
    WsMessage? message = wsMessageList.searchMessage(uuid);

    for (var wsDevice in wsDeviceList.devices) {
      if(wsDevice.ipAddress['ip'] ==  message?.device['ip'] && wsDevice.ipAddress['port'] ==  message?.device['port']){
        wsDevice.socket?.add(jsonEncode({"REQUEST": message?.message, "UUID": message?.uuid}));
        return;
      }
    }

  }

  Future<WsMessage> awaitRequest(Map<String, String> deviceIp, String command, List<String> parameters) async {
    // Send the message and get the WsMessage instance
    final WsMessage wsMessage = sendRequest(deviceIp, command, parameters);
  
    // Polling to check for a response
    while (wsMessage.rawResponse == null) {
      await Future.delayed(Duration(milliseconds: 100)); // adjust delay as needed
    }
  
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

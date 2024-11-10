import 'package:attempt_two/global_datatypes/ip_address.dart';

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
  }

  Future<void> updateWebsocketConnections(IPAddress ipAddress) async {  
    try {
      final WebSocket socket = await WebSocket.connect('ws://$ipAddress');
      print('WebSocket connected to $ipAddress');

      socket.listen(
        (incomingMessage) {
          print("{___________________RXXXXXXXXXXXXXXXX}");
          receiveMessage(incomingMessage);
        },
        onDone: () {
          print('WebSocket connection closed for $ipAddress');
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
      print('Failed to connect to WebSocket at $ipAddress}: $e');
    }
  }

  void receiveMessage(String incomingMessage) {
    Map<String, dynamic> decodedMessage = jsonDecode(incomingMessage);
    String messageUuid = decodedMessage["UUID"];
    WsMessage? ogMessage = wsMessageList.searchUnfulfilledMessage(messageUuid);

    ogMessage?.response = decodedMessage;
    ogMessage?.rawResponse = incomingMessage;
    ogMessage?.fulfilled = true;

    messageChangeNotifyFunction?.call();

    //check response wait list, and assign the response
  }

  void sendMessage(IPAddress deviceIp, String command, List<String> parameters){
    final WsMessage wsMessage = WsMessage(
      deviceIp: deviceIp,
      message: jsonEncode({"COMMAND": command, "PARAMETERS": parameters}),
      resendRequest: resendRequest,
    );

    wsMessage.fulfilled = true;
    wsMessage.response = "";
    wsMessage.rawResponse = "";


    for (var wsDevice in wsDeviceList.devices) {
      if(wsDevice.ipAddress == deviceIp){
        wsDevice.socket?.add(jsonEncode({"REQUEST": wsMessage.message}));
      }
      //TODO if no message gets sent, device no longer exists
    }

    wsMessageList.addMessage(wsMessage);
    messageChangeNotifyFunction?.call();
    return;
  }

  WsMessage sendRequest(IPAddress deviceIp, String command, List<String> parameters){
    final WsMessage wsMessage = WsMessage(
      deviceIp: deviceIp,
      message: jsonEncode({"COMMAND": command, "PARAMETERS": parameters}),
      resendRequest: resendRequest,
    );

    for (var wsDevice in wsDeviceList.devices) {
      if(wsDevice.ipAddress == deviceIp){ //TODO, maybe use the get device by uuid to do this? why am I always finding by ip and looping?
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
      if(wsDevice.ipAddress ==  message?.deviceIp){
        wsDevice.socket?.add(jsonEncode({"REQUEST": message?.message, "UUID": message?.uuid}));
        return;
      }
    }

  }

  Future<WsMessage> awaitRequest(IPAddress deviceIp, String command, List<String> parameters) async {
    // Send the message and get the WsMessage instance
    final WsMessage wsMessage = sendRequest(deviceIp, command, parameters);
  
    // Polling to check for a response
    while (wsMessage.rawResponse == null) {
      await Future.delayed(Duration(milliseconds: 100)); // adjust delay as needed
    }
  
    // Return the WsMessage with the response
    return wsMessage;
  }

  
  IPAddress? getDeviceIp(String deviceUniqueId){
    for (var wsDevice in wsDeviceList.devices) {
      if(wsDevice.deviceInfo?["UNIQUE_ID"] == deviceUniqueId){
        return wsDevice.ipAddress;
      }
    }
    return null;
  }

}

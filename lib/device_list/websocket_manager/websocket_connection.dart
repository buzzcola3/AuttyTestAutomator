import 'ip_scanner/ip_scanner.dart';
import 'dart:io';
import 'dart:convert';
import 'headers/websocket_datatypes.dart';




class WebSocketController {
  late WsDeviceList wsDeviceList;
  late WsMessageList wsMessageList;
  bool scanning = true;
  late IPScanner ipScanner;

  final void Function() newConnectionNotifyFunction;

  final void Function(WsMessage) messageChangeNotifyFunction;


  WebSocketController({
      required this.newConnectionNotifyFunction,
      required this.messageChangeNotifyFunction,
      required this.wsDeviceList,
      required this.wsMessageList
  }){
    IPScanner ipScanner = IPScanner(deviceChangeNotifyFunction: updateWebsocketConnections);
    ipScanner.ipResponding("127.0.0.1", "80");
    ipScanner.ipResponding("127.0.0.1", "81");
    ipScanner.ipResponding("127.0.0.1", "82");
    ipScanner.ipResponding("192.168.16.102", "80");
    //ipScanner.fullScan();
  }

  Future<WsMessage?> waitForIntroduceMessage(Map<String, String> ipAddress) async {
    const int retryIntervalMs = 50; // Retry every 50 milliseconds
    const int maxDurationMs = 40000; // Maximum duration of 40 seconds
    const int maxRetries = maxDurationMs ~/ retryIntervalMs; // Total number of retries
  
    WsMessage? foundMessage;
  
    for (int i = 0; i < maxRetries; i++) {
      // Try to search for the message
      foundMessage = wsMessageList.searchMessage(ipAddress, "introduce");
  
      // If message is found, return it
      if (foundMessage != null) {
        return foundMessage;
      }
  
      // Wait for the retry interval (50ms) before trying again
      await Future.delayed(Duration(milliseconds: retryIntervalMs));
    }
  
    // Return null if no message is found after the maximum retries
    return null;
  }
  
  
  Future<void> updateWebsocketConnections(Map<String, String> ipAddress) async {  
    try {
      // Establish WebSocket connection using dart:io
      final WebSocket socket = await WebSocket.connect('ws://${ipAddress['ip']}:${ipAddress['port']}');
      print('WebSocket connected to ${ipAddress['ip']} on port ${ipAddress['port']}');
  
      socket.listen(
        (incomingMessage) {
          // Handle incoming message
          receiveMessage(ipAddress, incomingMessage);
        },
        onDone: () {
          // Handle when the WebSocket connection is closed
          print('WebSocket connection closed for ${ipAddress['ip']} on port ${ipAddress['port']}');
          wsDeviceList.removeDevice(ipAddress);
        },
        onError: (error) {
          // Handle any error that occurs during WebSocket communication
          print('Error occurred on WebSocket connection: $error');
          wsDeviceList.removeDevice(ipAddress); // Remove device on error
        },
        cancelOnError: true, // Automatically cancel the subscription if an error occurs
      );
  
      // Add the WebSocket to your list of devices
      WsDevice newDevice = WsDevice(ipAddress: ipAddress, socket: socket, messageList: wsMessageList);
      wsDeviceList.addDevice(newDevice);
  
      // Wait until the WebSocket is ready (or some condition is met)
      while (!newDevice.ready) {
        await Future.delayed(Duration(milliseconds: 300)); // Avoid busy-waiting
      }
  
      newConnectionNotifyFunction(); // Notify that a new connection has been made
    } catch (e) {
      // Handle connection errors
      print('Failed to connect to WebSocket at ${ipAddress['ip']} on port ${ipAddress['port']}: $e');
    }
  }

  void receiveMessage(Map<String, String> messageSource, String incommingMessage) {
    Map<String, dynamic> decodedMessage = jsonDecode(incommingMessage);
    String ogRequest = decodedMessage["FOR_REQUEST"];
    final WsMessage message = WsMessage(source: messageSource, message: decodedMessage["RESPONSE"], originalRequest: ogRequest);

    wsMessageList.addMessage(message);

    messageChangeNotifyFunction(message);
    // Code to establish WebSocket connection
  }

  // Method to send a message
  void sendMessage(Map<String, dynamic> message, Map<String, String> ipAddress) {
    //final wsPayload = jsonEncode(message);
    //TODO implement me
  }
}

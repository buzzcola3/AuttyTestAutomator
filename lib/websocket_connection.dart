import 'ip_scanner.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'websocket_datatypes.dart';




class WebSocketController {
  WsDeviceList deviceList = WsDeviceList();
  WsMessageList wsCommunication = WsMessageList();
  bool scanning = true;
  late IPScanner ipScanner;

  final void Function() newConnectionNotifyFunction;

  final void Function(WsMessage) messageChangeNotifyFunction;


  WebSocketController({required this.newConnectionNotifyFunction, required this.messageChangeNotifyFunction}) {
    IPScanner ipScanner = IPScanner(deviceChangeNotifyFunction: updateWebsocketConnections);
    ipScanner.fullScan();
    //ipScanner.ipResponding("192.168.16.110", "80");
    
  }

  Future<WsMessage?> waitForIntroduceMessage(Map<String, String> ipAddress) async {
    const int retryIntervalMs = 50; // Retry every 50 milliseconds
    const int maxDurationMs = 40000; // Maximum duration of 40 seconds
    const int maxRetries = maxDurationMs ~/ retryIntervalMs; // Total number of retries
  
    WsMessage? foundMessage;
  
    for (int i = 0; i < maxRetries; i++) {
      // Try to search for the message
      foundMessage = wsCommunication.searchMessage(ipAddress, "introduce");
  
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
    if(ipAddress['ip'] == "" && ipAddress['port'] == ""){
      scanning = ipScanner.scanning;
      newConnectionNotifyFunction(); //update ui (scanning finished)
      return;
    }

    final channel = WebSocketChannel.connect(Uri.parse('ws://${ipAddress['ip']}:${ipAddress['port']}'));

    channel.stream.listen(
      (incomingMessage) {
        // Handle incoming message
        receiveMessage(ipAddress, incomingMessage);
      },
      onDone: () {
        // Handle when the channel closes
        print('WebSocket connection closed for ${ipAddress['ip']} on port ${ipAddress['port']}');
        // You can also remove the closed WebSocket from your list if needed
        deviceList.removeDevice(ipAddress);
      },
      onError: (error) {
        // Handle any error that occurs during the WebSocket communication
        print('Error occurred on WebSocket connection: $error');
      },
      cancelOnError: true, // Automatically cancel the subscription if an error occurs
    );

    WsDevice newDevice = WsDevice(ipAddress: ipAddress, channel: channel, messageList: wsCommunication);
    deviceList.addDevice(newDevice);

    while (!newDevice.ready) {
      await Future.delayed(Duration(milliseconds: 100)); // Delay to avoid busy-waiting
    }

    newConnectionNotifyFunction();
  }

  void receiveMessage(Map<String, String> messageSource, String incommingMessage) {
    Map<String, dynamic> decodedMessage = jsonDecode(incommingMessage);
    String ogRequest = decodedMessage["FOR_REQUEST"];
    final WsMessage message = WsMessage(source: messageSource, message: decodedMessage["RESPONSE"], originalRequest: ogRequest);

    wsCommunication.addMessage(message);

    messageChangeNotifyFunction(message);
    // Code to establish WebSocket connection
  }

  // Method to send a message
  void sendMessage(Map<String, dynamic> message, Map<String, String> ipAddress) {
    //final wsPayload = jsonEncode(message);
    //TODO implement me
  }
}

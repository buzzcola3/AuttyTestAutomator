import 'ip_scanner.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class WebSocketController {
  List<Map<String, String>> ipList = [];
  List<WebSocketChannel> websocketConnections = [];

  final void Function(Map<String, String>) newConnectionNotifyFunction;
  //example:
  //Map<String, String> --> {'ip': '192.168.1.24' 'port': "80"}

  final void Function(Map<String, Map<String, dynamic>>) messageChangeNotifyFunction;
  //example:
  //{
  //  'source':
  //    {
  //      'ip': '192.168.1.24',
  //      'port': '80',
  //    }
  //  'message':
  //    {
  //      'RESPONSE': 'ok',
  //    }
  //}


  WebSocketController({required this.newConnectionNotifyFunction, required this.messageChangeNotifyFunction}) {
    IPScanner ipScanner = IPScanner(deviceChangeNotifyFunction: updateWebsocketConnections);
    ipScanner.fullScan();
    
  }

  void updateWebsocketConnections(Map<String, String> ipAddress){
    ipList.add(ipAddress);
    final channel = WebSocketChannel.connect(Uri.parse('ws://${ipAddress['ip']}:${ipAddress['port']}'));
    websocketConnections.add(channel);
    newConnectionNotifyFunction(ipAddress);

    channel.stream.listen(
      (incomingMessage) {
        // Handle incoming message
        receiveMessage(ipAddress, incomingMessage);
      },
      onDone: () {
        // Handle when the channel closes
        print('WebSocket connection closed for ${ipAddress['ip']} on port ${ipAddress['port']}');
        // You can also remove the closed WebSocket from your list if needed
        websocketConnections.remove(channel);
        ipList.remove(ipAddress);
      },
      onError: (error) {
        // Handle any error that occurs during the WebSocket communication
        print('Error occurred on WebSocket connection: $error');
      },
      cancelOnError: true, // Automatically cancel the subscription if an error occurs
    );
  }

  void receiveMessage(Map<String, String> messageSource, String incommingMessage) {
    Map<String, dynamic> decodedMessage = jsonDecode(incommingMessage);
    final Map<String, Map<String, dynamic>> message = {"source": messageSource, "message": decodedMessage};
    messageChangeNotifyFunction(message);
    // Code to establish WebSocket connection
  }

  // Method to send a message
  void sendMessage(Map<String, dynamic> message, Map<String, String> ipAddress) {
    final wsPayload = jsonEncode(message);
    //TODO implement me
  }
}

import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:attempt_two/global_datatypes/ip_address.dart';

class IPScanner {
  // Properties
  String lastScanned = "";
  final void Function(IPAddress) deviceChangeNotifyFunction; // Function to notify device changes
  final void Function(bool)? scanDoneNotifyFunction;

  // Constructor that takes in a function
  IPScanner({required this.deviceChangeNotifyFunction, required this.scanDoneNotifyFunction});

  Future<void> scanSubnet(IPAddress subnetIp) async {
    List<Future> futures = [];
    String subnet = subnetIp.ip;

    List<String> octets = subnet.split('.');
    // Check if the last octet is '0' and remove it
    if (octets.isNotEmpty && octets.last == '0') {
      octets.removeLast();
    }
    subnet = octets.join('.'); // Reassemble the IP address

    //scanDoneNotifyFunction!(true);

    for (int i = 0; i < 255; i++) {
      final String ipAddress = '$subnet.$i';

      // Delay the start of each new instance by 200 milliseconds
      futures.add(Future.delayed(Duration(milliseconds: i * 200), () async {
        await attemptConnection(IPAddress(ipAddress, subnetIp.port));

      }));
    }

    // Wait for all ipResponding instances to complete
    await Future.wait(futures);
    //scanDoneNotifyFunction!(false);

    return;
  }

Future<void> attemptConnection(IPAddress ip) async {
  try {
    WebSocket socket = await WebSocket.connect('ws://$ip');
    print('Connected to server!');

    bool responded = false;
    bool stopPinging = false;
    
    late StreamSubscription subscription;
    subscription = socket.listen((message) {
      Map<String, dynamic> decodedMessage = jsonDecode(message);
      print('Received message: $message');

      if (decodedMessage["RESPONSE"] == 'OK' && decodedMessage["UUID"] == 'PING') {
        print('Server responded to ping.');
        deviceChangeNotifyFunction(ip);
        responded = true;
        stopPinging = true; // Stop further ping attempts
        socket.close();
        subscription.cancel();
      }
    });

    // Timer to send pings every second for 20 seconds
    for (int i = 0; i < 40; i++) {
      if (stopPinging) break; // Stop if server responded
      String request = """{"COMMAND": "PING", "PARAMETERS": ""}""";
      socket.add(jsonEncode({"REQUEST": request, "PARAMETERS": "", "UUID": "PING"}));
      await Future.delayed(Duration(seconds: 1));
    }

    // If no response after 40 seconds, close the socket and cancel subscription
    if (!responded) {
      print('No response after 40 seconds. Disconnecting...');
      socket.close();
      subscription.cancel();
    }
  } catch (e) {
    print('Error: $e');
  }
}
}

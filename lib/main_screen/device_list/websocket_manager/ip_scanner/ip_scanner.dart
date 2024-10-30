import 'dart:io';
import 'dart:convert';
import 'dart:async';

class IPScanner {
  // Properties
  String lastScanned = "";
  final void Function(Map<String, String>) deviceChangeNotifyFunction; // Function to notify device changes
  final void Function(bool)? scanDoneNotifyFunction;

  // Constructor that takes in a function
  IPScanner({required this.deviceChangeNotifyFunction, required this.scanDoneNotifyFunction});

  void discoverSubnets() {
    // TODO: Implement subnet discovery logic
  }

  Future<void> scanSubnet(String subnet, String port) async {
    List<Future> futures = [];

    //scanDoneNotifyFunction!(true);

    for (int i = 0; i < 255; i++) {
      final String ipAddress = '$subnet.$i';

      // Delay the start of each new instance by 200 milliseconds
      futures.add(Future.delayed(Duration(milliseconds: i * 200), () async {
        await ipResponding(ipAddress, port);

      }));
    }

    // Wait for all ipResponding instances to complete
    await Future.wait(futures);
    //scanDoneNotifyFunction!(false);

    return;
  }

Future<void> ipResponding(String ip, String port) async {
  try {
    WebSocket socket = await WebSocket.connect('ws://$ip:$port');
    print('Connected to server!');

    bool responded = false;
    bool stopPinging = false;
    
    late StreamSubscription subscription;
    subscription = socket.listen((message) {
      Map<String, dynamic> decodedMessage = jsonDecode(message);
      print('Received message: $message');

      if (decodedMessage["RESPONSE"] == 'ok' && decodedMessage["FOR_REQUEST"] == 'ping') {
        print('Server responded to ping.');
        Map<String, String> newDevice = {"ip": ip, "port": port};
        deviceChangeNotifyFunction(newDevice);
        responded = true;
        stopPinging = true; // Stop further ping attempts
        socket.close();
        subscription.cancel();
      }
    });

    // Timer to send pings every second for 20 seconds
    for (int i = 0; i < 40; i++) {
      if (stopPinging) break; // Stop if server responded
      socket.add('ping');
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

  Future<void> fullScan({String port = "80"}) async {
    final List<String> subnets = ["192.168.0", "192.168.1", "192.168.4", "192.168.16"]; //TODO discover subnets

    //scanDoneNotifyFunction!(true);

    for (String subnet in subnets) {
      await scanSubnet(subnet, port);
    }

    //scanDoneNotifyFunction!(false);

    return;
  }
}

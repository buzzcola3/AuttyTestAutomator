import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';

class IPScanner {
  // Properties
  bool scanning = false;
  String lastScanned = "";
  final void Function(Map<String, String>) deviceChangeNotifyFunction; // Function to notify device changes

  // Constructor that takes in a function
  IPScanner({required this.deviceChangeNotifyFunction});

  void discoverSubnets() {
    // TODO: Implement subnet discovery logic
  }

  Future<void> scanSubnet(String subnet, String port) async {
    List<Future> futures = [];

    scanning = true;

    for (int i = 0; i < 255; i++) {
      final String ipAddress = '$subnet.$i';

      // Delay the start of each new instance by 200 milliseconds
      futures.add(Future.delayed(Duration(milliseconds: i * 200), () async {
        await ipResponding(ipAddress, port);

      }));
    }

    // Wait for all ipResponding instances to complete
    await Future.wait(futures);
    scanning = false;

    return;
  }

  Future<bool> ipResponding(String ip, String port) async {
    final Completer<bool> completer = Completer<bool>();

    try {
      final channel = WebSocketChannel.connect(Uri.parse('ws://$ip:$port'));

      channel.sink.add('ping');

      channel.stream.listen((message) {
        Map<String, dynamic> decodedMessage = jsonDecode(message);
        if (decodedMessage["RESPONSE"] == 'ok') {
          Map<String, String> newDevice = {"ip": ip, "port": port};
          deviceChangeNotifyFunction(newDevice);
          completer.complete(true);
        }
      }, onError: (error) {
        completer.complete(false);
      }, onDone: () {
        channel.sink.close();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });

      // Timeout after a certain duration if no response is received
      Future.delayed(const Duration(seconds: 5)).then((_) {
        if (!completer.isCompleted) {
          completer.complete(false);
          channel.sink.close();
        }
      });
    } catch (e) {
      completer.complete(false);
    }

    lastScanned = '$ip:$port';
    return completer.future;
  }

  Future<void> fullScan({String port = "80"}) async {
    final List<String> subnets = ["192.168.0", "192.168.1", "192.168.4", "192.168.16"]; //TODO discover subnets

    for (String subnet in subnets) {
      await scanSubnet(subnet, port);
    }

    scanning = false;
    deviceChangeNotifyFunction({"": ""}); //trugger ui update

    return;
  }
}

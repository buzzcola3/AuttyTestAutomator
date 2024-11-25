import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:Autty/global_datatypes/ip_address.dart';
import 'package:Autty/global_datatypes/json.dart';

class IPScanner {
  // Properties
  IPAddress lastScanned = IPAddress("", 0);
  bool scanning = false;
  List<IPAddress> respondingDevices = [];
  List<IPAddress> pendingDevices = [];
  final void Function()? notifyChangeIPScanner;

  // Constructor that takes in a function
  IPScanner({required this.notifyChangeIPScanner});

  void forgetDevice(IPAddress ip){
    if (!respondingDevices.contains(ip)) {
      respondingDevices.removeWhere((scannedIp) => scannedIp == ip);
    }
  }

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

  Future<void> scanPorts(IPAddress ipAddress, int startPort, int endPort) async {
    if (startPort > endPort) {
      print("Invalid port range. Please check your input.");
      return;
    }
    if (endPort - startPort >  64){
      print("Too many ports to scan. Please limit port range to a maximum of 64 ports.");
      return;
    }
    if (startPort < 1) startPort = 1;

    // Loop through the port range
    for (int currentPort = startPort; currentPort <= endPort; currentPort++) {
      final currIPAddress = IPAddress(ipAddress.ip, currentPort);
      
      // Attempt to connect to each port
      attemptConnection(currIPAddress);
    }
  }

  Future<void> attemptConnection(IPAddress ip) async {
    pendingDevices.add(ip);
    scanning = true;
    try {
      WebSocket socket = await WebSocket.connect('ws://$ip');
      print('Connected to server!');
  
      bool responded = false;
      bool stopPinging = false;
      
      late StreamSubscription subscription;
      subscription = socket.listen((message) {
        Json decodedMessage = jsonDecode(message);
        print('Received message: $message');
  
        if (decodedMessage["RESPONSE"] == 'OK' && decodedMessage["UUID"] == 'PING') {
          print('Server responded to ping.');

          if (!respondingDevices.contains(ip)) {
            respondingDevices.add(ip);
          }
  
          pendingDevices.removeWhere((scannedIp) => scannedIp == ip);
          if(pendingDevices.isEmpty){
            scanning = false;
          }

          lastScanned = ip;
          notifyChangeIPScanner!();

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

        pendingDevices.removeWhere((scannedIp) => scannedIp == ip);
        if (!respondingDevices.contains(ip)) {
          respondingDevices.removeWhere((scannedIp) => scannedIp == ip);
        }

        if(pendingDevices.isEmpty){
          scanning = false;
        }
        lastScanned = ip;

        notifyChangeIPScanner!();

        print('No response after 40 seconds. Disconnecting...');
        socket.close();
        subscription.cancel();
      }
    } catch (e) {
      pendingDevices.removeWhere((scannedIp) => scannedIp == ip);
      if (!respondingDevices.contains(ip)) {
        respondingDevices.removeWhere((scannedIp) => scannedIp == ip);
      }

      if(pendingDevices.isEmpty){
        scanning = false;
      }
      lastScanned = ip;
      notifyChangeIPScanner!();
      //print('Error: $e');
    }
  }
}
  
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import "package:attempt_two/nodes/node_panels/node_preview.dart"; // Import the NodePreview widget

class DeviceScanner extends StatefulWidget {
  @override
  _DeviceScannerState createState() => _DeviceScannerState();
}

class _DeviceScannerState extends State<DeviceScanner> {
  List<String> ipScanList = ["192.168.16"];
  bool scanning = false;
  List<Map<String, dynamic>> respondingDevices = [];
  bool showOverlay = false;
  Map<String, dynamic>? selectedDevice; // Add a variable to hold the selected device

  @override
  void initState() {
    super.initState();
    fetchLocalSubnet();
  }

  Future<void> findDevicesOnSubnet(String localSubnet) async {
      List<String> respondingIpAddresses = [];
      for (int i = 98; i < 150; i++) {
          final ipAddress = 'ws://$localSubnet.$i:80';
          try {
              final channel = WebSocketChannel.connect(Uri.parse(ipAddress)); // Replace with actual port
              channel.sink.add('ping');
  
              channel.stream.listen((message) {
                  Map<String, dynamic> decodedMessage = jsonDecode(message);
                  if (decodedMessage["RESPONSE"] == 'ok') {
                      respondingIpAddresses.add(ipAddress);
                  }
              }, onError: (error) {
                  // Handle error
              }, onDone: () {
                  channel.sink.close();
                  // Handle WebSocket connection close
              });
  
          } catch (e) {
              // Handle error
          }
          await Future.delayed(Duration(milliseconds: 200));
  
          while (respondingIpAddresses.isNotEmpty) {
              String newDevice = respondingIpAddresses.removeAt(0);
              WebSocketChannel ws = WebSocketChannel.connect(Uri.parse(newDevice));
              ws.sink.add("introduce");
  
              bool responseReceived = false; // Flag to track if the response has been received
  
              ws.stream.listen((rawDevInfo) {
                  Map<String, dynamic> devInfo = jsonDecode(rawDevInfo);
                  if (!responseReceived) { // Only process if the response hasn't been received    
                    setState(() {
                        respondingDevices.add({
                            "ip": newDevice,
                            "devinfo": devInfo["RESPONSE"], // Ensure this key matches your response structure
                            "ws": ws
                        });
                    });
                    responseReceived = true; // Mark response as received
                  }
                  else{
                    print("response: ${devInfo["RESPONSE"]}");
                  }
              }, onError: (error) {
                  // Handle error
              }, onDone: () {
                //none
              });
          }
      }
  }


  Future<void> sendPingToScanList(List<String> subnets) async {
    setState(() {
      scanning = true;
    });
    for (var subnet in subnets) {
      await findDevicesOnSubnet(subnet);
    }
    setState(() {
      scanning = false;
    });
  }

  Future<void> fetchLocalSubnet() async {
    print("fetchLocalSubnet");
    try {
      final localIP = await fetchIpAddress().timeout(
        const Duration(milliseconds: 400),
        onTimeout: () => 'Timeout: Unable to fetch IP address within 400ms',
      );
      print("Local IP: $localIP");
      await sendPingToScanList(ipScanList);
    } catch (e) {
      print("Error: $e");
    }
    print("fetch_done");
  }

  Future<String> fetchIpAddress() async {
    // Mock implementation, replace with actual IP fetching logic
    return '192.168.16.1';
  }

  void _handleDeviceTap(Map<String, dynamic> device) {
    setState(() {
      showOverlay = true; // Show the overlay when a device is tapped
      selectedDevice = device; // Store the selected device
    });
  }

  void _closeOverlay() {
    setState(() {
      showOverlay = false; // Hide the overlay when the close button is tapped
      selectedDevice = null; // Clear the selected device
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(2.0), // Padding around the body content
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 2.0), // Border around the entire page
          borderRadius: BorderRadius.circular(8.0), // Rounded corners for the border
        ),
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: respondingDevices.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0), // Adjust margins
                        elevation: 2.0, // Reduced elevation for a thinner look
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0), // Reduced padding
                          tileColor: Colors.blueGrey[50], // Background color
                          title: Text(
                            respondingDevices[index]['devinfo']['DEVICE_NAME'],
                            style: TextStyle(color: Colors.black87, fontSize: 14.0), // Smaller font size
                          ),
                          leading: Icon(
                            Icons.devices,
                            color: Colors.blue, // Icon color
                            size: 20.0, // Smaller icon size
                          ),
                          onTap: () => _handleDeviceTap(respondingDevices[index]), // Pass the clicked device
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            // Overlay widget when device is tapped
            if (showOverlay)
              NodePreview(
                onClose: _closeOverlay,
                deviceData: selectedDevice
                // Pass the selected device's data to NodePreview if needed
              ),
            // Loading indicator
            if (scanning)
              Positioned(
                bottom: 3.0,
                left: 3.0,
                child: SizedBox(
                  width: 10.0,
                  height: 10.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0, // Thinner progress indicator
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

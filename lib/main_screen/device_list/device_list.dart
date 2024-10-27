import "dart:io";

import 'package:flutter/material.dart';
import 'dart:async';
import "package:attempt_two/main_screen/device_list/node_preview.dart"; // Import the NodePreview widget
import "websocket_manager/websocket_connection.dart";
import "websocket_manager/headers/websocket_datatypes.dart";
import 'internal_device.dart';

class DeviceScanner extends StatefulWidget {
  final WebSocketController wsController; // Required parameter 

  const DeviceScanner({
    super.key,
    required this.wsController,
  });

  @override
  DeviceScannerState createState() => DeviceScannerState();
}

class DeviceScannerState extends State<DeviceScanner> {
  bool showOverlay = false;
  WsDevice? selectedDevice; // Add a variable to hold the selected device


  @override
  void initState() {
    super.initState();

    widget.wsController.newConnectionNotifyFunction = updateDeviceList;


  }

  Future<void> updateDeviceList() async {
    
    setState(() {
      widget.wsController.wsDeviceList;
    });
  }



  void _handleDeviceTap(WsDevice device) {
    setState(() {
      showOverlay = true; // Show the overlay when a device is tapped
      selectedDevice = device; // Store the selected device
    });
  }


  void _handleFunctionDeviceTap() {
    WsMessageList dummyMessageList = WsMessageList();
    WsDevice dummyDevice = WsDevice(ipAddress: {"ip": "internal", "port": ""}, messageList: dummyMessageList, deviceInfo: internalDevice);
    setState(() {
      showOverlay = true; // Show the overlay when a device is tapped
      selectedDevice = dummyDevice; // Store the selected device
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
                  itemCount: widget.wsController.wsDeviceList.devices.length + 1, // +1 for the Functions item
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Functions item
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        elevation: 2.0,
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                          tileColor: Colors.blueGrey[50],
                          title: Text(
                            "Functions",
                            style: TextStyle(color: Colors.black87, fontSize: 14.0),
                          ),
                          leading: Icon(
                            Icons.functions, // Use the appropriate function icon
                            color: Colors.blue,
                            size: 20.0,
                          ),
                          onTap: () => _handleFunctionDeviceTap(),
                        ),
                      );
                    } else {
                      // Device items
                      int deviceIndex = index - 1; // Adjust index for device list
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        elevation: 2.0,
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                          tileColor: Colors.blueGrey[50],
                          title: Text(
                            widget.wsController.wsDeviceList.devices[deviceIndex].deviceInfo?['DEVICE_NAME'],
                            style: TextStyle(color: Colors.black87, fontSize: 14.0),
                          ),
                          leading: Icon(
                            Icons.devices,
                            color: Colors.blue,
                            size: 20.0,
                          ),
                          onTap: () => _handleDeviceTap(widget.wsController.wsDeviceList.devices[deviceIndex]),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          // Overlay widget when device is tapped
          if (showOverlay)
            NodePreview(
              onClose: _closeOverlay,
              deviceData: selectedDevice,
              wsMessageList: widget.wsController.wsMessageList,
              wsController: widget.wsController,
            ),
          // Loading indicator
          if (true)
            Positioned(
              bottom: 3.0,
              left: 3.0,
              child: SizedBox(
                width: 10.0,
                height: 10.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
}

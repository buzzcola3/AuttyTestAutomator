import 'package:flutter/material.dart';
import 'dart:async';
import "package:attempt_two/nodes/node_panels/node_preview.dart"; // Import the NodePreview widget
import "/websocket_connection.dart";
import "/websocket_datatypes.dart";

class DeviceScanner extends StatefulWidget {
  @override
  _DeviceScannerState createState() => _DeviceScannerState();
}

class _DeviceScannerState extends State<DeviceScanner> {
  bool showOverlay = false;
  WsDevice? selectedDevice; // Add a variable to hold the selected device

  late WebSocketController wsController;


  @override
  void initState() {
    super.initState();

    wsController = WebSocketController(
      newConnectionNotifyFunction: updateDeviceList, 
      messageChangeNotifyFunction: newMessageHandle
    );

    //fetchLocalSubnet();
  }

  Future<void> updateDeviceList() async {
    
    setState(() {
      wsController.deviceList;
    });
  }

  void newMessageHandle(WsMessage message){
    print(message.message);
  }


  void _handleDeviceTap(WsDevice device) {
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
                    itemCount: wsController.deviceList.devices.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0), // Adjust margins
                        elevation: 2.0, // Reduced elevation for a thinner look
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0), // Reduced padding
                          tileColor: Colors.blueGrey[50], // Background color
                          title: Text(
                            wsController.deviceList.devices[index].deviceInfo?['DEVICE_NAME'],
                            style: TextStyle(color: Colors.black87, fontSize: 14.0), // Smaller font size
                          ),
                          leading: Icon(
                            Icons.devices,
                            color: Colors.blue, // Icon color
                            size: 20.0, // Smaller icon size
                          ),
                          onTap: () => _handleDeviceTap(wsController.deviceList.devices[index]), // Pass the clicked device
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
            if (wsController.scanning)
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

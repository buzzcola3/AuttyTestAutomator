import 'package:flutter/material.dart';
import 'dart:async';
import "package:attempt_two/main_screen/device_list/node_preview.dart";
import "websocket_manager/websocket_connection.dart";
import "websocket_manager/headers/websocket_datatypes.dart";
import 'internal_device.dart';
import "package:attempt_two/userdata_database.dart";

class DeviceScanner extends StatefulWidget {
  final WebSocketController wsController;
  final UserdataDatabase userdataDatabase;

  const DeviceScanner({
    super.key,
    required this.wsController,
    required this.userdataDatabase,
  });

  @override
  DeviceScannerState createState() => DeviceScannerState();
}

class DeviceScannerState extends State<DeviceScanner> {
  bool showOverlay = false;
  bool showGreenBox = false;
  WsDevice? selectedDevice;
  late Future<Map<String, dynamic>> userdataDatabase;
  List<Map<String, String>>? previouslyConnected;

  @override
  void initState() {
    super.initState();
    widget.wsController.newConnectionNotifyFunction = updateDeviceList;
    userdataDatabase = widget.userdataDatabase.getDeviceListData();
    connectToPreviouslyConnected();
  }

  Future<void> connectToPreviouslyConnected() async {
    Map<String, dynamic> list = await userdataDatabase;
  
    // Safely cast the connected devices list
    List<Map<String, String>>? connectedDevices = (list['connectedDevices'] as List<dynamic>?)
        ?.whereType<Map<String, dynamic>>()
        .map((item) => item.cast<String, String>())
        .toList();
  
    previouslyConnected = connectedDevices;
  
    if (previouslyConnected != null) {
      for (var dev in previouslyConnected!) {
        // Check if device is already in wsDeviceList.devices based on ip and port
        bool isConnected = widget.wsController.wsDeviceList.devices.any((connectedDevice) =>
            connectedDevice.ipAddress['ip'] == dev['ip'] &&
            connectedDevice.ipAddress['port'] == dev['port']);
        
        // Only attempt connection if the device is not already connected
        if (!isConnected) {
          widget.wsController.ipScanner.attemptConnection(dev['ip']!, dev['port']!);
        }
      }
    }
  }


Future<void> updateDeviceList() async {
  setState(() {
    widget.wsController.wsDeviceList;
  });

  if (previouslyConnected == null) {
    Map<String, dynamic> list = await userdataDatabase;
    previouslyConnected = List<Map<String, String>>.from(list['connectedDevices'] ?? []);
  }

  for (var device in widget.wsController.wsDeviceList.devices) {
    int existingIndex = previouslyConnected!.indexWhere((ipMap) =>
        ipMap['ip'] == device.ipAddress['ip'] &&
        ipMap['port'] == device.ipAddress['port']);

    // If the device is already in the list, remove it
    if (existingIndex != -1) {
      previouslyConnected!.removeAt(existingIndex);
    }

    // Ensure the list does not exceed 16 devices
    if (previouslyConnected!.length >= 16) {
      previouslyConnected!.removeAt(0); // Remove the oldest device
    }

    // Add the new device
    previouslyConnected!.add(device.ipAddress);
  }

  await widget.userdataDatabase
      .saveDeviceListData({'connectedDevices': previouslyConnected});
}

  void _handleDeviceTap(WsDevice device) {
    setState(() {
      showOverlay = true;
      selectedDevice = device;
    });
  }

  void _handleFunctionDeviceTap() {
    WsMessageList dummyMessageList = WsMessageList();
    WsDevice dummyDevice = WsDevice(
      ipAddress: {"ip": "internal", "port": ""},
      messageList: dummyMessageList,
      deviceInfo: internalDevice,
    );
    setState(() {
      showOverlay = true;
      selectedDevice = dummyDevice;
    });
  }

  void _closeOverlay() {
    setState(() {
      showOverlay = false;
      selectedDevice = null;
    });
  }

  void _toggleGreenBox() {
    setState(() {
      showGreenBox = !showGreenBox;
    });
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      padding: EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 2.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: widget.wsController.wsDeviceList.devices.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
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
                            Icons.functions,
                            color: Color.fromARGB(255, 58, 58, 58),
                            size: 20.0,
                          ),
                          onTap: _handleFunctionDeviceTap,
                        ),
                      );
                    } else {
                      int deviceIndex = index - 1;
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        elevation: 2.0,
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                          tileColor: Colors.blueGrey[50],
                          title: Text(
                            widget.wsController.wsDeviceList.devices[deviceIndex].deviceInfo!['DEVICE_NAME'],
                            style: TextStyle(color: Colors.black87, fontSize: 14.0),
                          ),
                          leading: Icon(
                            Icons.devices,
                            color: Color.fromARGB(255, 58, 58, 58),
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
          if (showOverlay)
            NodePreview(
              onClose: _closeOverlay,
              deviceData: selectedDevice,
              wsMessageList: widget.wsController.wsMessageList,
              wsController: widget.wsController,
            ),
          Positioned(
            bottom: 3.0,
            left: 3.0,
            child: SizedBox(
              width: 10.0,
              height: 10.0,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                color: Color.fromARGB(255, 58, 58, 58),
              ),
            ),
          ),
          Positioned(
            bottom: 0.0,
            right: 0.0,
            child: SizedBox(
              width: 18.0,
              height: 18.0,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.add, color: Color.fromARGB(255, 58, 58, 58)),
                iconSize: 18.0,
                onPressed: _toggleGreenBox,
              ),
            ),
          ),
          if (showGreenBox)
            Positioned(
              bottom: 0,
              right: 0,
              child: MouseRegion(
                onEnter: (_) {},
                onExit: (_) {
                  setState(() {
                    showGreenBox = false;
                  });
                },
                child: manualDeviceConnectionMenu(context, connectToPreviouslyConnected),
              ),
            ),
        ],
      ),
    ),
  );
}

Widget manualDeviceConnectionMenu(BuildContext context, Future<void> Function() connectToPreviouslyConnected) {
  return Container(
    clipBehavior: Clip.hardEdge,
    decoration: BoxDecoration(
      color: Colors.transparent,
    ),
    width: 120.0,
    child: Column(
      children: [
        ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Add Device"),
                  content: Text("Enter details to add a new device."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        // Add device logic here
                        Navigator.pop(context);
                      },
                      child: Text("Add"),
                    ),
                  ],
                );
              },
            );
          },
          style: _buttonStyle,
          child: _buildButtonContent(Icons.add, 'Add'),
        ),
ElevatedButton(
  onPressed: () async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Attempting to reconnect to previously connected devices..."),
        duration: Duration(seconds: 3), // Adjust duration as needed
      ),
    );

    // Call the function to attempt reconnection
    await connectToPreviouslyConnected();
  },
  style: _buttonStyle,
  child: _buildButtonContent(Icons.refresh, 'Reconnect'),
),

        ElevatedButton(
          onPressed: () {
            // Scan subnet dialog logic here
          },
          style: _buttonStyle,
          child: _buildButtonContent(Icons.language, 'Scan Subnet'),
        ),
        ElevatedButton(
          onPressed: () {
            // Port scan dialog logic here
          },
          style: _buttonStyle,
          child: _buildButtonContent(Icons.search, 'Scan Ports'),
        ),
      ],
    ),
  );
}

ButtonStyle get _buttonStyle => ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      minimumSize: Size(120.0, 30.0),
      textStyle: TextStyle(color: Colors.black87, fontSize: 10.0),
      backgroundColor: Color.fromARGB(255, 80, 200, 120),
    );

Widget _buildButtonContent(IconData icon, String label) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: 14.0, color: Color.fromARGB(255, 58, 58, 58)),
      SizedBox(width: 8.0),
      Text(label),
    ],
  );
}
}
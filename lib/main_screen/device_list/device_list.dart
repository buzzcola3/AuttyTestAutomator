import 'package:flutter/material.dart';
import 'dart:async';
import "package:attempt_two/main_screen/device_list/node_preview.dart";
import "websocket_manager/websocket_connection.dart";
import "websocket_manager/headers/websocket_datatypes.dart";
import 'internal_device.dart';
import "package:attempt_two/userdata_database.dart";
import "package:attempt_two/global_datatypes/ip_address.dart";

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
  List<Map<String, dynamic>>? previouslyConnected;

  @override
  void initState() {
    super.initState();
    widget.wsController.newConnectionNotifyFunction = updateDeviceList;
    userdataDatabase = widget.userdataDatabase.getDeviceListData();
    connectToPreviouslyConnected();
  }

  void connectToDevice(IPAddress ipAddress){
    widget.wsController.ipScanner.attemptConnection(ipAddress);
  }

  void scanSubnet(IPAddress subnetIp){
    widget.wsController.ipScanner.scanSubnet(subnetIp);
  }

  Future<void> connectToPreviouslyConnected() async {
    Map<String, dynamic> list = await userdataDatabase;
  
    // Safely cast the connected devices list
    List<Map<String, dynamic>>? connectedDevices = (list['connectedDevices'] as List<dynamic>?)
        ?.whereType<Map<String, dynamic>>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  
    previouslyConnected = connectedDevices;
  
    if (previouslyConnected != null) {
      for (var dev in previouslyConnected!) {
        widget.wsController.ipScanner.attemptConnection(IPAddress.fromMap(dev));
      }
    }
  }


Future<void> updateDeviceList() async {
  setState(() {
    widget.wsController.wsDeviceList;
  });

  if (previouslyConnected == null) {
    Map<String, dynamic> list = await userdataDatabase;
    previouslyConnected = List<Map<String, dynamic>>.from(list['connectedDevices'] ?? []);
  }

  for (var device in widget.wsController.wsDeviceList.devices) {
    int existingIndex = previouslyConnected!.indexWhere((ipMap) =>
        IPAddress.fromMap(ipMap) == device.ipAddress);

    // If the device is already in the list, remove it
    if (existingIndex != -1) {
      previouslyConnected!.removeAt(existingIndex);
    }

    // Ensure the list does not exceed 16 devices
    if (previouslyConnected!.length >= 16) {
      previouslyConnected!.removeAt(0); // Remove the oldest device
    }

    // Add the new device
    final ip = device.ipAddress.toMap();
    previouslyConnected!.add(ip);
  }

  await widget.userdataDatabase.saveDeviceListData({'connectedDevices': previouslyConnected});
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
      ipAddress: IPAddress('', 0),
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
  final TextEditingController ipController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  return Container(
    clipBehavior: Clip.hardEdge,
    decoration: BoxDecoration(
      color: Colors.transparent,
    ),
    width: 120.0,
    child: Column(
      children: [
        // Add Device Button
        ElevatedButton(
          onPressed: () {
            _showAddDeviceDialog(context, formKey, ipController, portController);
          },
          style: _buttonStyle,
          child: _buildButtonContent(Icons.add, 'Add'),
        ),
        // Reconnect Button
        ElevatedButton(
          onPressed: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Attempting to reconnect to previously connected devices..."),
                duration: Duration(seconds: 3),
              ),
            );
            await connectToPreviouslyConnected();
          },
          style: _buttonStyle,
          child: _buildButtonContent(Icons.refresh, 'Reconnect'),
        ),
        // Scan Subnet Button
        ElevatedButton(
          onPressed: () {
            _showScanSubnetDialog(context, formKey, ipController, portController);
          },
          style: _buttonStyle,
          child: _buildButtonContent(Icons.language, 'Scan Subnet'),
        ),
        // Scan Ports Button
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

void _showAddDeviceDialog(BuildContext context, GlobalKey<FormState> formKey, TextEditingController ipController, TextEditingController portController) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Add Device"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Enter IP address and port of the new device."),
              SizedBox(height: 10),
              TextField(
                controller: ipController,
                decoration: InputDecoration(
                  labelText: "IP Address",
                  hintText: "e.g., 192.168.1.1",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onSubmitted: (_) => _submitForm(formKey, ipController, portController, context),
              ),
              SizedBox(height: 10),
              TextField(
                controller: portController,
                decoration: InputDecoration(
                  labelText: "Port",
                  hintText: "e.g., 80",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _submitForm(formKey, ipController, portController, context),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Attempting to add the device..."),
                  duration: Duration(seconds: 3),
                ),
              );
              _submitForm(formKey, ipController, portController, context); // Add device
            },
            child: Text("Add"),
          ),
        ],
      );
    },
  );
}

void _showScanSubnetDialog(BuildContext context, GlobalKey<FormState> formKey, TextEditingController ipController, TextEditingController portController) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Scan Subnet"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Enter Subnet IP address and Port for scanning."),
              SizedBox(height: 10),
              TextField(
                controller: ipController,
                decoration: InputDecoration(
                  labelText: "Subnet",
                  hintText: "e.g., 192.168.1.0",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onSubmitted: (_) => _startSubnetScan(formKey, ipController, portController, context),
              ),
              SizedBox(height: 10),
              TextField(
                controller: portController,
                decoration: InputDecoration(
                  labelText: "Port",
                  hintText: "e.g., 80",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _startSubnetScan(formKey, ipController, portController, context),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Started Subnet Scan..."),
                  duration: Duration(seconds: 3),
                ),
              );
              _startSubnetScan(formKey, ipController, portController, context); // Start scan
            },
            child: Text("Scan"),
          ),
        ],
      );
    },
  );
}

void _startSubnetScan(GlobalKey<FormState> formKey, TextEditingController ipController, TextEditingController portController, BuildContext context) {
  final ipAddress = IPAddress(ipController.text, portController.text); // Adjust the port if needed
  scanSubnet(ipAddress); // Placeholder function to handle subnet scan
  Navigator.pop(context); // Close the dialog
}


void _submitForm(GlobalKey<FormState> formKey, TextEditingController ipController, TextEditingController portController, BuildContext context) {
  if (formKey.currentState?.validate() ?? false) {
    final ip = IPAddress(ipController.text, int.tryParse(portController.text) ?? 0);
    connectToDevice(ip); // Replace with your actual connection method
    Navigator.pop(context); // Close the dialog after adding the device
  }
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
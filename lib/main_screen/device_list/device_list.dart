import 'package:flutter/material.dart';
import 'dart:async';
import "package:attempt_two/main_screen/device_list/node_preview.dart";
import "websocket_manager/websocket_manager.dart";
import "websocket_manager/headers/websocket_datatypes.dart";
import 'internal_device.dart';
import "package:attempt_two/userdata_database.dart";
import "package:attempt_two/global_datatypes/ip_address.dart";

class DeviceScanner extends StatefulWidget {
  final WebsocketManager websocketManager;
  final UserdataDatabase userdataDatabase;

  const DeviceScanner({
    super.key,
    required this.websocketManager,
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

    widget.websocketManager.deviceListChangeCallbacks.add(updateDeviceList);
    userdataDatabase = widget.userdataDatabase.getDeviceListData();
    connectToPreviouslyConnected();
  }

  void connectToDevice(IPAddress ipAddress){
    widget.websocketManager.ipScanner.attemptConnection(ipAddress);
  }

  void scanSubnet(IPAddress subnetIp){
    widget.websocketManager.ipScanner.scanSubnet(subnetIp);
  }

  Future<void> connectToPreviouslyConnected() async {
    Map<String, dynamic> list = await userdataDatabase;
  
    if(previouslyConnected == null){
      // Safely cast the connected devices list
      List<Map<String, dynamic>>? connectedDevices = (list['connectedDevices'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
      previouslyConnected = connectedDevices;
    }

  
    if (previouslyConnected != null) {
      for (var dev in previouslyConnected!) {
        widget.websocketManager.ipScanner.attemptConnection(IPAddress.fromMap(dev));
      }
    }
  }


Future<void> updateDeviceList() async {
  setState(() {
    widget.websocketManager.deviceList;
  });

  if (previouslyConnected == null) {
    Map<String, dynamic> list = await userdataDatabase;
    previouslyConnected = List<Map<String, dynamic>>.from(list['connectedDevices'] ?? []);
  }

  for (var device in widget.websocketManager.deviceList.devices) {
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
    WsDevice dummyDevice = internalWsDevice;
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

  void _toggleManualConnectionMenu() {
    setState(() {
      showGreenBox = !showGreenBox;
    });
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      padding: const EdgeInsets.all(2.0),
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
                  itemCount: widget.websocketManager.deviceList.devices.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        elevation: 2.0,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                          tileColor: Colors.blueGrey[50],
                          title: const Text(
                            "Functions",
                            style: TextStyle(color: Colors.black87, fontSize: 14.0),
                          ),
                          leading: const Icon(
                            Icons.functions,
                            color: Color.fromARGB(255, 58, 58, 58),
                            size: 20.0,
                          ),
                          onTap: _handleFunctionDeviceTap,
                        ),
                      );
                    } else {
                      int deviceIndex = index - 1;
                      final device = widget.websocketManager.deviceList.devices[deviceIndex];
                      final isReady = device.ready;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        elevation: 2.0,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                          tileColor: isReady ? Colors.blueGrey[50] : Colors.grey[300],
                          title: Text(
                            device.deviceInfo!.deviceName,
                            style: TextStyle(
                              color: isReady ? Colors.black87 : Colors.grey[700],
                              fontSize: 14.0,
                            ),
                          ),
                          leading: Icon(
                            Icons.devices,
                            color: isReady
                                ? const Color.fromARGB(255, 58, 58, 58)
                                : Colors.grey[600],
                            size: 20.0,
                          ),
                          onTap: isReady
                              ? () => _handleDeviceTap(device)
                              : null, // Disable tap if not ready
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
              websocketManager: widget.websocketManager,
            ),
          Positioned(
            bottom: 3.0,
            left: 3.0,
            child: widget.websocketManager.ipScanner.scanning
                ? const SizedBox(
                    width: 10.0,
                    height: 10.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: Color.fromARGB(255, 58, 58, 58),
                    ),
                  )
                : const SizedBox.shrink(), // Empty widget when not scanning
          ),
          Positioned(
            bottom: 0.0,
            right: 0.0,
            child: SizedBox(
              width: 18.0,
              height: 18.0,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.add, color: Color.fromARGB(255, 58, 58, 58)),
                iconSize: 18.0,
                onPressed: _toggleManualConnectionMenu,
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
    decoration: const BoxDecoration(
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
              const SnackBar(
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
            _showPortScanDialog(context, formKey, ipController, TextEditingController(), TextEditingController());
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
        title: const Text("Add Device"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter IP address and port of the new device."),
              const SizedBox(height: 10),
              TextField(
                controller: ipController,
                decoration: const InputDecoration(
                  labelText: "IP Address",
                  hintText: "e.g., 192.168.1.1",
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onSubmitted: (_) => _addDevice(formKey, ipController, portController, context),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: portController,
                decoration: const InputDecoration(
                  labelText: "Port",
                  hintText: "e.g., 80",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _addDevice(formKey, ipController, portController, context),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Attempting to add the device..."),
                  duration: Duration(seconds: 3),
                ),
              );
              _addDevice(formKey, ipController, portController, context); // Add device
            },
            child: const Text("Add"),
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
        title: const Text("Scan Subnet"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter Subnet IP address and Port for scanning."),
              const SizedBox(height: 10),
              TextField(
                controller: ipController,
                decoration: const InputDecoration(
                  labelText: "Subnet",
                  hintText: "e.g., 192.168.1.0",
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onSubmitted: (_) => _startSubnetScan(formKey, ipController, portController, context),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: portController,
                decoration: const InputDecoration(
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
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Started Subnet Scan..."),
                  duration: Duration(seconds: 3),
                ),
              );
              _startSubnetScan(formKey, ipController, portController, context); // Start scan
            },
            child: const Text("Scan"),
          ),
        ],
      );
    },
  );
}

void _showPortScanDialog(
  BuildContext context,
  GlobalKey<FormState> formKey,
  TextEditingController ipController,
  TextEditingController portStartController,
  TextEditingController portEndController,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Scan Ports"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter IP address and port range for scanning."),
              const SizedBox(height: 10),
              TextField(
                controller: ipController,
                decoration: const InputDecoration(
                  labelText: "IP Address",
                  hintText: "e.g., 192.168.1.1",
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: portStartController,
                decoration: const InputDecoration(
                  labelText: "Start Port",
                  hintText: "e.g., 20",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: portEndController,
                decoration: const InputDecoration(
                  labelText: "End Port",
                  hintText: "e.g., 80",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Started Port Scan..."),
                  duration: Duration(seconds: 3),
                ),
              );
              _startPortScan(formKey, ipController, portStartController, portEndController, context);
            },
            child: const Text("Scan"),
          ),
        ],
      );
    },
  );
}

void _startSubnetScan(GlobalKey<FormState> formKey, TextEditingController ipController, TextEditingController portController, BuildContext context) {
  if (formKey.currentState?.validate() ?? false) {
    final ipAddress = IPAddress(ipController.text, portController.text);
    scanSubnet(ipAddress); // Placeholder function to handle subnet scan
    Navigator.pop(context); // Close the dialog
  }
}

void _startPortScan(
  GlobalKey<FormState> formKey,
  TextEditingController ipController,
  TextEditingController portStartController,
  TextEditingController portEndController,
  BuildContext context,
) {
  if (formKey.currentState?.validate() ?? false) {
    // Parse the start and end ports
    int? startPort = int.tryParse(portStartController.text);
    final int? endPort = int.tryParse(portEndController.text);

    // Check that the start and end ports are valid
    if (startPort == null || endPort == null || startPort > endPort) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid port range. Please check your input."),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (startPort < 1) startPort = 1;

    if (endPort - startPort >  64){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Too many ports to scan. Please limit port range to a maximum of 64 ports."),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Loop through the port range
    for (int currentPort = startPort; currentPort <= endPort; currentPort++) {
      final ipAddress = IPAddress(ipController.text, currentPort);
      
      // Attempt to connect to each port
      connectToDevice(ipAddress);
    }

    // Close the dialog after starting the scan
    Navigator.pop(context);
    
    // Show a snackbar to indicate the scan has started
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Started scanning ports from $startPort to $endPort."),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

void _addDevice(GlobalKey<FormState> formKey, TextEditingController ipController, TextEditingController portController, BuildContext context) {
  if (formKey.currentState?.validate() ?? false) {
    final ip = IPAddress(ipController.text, int.tryParse(portController.text) ?? 0);
    connectToDevice(ip); // Replace with your actual connection method
    Navigator.pop(context); // Close the dialog after adding the device
  }
}


ButtonStyle get _buttonStyle => ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      minimumSize: const Size(120.0, 30.0),
      textStyle: const TextStyle(color: Colors.black87, fontSize: 10.0),
      backgroundColor: const Color.fromARGB(255, 80, 200, 120),
    );

Widget _buildButtonContent(IconData icon, String label) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: 14.0, color: const Color.fromARGB(255, 58, 58, 58)),
      const SizedBox(width: 8.0),
      Text(label),
    ],
  );
}
}
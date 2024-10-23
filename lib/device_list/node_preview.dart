import 'package:flutter/material.dart';
import 'package:attempt_two/node_generation/node_generator.dart';
import "websocket_manager/headers/websocket_datatypes.dart";

class NodePreview extends StatefulWidget {
  final VoidCallback onClose;
  final WsDevice? deviceData;

  const NodePreview({required this.onClose, this.deviceData, super.key});

  @override
  _NodePreviewState createState() => _NodePreviewState();
}

enum DisplayState { nodes, commands, help } // Enum to represent the display states

class _NodePreviewState extends State<NodePreview> {
  DisplayState currentDisplayState = DisplayState.nodes; // Default to showing nodes

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(
            color: Colors.white,
          ),
          // Control bar at the top with text and 4 buttons
          Positioned(
            top: 2.0, // Reduced top padding
            left: 0.0,
            right: 0.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Thin text above the buttons, with reduced vertical space
                Text(
                  widget.deviceData != null ? widget.deviceData!.deviceInfo!['DEVICE_NAME'] : 'Control Bar',
                  style: TextStyle(
                    fontSize: 12.0, // Reduced font size
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 0.0), // Reduced spacing between text and buttons
                // Row of 4 buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Replaced the close X with an arrow back icon
                    IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: widget.onClose, // Replaced the close button functionality
                    ),
                    // Node icon
                    IconButton(
                      icon: Icon(Icons.device_hub), // Node icon
                      onPressed: () {
                        setState(() {
                          currentDisplayState = DisplayState.nodes; // Show example nodes
                        });
                      },
                    ),
                    // Command window icon
                    IconButton(
                      icon: Icon(Icons.terminal), // Command window icon
                      onPressed: () {
                        setState(() {
                          currentDisplayState = DisplayState.commands; // Show available commands
                        });
                      },
                    ),
                    // Help icon (question mark)
                    IconButton(
                      icon: Icon(Icons.help), // Help icon
                      onPressed: () {
                        setState(() {
                          currentDisplayState = DisplayState.help; // Show help information
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content area for nodes, commands, or help
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: 60.0), // Adjusted padding for control bar
              child: _buildCurrentContent(), // Show based on current display state
            ),
          ),
        ],
      ),
    );
  }

  // Determines which content to display based on the currentDisplayState
  Widget _buildCurrentContent() {
    switch (currentDisplayState) {
      case DisplayState.help:
        return _buildHelpContent();
      case DisplayState.commands:
        return _buildCommandList();
      case DisplayState.nodes:
      default:
        return _buildNodeList();
    }
  }

// Builds the help content with device information
Widget _buildHelpContent() {
  if (widget.deviceData == null) {
    return Center(child: Text('No device data available.'));
  }

  String description = widget.deviceData!.deviceInfo!['DEVICE_DESCRIPTION'] ?? 'No description available';
  String ipAddress = widget.deviceData!.ipAddress['ip'] ?? 'No IP address available';
  String uniqueId = widget.deviceData!.deviceInfo!['UNIQUE_ID'] ?? 'No UNIQUE_ID available';

  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: SingleChildScrollView(  // Make content scrollable
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Description: $description', style: TextStyle(fontSize: 14.0)),
          SizedBox(height: 8.0),  // Add spacing between texts
          Text('IP Address: $ipAddress', style: TextStyle(fontSize: 14.0)),
          SizedBox(height: 8.0),
          Text('Unique ID: $uniqueId', style: TextStyle(fontSize: 14.0)),
        ],
      ),
    ),
  );
}

// Builds the command list from device data
Widget _buildCommandList() {
  if (widget.deviceData == null || widget.deviceData!.deviceInfo!['DEVICE_AVAILABLE_COMMANDS'] == null) {
    return Center(child: Text('No commands available.'));
  }
  List<String> commands = List<String>.from(widget.deviceData!.deviceInfo!['DEVICE_AVAILABLE_COMMANDS']);
  
  return ListView.builder(
      itemCount: commands.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () {
              // Handle the command action here
              widget.deviceData!.socket?.add(commands[index]);
              print("Executing command: ${commands[index]}"); // Replace with actual command execution logic
            },
            child: Text(commands[index]), // Display the command
          ),
        );
      },
    );
}

// Builds the list of device nodes
Widget _buildNodeList() {
  // Check if device data and commands are available
  if (widget.deviceData == null || widget.deviceData!.deviceInfo!['DEVICE_AVAILABLE_COMMANDS'] == null) {
    return Center(child: Text('No commands available.'));
  }

  // Retrieve the available nodes from device data
  List<dynamic> dyn_nodes = widget.deviceData!.deviceInfo!['DEVICE_AVAILABLE_NODES'];
  //cast to the correct strict datastructure
  List<Map<String, dynamic>> nodes = dyn_nodes.cast<Map<String, dynamic>>();

  return ListView.builder(
    itemCount: nodes.length, // Set the item count based on the number of nodes
    itemBuilder: (context, index) {
      // Get the command name to display
      Map<String, dynamic> singleNode = nodes[index];

      Map<String, dynamic> encodedNodeIdentifier = encodeNodeFunction(
        deviceUniqueId: widget.deviceData!.deviceInfo!["UNIQUE_ID"],
        nodeCommand: singleNode["Command"],
        );

      Widget? fabricatedDummyNode = fabricateNode(
          nodeName: singleNode["Name"],
          nodeColor: singleNode["Color"],
          nodeType: singleNode["Type"],
          inPorts: singleNode["InPorts"],
          outPorts: singleNode["OutPorts"],
          svgIconString: singleNode["SvgIcon"],
          isDummy: true
        );

      Widget? fabricatedNode = fabricateNode(
          nodeName: singleNode["Name"],
          nodeColor: singleNode["Color"],
          nodeType: singleNode["Type"],
          inPorts: singleNode["InPorts"],
          outPorts: singleNode["OutPorts"],
          svgIconString: singleNode["SvgIcon"],
          isDummy: false
        );

      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Center(  // Wrap each node in a Center to avoid stretching
          child: SizedBox(
            child: Draggable<Map<String, dynamic>>(
              data: {"encodedFunction": encodedNodeIdentifier, "node": fabricatedNode},
              feedback: Material(
                color: Colors.transparent,
                child: Opacity(
                  opacity: 0.7,
                  child: generatePreviewNode(nodeType: fabricatedDummyNode),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.5,
                child: generatePreviewNode(nodeType: fabricatedDummyNode),
              ),
              child: generatePreviewNode(nodeType: fabricatedDummyNode),
            ),
          ),
        )
      );
    },
  );
}


}

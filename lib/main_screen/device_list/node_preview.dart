import 'package:Autty/global_datatypes/device_info.dart';
import 'package:Autty/main_screen/device_list/websocket_manager/communication_handler.dart';
import 'package:Autty/main_screen/device_list/websocket_manager/websocket_manager.dart';
import 'package:flutter/material.dart';
import 'package:Autty/main_screen/device_list/node_generation/node_generator.dart';

class NodePreview extends StatefulWidget {
  final VoidCallback onClose;
  final RemoteDevice? deviceData;
  final WebsocketManager websocketManager;

  const NodePreview({
    required this.onClose,
    this.deviceData,
    required this.websocketManager,
    super.key,
  });

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
                  widget.deviceData != null ? widget.deviceData!.deviceInfo.deviceName : 'Control Bar',
                  style: const TextStyle(
                    fontSize: 12.0, // Reduced font size
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 0.0), // Reduced spacing between text and buttons
                // Row of 4 buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Replaced the close X with an arrow back icon
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      tooltip: "Return",
                      onPressed: widget.onClose, // Replaced the close button functionality
                    ),
                    // Node icon
                    IconButton(
                      icon: const Icon(Icons.device_hub), // Node icon
                      tooltip: "Nodes",
                      onPressed: () {
                        setState(() {
                          currentDisplayState = DisplayState.nodes; // Show example nodes
                        });
                      },
                    ),
                    // Command window icon
                    IconButton(
                      icon: const Icon(Icons.terminal), // Command window icon
                      tooltip: "Commands",
                      onPressed: () {
                        setState(() {
                          currentDisplayState = DisplayState.commands; // Show available commands
                        });
                      },
                    ),
                    // Help icon (question mark)
                    IconButton(
                      icon: const Icon(Icons.help), // Help icon
                      tooltip: "Device Information",
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
        return _buildNodeList();
    }
  }

// Builds the help content with device information
Widget _buildHelpContent() {
  if (widget.deviceData == null) {
    return const Center(child: Text('No device data available.'));
  }

  String description = widget.deviceData!.deviceInfo.deviceName;
  String ipAddress = widget.deviceData!.deviceIp.toString();
  String uniqueId = widget.deviceData!.deviceInfo.deviceUniqueId;

  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: SingleChildScrollView(  // Make content scrollable
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Description: $description', style: const TextStyle(fontSize: 14.0)),
          const SizedBox(height: 8.0),  // Add spacing between texts
          Text('IP Address: $ipAddress', style: const TextStyle(fontSize: 14.0)),
          const SizedBox(height: 8.0),
          Text('Unique ID: $uniqueId', style: const TextStyle(fontSize: 14.0)),
        ],
      ),
    ),
  );
}

// Builds the command list from device data
Widget _buildCommandList() {
  List<String> commands = [];
  for(Node node in widget.deviceData!.deviceInfo.deviceAvailableNodes.nodes){
    if(node.function != null && node.function!.parameters != null && node.function!.parameters!.isEmpty){
      if(widget.deviceData!.deviceInfo.deviceUniqueId != "internal"){
        commands.add(node.function!.command);
      }
    }
  }
  if (commands.isEmpty) {
    return const Center(child: Text('No commands available.'));
  }
  return ListView.builder(
      itemCount: commands.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () {
              // Handle the command action here
              widget.deviceData!.callRemoteFunction(commands[index], {});
              //sendMessage
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
  if (widget.deviceData == null) {
    return const Center(child: Text('No nodes available.'));
  }

  AvailableNodes nodes = widget.deviceData!.deviceInfo.deviceAvailableNodes;

  return ListView.builder(
    itemCount: nodes.nodes.length, // Set the item count based on the number of nodes
    itemBuilder: (context, index) {
      // Get the command name to display
      Node singleNode = nodes.nodes[index];

      NodeDNA nodeDNA = NodeDNA(
        deviceUuid: widget.deviceData!.deviceInfo.deviceUniqueId,
        nodeUuid: '',
        nodeFunction: singleNode.function!,
        nodeName: singleNode.name,
        nodeColor: singleNode.color,
        nodeType: singleNode.type,
        svgIconString: singleNode.svgIcon,
      );

      NodeWithNotifiers? fabricatedDummyNode = fabricateNode( //TODO NodeDNA as input
          nodeDNA: nodeDNA,
          isDummy: true
        );

      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Center(  // Wrap each node in a Center to avoid stretching
          child: SizedBox(
            child: Draggable<NodeDNA>(
              data: nodeDNA,
              feedback: Material(
                color: Colors.transparent,
                child: Opacity(
                  opacity: 0.7,
                  child: generatePreviewNode(nodeType: fabricatedDummyNode.node),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.5,
                child: generatePreviewNode(nodeType: fabricatedDummyNode.node),
              ),
              child: generatePreviewNode(nodeType: fabricatedDummyNode.node),
            ),
          ),
        )
      );
    },
  );
}


}

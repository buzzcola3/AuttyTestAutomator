import 'dart:math';

import 'package:Autty/global_datatypes/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:node_editor/node_editor.dart';


double _DEFAULT_WIDTH = 180;
const double _DEFAULT_NODE_PADDING = 0; // Keep 0
Color _NODE_CONNECTION_COLOR = const Color.fromARGB(255, 109, 109, 109);
const double _NODE_EDGE_RADIUS = 6;

NodeWidgetBase generateNode({
  required Widget nodeType,

  required String nodeUuid,

  required void Function(DragStartDetails) onPanStart,
  required void Function(DragUpdateDetails) onPanUpdate,
  required void Function(DragEndDetails) onPanEnd,
  required GestureTapCallback onTap,
}) {

  
  return ContainerNodeWidget(
    name: nodeUuid,
    typeName: 'node',
    selectedBorder: Border.all(color: Colors.white),
    border: Border.all(color: Colors.transparent),
    radius: _NODE_EDGE_RADIUS,
    backgroundColor: Colors.transparent, // Transparent background
    width: _DEFAULT_WIDTH, // Width is fixed
    contentPadding: const EdgeInsets.all(_DEFAULT_NODE_PADDING),
    child: GestureDetector(
      onTap: onTap,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: nodeType, // Child widget defines height and appearance
    ),
  );
}

Container generatePreviewNode({
  required Widget? nodeType,
}) {
  return Container(
    decoration: const BoxDecoration(
      color: Colors.transparent, // Default color for the preview node// Selected border
    ),
    width: _DEFAULT_WIDTH,
    child: nodeType,
  );
}

Widget generateInPort({ bool isDummy = false, required String name }) {
  if (isDummy) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.transparent, // Transparent background
        borderRadius: BorderRadius.circular(4), // Rounded edges
      ),
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4), // Rounded edges
            border: Border.all(color: _NODE_CONNECTION_COLOR, width: 1),
          ),
        ),
      ),
    );
  } else {
    return InPortWidget(
      name: name,
      onConnect: (String name, String port) => true,
      icon: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.transparent, // Transparent background
          borderRadius: BorderRadius.circular(4), // Rounded edges
        ),
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white, // White background
              borderRadius: BorderRadius.circular(4), // Rounded edges
              border: Border.all(color: _NODE_CONNECTION_COLOR, width: 1),
            ),
          ),
        ),
      ),
      iconConnected: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.transparent, // Transparent background
          borderRadius: BorderRadius.circular(4), // Rounded edges
        ),
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white, // Background color when connected
              borderRadius: BorderRadius.circular(4), // Rounded edges
              border: Border.all(color: _NODE_CONNECTION_COLOR, width: 1),
            ),
          ),
        ),
      ),
      multiConnections: false,
      connectionTheme: ConnectionTheme(
        color: _NODE_CONNECTION_COLOR,
        strokeWidth: 2,
      ),
    );
  }
}

Widget generateOutPort({ bool isDummy = false, required String name }) {
  if (isDummy) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.transparent, // Transparent background
        borderRadius: BorderRadius.circular(4), // Rounded edges
      ),
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white, // Color for dummy port
            borderRadius: BorderRadius.circular(4), // Rounded edges
            border: Border.all(color: _NODE_CONNECTION_COLOR, width: 1),
          ),
        ),
      ),
    );
  } else {
    return OutPortWidget(
      name: name,
      icon: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.transparent, // Transparent background
          borderRadius: BorderRadius.circular(4), // Rounded edges
        ),
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white, // White background
              borderRadius: BorderRadius.circular(4), // Rounded edges
              border: Border.all(color: _NODE_CONNECTION_COLOR, width: 1),
            ),
          ),
        ),
      ),
      iconConnected: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.transparent, // Transparent background
          borderRadius: BorderRadius.circular(4), // Rounded edges
        ),
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white, // Background color when connected
              borderRadius: BorderRadius.circular(4), // Rounded edges
              border: Border.all(color: _NODE_CONNECTION_COLOR, width: 1),
            ),
          ),
        ),
      ),
      multiConnections: false,
      connectionTheme: ConnectionTheme(
        color: _NODE_CONNECTION_COLOR,
        strokeWidth: 2,
      ),
    );
  }
}

Color getNodeAccentColor(String colorName) {
  // Map of base colors to their accent equivalents
  Map<String, Color> colorMap = {
    'red': Colors.redAccent,
    'blue': Colors.blueAccent,
    'green': Colors.greenAccent,
    'yellow': Colors.yellowAccent,
    'purple': Colors.purpleAccent,
    'orange': Colors.orangeAccent,
    'pink': Colors.pinkAccent,
    'teal': Colors.tealAccent,
    'indigo': Colors.indigoAccent,
    'cyan': Colors.cyanAccent,
  };

  // Normalize the input (convert to lowercase to handle case-insensitive input)
  String normalizedColorName = colorName.toLowerCase();

  // If the input is "random", generate a random accent color
  if (normalizedColorName == "random") {
    List<Color> availableColors = colorMap.values.toList();
    return availableColors[Random().nextInt(availableColors.length)];
  }

  // Return the accent color if it's found in the map, or a default accent color if not found
  return colorMap[normalizedColorName] ?? Colors.blueAccent; // Default to blueAccent if not found
}

Color getNodeColor(String colorName) {
  // Map of color names to their base Color equivalents
  Map<String, Color> colorMap = {
    'red': Colors.red,
    'blue': Colors.blue,
    'green': Colors.green,
    'yellow': Colors.yellow,
    'purple': Colors.purple,
    'orange': Colors.orange,
    'pink': Colors.pink,
    'teal': Colors.teal,
    'indigo': Colors.indigo,
    'cyan': Colors.cyan,
  };

  // Normalize the input (convert to lowercase to handle case-insensitive input)
  String normalizedColorName = colorName.toLowerCase();

  // If the input is "random", generate a random color
  if (normalizedColorName == "random") {
    List<Color> availableColors = colorMap.values.toList();
    return availableColors[Random().nextInt(availableColors.length)];
  }

  // Return the color if found in the map, or a default color if not found
  return colorMap[normalizedColorName] ?? Colors.blue; // Default to blue if not found
}

Widget? fabricateNode({
  String nodeName = "",
  String nodeColor = "",
  NodeType nodeType = NodeType.basicNode,
  FunctionNode? nodeFunction = null,
  bool isDummy = false,
  String svgIconString = ""
}) {
  switch(nodeType) {
    case NodeType.basicNode:
      return BasicNode(
        isDummy: isDummy, 
        nodeName: nodeName,  
        color: getNodeColor(nodeColor), 
        accentColor: getNodeAccentColor(nodeColor), 
        nodeFunction: nodeFunction,
        svgIconString: svgIconString
      );

    case NodeType.outputNode: //TODO delete this, make just a start node
      return outputNode(
        isDummy: isDummy, 
        nodeName: nodeName, 
        color: getNodeColor(nodeColor), 
        accentColor: getNodeAccentColor(nodeColor), 
        nodeFunction: nodeFunction,
        svgIconString: svgIconString
      );
  }
  return null;  // Handle any other cases if needed
}


class BasicNode extends StatelessWidget {
  final bool isDummy;
  final Color accentColor;
  final Color color;
  final String? nodeName;
  final String? svgIconString;
  final FunctionNode? nodeFunction;

  // Constructor for BasicNode
  const BasicNode({
    super.key,
    this.isDummy = false,
    this.accentColor = Colors.lightBlue,
    this.color = Colors.lightBlueAccent,
    this.nodeName,
    this.svgIconString,
    this.nodeFunction
  });

  static const double _NODE_EDGE_RADIUS = 8.0;


List<Widget> getInPorts(FunctionNode nodeFunction) {
  return [
    // only if parameter.type is not "void", add it to the return list
    // Dynamically add rows for each parameter
    ...?nodeFunction.parameters?.map((parameter) {
      if (parameter.hardSet){
        return SizedBox.shrink();
      }
      return SizedBox(
        height: 25,
        child: Row(
          children: [
            // Rectangle that sticks out
            Transform.translate(
              offset: Offset(-2, 0), // Move 2 pixels to the left
              child: MouseRegion(
                cursor: SystemMouseCursors.click, // Change cursor to 'click' style
                child: generateInPort(isDummy: isDummy, name: parameter.name)
              ),
            ),
            // Text next to the rectangle
            Text(
              parameter.name, // Display the parameter's name
              style: TextStyle(fontSize: 10, color: Colors.white, fontFamily: 'CascadiaCode',),
            ),
          ],
        ),
      );
    }).toList(),

    // Always include the "Trigger in" row
    SizedBox(
      height: 25,
      child: Row(
        children: [
          // Rectangle that sticks out
          Transform.translate(
            offset: Offset(-2, 0), // Move 2 pixels to the left
            child: MouseRegion(
              cursor: SystemMouseCursors.click, // Change cursor to 'click' style
              child: generateInPort(isDummy: isDummy, name: "Trigger In")
            ),
          ),
          // Text next to the rectangle
          Text(
            "Trigger In", // Static text for the trigger
            style: TextStyle(fontSize: 10, color: Colors.white, fontFamily: 'CascadiaCode'),
          ),
        ],
      ),
    ),

  ];
}





List<Widget> getOutPorts(FunctionNode nodeFunction, bool isDummy) {
  // List of widgets for outports
  List<Widget> outPortWidgets = [];

  // Add the return port row if the return type is not void
  if (nodeFunction.returnType != "void") {
    outPortWidgets.add(
      SizedBox(
        height: 25,
        child: Row(
          children: [
            // Text on the right
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  nodeFunction.returnName!, // Display the parameter's name
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontFamily: 'CascadiaCode',
                  ),
                ),
              ),
            ),
            // Rectangle that sticks out
            Transform.translate(
              offset: Offset(2, 0), // Move 2 pixels to the right
              child: MouseRegion(
                cursor: SystemMouseCursors.click, // Change cursor to 'click' style
                child: generateOutPort(isDummy: isDummy, name: nodeFunction.returnName!),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Always include the "Trigger Out" row
  outPortWidgets.add(
    SizedBox(
      height: 25,
      child: Row(
        children: [
          // Text on the right
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Trigger Out", // Static text for the trigger
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontFamily: 'CascadiaCode',
                ),
              ),
            ),
          ),
          // Rectangle that sticks out
          Transform.translate(
            offset: Offset(2, 0), // Move 2 pixels to the right
            child: MouseRegion(
              cursor: SystemMouseCursors.click, // Change cursor to 'click' style
              child: generateOutPort(isDummy: isDummy, name: "Trigger Out"),
            ),
          ),
        ],
      ),
    ),
  );

  return outPortWidgets;
}



  @override
Widget build(BuildContext context) {
  return Container(
decoration: BoxDecoration(
  color: color, // Background color
  borderRadius: const BorderRadius.all(Radius.circular(8)),
),

    child: Column(
      children: [
        // First container: Transparent container with spacing around the row
Container(
  color: Colors.transparent, // Vivid color for the main container
  height: 22,
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // First item: SVG icon with square aspect ratio
      Container(
    decoration: const BoxDecoration(
    border: Border(
      right: BorderSide(
        color: Colors.white, // White color for the border
        width: 1, // Border width of 1px
      ),
    ),
  ),
        child: Padding(
          padding: const EdgeInsets.all(3.0), // Padding for the first item
          child: svgIconString != null
              ? Container(
                  width: 16,
                  alignment: Alignment.center,
                  color: Colors.transparent, // Debugging color for this container
                  child: SvgPicture.string(
                    svgIconString!,
                    color: Colors.white,
                    ),
                )
              : Container(
                  width: 16,
                  alignment: Alignment.center,
                  color: Colors.transparent, // Debugging color for this container
                  child: const Icon(Icons.image_not_supported, size: 16),
                ),
        ),
      ),

      // Second item: Node name text in the center

  Text(
    nodeName ?? "Unknown Node",
    style: const TextStyle(fontSize: 14, color: Colors.white, fontFamily: 'CascadiaCode',),
  ),


      // Third item: Loading circle with square aspect ratio
      Padding(
        padding: const EdgeInsets.all(4.0), // Padding for the loading circle
        child: Container(
          width: 14,
          alignment: Alignment.center,
          color: Colors.transparent, // Debugging color for this container
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    ],
  ),
),

// Second container: Empty transparent container
Container(
  decoration: const BoxDecoration(
    border: Border(
      top: BorderSide(
        color: Colors.white, // White color for the border
        width: 1, // Border width of 1px
      ),
    ),
  ),
  child: Row(
    children: [
      // First column
      Expanded(
        child: Column(
          children: getInPorts(nodeFunction!), // Get the children from getPorts() for the first column
        ),
      ),
      // Second column
      Expanded(
        child: Column(
          children: getOutPorts(nodeFunction!, isDummy), // Get the children from getPorts() for the second column
        ),
      ),
    ],
  ),
),

        
      ],
    ),
  );
}
}






Widget outputNode({
  bool isDummy = false,
  Color accentColor = Colors.lightBlue,
  Color color = Colors.lightBlueAccent,
  String? nodeName, // Parameter for node text
  String? svgIconString, // SVG string for the icon
  FunctionNode? nodeFunction,
}) {

  // Calculate the height based on the number of outPorts
  //int numberOfPorts = outPorts.length;
  //double calculatedHeight = 20 * numberOfPorts + 20;
  double calculatedHeight = 20 * 1 + 20;

  return Container(
    color: Colors.transparent, // Make the container transparent
    child: Stack(
      clipBehavior: Clip.none, // Allow the ports to overflow the node bounds
      children: [
        // Main node container with border and radius, wrapped in a Center widget
        Center(
          child: Container(
            height: calculatedHeight - 3, // Set the calculated height for the entire node
            decoration: BoxDecoration(
              color: color, // Apply the main color to the node
              border: Border.all(color: Colors.grey, width: 1), // Thin border
              borderRadius: BorderRadius.circular(_NODE_EDGE_RADIUS), // Rounded corners for both sides
            ),
            child: Row(
              children: [
                // Left side accent color section with rounded corners
                Container(
                  width: 40, // Fixed width for accent color section
                  decoration: BoxDecoration(
                    color: accentColor, // Apply the accent color to the left side
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(_NODE_EDGE_RADIUS)), // Rounded corners for the left side
                  ),
                  child: Center(
                    child: svgIconString != null
                        ? SvgPicture.string(
                            svgIconString, // Use the SVG string
                            color: Colors.white, // Adjust color if necessary
                            width: 16.0, // Adjust the size of the SVG
                            height: 16.0,
                          )
                        : const Icon(
                            Icons.warning, // Fallback icon if SVG string is null
                            color: Colors.white,
                            size: 16.0, // Adjust the icon size
                          ),
                  ),
                ),
                // Vertical divider where the blue meets the accent blue
                Container(
                  width: 0.7, // Thin width for the divider
                  color: Colors.grey, // Same color as the border
                ),
                // Right side main section for the node content
                Expanded(
child: Container(
  color: Colors.transparent, // Keep transparent to let the border show
  child: Align(
    alignment: Alignment.centerLeft, // Align the text to the right
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0), // Add 5px space on left and right
      child: Text(
        nodeName ?? '', // Display the node text, default to empty string if null
        style: const TextStyle(
          color: Colors.black,
          fontFamily: 'CascadiaCode',
        ), // Customize the text style as needed
      ),
    ),
  ),
),

                ),
              ],
            ),
          ),
        ),
        // Overlay for out-ports (right side)
//        Positioned(
//          right: -9.5, // Stick out by -9.5px (half of port size)
//          top: 0,
//          bottom: 0,
//          child: Column(
//            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Evenly space out-ports vertically
//            children: outPorts.map((portName) {
//              return generateOutPort(isDummy: isDummy, name: portName);
//            }).toList(),
//          ),
//        ),
      ],
    ),
  );
}

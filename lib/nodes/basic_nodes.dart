import 'package:flutter/material.dart';
import 'package:node_editor/node_editor.dart';

double _DEFAULT_WIDTH = 200;
double _DEFAULT_RADIUS = 10;
Color _DEFAULT_NODE_COLOR = Colors.blue.shade800;
Color _DEFAULT_NODE_BORDER_COLOR = Colors.white;
double _DEFAULT_NODE_PADDING = 4;

NodeWidgetBase generateNode({
  required String name,
  required Widget nodeType,
  required void Function(LongPressStartDetails) onLongPressStart,
  required void Function(LongPressMoveUpdateDetails) onLongPressMoveUpdate,
  required void Function(LongPressEndDetails) onLongPressEnd,
}){
  return ContainerNodeWidget(
    name: name,
    typeName: 'node_3',
    backgroundColor: _DEFAULT_NODE_COLOR,
    radius: _DEFAULT_RADIUS,
    width: _DEFAULT_WIDTH,
    contentPadding: const EdgeInsets.all(4),
    selectedBorder: Border.all(color: Colors.white),
    child: GestureDetector(
      onLongPressStart: onLongPressStart,
      onLongPressMoveUpdate: onLongPressMoveUpdate,
      onLongPressEnd: onLongPressEnd,
      child: nodeType,
    ),
  );
}

Container generatePreviewNode({
  required Widget nodeType,
}){

  return Container(
    decoration: BoxDecoration(
      color: _DEFAULT_NODE_COLOR,
      borderRadius: BorderRadius.circular(_DEFAULT_RADIUS),
      border: Border.all(color: _DEFAULT_NODE_BORDER_COLOR), // Selected border
    ),
    width: _DEFAULT_WIDTH,
    padding: EdgeInsets.all(_DEFAULT_NODE_PADDING),
    child: nodeType,
  );
}

Widget generateInPort({
  bool isDummy = false,
  })
{
  if(isDummy){
    return Icon(
                  Icons.circle_outlined,
                  color: Colors.yellowAccent,
                  size: 20,
                );
  }
  else{
    return InPortWidget(
                name: 'PortIn1',
                onConnect: (String name, String port) => true,
                icon: Icon(
                  Icons.circle_outlined,
                  color: Colors.yellowAccent,
                  size: 20,
                ),
                iconConnected: Icon(
                  Icons.circle,
                  color: Colors.yellowAccent,
                  size: 20,
                ),
                multiConnections: false,
                connectionTheme: ConnectionTheme(
                  color: Colors.yellowAccent,
                  strokeWidth: 2,
                ),
              );
  }
}

Widget generateOutPort({
  bool isDummy = false,
  })
{
  if(isDummy){
    return Icon(
                  Icons.pause_circle_outline,
                  color: Colors.deepOrange,
                  size: 24,
                );
  }
  else{
    return OutPortWidget(
            name: 'PortOut1',
            icon: Icon(
              Icons.pause_circle_outline,
              color: Colors.deepOrange,
              size: 24,
            ),
            iconConnected: Icon(
              Icons.pause_circle,
              color: Colors.deepOrange,
              size: 24,
            ),
            multiConnections: false,
            connectionTheme: ConnectionTheme(
              color: Colors.deepOrange,
              strokeWidth: 2,
            ),
          );
  }
}


Widget basicNode({
  bool isDummy = false,
  })
{
  return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              generateInPort(isDummy: isDummy)
            ],
          ),
          Icon(Icons.safety_divider),
          generateOutPort(isDummy: isDummy)
        ],
      );
}
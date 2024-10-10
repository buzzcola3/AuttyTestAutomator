import 'package:flutter/material.dart';
import 'package:node_editor/node_editor.dart';
import '../basic_nodes.dart';

class NodeEditorWidget extends StatefulWidget {
  const NodeEditorWidget({super.key});

  @override
  _NodeEditorWidgetState createState() => _NodeEditorWidgetState();
}

class _NodeEditorWidgetState extends State<NodeEditorWidget> {
  late NodeEditorController _controller;
  late FocusNode _focusNode;

  String? _currentDraggedNodeId;
  Offset _currentDraggedPosition = Offset(0, 0);
  double dragStep = 20.0;

  @override
  void initState() {
    super.initState();
    _controller = NodeEditorController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Offset _dragGridSnap(Offset draggingPosition) {
    double dragPosX = _currentDraggedPosition.dx;
    double dragPosY = _currentDraggedPosition.dy;

    double dragDeltaX = dragPosX - draggingPosition.dx;
    double dragDeltaY = dragPosY - draggingPosition.dy;

    double snapDragDeltaX = 0;
    double snapDragDeltaY = 0;

    if (dragDeltaX >= dragStep) {
      snapDragDeltaX -= dragStep;
      dragPosX -= dragStep;
      _currentDraggedPosition = Offset(dragPosX, _currentDraggedPosition.dy);
    }

    if (dragDeltaX <= -dragStep) {
      snapDragDeltaX += dragStep;
      dragPosX += dragStep;
      _currentDraggedPosition = Offset(dragPosX, _currentDraggedPosition.dy);
    }

    if (dragDeltaY >= dragStep) {
      snapDragDeltaY -= dragStep;
      dragPosY -= dragStep;
      _currentDraggedPosition = Offset(_currentDraggedPosition.dx, dragPosY);
    }

    if (dragDeltaY <= -dragStep) {
      snapDragDeltaY += dragStep;
      dragPosY += dragStep;
      _currentDraggedPosition = Offset(_currentDraggedPosition.dx, dragPosY);
    }

    return Offset(snapDragDeltaX, snapDragDeltaY);
  }

  void _addNodeAtPosition(Offset position) {
    int nodeId = _controller.nodes.length + 1;
    String nodeName = 'node_$nodeId';

    _controller.addNode(
      generateNode(
        nodeType: basicNode(isDummy: false),
        name: nodeName,
        onLongPressStart: (details) {
          _currentDraggedNodeId = nodeName;
          _currentDraggedPosition = details.globalPosition;
          print('Long press started at: ${details.globalPosition}');
        },
        onLongPressMoveUpdate: (details) {
          if (_currentDraggedNodeId != null) {
            Offset cursorDelta = _dragGridSnap(details.globalPosition);
            _controller.moveNodePosition(_currentDraggedNodeId!, cursorDelta);
            print('Cursor Position during drag: $cursorDelta');
          }
        },
        onLongPressEnd: (details) {
          _currentDraggedNodeId = null;
          print('Long press ended');
        },
      ),
      //NodePosition.custom(Offset(position.dx, position.dy)), // Add the node at the drop position
      NodePosition.centerScreen,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          DragTarget<String>(
            onAcceptWithDetails: (details) {
              print('Item dropped: ${details.data}');
              print('Drop location: ${details.offset}');
              // Trigger the node addition at the drop position
              _addNodeAtPosition(details.offset);
            },
            builder: (context, candidateData, rejectedData) {
              return MouseRegion(
                child: NodeEditor(
                  focusNode: _focusNode,
                  controller: _controller,
                  background: const GridBackground(),
                  infiniteCanvasSize: 5000,
                ),
              );
            },
          ),
          Positioned(
            top: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () => _addNodeAtPosition(Offset(100, 100)), // Default add node at (100, 100)
              child: const Icon(Icons.add),
              tooltip: 'Add Node',
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:node_editor/node_editor.dart';
import '../node_generation/node_generator.dart';

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
  double dragStep = 20.0; //TODO: make this be one definition of grid size
  
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

  void _addNode() {
    // Example: Add node at a specific position on the screen
    _addNodeAtPosition(
      const Offset(200, 200), 
      basicNode(isDummy: false)
    );
  }

  void _playground_scroll_handle(Offset offset){
    double hor_pos = _controller.horizontalScrollController.offset;
    double ver_pos = _controller.verticalScrollController.offset;

    hor_pos -= offset.dx;
    ver_pos -= offset.dy;

    _controller.horizontalScrollController.jumpTo(hor_pos);
    _controller.verticalScrollController.jumpTo(ver_pos);
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

  void _addNodeAtPosition(Offset position, Widget node) {
    int nodeId = _controller.nodes.length + 1;
    String nodeName = 'node_$nodeId';

    _controller.addNode(
      generateNode(
        nodeType: node,
        name: nodeName,
        onPanStart: (details) {
          _currentDraggedNodeId = nodeName;
          _currentDraggedPosition = details.globalPosition;
          print('Pan started at: ${details.globalPosition}');
        },
        onPanUpdate: (details) {
          if (_currentDraggedNodeId != null) {
            Offset cursorDelta = _dragGridSnap(details.globalPosition);
            _controller.moveNodePosition(_currentDraggedNodeId!, cursorDelta);
            print('Cursor Position during drag: $cursorDelta');
          }
        },
        onPanEnd: (details) {
          _currentDraggedNodeId = null;
          print('Pan ended');
        },
      ),
      NodePosition.custom(position),
    );

  }

    double _snapToGrid(double value) {
      return (value / 20).round() * 20; //TODO grid size
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.green,
        ),
        child: GestureDetector(
          onPanUpdate: (details) {
            // Handle pan (drag) gesture
            _playground_scroll_handle(details.delta);
            // You can implement custom behavior for dragging here
          },
          onTap: () {
            // Handle tap gesture
            print('NodeEditorWidget tapped');
          },
          child: Stack(
            children: [
              DragTarget<Widget>(
                onAcceptWithDetails: (details) {     
                  // Calculate absolute position of the drop on the playground
                  Offset playgroundAbsPos = details.offset - (_controller.stackPos ?? Offset.zero);
                
                  // Calculate relative position by adding scroll offsets
                  Offset playgroundRelPos = Offset(
                    playgroundAbsPos.dx + _controller.horizontalScrollController.offset,
                    playgroundAbsPos.dy + _controller.verticalScrollController.offset,
                  );
        
                  Offset snappedPos = Offset(
                    _snapToGrid(playgroundRelPos.dx),
                    _snapToGrid(playgroundRelPos.dy),
                  );
        
                  Offset finalPos = Offset(
                    snappedPos.dx < 0 ? 0 : snappedPos.dx,
                    snappedPos.dy < 0 ? 0 : snappedPos.dy,
                  );
                
                  // Trigger the node addition at the calculated drop position
                  _addNodeAtPosition(finalPos, details.data);
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
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNode, // Calls _addNode which in turn calls _addNodeAtPosition
        child: const Icon(Icons.add),
        tooltip: 'Add Node',
      ),
    );
  }
}

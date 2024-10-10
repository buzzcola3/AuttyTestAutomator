import 'package:flutter/material.dart';
import 'package:node_editor/node_editor.dart';

class NodePreviewWidget extends StatefulWidget {
  const NodePreviewWidget({super.key});

  @override
  _NodePreviewWidgetState createState() => _NodePreviewWidgetState();
}

class _NodePreviewWidgetState extends State<NodePreviewWidget> {
  late NodeEditorController _controller;
  late FocusNode _focusNode;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MouseRegion(
        child: NodeEditor(
          focusNode: _focusNode,
          controller: _controller,
          background: const GridBackground(),
          infiniteCanvasSize: 5000,
        ),
      ),
    );
  }
}

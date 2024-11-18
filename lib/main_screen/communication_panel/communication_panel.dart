import 'package:attempt_two/main_screen/device_list/websocket_manager/headers/websocket_datatypes.dart';
import 'package:flutter/material.dart';

enum ConsoleTab { websocket, execute, log }
enum MessageType { generic, error, response, request, info, warning }

class DebugConsoleController {
  final GlobalKey<_DebugConsoleState> _key = GlobalKey<_DebugConsoleState>();

  GlobalKey<_DebugConsoleState> get key => _key;

  /// Adds a message to the console
  void addMessage(dynamic message, MessageType type, ConsoleTab tab) {
    if (type == MessageType.request && message is! WsMessage) {
      throw ArgumentError(
        'Messages of type "request" must be of type WsMessage.',
      );
    }
    _key.currentState?._addMessage({'message': message, 'type': type}, tab: tab);
  }

  /// Scrolls to the bottom of the console
  void scrollToBottom() {
    _key.currentState?._scrollToBottom();
  }
}

// Main Debug Console widget
class DebugConsole extends StatefulWidget {
  const DebugConsole({Key? key}) : super(key: key);

  @override
  _DebugConsoleState createState() => _DebugConsoleState();
}

class _DebugConsoleState extends State<DebugConsole>
    with SingleTickerProviderStateMixin {
  final Map<ConsoleTab, List<dynamic>> _tabMessages = {
    ConsoleTab.websocket: [],
    ConsoleTab.execute: [],
    ConsoleTab.log: [],
  };

  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;

  bool _autoScrollEnabled = true;
  bool _showScrollToBottomButton = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: ConsoleTab.values.length, vsync: this);
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    final nearBottom =
        _scrollController.offset < _scrollController.position.maxScrollExtent - 100;
    setState(() {
      _showScrollToBottomButton = nearBottom;
      _autoScrollEnabled = !nearBottom;
    });
  }

  /// Adds a message to the specified tab
  void _addMessage(dynamic message, {required ConsoleTab tab}) {
    setState(() {
      _tabMessages[tab]?.add(message);
    });
    if (_autoScrollEnabled) _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

@override
Widget build(BuildContext context) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10), // Rounded corners for the entire widget
      border: Border.all(
        color: Colors.grey, // Gray color
        width: 2,           // 2px wide border
      ),
    ),
    child: Stack(
      children: [
        // Main content with TabBarView
        Column(
          children: [
            // TabBarView for the tabs (Body content)
            Expanded(
              child: Container(
                child: TabBarView(
                  controller: _tabController,
                  children: ConsoleTab.values.map((tab) => _buildTabContent(_tabMessages[tab]!)).toList(),
                ),
              ),
            ),
            // Container for the icons (acting as the custom AppBar)
            Container(
              color: Colors.transparent, // Background color for the button row
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start, // Align icons to the right
                children: [
                  IconButton(
                    icon: Icon(Icons.web),
                    onPressed: () {
                      // Switch to the first tab
                      _tabController.animateTo(0);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.play_arrow),
                    onPressed: () {
                      // Switch to the second tab
                      _tabController.animateTo(1);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.list),
                    onPressed: () {
                      // Switch to the third tab
                      _tabController.animateTo(2);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        
        // Floating Action Button (independent of the custom AppBar)
        if (_showScrollToBottomButton)
          Positioned(
            bottom: 16.0, // Adjust the position from the bottom
            right: 16.0,  // Adjust the position from the right
            child: FloatingActionButton(
              onPressed: _scrollToBottom,
              child: const Icon(Icons.arrow_downward),
            ),
          ),
      ],
    ),
  );
}


Widget _buildTabContent(List<dynamic> messages) {
  return ListView.builder(
    controller: _scrollController,
    itemCount: messages.length,
    itemBuilder: (context, index) {
      final message = messages[index];
      if (message['message'] is WsMessage) {
        return _buildWsMessageTile(message['message']);
      } else if (message['message'] is String) {
         return _buildTextMessageTile(
           message['message'],
           message['type'] ?? MessageType.generic,
         );
      }
      return const SizedBox.shrink();
    },
  );
}







Widget _buildWsMessageTile(WsMessage message) {
  final style = _getMessageStyle(MessageType.request); // Assuming WsMessage always uses `request`

  return Container(
    decoration: BoxDecoration(
      color: style.backgroundColor, // Tile background color
      border: const Border(
        bottom: BorderSide(color: Colors.grey, width: 1), // Bottom border
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Add extra space from the left
            const SizedBox(width: 8), // Spacing from the left before the icon
            if (style.icon != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 20, maxHeight: 20), // Icon size constraints
                child: style.icon,
              ),
            const SizedBox(width: 10), // Spacing between icon and text
            Expanded(
              child: Text(
                message.message,
                style: TextStyle(color: style.textColor, fontSize: 14),
              ),
            ),
            IconButton(
              icon: Icon(
                message.fulfilled ? Icons.check_circle : Icons.circle_outlined, // Filled circle if fulfilled
                color: message.fulfilled ? Colors.green : Colors.grey,
                size: 16, // Icon size
              ),
              onPressed: () {
                // Toggle fulfilled state when button is pressed
                setState(() {
                  message.fulfilled = !message.fulfilled;
                });
              },
            ),
          ],
        ),
        if (message.fulfilled)
          Padding(
            padding: const EdgeInsets.only(left: 40.0), // Indentation for response text
            child: Text(
              message.rawResponse ?? "No response available", // Display response if fulfilled
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ),
      ],
    ),
  );
}





Widget _buildTextMessageTile(String text, MessageType type) {
  final style = _getMessageStyle(type);

  return Container(
    decoration: BoxDecoration(
      color: style.backgroundColor, // Tile background color
      border: const Border(
        bottom: BorderSide(color: Colors.grey, width: 1), // Bottom border
      ),
    ),
    child: SizedBox(
      height: 40, // Set a fixed height for the tile to prevent it from shrinking
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Center the icon vertically
        children: [
          // Add extra space from the left before the icon
          const SizedBox(width: 8), // Spacing from the left before the icon
          if (style.icon != null)
            style.icon!, // Add icon if not null
          const SizedBox(width: 10), // Spacing between icon and text
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: style.textColor, fontSize: 14),
              overflow: TextOverflow.ellipsis, // Truncate text if it overflows
              maxLines: 1, // Limit the text to a single line
            ),
          ),
        ],
      ),
    ),
  );
}







  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
}

class MessageStyle {
  final Color textColor;
  final Color backgroundColor;
  final Icon? icon;

  const MessageStyle({
    required this.textColor,
    required this.backgroundColor,
    this.icon,
  });
}

MessageStyle _getMessageStyle(MessageType type) {
  switch (type) {
    case MessageType.error:
      return MessageStyle(
        textColor: Colors.redAccent,
        backgroundColor: Colors.transparent,
        icon: const Icon(
          Icons.error,
          color: Color.fromARGB(255, 58, 58, 58),
          size: 16, // Set icon size to 16
        ),
      );
    case MessageType.response:
      return MessageStyle(
        textColor: Colors.grey[400]!,
        backgroundColor: Colors.grey.withOpacity(0.1),
        icon: const Icon(
          Icons.reply,
          color: Color.fromARGB(255, 58, 58, 58),
          size: 16, // Set icon size to 16
        ),
      );
    case MessageType.request:
      return const MessageStyle(
        textColor: Colors.black,
        backgroundColor: Colors.transparent,
        icon: Icon(
          Icons.arrow_forward, // Small ">" icon
          color: Color.fromARGB(255, 58, 58, 58),
          size: 16, // Set icon size to 16
        ),
      );
    case MessageType.info:
      return MessageStyle(
        textColor: Colors.cyan,
        backgroundColor: Colors.cyan.withOpacity(0.1),
        icon: const Icon(
          Icons.info,
          color: Color.fromARGB(255, 58, 58, 58),
          size: 16, // Set icon size to 16
        ),
      );
    case MessageType.warning:
      return MessageStyle(
        textColor: Colors.amber,
        backgroundColor: Colors.amber.withOpacity(0.1),
        icon: const Icon(
          Icons.warning,
          color: Color.fromARGB(255, 58, 58, 58),
          size: 16, // Set icon size to 16
        ),
      );
    default:
      return const MessageStyle(
        textColor: Colors.black,
        backgroundColor: Colors.transparent,
        icon: Icon(
          Icons.message,
          color: Color.fromARGB(255, 58, 58, 58),
          size: 16, // Set icon size to 16
        ),
      );
  }
}


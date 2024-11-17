import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:attempt_two/userdata_database.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:attempt_two/main_screen/node_playground_file_manager/playground_save_and_load.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter_svg/flutter_svg.dart';

class JsonFileManager extends StatefulWidget {
  final PlaygroundSaveLoad playgroundSaveLoad;
  final UserdataDatabase userdataDatabase;

  const JsonFileManager({
    super.key,
    required this.playgroundSaveLoad,
    required this.userdataDatabase
    });

  @override
  _JsonFileManagerState createState() => _JsonFileManagerState();
}

class _JsonFileManagerState extends State<JsonFileManager> {
  List<Map<String, dynamic>> jsonFiles = [];
  Map<String, Uint8List> fileContents = {};
  int? executingIndex;

Future<void> _executeAllFiles() async {
  for (int i = 0; i < jsonFiles.length; i++) {
    setState(() {
      executingIndex = i;
      jsonFiles[i]['status'] = null; // Reset status during execution
    });

    final fileName = jsonFiles[i]['name'];
    bool success = false;

    if (fileContents.containsKey(fileName)) {
      String jsonContent = utf8.decode(fileContents[fileName]!);
      success = await widget.playgroundSaveLoad.loadAndExecutePlayground(jsonContent);
    } else {
      print('No content found for $fileName');
    }

    // Update the status based on the execution result
    setState(() {
      jsonFiles[i]['status'] = success ? 'success' : 'failure';
    });

    // Optional delay for UI
    await Future.delayed(const Duration(milliseconds: 500));
  }

  setState(() {
    executingIndex = null; // Reset executing index
  });
}



  Future<void> _loadFileToPlayground(int index) async {
    final fileName = jsonFiles[index]['name'];

    if (fileContents.containsKey(fileName)) {
      String jsonContent = utf8.decode(fileContents[fileName]!);
      widget.playgroundSaveLoad.loadPlayground(jsonContent);

      print('Executing JSON from $fileName: $jsonContent');
    } else {
      print('No content found for $fileName');
    }
  }

  Future<void> _pickFiles() async {
    var result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['json', 'zip'],
    );
  
    if (result != null) {
      for (var file in result.files) {
        if (file.path != null) {
          final File selectedFile = File(file.path!);
  
          if (file.extension == 'json') {
            // Handle individual JSON files
            try {
              String jsonString = await selectedFile.readAsString();
              Map<String, dynamic> jsonContent = jsonDecode(jsonString);
  
              setState(() {
                jsonFiles.add({'name': file.name, 'content': jsonContent, 'hover': false});
                fileContents[file.name] = Uint8List.fromList(utf8.encode(jsonString));
              });
            } catch (e) {
              print('Error reading JSON from file ${file.name}: $e');
            }
          } else if (file.extension == 'zip') {
            // Handle ZIP files
            try {
              final zipData = await selectedFile.readAsBytes();
              final archive = ZipDecoder().decodeBytes(zipData);
              List<String> orderList = [];
              Map<String, Map<String, dynamic>> tempJsonFiles = {};
  
              // Read the order file if it exists
              for (var archiveFile in archive) {
                if (archiveFile.isFile && archiveFile.name == 'file.order') {
                  final orderContent = utf8.decode(archiveFile.content as List<int>);
                  final jsonOrder = jsonDecode(orderContent);
                  orderList = List<String>.from(jsonOrder["file_order"]);
                  break;
                }
              }
  
              // Parse JSON files and store them temporarily
              for (var archiveFile in archive) {
                if (archiveFile.isFile && archiveFile.name.endsWith('.json') && archiveFile.name != 'file.order') {
                  final jsonString = utf8.decode(archiveFile.content as List<int>);
                  Map<String, dynamic> jsonContent = jsonDecode(jsonString);
                  tempJsonFiles[archiveFile.name] = {'content': jsonContent, 'data': Uint8List.fromList(utf8.encode(jsonString))};
                }
              }
  
              // Arrange files based on the order list
              setState(() {
                for (var fileName in orderList) {
                  if (tempJsonFiles.containsKey(fileName)) {
                    jsonFiles.add({'name': fileName, 'content': tempJsonFiles[fileName]!['content'], 'hover': false});
                    fileContents[fileName] = tempJsonFiles[fileName]!['data'];
                  }
                }
  
                // Add remaining files not listed in file.order
                for (var entry in tempJsonFiles.entries) {
                  if (!orderList.contains(entry.key)) {
                    jsonFiles.add({'name': entry.key, 'content': entry.value['content'], 'hover': false});
                    fileContents[entry.key] = entry.value['data'];
                  }
                }
              });
            } catch (e) {
              print('Error reading ZIP file ${file.name}: $e');
            }
          } else {
            print('Unsupported file type: ${file.name}');
          }
        }
      }
    }
  }

  Future<void> _renameFile(int index) async {
    final currentName = jsonFiles[index]['name'];
    final controller = TextEditingController(text: currentName.replaceAll('.json', ''));

    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Rename File"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Enter new name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text("Rename"),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() {
        final jsonContent = widget.playgroundSaveLoad.saveToJson();
        jsonFiles[index]['name'] = '$newName.json';
        fileContents['$newName.json'] = Uint8List.fromList(utf8.encode(jsonContent));
        fileContents.remove(currentName);
      });
    }
  }

  Future<void> _downloadFile(String fileName) async {
    final Uint8List bytes = fileContents[fileName]!;

    try {
      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        mimeType: MimeType.json,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$fileName saved to Downloads folder successfully!')),
      );
    } catch (e) {
      print('Error saving file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save $fileName')),
      );
    }
  }

  Future<void> _downloadAllAsZip() async {
    final controller = TextEditingController();
    final zipFileName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Save as Zip"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Enter zip file name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  
    if (zipFileName != null && zipFileName.isNotEmpty) {
      final archive = Archive();
  
      // Add each JSON file to the archive
      for (var entry in fileContents.entries) {
        archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
      }
  
      // Create the .order file content
      List<String> fileOrder = jsonFiles.map((file) => file['name'] as String).toList();
      String orderJson = jsonEncode({'file_order': fileOrder});
      Uint8List orderData = Uint8List.fromList(utf8.encode(orderJson));
  
      // Add the .order file to the archive
      archive.addFile(ArchiveFile('file.order', orderData.length, orderData));
  
      // Encode the archive to zip format
      final zipData = ZipEncoder().encode(archive)!;
  
      try {
        await FileSaver.instance.saveFile(
          name: '$zipFileName.zip',
          bytes: Uint8List.fromList(zipData),
          mimeType: MimeType.zip,
        );
  
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$zipFileName.zip saved to Downloads folder successfully!')),
        );
      } catch (e) {
        print('Error saving zip file: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save $zipFileName.zip')),
        );
      }
    }
  }

  void _deleteFile(int index) {
    setState(() {
      final fileName = jsonFiles[index]['name'];
      jsonFiles.removeAt(index);
      fileContents.remove(fileName);
    });
  }

  void _savePlayground() async {
    final controller = TextEditingController();
    final newFileName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Save Playground"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Enter file name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    if (newFileName != null && newFileName.isNotEmpty) {
      String playgroundJson = widget.playgroundSaveLoad.savePlayground();
      Uint8List fileContent = Uint8List.fromList(utf8.encode(playgroundJson));

      setState(() {
        final fullFileName = '$newFileName.json';
        jsonFiles.add({'name': fullFileName, 'content': jsonDecode(playgroundJson), 'hover': false});
        fileContents[fullFileName] = fileContent;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$newFileName.json saved!')),
      );
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 2.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          // Top action icons
Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    IconButton(
      padding: new EdgeInsets.all(0.0),
      icon: SvgPicture.asset(
        'lib/svg_icons/playground_list_execute_icon.svg',
        width: 32,  // Larger icon size
        height: 32, // Larger icon size
        color: const Color.fromARGB(255, 58, 58, 58),
      ),
      onPressed: _executeAllFiles,
    ),
    IconButton(
      icon: SvgPicture.asset(
        'lib/svg_icons/playground_download_icon.svg',
        width: 24,
        height: 24,
        color: const Color.fromARGB(255, 58, 58, 58),
      ),
      onPressed: _downloadAllAsZip,
    ),
    IconButton(
      icon: SvgPicture.asset(
        'lib/svg_icons/playground_upload_icon.svg',
        width: 24,
        height: 24,
        color: const Color.fromARGB(255, 58, 58, 58),
      ),
      onPressed: _pickFiles,
    ),
    IconButton(
      icon: SvgPicture.asset(
        'lib/svg_icons/playground_save_icon.svg',
        width: 24,
        height: 24,
        color: const Color.fromARGB(255, 58, 58, 58),
      ),
      onPressed: _savePlayground,
    ),
  ],
),

          
          // List of JSON files with reordering
          Expanded(
            child: Overlay(
              initialEntries: [
                OverlayEntry(builder: (context){
                  return                ReorderableListView.builder(
                buildDefaultDragHandles: false, // Disable default drag handles
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = jsonFiles.removeAt(oldIndex);
                    jsonFiles.insert(newIndex, item);
                  });
                },
                itemCount: jsonFiles.length,
                itemBuilder: (context, index) {
                  final status = jsonFiles[index]['status'];
                  final color = status == 'success'
                    ? Colors.green
                      : status == 'failure'
                        ? Colors.red
                          : executingIndex == index
                            ? Colors.blue
                              : Colors.grey[300];
                              
                  return MouseRegion(
                    key: ValueKey(jsonFiles[index]['name']),
                    onEnter: (_) => setState(() => jsonFiles[index]['hover'] = true),
                    onExit: (_) => setState(() => jsonFiles[index]['hover'] = false),
                    child: Container(
                      color: color,
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      height: 40,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Row(
                            children: [
                              if (!jsonFiles[index]['hover'])
                                const Icon(Icons.insert_drive_file, size: 18, color: Color.fromARGB(255, 58, 58, 58)),
                              const SizedBox(width: 8),
                              Text(
                                !jsonFiles[index]['hover'] ? jsonFiles[index]['name'] : "",
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                            ],
                          ),
                          if (jsonFiles[index]['hover'])
                            Positioned(
                              right: 0,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Custom drag handle for reordering within the hover overlay
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: const Icon(Icons.drag_handle, size: 20, color: Color.fromARGB(255, 58, 58, 58)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.play_arrow, size: 20, color: Color.fromARGB(255, 58, 58, 58)),
                                    onPressed: () => _loadFileToPlayground(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20, color: Color.fromARGB(255, 58, 58, 58)),
                                    onPressed: () => _renameFile(index),
                                  ),
                                  IconButton(
                                    icon: SvgPicture.asset(
                                      'lib/svg_icons/playground_download_icon.svg',
                                      width: 20,
                                      height: 20,
                                      color: const Color.fromARGB(255, 58, 58, 58),
                                    ),
                                    onPressed: () => _downloadFile(jsonFiles[index]['name']),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Color.fromARGB(255, 58, 58, 58)),
                                    onPressed: () => _deleteFile(index),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
                })
              ],

            ),
          ),
        ],
      ),
    ),
  );
}




}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:Autty/userdata_database.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:Autty/main_screen/node_playground_file_manager/playground_save_and_load.dart';
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
  

  @override
  void initState() {
    super.initState();
    _initializeFileManager();
    setState(() {
      
    });
  }

  void _initializeFileManager() async {
    await _restoreFilesFromInternalDatabase();
  }

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
          await _importJsonFile(selectedFile, file.name);
          _saveFilesToInternalDatabase();
        } else if (file.extension == 'zip') {
          await _importZipFile(selectedFile);
          _saveFilesToInternalDatabase();
        } else {
          print('Unsupported file type: ${file.name}');
        }
      }
    }
  }
}

Future<void> _importJsonFile(File selectedFile, String fileName) async {
  try {
    // Ensure unique filename
    String uniqueFileName = fileName;
    while (_doesFileNameExist(uniqueFileName)) {
      uniqueFileName = _incrementFileName(uniqueFileName);
    }

    // Read and decode JSON content
    String jsonString = await selectedFile.readAsString();
    Map<String, dynamic> jsonContent = jsonDecode(jsonString);

    setState(() {
      jsonFiles.add({'name': uniqueFileName, 'content': jsonContent, 'hover': false});
      fileContents[uniqueFileName] = Uint8List.fromList(utf8.encode(jsonString));
    });
  } catch (e) {
    print('Error reading JSON from file $fileName: $e');
  }
}

Future<void> _importZipFile(File selectedFile) async {
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

        // Ensure unique filename
        String uniqueName = archiveFile.name;
        while (_doesFileNameExist(uniqueName)) {
          uniqueName = _incrementFileName(uniqueName);
        }

        tempJsonFiles[uniqueName] = {
          'content': jsonContent,
          'data': Uint8List.fromList(utf8.encode(jsonString)),
        };
      }
    }

    // Arrange files based on the order list
    setState(() {
      for (var fileName in orderList) {
        if (tempJsonFiles.containsKey(fileName)) {
          jsonFiles.add({
            'name': fileName,
            'content': tempJsonFiles[fileName]!['content'],
            'hover': false,
          });
          fileContents[fileName] = tempJsonFiles[fileName]!['data'];
        }
      }

      // Add remaining files not listed in file.order
      for (var entry in tempJsonFiles.entries) {
        if (!orderList.contains(entry.key)) {
          jsonFiles.add({
            'name': entry.key,
            'content': entry.value['content'],
            'hover': false,
          });
          fileContents[entry.key] = entry.value['data'];
        }
      }
    });
  } catch (e) {
    print('Error reading ZIP file: $e');
  }
}

// Helper function to increment the file name by adding underscores
String _incrementFileName(String fileName) {
  final nameWithoutExtension = fileName.replaceAll('.json', '');
  return '${nameWithoutExtension}_.json';
}


Future<void> _renameFile(int index) async {
  final currentName = jsonFiles[index]['name'];
  final controller = TextEditingController(text: currentName.replaceAll('.json', ''));

  String? newName;

  do {
    newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Rename File"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: "Enter new name"),
              ),
              if (newName != null && _doesFileNameExist('$newName.json'))
                const Text(
                  "A file with this name already exists. Please choose a different name.",
                  style: TextStyle(color: Colors.red),
                ),
            ],
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

    if (newName == null) {
      return; // User canceled the operation
    }
  } while (_doesFileNameExist('$newName.json'));

  if (newName.isNotEmpty) {
    setState(() {
      fileContents['$newName.json'] = fileContents[jsonFiles[index]['name']]!;
      fileContents.remove(jsonFiles[index]['name']);
      jsonFiles[index]['name'] = '$newName.json';
      
    });
    _saveFilesToInternalDatabase();
  }
}

bool _doesFileNameExist(String name) {
  return jsonFiles.any((file) => file['name'] == name);
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

  Future<List<int>> _getFileManagerZipData() async {
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
    return zipData;
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
      final zipData = await _getFileManagerZipData();
  
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
    _saveFilesToInternalDatabase();
  }

  void _saveFilesToInternalDatabase() async {
    final zipData = await _getFileManagerZipData();
    widget.userdataDatabase.saveFileManagerData(zipData);
  }

Future<void> _restoreFilesFromInternalDatabase() async {
  try {
    // Retrieve ZIP data from the database
    List<int> zipData = await widget.userdataDatabase.getFileManagerData();

    // Pass the data to a helper function for ZIP processing
    await _processZipData(Uint8List.fromList(zipData));
  } catch (e) {
    print("Error restoring files from database: $e");
  }
}

Future<void> _processZipData(Uint8List zipData) async {
  try {
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
        tempJsonFiles[archiveFile.name] = {
          'content': jsonContent,
          'data': Uint8List.fromList(utf8.encode(jsonString)),
        };
      }
    }

    // Arrange files based on the order list
    setState(() {
      for (var fileName in orderList) {
        if (tempJsonFiles.containsKey(fileName)) {
          jsonFiles.add({
            'name': fileName,
            'content': tempJsonFiles[fileName]!['content'],
            'hover': false,
          });
          fileContents[fileName] = tempJsonFiles[fileName]!['data'];
        }
      }

      // Add remaining files not listed in file.order
      for (var entry in tempJsonFiles.entries) {
        if (!orderList.contains(entry.key)) {
          jsonFiles.add({
            'name': entry.key,
            'content': entry.value['content'],
            'hover': false,
          });
          fileContents[entry.key] = entry.value['data'];
        }
      }
    });
  } catch (e) {
    print("Error processing ZIP data: $e");
  }
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
    String fullFileName = '$newFileName.json';

    // Check if the file already exists
    bool fileExists = jsonFiles.any((file) => file['name'] == fullFileName);

    if (fileExists) {
      // Show a dialog to ask if the user wants to overwrite the file
      bool overwrite = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("File Already Exists"),
            content: const Text("A file with this name already exists. Do you want to overwrite it?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Overwrite"),
              ),
            ],
          );
        },
      ) ?? false;

      if (!overwrite) {
        // If user doesn't want to overwrite, do nothing
        return;
      }

      // Remove the existing file before saving the new one
      setState(() {
        jsonFiles.removeWhere((file) => file['name'] == fullFileName);
        fileContents.remove(fullFileName);
      });
    }

    // Save the new file
    String playgroundJson = widget.playgroundSaveLoad.savePlayground();
    Uint8List fileContent = Uint8List.fromList(utf8.encode(playgroundJson));

    setState(() {
      jsonFiles.add({'name': fullFileName, 'content': jsonDecode(playgroundJson), 'hover': false});
      fileContents[fullFileName] = fileContent;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$newFileName.json saved!')),
    );

    _saveFilesToInternalDatabase();
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
                  _saveFilesToInternalDatabase();
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

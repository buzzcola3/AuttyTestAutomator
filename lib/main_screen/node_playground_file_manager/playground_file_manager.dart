import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:Autty/main_screen/node_playground_file_manager/file_datatypes.dart';
import 'package:Autty/userdata_database.dart';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:Autty/main_screen/node_playground/playground_save_and_load.dart';
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
  AuttyJsonFileFolder auttyJsonFileFolder = AuttyJsonFileFolder();
  int? executingIndex;
  int? hoverIndex;
  

  @override
  void initState() {
    super.initState();
    _initializeFileManager();
    setState(() {
      
    });
  }

  void _initializeFileManager() async {
//    await _restoreFilesFromInternalDatabase();
  }

Future<void> _executeAllFiles() async {
  for (int i = 0; i < auttyJsonFileFolder.files.length; i++) {
    setState(() {
      executingIndex = i;
    });

    bool success = false;
    success = await widget.playgroundSaveLoad.loadAndExecutePlayground(json.decode(auttyJsonFileFolder.files[i].nodePlaygroundData));


    // Update the status based on the execution result
    setState(() {
      auttyJsonFileFolder.files[i].executionResultSuccess = success;
    });

    // Optional delay for UI
    await Future.delayed(const Duration(milliseconds: 500));
  }

  setState(() {
    executingIndex = null; // Reset executing index
  });
}



  Future<void> _loadFileToPlayground(int index) async {
    widget.playgroundSaveLoad.loadPlayground(json.decode(auttyJsonFileFolder.files[index].nodePlaygroundData));
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

        } else if (file.extension == 'zip') {
          await _importZipFile(selectedFile);

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
    AuttyJsonFile auttyJsonFile = AuttyJsonFile.fromJsonString(jsonString);


    setState(() {
      auttyJsonFileFolder.addFile(auttyJsonFile);
    });
  } catch (e) {
    print('Error reading JSON from file $fileName: $e');
  }
}

Future<void> _importZipFile(File selectedFile) async {
  try {
    final zipData = await selectedFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(zipData);

    // Parse JSON files and store them temporarily
    for (var archiveFile in archive) {
      if (archiveFile.isFile && archiveFile.name.endsWith('.json')) {
        final jsonString = utf8.decode(archiveFile.content as List<int>);
        AuttyJsonFile file = AuttyJsonFile.fromJsonString(jsonString);

        auttyJsonFileFolder.addFile(file);
      }
    }

    // Arrange files based on the order list
    setState(() {
      auttyJsonFileFolder.files;
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


Future<void> _renameFile(String currentName) async {
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
      auttyJsonFileFolder.renameFile(currentName, '${newName!}.json');
    });
  }
}

  bool _doesFileNameExist(String name) {
    return auttyJsonFileFolder.files.any((file) => file.filename == name);
  }


  Future<void> _downloadFile(int index) async {
    final jsonData = auttyJsonFileFolder.files[index].toJson(); // Get JSON data
    final String jsonString = jsonEncode(jsonData); // Convert to JSON string
    final Uint8List bytes = Uint8List.fromList(utf8.encode(jsonString)); // Convert string to bytes
  
    final String fileName = auttyJsonFileFolder.files[index].filename; // Use filename from the file object
  
    try {
      await FileSaver.instance.saveFile(
        name: fileName, // Use fileName here
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
      final zipData = auttyJsonFileFolder.exportAsZip();
  
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
    final fileName = auttyJsonFileFolder.files[index].filename;
    setState(() {
      auttyJsonFileFolder.removeFile(filename: fileName);
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
    String fullFileName = '$newFileName.json';

    // Check if the file already exists
    bool fileExists = _doesFileNameExist(fullFileName);

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
        auttyJsonFileFolder.removeFile(filename: fullFileName);
      });
    }

    // Save the new file
    int filePosition = auttyJsonFileFolder.files.length +1;
    String playgroundJson = widget.playgroundSaveLoad.savePlayground();
    AuttyJsonFile auttyJsonFile = AuttyJsonFile(filename: fullFileName, executionData: {}, nodePlaygroundData: playgroundJson, filePosition: filePosition);


    setState(() {
      auttyJsonFileFolder.addFile(auttyJsonFile);
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
                auttyJsonFileFolder.changeFileOrder(oldIndex, newIndex);
                },
                itemCount: auttyJsonFileFolder.files.length,
                itemBuilder: (context, index) {
                  final status = auttyJsonFileFolder.files[index].executionResultSuccess;
                  final color = status == true
                    ? Colors.green
                      : status == false
                        ? Colors.red
                          : executingIndex == index
                            ? Colors.blue
                              : Colors.grey[300];
                              
                  return MouseRegion(
                    key: ValueKey(auttyJsonFileFolder.files[index].filename),
                    onEnter: (_) => setState(() => hoverIndex = index),
                    onExit: (_) => setState(() => hoverIndex = null),
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
                              if (hoverIndex != index)
                                const Icon(Icons.insert_drive_file, size: 18, color: Color.fromARGB(255, 58, 58, 58)),
                              const SizedBox(width: 8),
                              Text(
                                hoverIndex != index ? auttyJsonFileFolder.files[index].filename : "",
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                            ],
                          ),
                          if (index == hoverIndex)
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
                                    onPressed: () => _renameFile(auttyJsonFileFolder.files[index].filename),
                                  ),
                                  IconButton(
                                    icon: SvgPicture.asset(
                                      'lib/svg_icons/playground_download_icon.svg',
                                      width: 20,
                                      height: 20,
                                      color: const Color.fromARGB(255, 58, 58, 58),
                                    ),
                                    onPressed: () => _downloadFile(index),
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

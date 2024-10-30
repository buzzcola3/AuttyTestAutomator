import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive.dart';
import 'package:attempt_two/main_screen/node_playground_file_manager/playground_save_and_load.dart';
import 'package:file_saver/file_saver.dart';

class JsonFileManager extends StatefulWidget {
  final PlaygroundSaveLoad playgroundSaveLoad; // Required parameter

  const JsonFileManager({Key? key, required this.playgroundSaveLoad}) : super(key: key);

  @override
  _JsonFileManagerState createState() => _JsonFileManagerState();
}

class _JsonFileManagerState extends State<JsonFileManager> {
  List<Map<String, dynamic>> jsonFiles = [];
  Map<String, Uint8List> fileContents = {};

Future<void> _pickFiles() async {
  var result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    type: FileType.custom,
    allowedExtensions: ['json'],
  );

  if (result != null) {
    for (var file in result.files) {
      if (file.path != null) {
        // Use the file path to read the file
        final File selectedFile = File(file.path!);
        
        try {
          // Read the content as a string
          String jsonString = await selectedFile.readAsString();
          Map<String, dynamic> jsonContent = jsonDecode(jsonString);

          setState(() {
            jsonFiles.add({'name': file.name, 'content': jsonContent}); // Store the content
            // Convert the string to bytes for later download purposes
            fileContents[file.name] = Uint8List.fromList(utf8.encode(jsonString)); // Store bytes
          });
        } catch (e) {
          print('Error reading JSON from file ${file.name}: $e');
        }
      } else {
        print('No path found for file ${file.name}');
      }
    }
  }
}


  Future<void> _addNewFile() async {
    String newFileName = 'new_file_${jsonFiles.length + 1}.json';
    final jsonString = widget.playgroundSaveLoad.saveToJson(); // Save nodes as JSON
    final newFileContent = Uint8List.fromList(utf8.encode(jsonString));

    setState(() {
      jsonFiles.add({'name': newFileName, 'content': {}});
      fileContents[newFileName] = newFileContent;
    });
  }

  Future<void> _renameFile(int index) async {
    final currentName = jsonFiles[index]['name'];
    final controller = TextEditingController(text: currentName.replaceAll('.json', ''));

    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Rename File"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "Enter new name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text("Rename"),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() {
        final jsonContent = widget.playgroundSaveLoad.saveToJson(); // Save current nodes
        jsonFiles[index]['name'] = '$newName.json';
        fileContents['$newName.json'] = Uint8List.fromList(utf8.encode(jsonContent)); // Update content
        fileContents.remove(currentName); // Remove old file
      });
    }
  }

  Future<void> _downloadFile(String fileName) async {
    final Uint8List bytes = fileContents[fileName]!;

    try {
      await FileSaver.instance.saveFile(
        name: fileName,  // The name for the saved file
        bytes: bytes,    // File contents as bytes
        mimeType: MimeType.json,  // Specify the MIME type for JSON files
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
    final archive = Archive();
    for (var entry in fileContents.entries) {
      archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
    }
    final zipData = ZipEncoder().encode(archive)!;

    final directory = await getTemporaryDirectory();
    final zipPath = '${directory.path}/json_files.zip';
    final zipFile = File(zipPath);
    await zipFile.writeAsBytes(zipData);

    await Share.shareXFiles([XFile(zipPath)], text: 'Download all JSON files as ZIP');
  }

void _executeJson(int index) {
  // Get the JSON content from the fileContents map using the correct name
  final fileName = jsonFiles[index]['name'];
  
  if (fileContents.containsKey(fileName)) {
    String jsonContent = utf8.decode(fileContents[fileName]!);

    // Call the loadPlayground method with the JSON content
    widget.playgroundSaveLoad.loadPlayground(jsonContent);

    // Optional: Print the content for debugging
    print('Executing JSON from $fileName: $jsonContent');
  } else {
    print('No content found for $fileName');
  }
}


  void _saveNodes() async {
    // Prompt user for a new file name
    final controller = TextEditingController();
    final newFileName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Save Playground"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "Enter file name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text("Save"),
            ),
          ],
        );
      },
    );

    if (newFileName != null && newFileName.isNotEmpty) {
      // Save nodes as JSON
      String playgroundJson = widget.playgroundSaveLoad.savePlayground();
      Uint8List fileContent = Uint8List.fromList(utf8.encode(playgroundJson));
      
      setState(() {
        // Add new file entry to jsonFiles and fileContents
        final fullFileName = '$newFileName.json';
        jsonFiles.add({'name': fullFileName, 'content': jsonDecode(playgroundJson)});
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addNewFile,
                ),
                IconButton(
                  icon: Icon(Icons.file_upload),
                  onPressed: _pickFiles,
                ),
                IconButton(
                  icon: Icon(Icons.cloud_download),
                  onPressed: _downloadAllAsZip,
                ),
//                IconButton(
//                  icon: Icon(Icons.save),
//                  onPressed: _saveToJson, // Button to save to JSON
//                ),
                IconButton(
                  icon: Icon(Icons.save_alt),
                  onPressed: _saveNodes, // New button to save node
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: jsonFiles.length,
                itemBuilder: (context, index) {
                  final fileName = jsonFiles[index]['name'].replaceAll('.json', ''); // Remove .json extension
                  return Container(
                    color: Colors.grey[300], // Light gray background
                    margin: const EdgeInsets.symmetric(vertical: 4.0), // Spacing between items
                    height: 30, // Fixed height
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0), // Add padding for icon
                          child: Row(
                            children: [
                              Icon(Icons.insert_drive_file, size: 18, color: Colors.grey[700]), // File icon
                              SizedBox(width: 8),
                              Text(
                                fileName,
                                style: TextStyle(fontSize: 14, color: Colors.black87), // Adjust text size
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 8.0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.play_arrow, size: 20, color: Colors.green), // Play icon
                                onPressed: () => _executeJson(index),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, size: 20), // Edit icon
                                onPressed: () => _renameFile(index),
                              ),
                              IconButton(
                                icon: Icon(Icons.download, size: 20), // Download icon
                                onPressed: () => _downloadFile(jsonFiles[index]['name']),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

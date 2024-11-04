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
import 'package:flutter_svg/flutter_svg.dart';

class JsonFileManager extends StatefulWidget {
  final PlaygroundSaveLoad playgroundSaveLoad;

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
          final File selectedFile = File(file.path!);

          try {
            String jsonString = await selectedFile.readAsString();
            Map<String, dynamic> jsonContent = jsonDecode(jsonString);

            setState(() {
              jsonFiles.add({'name': file.name, 'content': jsonContent});
              fileContents[file.name] = Uint8List.fromList(utf8.encode(jsonString));
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
    final jsonString = widget.playgroundSaveLoad.saveToJson();
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
          title: Text("Save as Zip"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "Enter zip file name"),
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

    if (zipFileName != null && zipFileName.isNotEmpty) {
      final archive = Archive();
      for (var entry in fileContents.entries) {
        archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
      }
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

  void _executeJson(int index) {
    final fileName = jsonFiles[index]['name'];

    if (fileContents.containsKey(fileName)) {
      String jsonContent = utf8.decode(fileContents[fileName]!);
      widget.playgroundSaveLoad.loadPlayground(jsonContent);

      print('Executing JSON from $fileName: $jsonContent');
    } else {
      print('No content found for $fileName');
    }
  }

  void _savePlayground() async {
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
      String playgroundJson = widget.playgroundSaveLoad.savePlayground();
      Uint8List fileContent = Uint8List.fromList(utf8.encode(playgroundJson));

      setState(() {
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
                  icon: Transform.scale(
                    scale: 1,
                    child: SvgPicture.asset(
                      'lib/svg_icons/playground_download_icon.svg',
                      width: 24,
                      height: 24,
                      color: const Color.fromARGB(255, 58, 58, 58),
                    ),
                  ),
                  onPressed: _downloadAllAsZip,
                ),
                IconButton(
                  icon: Transform.scale(
                    scale: 1,
                    child: SvgPicture.asset(
                      'lib/svg_icons/playground_upload_icon.svg',
                      width: 24,
                      height: 24,
                      color: const Color.fromARGB(255, 58, 58, 58),
                    ),
                  ),
                  onPressed: _pickFiles,
                ),
                IconButton(
                  icon: Transform.scale(
                    scale: 1,
                    child: SvgPicture.asset(
                      'lib/svg_icons/playground_save_icon.svg',
                      width: 24,
                      height: 24,
                      color: const Color.fromARGB(255, 58, 58, 58),
                    ),
                  ),
                  onPressed: _savePlayground,
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: jsonFiles.length,
                itemBuilder: (context, index) {
                  final fileName = jsonFiles[index]['name'].replaceAll('.json', '');
                  return MouseRegion(
                    onEnter: (_) => setState(() => jsonFiles[index]['hover'] = true),
                    onExit: (_) => setState(() => jsonFiles[index]['hover'] = false),
                    child: Container(
                      color: Colors.grey[300],
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      height: 30,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Row(
                              children: [
                                Icon(Icons.insert_drive_file, size: 18, color: Colors.grey[700]),
                                SizedBox(width: 8),
                                Text(
                                  fileName,
                                  style: TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                          if (jsonFiles[index]['hover'] == true)
                            Positioned(
                              right: 8.0,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.play_arrow, size: 20, color: Colors.green),
                                    onPressed: () => _executeJson(index),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit, size: 20),
                                    onPressed: () => _renameFile(index),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.download, size: 20),
                                    onPressed: () => _downloadFile(jsonFiles[index]['name']),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
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

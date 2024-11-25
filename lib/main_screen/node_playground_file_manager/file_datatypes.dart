import 'dart:convert';
import 'dart:typed_data';
import 'package:Autty/main_screen/communication_panel/communication_panel.dart';
import 'package:archive/archive.dart';
import 'package:Autty/global_datatypes/json.dart';

class AuttyJsonFile {
  String filename;
  List<Json> executionData;
  bool? executionResultSuccess;
  String nodePlaygroundData;
  int filePosition;

  AuttyJsonFile({
    required this.filename,
    required this.executionData,
    required this.nodePlaygroundData,
    required this.filePosition,
    this.executionResultSuccess
  });

  void addExecuteData(String resultMessage, String sourceNode, MessageType messageType){
    executionData.add({"message": resultMessage, "sourceNode": sourceNode, "messageType": messageType.toJson()});
  }

  /// Converts the instance into a JSON object
  Json toJson() {
    return {
      'filename': filename,
      'executionData': executionData,
      'nodePlaygroundData': nodePlaygroundData,
      'filePosition': filePosition, // Include in JSON
      'executionResultSuccess': executionResultSuccess
    };
  }

  /// Recreates an `AuttyJsonFile` instance from a JSON object
  factory AuttyJsonFile.fromJson(Json json) {
    return AuttyJsonFile(
      filename: json['filename'],
      executionData: List.from(json['executionData'] ?? []),
      nodePlaygroundData: json['nodePlaygroundData'],
      filePosition: json['filePosition'] ?? 0, // Default to 0 if not provided
      executionResultSuccess: json['executionResultSuccess']
    );
  }

  /// Converts the instance into a JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Recreates an `AuttyJsonFile` instance from a JSON string
  factory AuttyJsonFile.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Json;
    return AuttyJsonFile.fromJson(json);
  }
}


class AuttyJsonFileFolder {
  List<AuttyJsonFile> files = [];

  AuttyJsonFileFolder({List<AuttyJsonFile>? files})
      : files = files ?? [] {
    // Ensure the files are always ordered by filePosition upon initialization
    _sortFiles();
  }

  /// Sorts the files list by `filePosition`
  void _sortFiles() {
    files.sort((a, b) => a.filePosition.compareTo(b.filePosition));
  }

/// Adds a new file to the folder and ensures the list remains ordered
void addFile(AuttyJsonFile file) {
  // Check for duplicates and append `_` to the filename if necessary
  String newFilename = file.filename;
  while (files.any((existingFile) => existingFile.filename == newFilename)) {
    newFilename += '_';
  }

  // Update the file's filename with the unique name
  file.filename = newFilename;

  // Add the file and sort the list
  files.add(file);
  _sortFiles();
  normalizeFilePositions();
}

  /// Renames a file identified by its current filename
  bool renameFile(String currentFilename, String newFilename) {
    try {
      final file = files.firstWhere((file) => file.filename == currentFilename);
      file.filename = newFilename; // Update the filename
      return true;
    } catch (e) {
      // File not found
      return false;
    }
  }

  /// Removes a file by filename or file reference
  bool removeFile({String? filename, AuttyJsonFile? file}) {
    if (file != null) {
      // Remove by file reference
      final removed = files.remove(file);
      if (removed) _sortFiles(); // Re-sort after removal
      return removed;
    } else if (filename != null) {
      // Remove by filename
      final initialLength = files.length;
      files.removeWhere((f) => f.filename == filename);
      if (files.length < initialLength) {
        _sortFiles(); // Re-sort after removal
        return true;
      }
    }
    return false; // Nothing removed
  }

bool changeFileOrder(int oldPosition, int newPosition) {
  // Find the file at the old position
  try {
    final placeholderfile = AuttyJsonFile(filename: "", executionData: [], nodePlaygroundData: "", filePosition: 0);
    final file = files.removeAt(oldPosition);
    files.insert(oldPosition, placeholderfile);

    files.insert(newPosition, file);
    files.remove(placeholderfile);

    normalizeFilePositions();

    return true; // Operation successful
  } catch (e) {
    // If something goes wrong (e.g., file not found)
    return false;
  }
}

/// Ensures there are no skipped positions in the file list.
/// Reassigns `filePosition` values sequentially and maintains the current order.
void normalizeFilePositions() {
  // Reassign positions sequentially starting from 0
  for (int i = 0; i < files.length; i++) {
    files[i].filePosition = i;
  }
}

  /// Exports the files as a zip archive (returns Uint8List for saving to a file)
  Uint8List exportAsZip() {
    final archive = Archive();

    for (var file in files) {
      final filename = file.filename;
      final content = utf8.encode(file.toJsonString());
      archive.addFile(ArchiveFile(filename, content.length, content));
    }

    return Uint8List.fromList(ZipEncoder().encode(archive)!);
  }

  /// Imports files from a zip archive (given Uint8List zipData)
  factory AuttyJsonFileFolder.importFromZip(Uint8List zipData) {
    final archive = ZipDecoder().decodeBytes(zipData);
    final List<AuttyJsonFile> importedFiles = [];

    for (var file in archive.files) {
      if (!file.isFile) continue;
      final content = utf8.decode(file.content as List<int>);
      final jsonData = jsonDecode(content) as Json;
      importedFiles.add(AuttyJsonFile.fromJson(jsonData));
    }

    // Ensure the imported files are ordered by filePosition
    return AuttyJsonFileFolder(files: importedFiles).._sortFiles();
  }

  /// Retrieves the list of files as ordered JSON
  List<Json> toJson() {
    return files.map((file) => file.toJson()).toList();
  }

  /// Loads files from a JSON array
  factory AuttyJsonFileFolder.fromJson(List<Json> json) {
    final files = json.map((data) => AuttyJsonFile.fromJson(data)).toList();
    return AuttyJsonFileFolder(files: files).._sortFiles();
  }
}
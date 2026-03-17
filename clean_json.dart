// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

void main() {
  // Use absolute paths to avoid confusion
  final enPath = 'd:/New folder (12)/green_algeria/assets/translations/en.json';
  final arPath = 'd:/New folder (12)/green_algeria/assets/translations/ar.json';

  void cleanFile(String path) {
    final file = File(path);
    if (file.existsSync()) {
      try {
        final content = file.readAsStringSync();
        // Decode to Map (automatically handles duplicates by taking the last one)
        final data = json.decode(content) as Map<String, dynamic>;
        
        // Sort keys alphabetically
        final sortedKeys = data.keys.toList()..sort();
        final sortedData = {
          for (var key in sortedKeys) key: data[key]
        };
        
        // Write back with nice formatting
        final encoder = const JsonEncoder.withIndent('    ');
        file.writeAsStringSync(encoder.convert(sortedData));
        print('Successfully cleaned: $path');
      } catch (e) {
        print('Error cleaning $path: $e');
      }
    } else {
      print('File not found: $path');
    }
  }

  cleanFile(enPath);
  cleanFile(arPath);
}

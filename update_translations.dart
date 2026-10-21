import 'dart:io';

void main() {
  final file = File('lib/app/modules/video_editor/core/constants/app_strings.dart');
  final lines = file.readAsLinesSync();
  
  final enMap = <String, String>{};
  
  final newLines = <String>[];
  
  for (final line in lines) {
    if (line.trim().startsWith('static const ')) {
      // e.g. static const editorTitle = 'Editor';
      final regex = RegExp(r"static const (\w+) = '(.+)';");
      final match = regex.firstMatch(line);
      if (match != null) {
        final key = match.group(1)!;
        final val = match.group(2)!;
        enMap[key] = val;
        newLines.add(line.replaceFirst(
          regex,
          "static String get $key => '$key'.tr;"
        ));
      } else {
        // Handle multiline strings if any
        final regex2 = RegExp(r'static const (\w+) =');
        final match2 = regex2.firstMatch(line);
        if (match2 != null) {
            final key = match2.group(1)!;
            newLines.add("  static String get $key => '$key'.tr;");
            enMap[key] = "TODO";
        } else {
            newLines.add(line);
        }
      }
    } else {
      newLines.add(line);
    }
  }
  
  // Need to import Get
  newLines.insert(0, "import 'package:get/get.dart';");
  
  file.writeAsStringSync(newLines.join('\n'));
  
  // Now write to en.dart and gu.dart
  void appendToLang(String path) {
    final langFile = File(path);
    String content = langFile.readAsStringSync();
    
    // Find the last '};'
    final insertIndex = content.lastIndexOf('};');
    if (insertIndex == -1) return;
    
    final sb = StringBuffer();
    sb.writeln('  // Video Editor');
    for (final entry in enMap.entries) {
      sb.writeln("  '${entry.key}': '${entry.value.replaceAll("'", "\\'")}',");
    }
    
    content = content.substring(0, insertIndex) + sb.toString() + content.substring(insertIndex);
    langFile.writeAsStringSync(content);
  }
  
  appendToLang('lib/app/core/lang/en.dart');
  appendToLang('lib/app/core/lang/gu.dart');
}

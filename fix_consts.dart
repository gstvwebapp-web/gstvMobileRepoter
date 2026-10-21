import 'dart:io';

void main() {
  final files = [
    'lib/app/modules/video_editor/presentation/views/editor_view.dart',
    'lib/app/modules/video_editor/presentation/widgets/export_progress_dialog.dart',
    'lib/app/modules/video_editor/presentation/widgets/editor_toolbar.dart',
  ];
  
  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    
    var content = file.readAsStringSync();
    
    // Replace const Text(AppStrings.xxx) with Text(AppStrings.xxx)
    content = content.replaceAll('const Text(AppStrings.', 'Text(AppStrings.');
    // Replace tooltip: AppStrings.xxx with tooltip: AppStrings.xxx (it's already not const if it's dynamic, but let's check)
    // Actually, in EditorView we had:
    // title: const Text(AppStrings.editorTitle),
    // That's handled.
    // child: const Text(AppStrings.export,
    // Handled.
    
    // Wait, what if there's const Padding(child: Text(AppStrings...))?
    // Let's run a more aggressive regex.
    content = content.replaceAll(RegExp(r'const\s+(Text\(AppStrings\.)'), r'\1');
    content = content.replaceAll(RegExp(r'const\s+(Icon\(.+?,\s+tooltip:\s*AppStrings\.)'), r'\1');
    
    file.writeAsStringSync(content);
  }
}

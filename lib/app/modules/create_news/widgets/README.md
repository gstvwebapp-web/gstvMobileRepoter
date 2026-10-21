# HTML Editor Widget

A custom Flutter widget that provides a read-only HTML viewer with tap-to-edit functionality. When tapped, it opens a full-screen HTML editor for content editing.

## Features

- **Read-only Preview**: Shows content preview with stripped HTML tags
- **Tap to Edit**: Opens full-screen HTML editor when tapped
- **Full-screen Editor**: Rich HTML editing experience with toolbar
- **Auto-save**: Content is automatically saved when going back
- **Content Validation**: Real-time content validation and callbacks
- **Responsive Design**: Adapts to different screen sizes
- **Clean UI**: Modern design with shadows and rounded corners

## Usage

### Basic Usage

```dart
import 'package:html_editor_enhanced/html_editor.dart';
import 'widgets/html_editor_widget.dart';

class MyScreen extends StatelessWidget {
  final HtmlEditorController _controller = HtmlEditorController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HtmlEditorWidget(
        controller: _controller,
        hint: 'Enter your content here...',
        onContentChanged: (String content) {
          print('Content changed: $content');
        },
      ),
    );
  }
}
```

### With Initial Content

```dart
HtmlEditorWidget(
  controller: _controller,
  initialContent: '<p>Initial HTML content</p>',
  hint: 'Enter your content here...',
  onContentChanged: (String content) {
    // Handle content changes
  },
)
```

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `controller` | `HtmlEditorController` | Yes | Controller for the HTML editor |
| `initialContent` | `String?` | No | Initial HTML content to display |
| `onContentChanged` | `Function(String)?` | No | Callback when content changes |
| `hint` | `String` | No | Placeholder text (default: 'Enter content here...') |

## Implementation Details

### Widget Structure

1. **Preview Container**: Shows content preview with edit icon
2. **Content Display**: Strips HTML tags and shows plain text preview
3. **Tap Handler**: Opens full-screen editor on tap
4. **Full-screen Editor**: Complete HTML editing experience

### Full-screen Editor Features

- **Rich Toolbar**: Complete formatting options
- **Auto-save**: Content saved automatically on back navigation
- **Success Feedback**: Shows success message when content is saved
- **Error Handling**: Graceful error handling with user feedback

### Content Flow

1. User sees read-only preview of content
2. User taps on widget to edit
3. Full-screen editor opens with current content
4. User edits content using rich toolbar
5. User taps "Save" or back button
6. Content is saved and preview is updated
7. Success message is shown

## Demo

A complete demo is available at `/html-editor-demo` route. The demo shows:

- Multiple HTML editor widgets
- Content preview functionality
- HTML source code viewing
- Clear all functionality

## Integration

### In Create News Screen

The widget is already integrated into the create news screen:

```dart
HtmlEditorWidget(
  controller: controller.htmlEditorController,
  hint: 'Enter news content here...',
  onContentChanged: (String content) {
    controller.validateStep2();
  },
)
```

### In Live News Items

```dart
HtmlEditorWidget(
  controller: item.contentController,
  hint: 'Enter live news content...',
  onContentChanged: (String content) {
    // Content changed for live news item
  },
)
```

## Benefits

1. **Better UX**: Clean preview with easy edit access
2. **Space Efficient**: Compact preview saves screen space
3. **Full-screen Editing**: Immersive editing experience
4. **Native HTML**: Direct HTML handling without conversion
5. **Consistent Design**: Matches app's design language
6. **Easy Integration**: Simple drop-in replacement for existing editors

## Migration from Quill

This widget was created as part of migrating from Flutter Quill to HTML Editor Enhanced:

- **Before**: Complex Quill Delta ↔ HTML conversion
- **After**: Direct HTML editing and display
- **Result**: Simplified codebase and better user experience

## Troubleshooting

### Common Issues

1. **Scrollable Context Warnings**: Normal for HTML editor widgets, can be ignored
2. **Content Not Updating**: Ensure `onContentChanged` callback is properly implemented
3. **Initial Content Not Showing**: Check that `initialContent` is valid HTML

### Performance Tips

1. Use single controller instance per widget
2. Avoid frequent content updates
3. Implement proper disposal of controllers

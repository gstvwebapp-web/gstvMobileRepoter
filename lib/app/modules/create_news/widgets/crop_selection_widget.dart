import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;

class CropSelectionWidget extends StatefulWidget {
  final File imageFile;
  final double aspectRatio;
  final Function(Rect)? onCropAreaChanged;

  const CropSelectionWidget({
    super.key,
    required this.imageFile,
    required this.aspectRatio,
    this.onCropAreaChanged,
  });

  @override
  State<CropSelectionWidget> createState() => _CropSelectionWidgetState();
}

class _CropSelectionWidgetState extends State<CropSelectionWidget> {
  Rect cropRect = const Rect.fromLTWH(0.1, 0.25, 0.8, 0.45); // Centered landscape crop area for 1200x680
  ui.Image? _image;
  Size _imageSize = Size.zero;

  // Zoom and pan variables
  final double _scale = 1.0;
  final Offset _offset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _image = frame.image;
      _imageSize = Size(frame.image.width.toDouble(), frame.image.height.toDouble());
    });
  }

  void _updateCropRect(Rect newRect) {
    setState(() {
      cropRect = newRect;
    });
    widget.onCropAreaChanged?.call(cropRect);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Zoomable and pannable image
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(
                    widget.imageFile,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
                ),
              ),
              // Interactive crop overlay
              if (_image != null)
                InteractiveCropOverlay(
                  imageSize: _imageSize,
                  containerSize: constraints.biggest,
                  aspectRatio: widget.aspectRatio,
                  cropRect: cropRect,
                  onCropRectChanged: _updateCropRect,
                ),
            ],
          );
        },
      ),
    );
  }
}

class InteractiveCropOverlay extends StatefulWidget {
  final Size imageSize;
  final Size containerSize;
  final double aspectRatio;
  final Rect cropRect;
  final Function(Rect) onCropRectChanged;

  const InteractiveCropOverlay({
    super.key,
    required this.imageSize,
    required this.containerSize,
    required this.aspectRatio,
    required this.cropRect,
    required this.onCropRectChanged,
  });

  @override
  State<InteractiveCropOverlay> createState() => _InteractiveCropOverlayState();
}

class _InteractiveCropOverlayState extends State<InteractiveCropOverlay> {
  late Rect _currentCropRect;

  @override
  void initState() {
    super.initState();
    _currentCropRect = widget.cropRect;
  }

  @override
  void didUpdateWidget(InteractiveCropOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cropRect != widget.cropRect) {
      _currentCropRect = widget.cropRect;
    }
  }

  Size _getDisplayImageSize() {
    final containerAspectRatio = widget.containerSize.width / widget.containerSize.height;
    final imageAspectRatio = widget.imageSize.width / widget.imageSize.height;

    if (imageAspectRatio > containerAspectRatio) {
      // Image is wider than container, fit to width
      final displayWidth = widget.containerSize.width;
      final displayHeight = displayWidth / imageAspectRatio;
      return Size(displayWidth, displayHeight);
    } else {
      // Image is taller than container, fit to height
      final displayHeight = widget.containerSize.height;
      final displayWidth = displayHeight * imageAspectRatio;
      return Size(displayWidth, displayHeight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayImageSize = _getDisplayImageSize();
    final imageLeft = (widget.containerSize.width - displayImageSize.width) / 2;
    final imageTop = (widget.containerSize.height - displayImageSize.height) / 2;

    // Calculate crop dimensions based on aspect ratio
    final maxCropWidth = displayImageSize.width * 0.7; // 70% of image width
    final maxCropHeight = maxCropWidth / widget.aspectRatio; // Maintain aspect ratio

    // Calculate actual crop position
    final cropWidth = maxCropWidth;
    final cropHeight = maxCropHeight;
    final cropLeft = imageLeft + (_currentCropRect.left * displayImageSize.width);
    final cropTop = imageTop + (_currentCropRect.top * displayImageSize.height);

    return Stack(
      children: [
        // Dark overlay
        CustomPaint(
          size: widget.containerSize,
          painter: OverlayPainter(
            cropRect: Rect.fromLTWH(cropLeft, cropTop, cropWidth, cropHeight),
          ),
        ),
        // Draggable crop area
        Positioned(
          left: cropLeft,
          top: cropTop,
          child: GestureDetector(
            onPanUpdate: (details) {
              // Calculate movement in normalized coordinates
              final deltaX = details.delta.dx / displayImageSize.width;
              final deltaY = details.delta.dy / displayImageSize.height;

              // Calculate new position with constraints
              final newLeft = (_currentCropRect.left + deltaX).clamp(
                0.0,
                1.0 - (cropWidth / displayImageSize.width)
              );
              final newTop = (_currentCropRect.top + deltaY).clamp(
                0.0,
                1.0 - (cropHeight / displayImageSize.height)
              );

              // Create new rect with fixed size
              final newRect = Rect.fromLTWH(
                newLeft,
                newTop,
                cropWidth / displayImageSize.width,
                cropHeight / displayImageSize.height,
              );

              setState(() {
                _currentCropRect = newRect;
              });
              widget.onCropRectChanged(newRect);
            },
            child: Container(
              width: cropWidth,
              height: cropHeight,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2196F3), width: 3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                children: [
                  // Grid lines
                  CustomPaint(
                    size: Size(cropWidth, cropHeight),
                    painter: GridPainter(),
                  ),
                  // Corner handles
                  _buildCornerHandle(Alignment.topLeft),
                  _buildCornerHandle(Alignment.topRight),
                  _buildCornerHandle(Alignment.bottomLeft),
                  _buildCornerHandle(Alignment.bottomRight),
                  // Center text showing aspect ratio
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '1200 × 680',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCornerHandle(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: Offset(
          alignment.x * 10, // Move handle outside border
          alignment.y * 10,
        ),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;

    // Draw grid lines (3x3)
    for (int i = 1; i < 3; i++) {
      // Vertical lines
      final double x = size.width * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);

      // Horizontal lines
      final double y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class OverlayPainter extends CustomPainter {
  final Rect cropRect;

  OverlayPainter({required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.6);

    // Draw overlay (everything except crop area)
    final Path path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, overlayPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

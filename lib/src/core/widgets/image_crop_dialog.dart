import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class CropOverlayPainter extends CustomPainter {
  const CropOverlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.65)
      ..style = PaintingStyle.fill;

    final outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final innerPath = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2,
      ));

    final cropPath = Path.combine(PathOperation.difference, outerPath, innerPath);
    canvas.drawPath(cropPath, paint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawOval(
      Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2,
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ImageCropDialog extends StatefulWidget {
  final File imageFile;

  const ImageCropDialog({super.key, required this.imageFile});

  @override
  State<ImageCropDialog> createState() => _ImageCropDialogState();
}

class _ImageCropDialogState extends State<ImageCropDialog> {
  final TransformationController _controller = TransformationController();
  ui.Image? _uiImage;
  bool _loading = true;
  double _initScaleCover = 1.0;
  double _wInit = 300;
  double _hInit = 300;
  static const double _viewportSize = 280.0;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final Uint8List bytes = await widget.imageFile.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo fi = await codec.getNextFrame();
      final image = fi.image;

      final wOrig = image.width.toDouble();
      final hOrig = image.height.toDouble();

      // Calculate scale to cover the circular viewport
      _initScaleCover = (wOrig < hOrig)
          ? (_viewportSize / wOrig)
          : (_viewportSize / hOrig);

      setState(() {
        _uiImage = image;
        _wInit = wOrig * _initScaleCover;
        _hInit = hOrig * _initScaleCover;
        _loading = false;
      });

      // Align image to center of viewport
      final double initialX = (_viewportSize - _wInit) / 2;
      final double initialY = (_viewportSize - _hInit) / 2;
      _controller.value = Matrix4.identity()
        ..translate(initialX, initialY);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load image: $e')),
        );
      }
    }
  }

  Future<void> _cropAndSave() async {
    if (_uiImage == null) return;
    setState(() => _loading = true);

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // We want to record exactly the size of the viewport (280x280)
      final matrix = _controller.value;
      canvas.transform(matrix.storage);

      canvas.drawImageRect(
        _uiImage!,
        Rect.fromLTWH(0, 0, _uiImage!.width.toDouble(), _uiImage!.height.toDouble()),
        Rect.fromLTWH(0, 0, _wInit, _hInit),
        Paint()
          ..isAntiAlias = true
          ..filterQuality = ui.FilterQuality.high,
      );

      final croppedImage = await recorder.endRecording().toImage(
            _viewportSize.toInt(),
            _viewportSize.toInt(),
          );
      final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      final croppedBytes = byteData!.buffer.asUint8List();

      final String dir = widget.imageFile.parent.path;
      final String newPath = '$dir/cropped_${DateTime.now().millisecondsSinceEpoch}.png';
      final File croppedFile = File(newPath);
      await croppedFile.writeAsBytes(croppedBytes);

      if (mounted) {
        Navigator.of(context).pop(croppedFile);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to crop image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('Crop Profile Photo', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                const Spacer(),
                Center(
                  child: Container(
                    width: _viewportSize,
                    height: _viewportSize,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: InteractiveViewer(
                            transformationController: _controller,
                            boundaryMargin: const EdgeInsets.all(_viewportSize),
                            minScale: 0.8,
                            maxScale: 4.0,
                            child: Image.file(
                              widget.imageFile,
                              width: _wInit,
                              height: _hInit,
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                        const Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: CropOverlayPainter(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Pinch to zoom and drag to adjust the face inside the circle',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  color: const Color(0xFF121212),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _cropAndSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF004D2A),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Crop & Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

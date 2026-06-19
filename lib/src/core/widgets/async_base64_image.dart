import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Uint8List _decodeBase64(String base64String) {
  return base64Decode(base64String);
}

class AsyncBase64Image extends StatefulWidget {
  final String base64String;
  final BoxFit fit;
  final WidgetBuilder? placeholderBuilder;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final double? width;
  final double? height;

  const AsyncBase64Image({
    super.key,
    required this.base64String,
    this.fit = BoxFit.cover,
    this.placeholderBuilder,
    this.errorBuilder,
    this.width,
    this.height,
  });

  @override
  State<AsyncBase64Image> createState() => _AsyncBase64ImageState();
}

class _AsyncBase64ImageState extends State<AsyncBase64Image> {
  Uint8List? _bytes;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void didUpdateWidget(covariant AsyncBase64Image oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.base64String != widget.base64String) {
      _decodeImage();
    }
  }

  Future<void> _decodeImage() async {
    setState(() {
      _bytes = null;
      _hasError = false;
    });
    try {
      final decodedBytes = await compute(_decodeBase64, widget.base64String);
      if (mounted) {
        setState(() {
          _bytes = decodedBytes;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorBuilder?.call(context, Exception('Failed to decode Base64'), null) ?? 
          const SizedBox();
    }
    if (_bytes == null) {
      return widget.placeholderBuilder?.call(context) ?? const SizedBox();
    }
    return Image.memory(
      _bytes!,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      errorBuilder: widget.errorBuilder,
    );
  }
}

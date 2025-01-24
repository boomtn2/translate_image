import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:image_translate/openai_helper.dart';
import 'package:path_provider/path_provider.dart';

import 'text_dectecion.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeRemoveText(),
    );
  }
}

class HomeRemoveText extends StatefulWidget {
  const HomeRemoveText({super.key});

  @override
  State<HomeRemoveText> createState() => _HomeRemoveTextState();
}

class _HomeRemoveTextState extends State<HomeRemoveText> {
  ui.Image? _image;
  bool _isLoading = true;
  List<Rect> listRects = [];
  List<String> listText = [];
  @override
  void initState() {
    super.initState();
    // _loadImageFromFile(
    //     'C:/Users/Admin/Downloads/Screenshot 2025-01-24 084435.png'); // Thay đường dẫn ảnh tại đây
  }

  Future<void> _loadImageFromFile(String filePath) async {
    try {
      // Đọc file từ bộ nhớ thiết bị
      final file = File(filePath);
      final Uint8List imageBytes = await file.readAsBytes();

      // Chuyển đổi Uint8List thành ui.Image
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();

      final listBlock = await VisionGoogleAPI().textDetection();

      for (var element in listBlock) {
        listRects.add(convertBoundingPolyToRect(element.positions));
        final stTranslate = await OpenaiHelper().getTranslate(element.text);
        final textResponse = stTranslate['choices'];
        String text = '';
        if (textResponse is List) {
          for (var element in textResponse) {
            text += element['message']['content'];
          }
        }
        listText.add(text);
      }

      setState(() {
        _image = frame.image;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading image from file: $e');
    }
  }

// Hàm chuyển boundingPoly sang Rect
  Rect convertBoundingPolyToRect(List<Position> vertices) {
    final left = vertices[0].x; // x của đỉnh trên bên trái
    final top = vertices[0].y; // y của đỉnh trên bên trái
    final right = vertices[1].x; // x của đỉnh trên bên phải
    final bottom = vertices[2].y; // y của đỉnh dưới bên phải

    return Rect.fromLTRB(
        left.toDouble(), top.toDouble(), right.toDouble(), bottom.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image from Local File')),
      body: SingleChildScrollView(
        child: Center(
          // child: ElevatedButton(
          //     onPressed: () {
          //       VisionGoogleAPI().textDetection();
          //     },
          //     child: Text('Text Dectection')),
          child: _isLoading
              ? const CircularProgressIndicator()
              : _image == null
                  ? const Text('Failed to load image')
                  : CustomPaint(
                      size: Size(
                        _image!.width.toDouble(),
                        _image!.height.toDouble(),
                      ),
                      painter: ColorOverlayPainter(
                          texts: listText,
                          textStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                          image: _image!,
                          rects: listRects,
                          overlayColor: Colors.red),
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _loadImageFromFile(
              'C:/Users/Admin/Downloads/Screenshot 2025-01-24 084435.png');
        },
      ),
    );
  }
}

class ColorOverlayPainter extends CustomPainter {
  final ui.Image image;
  final List<Rect> rects; // Nhiều hình chữ nhật
  final Color overlayColor; // Màu phủ cho từng hình chữ nhật
  final List<String> texts; // Danh sách văn bản tương ứng với mỗi hình chữ nhật
  final TextStyle textStyle;

  ColorOverlayPainter({
    required this.image,
    required this.rects,
    required this.overlayColor,
    required this.texts,
    required this.textStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Vẽ hình ảnh gốc
    paintImage(
      canvas: canvas,
      rect: Offset.zero & size,
      image: image,
      fit: BoxFit.cover,
    );

    // Vẽ từng hình chữ nhật với lớp màu phủ và văn bản
    for (int i = 0; i < rects.length; i++) {
      final rect = rects[i];
      final color = overlayColor;
      final text = texts[i];

      // Vẽ lớp màu phủ
      final paint = Paint()..color = color;
      canvas.drawRect(rect, paint);

      // Vẽ văn bản lên trên hình chữ nhật
      _drawText(canvas, rect, text);
    }
  }

  void _drawText(Canvas canvas, Rect rect, String text) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(minWidth: 0, maxWidth: rect.width);

    // Tính toán vị trí để căn giữa văn bản trong hình chữ nhật
    final offset = Offset(
      rect.left + (rect.width - textPainter.width) / 2,
      rect.top + (rect.height - textPainter.height) / 2,
    );

    // Vẽ văn bản lên canvas
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

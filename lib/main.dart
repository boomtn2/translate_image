import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
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

class OjectTranslateImage {
  ui.Image? image;
  List<Rect> listRects = [];
  List<String> listText = [];
}

class _HomeRemoveTextState extends State<HomeRemoveText> {
  bool _isLoading = true;
  List<OjectTranslateImage> listImage = [];
  @override
  void initState() {
    super.initState();
    // _loadImageFromFile(
    //     'C:/Users/Admin/Downloads/Screenshot 2025-01-24 084435.png'); // Thay đường dẫn ảnh tại đây
  }

  Future<void> _loadImageFromFile(String filePath) async {
    try {
      Dio dio = Dio();
      Response<Uint8List> response = await dio.get<Uint8List>(
        filePath,
        options: Options(responseType: ResponseType.bytes), // Tải ảnh dạng byte
      );
      if (response.statusCode == 200) {
        OjectTranslateImage ojectTranslateImage = OjectTranslateImage();
        // Đọc file từ bộ nhớ thiết bị
        // final file = File(filePath);
        // final Uint8List imageBytes = await file.readAsBytes();
        final Uint8List imageBytes = response.data!;
        final base64 = base64Encode(imageBytes);

        // Chuyển đổi Uint8List thành ui.Image
        final codec = await ui.instantiateImageCodec(imageBytes);
        final frame = await codec.getNextFrame();

        final listBlock = await VisionGoogleAPI().textDetection(base64);

        for (var element in listBlock) {
          ojectTranslateImage.listRects
              .add(convertBoundingPolyToRect(element.positions));
          final stTranslate = await OpenaiHelper().getTranslate(element.text);
          final textResponse = stTranslate['choices'];
          String text = '';
          if (textResponse is List) {
            for (var element in textResponse) {
              text += element['message']['content'];
            }
          }
          ojectTranslateImage.listText.add(text);
        }

        setState(() {
          ojectTranslateImage.image = frame.image;
          List<OjectTranslateImage> list = [...listImage, ojectTranslateImage];
          listImage = list;
          _isLoading = false;
        });
      }
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
            child: Column(
          children: [
            SizedBox(
                height: 350,
                width: 350,
                child: Expanded(
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(
                        url: WebUri(
                            'https://manhwa18.cc/webtoon/turning-my-life-around-with-crypto/chapter-11')),
                    onWebViewCreated: onWebViewCreated,
                  ),
                )),
            for (int i = 0; i < listImage.length; ++i)
              CustomPaint(
                size: Size(
                  listImage[i].image!.width.toDouble(),
                  listImage[i].image!.height.toDouble(),
                ),
                painter: ColorOverlayPainter(
                    texts: listImage[i].listText,
                    textStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                    image: listImage[i].image!,
                    rects: listImage[i].listRects,
                    overlayColor: Colors.red),
              ),
          ],
        )),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // _loadImageFromFile(
          //     'https://cdn01.manhwa18.cc/uploads/4513/11/2-9c9ea.jpg');
        },
      ),
    );
  }

  InAppWebViewController? webViewController;

  void onWebViewCreated(InAppWebViewController controller) {
    debugPrint('onWebViewCreated');
    webViewController = controller;
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

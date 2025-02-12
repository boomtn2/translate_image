import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:image_translate/openai_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'text_dectecion.dart';
import 'package:permission_handler/permission_handler.dart';

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
  List<OjectTranslateImage> listImage = [];
  final List<ContentBlocker> contentBlockers = [];
  final adUrlFilters = [
    ".*.doubleclick.net/.*",
    ".*.ads.pubmatic.com/.*",
    ".*.googlesyndication.com/.*",
    ".*.google-analytics.com/.*",
    ".*.adservice.google.*/.*",
    ".*.adbrite.com/.*",
    ".*.exponential.com/.*",
    ".*.quantserve.com/.*",
    ".*.scorecardresearch.com/.*",
    ".*.zedo.com/.*",
    ".*.adsafeprotected.com/.*",
    ".*.teads.tv/.*",
    ".*.outbrain.com/.*",
    ".*.fly-ads.net/.*",
    ".*.blueseed.tv/.*",
    ".*.yomedia.vn/.*",
    ".*.kernh41.com/.*",
    ".*.tpmedia.online/.*",
  ];

  void _adsBlock() {
    for (final adUrlFilter in adUrlFilters) {
      contentBlockers.add(ContentBlocker(
          trigger: ContentBlockerTrigger(
            urlFilter: adUrlFilter,
          ),
          action: ContentBlockerAction(
            type: ContentBlockerActionType.BLOCK,
          )));
    }

    // apply the "display: none" style to some HTML elements
    contentBlockers.add(ContentBlocker(
        trigger: ContentBlockerTrigger(
          urlFilter: ".*",
        ),
        action: ContentBlockerAction(
            type: ContentBlockerActionType.CSS_DISPLAY_NONE,
            selector:
                ".banner, .banners, .ads, .ad, .advert, .widget-ads, .ad-unit")));
  }

  @override
  void initState() {
    super.initState();
    _adsBlock();
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
              .add(element.convertBoundingPolyToRect());
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
        });
      }
    } catch (e) {
      setState(() {});
      debugPrint('Error loading image from file: $e');
    }
  }

  Future<void> _loadImageFromBase64(String base64) async {
    try {
      OjectTranslateImage ojectTranslateImage = OjectTranslateImage();

      final Uint8List imageBytes = base64Decode(base64);

      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();

      final listBlock = await VisionGoogleAPI().textDetection(base64);

      for (var element in listBlock) {
        ojectTranslateImage.listRects.add(element.convertBoundingPolyToRect());
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
      });
    } catch (e) {
      setState(() {});
      debugPrint('Error loading image from file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          ElevatedButton(
              onPressed: () async {
                for (int i = 0; i < listImage.length; ++i) {
                  double sizeWidth = listImage[i].image!.width.toDouble();
                  double sizeHeight = listImage[i].image!.height.toDouble();
                  await exportImage(
                      ColorOverlayPainter(
                          texts: listImage[i].listText,
                          textStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                          image: listImage[i].image!,
                          rects: listImage[i].listRects,
                          overlayColor: Colors.red),
                      Size(sizeWidth, sizeHeight),
                      'image_$i');
                }
              },
              child: const Text('Save')),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
            child: Column(
          children: [
            SizedBox(
              height: 350,
              width: 350,
              child: InAppWebView(
                initialSettings:
                    InAppWebViewSettings(contentBlockers: contentBlockers),
                initialUrlRequest:
                    URLRequest(url: WebUri('https://truyenqqto.com/')),
                onWebViewCreated: onWebViewCreated,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                    onPressed: () async {
                      await translateImageUrl();
                    },
                    child: const Text('Translate Url')),
                ElevatedButton(
                    onPressed: () async {
                      await translateImageBase64();
                    },
                    child: const Text('Translate Base64'))
              ],
            ),
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
    );
  }

  InAppWebViewController? webViewController;

  void onWebViewCreated(InAppWebViewController controller) {
    debugPrint('onWebViewCreated');
    webViewController = controller;
  }

  Future translateImageUrl() async {
    listImage.clear();
    final urls = await webViewController?.evaluateJavascript(
        source:
            """const imageUrls = [...document.querySelectorAll('img')].map(img => img.dataset.src || img.src); imageUrls;""");

    if (urls is List) {
      for (var element in urls) {
        await _loadImageFromFile('$element');
      }
    }
  }

  Future translateImageBase64() async {
    listImage.clear();
    final base64String = await webViewController?.evaluateJavascript(source: """
function getImageBase64Sync() {
    let img = document.querySelector("div.page-chapter img");
    if (!img) return '';

    let canvas = document.createElement("canvas");
    let ctx = canvas.getContext("2d");

    canvas.width = img.naturalWidth;  // Dùng kích thước thực của ảnh
    canvas.height = img.naturalHeight;

    ctx.drawImage(img, 0, 0); // Vẽ ảnh lên canvas

    return canvas.toDataURL("image/jpeg"); // Chuyển thành Base64
}

let imgBase64 = getImageBase64Sync();
 imgBase64;
    """);

    print("Base64: ${base64String}");
    String st = base64String.split(',')[1]; // Lấy phần sau "base64,"

    await _loadImageFromBase64(st);
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

// Hàm chuyển đổi và lưu ảnh
Future<void> saveImage(ui.Image image, String name) async {
  // Yêu cầu quyền truy cập bộ nhớ trên Android
  if (Platform.isAndroid) {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      print("Không có quyền truy cập bộ nhớ");
      return;
    }
  }

  // Chuyển đổi ui.Image sang byte
  ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) return;

  Uint8List pngBytes = byteData.buffer.asUint8List();

  // Lưu file vào thư mục máy
  final directory =
      await getExternalStorageDirectory(); // Dùng thư mục ngoài trên Android
  final filePath = '${directory!.path}/$name.png';

  File file = File(filePath);
  await file.writeAsBytes(pngBytes);

  print("Ảnh đã được lưu tại: $filePath");
}

// Chuyển CustomPainter thành hình ảnh
Future<void> exportImage(
    ColorOverlayPainter painter, Size size, String name) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  painter.paint(canvas, size);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());

  await saveImage(image, name);
}

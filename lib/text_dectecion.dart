import 'package:dio/dio.dart';

import 'env.dart';

class VisionGoogleAPI {
  String api =
      "https://vision.googleapis.com/v1/images:annotate?key=$googleVisionKey";

  Map body = {
    "requests": [
      {
        "image": {"content": ""},
        "features": [
          {"type": "TEXT_DETECTION"}
        ],
        // "imageContext": {
        //   "languageHints": ["zh"]
        // }
      }
    ]
  };

  static String language = "zh";

  Future<List<Block>> textDetection(String image) async {
    Dio dio = Dio();
    final response = await dio.post(api, data: {
      "requests": [
        {
          "image": {"content": image},
          "features": [
            {"type": "TEXT_DETECTION"}
          ],
          // "imageContext": {
          //   "languageHints": ["zh"]
          // }
        }
      ]
    });
    print(response.data);
    if (response.statusCode == 200) {
      final list = response.data['responses'][0]['fullTextAnnotation']['pages'];

      final blocks = list[0]['blocks'];
      List<Block> blockModels = [];
      for (var item in blocks) {
        blockModels.add(Block.json(item));
      }

      // for (var element in blockModels) {
      //   print(element.toString());
      // }

      return blockModels;
    }

    return [];
  }

  void sapXep(List<Block> blocks) {
    for (int i = 0; i < blocks.length; ++i) {
      Position left = blocks[i].positions[2];
      Position right = blocks[i].positions[3];

      for (int j = i + 1; j < blocks.length - 1; ++j) {
        Position leftHead = blocks[i].positions[0];
        Position rightHead = blocks[i].positions[1];
      }
    }
  }
}

class Block {
  final List<Position> positions;
  final String text;
  String translate = '';

  Block({required this.positions, required this.text});

  factory Block.json(Map<String, dynamic> json) {
    final position = json['boundingBox']['vertices'];
    final words = json['paragraphs'][0]['words'];
    String text = '';
    for (var word in words) {
      final symbols = word['symbols'];
      for (var symbol in symbols) {
        var char = symbol['text'];
        text += '$char';
      }
      text += ' ';
    }

    List<Position> listPosition = [];
    for (var item in position) {
      listPosition.add(Position(x: item['x'] ?? 0, y: item['y'] ?? 0));
    }
    return Block(positions: listPosition, text: text);
  }

  @override
  String toString() {
    String positionText = '';
    for (var element in positions) {
      positionText += '{x:${element.x} ,y:${element.y}}\n';
    }
    return '$text \n $positionText';
  }
}

class Position {
  final int x;
  final int y;

  Position({required this.x, required this.y});
}

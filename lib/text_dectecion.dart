import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'env.dart';

class VisionGoogleAPI {
  String api =
      "https://vision.googleapis.com/v1/images:annotate?key=$googleVisionKey";

<<<<<<< HEAD
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

=======
>>>>>>> 5e5aab2ca23fa3ca9729dae53b0a222058ac6852
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
<<<<<<< HEAD
    print(response.data);
=======
>>>>>>> 5e5aab2ca23fa3ca9729dae53b0a222058ac6852
    if (response.statusCode == 200) {
      final list = response.data['responses'][0]['fullTextAnnotation']['pages'];

      final blocks = list[0]['blocks'];
      List<Block?> blockModels = [];
      for (var item in blocks) {
        blockModels.add(Block.json(item));
      }

      Map<int, int> positionNear = {};

      for (int i = 0; i < blockModels.length; ++i) {
        for (int j = i + 1; j < blockModels.length; ++j) {
          double distance = minEdgeDistance(blockModels[i]!, blockModels[j]!);
          if (distance < 10) {
            positionNear.addAll({i: j});
          }
        }
      }

//
      positionNear.forEach((key, value) {
        if (value != -1) {
          final box = merge(blockModels[key]!, blockModels[value]!);
          blockModels[value] = null;
          blockModels[key] = mergeBox(positionNear, value, box, blockModels);
        }
      });

      List<Block> listBlock = [];

      for (var element in blockModels) {
        if (element != null) {
          listBlock.add(element);
        }
      }

      return listBlock;
    }

    return [];
  }
}

class Block {
  final List<Position> positions;
  final String text;
  String translate = '';

  Block({required this.positions, required this.text});

  // Lấy danh sách các cạnh từ 4 điểm
  List<List<Position>> get edges {
    return [
      [positions[0], positions[1]],
      [positions[1], positions[2]],
      [positions[2], positions[3]],
      [positions[3], positions[0]]
    ];
  }

  Rect convertBoundingPolyToRect() {
    double left = positions.map((p) => p.x).reduce((a, b) => a < b ? a : b);
    double top = positions.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    double right = positions.map((p) => p.x).reduce((a, b) => a > b ? a : b);
    double bottom = positions.map((p) => p.y).reduce((a, b) => a > b ? a : b);

    return Rect.fromLTRB(
        left.toDouble(), top.toDouble(), right.toDouble(), bottom.toDouble());
  }

  factory Block.json(Map<String, dynamic> json) {
    final position = json['boundingBox']['vertices'];
    final paragraphs = json['paragraphs'];
    String text = '';
<<<<<<< HEAD
    for (var word in words) {
      final symbols = word['symbols'];
      for (var symbol in symbols) {
        var char = symbol['text'];
        text += '$char';
      }
      text += ' ';
=======
    for (var paragraph in paragraphs) {
      final words = paragraph['words'];
      for (var word in words) {
        final char = word['symbols'];
        for (var item in char) {
          text += '${item['text']}';
        }
      }
>>>>>>> 5e5aab2ca23fa3ca9729dae53b0a222058ac6852
    }

    List<Position> listPosition = [];
    for (var item in position) {
<<<<<<< HEAD
      listPosition.add(Position(x: item['x'] ?? 0, y: item['y'] ?? 0));
=======
      double x = double.tryParse('${item['x']}') ?? 0;
      double y = double.tryParse('${item['y']}') ?? 0;
      listPosition.add(Position(x: x, y: y));
>>>>>>> 5e5aab2ca23fa3ca9729dae53b0a222058ac6852
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

Block merge(Block box1, Block box2) {
  double minX = [...box1.positions, ...box2.positions]
      .map((p) => p.x)
      .reduce((a, b) => a < b ? a : b);

  double maxX = [...box1.positions, ...box2.positions]
      .map((p) => p.x)
      .reduce((a, b) => a > b ? a : b);

  double minY = [...box1.positions, ...box2.positions]
      .map((p) => p.y)
      .reduce((a, b) => a < b ? a : b);

  double maxY = [...box1.positions, ...box2.positions]
      .map((p) => p.y)
      .reduce((a, b) => a > b ? a : b);

  return Block(text: box1.text + box2.text, positions: [
    Position(x: minX, y: minY),
    Position(x: maxX, y: minY),
    Position(x: maxX, y: maxY),
    Position(x: minX, y: maxY),
  ]);
}

// Tính trung điểm của đoạn thẳng giữa hai điểm
Position midPosition(Position p1, Position p2) {
  return Position(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2);
}

// Tính khoảng cách từ điểm đến đoạn thẳng
double pointToSegmentDistance(Position p, Position a, Position b) {
  double px = b.x - a.x;
  double py = b.y - a.y;
  double norm = px * px + py * py;

  double u = ((p.x - a.x) * px + (p.y - a.y) * py) / norm;
  u = u.clamp(0, 1); // Giữ u trong khoảng [0, 1]

  Position closest = Position(x: a.x + u * px, y: a.y + u * py);
  return sqrt(pow(p.x - closest.x, 2) + pow(p.y - closest.y, 2));
}

// Tính khoảng cách viền gần nhất giữa hai box
double minEdgeDistance(Block box1, Block box2) {
  double minDistance = double.infinity;

  for (var edge1 in box1.edges) {
    Position mid1 = midPosition(edge1[0], edge1[1]);
    for (var edge2 in box2.edges) {
      double distance = pointToSegmentDistance(mid1, edge2[0], edge2[1]);
      minDistance = min(minDistance, distance);
    }
  }

  for (var edge2 in box2.edges) {
    Position mid2 = midPosition(edge2[0], edge2[1]);
    for (var edge1 in box1.edges) {
      double distance = pointToSegmentDistance(mid2, edge1[0], edge1[1]);
      minDistance = min(minDistance, distance);
    }
  }

  return minDistance;
}

class Position {
  final double x;
  final double y;

  Position({required this.x, required this.y});
}

Block mergeBox(Map<int, int> position, int key, Block box, List<Block?> list) {
  int? value = position[key];

  if (value != null && value != -1) {
    box = merge(box, list[value]!);
    position[key] = -1;
    list[value] = null;
    box = mergeBox(position, value, box, list);
  }

  return box;
}

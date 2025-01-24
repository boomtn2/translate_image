import 'package:dio/dio.dart';

import 'env.dart';

String keyOpenAI = openAIKey;

class OpenaiHelper {
  final baseOption = BaseOptions(
      method: 'POST', baseUrl: 'https://api.openai.com/v1/embeddings');

  final option = Options(
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $keyOpenAI'
    },
  );

  Dio dio = Dio();

  Future<List?> getEmbedding(String text) async {
    // print('RESPONSE ${text}');

    final response = await dio.post(
      'https://api.openai.com/v1/embeddings',
      options: option,
      data: {
        "input": text,
        "model": "text-embedding-3-small",
      },
    );

    // print('RESPONSE ${response}');
    return response.data['data'][0]['embedding'];
  }

  Future<Map> getTranslate(String text) async {
    // print('RESPONSE ${text}');

    final response = await dio.post(
        'https://api.openai.com/v1/chat/completions',
        options: option,
        data: {
          "model": "ft:gpt-4o-mini-2024-07-18:hieu:nam-hanviet:AkDdsrfy",
          "messages": [
            {
              "role": "user",
              "content": [
                {"type": "text", "text": text}
              ]
            }
          ],
          "response_format": {"type": "text"},
          "temperature": 0.2,
          "max_completion_tokens": 2024,
          "top_p": 0.3,
          "frequency_penalty": 0,
          "presence_penalty": 0
        });

    return response.data;
  }
}

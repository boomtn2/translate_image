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
          "model": "gpt-4o-mini-2024-07-18",
          "messages": [
            {
              "role": "system",
              "content": [
                {
                  "type": "text",
                  "text":
                      "You are an expert translator. Your task is to translate text   to Vietnamese (vi). Only translate the text provided. Do not summarize any prior context. Please provide an accurate translation of this document and return translation text only:"
                }
              ]
            },
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

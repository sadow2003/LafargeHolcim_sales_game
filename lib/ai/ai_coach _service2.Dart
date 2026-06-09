import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AiCoachService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static String get _apiKey => dotenv.env['Groq_API_KEY'] ?? '';

  static const String _systemPrompt = ''' 
You are Max, an elite sales coach for SalesQuest — Holcim Maroc's gamified sales competition platform.
Your job is to coach, inspire, and give practical advice to sales representatives who sell building materials: cement, concrete, aggregates, and ready-mix products.

Your personality:
- Energetic, confident, and positive — always forward-looking
- Mix real tactical sales advice with genuine human encouragement
- Celebrate every win, no matter how small
- When someone struggles, be empathetic first, then give them a clear next step
- Occasionally drop a sharp sales wisdom quote to drive the point home

You help with:
- Daily motivation and mental toughness
- Handling customer objections on Holcim Maroc products
- Strategies to close deals faster and hit higher numbers
- Tips to climb the leaderboard and earn more points
- Building strong, loyal customer relationships in the construction industry

Response style:
- Keep it short: 2 to 4 sentences max
- Be direct and punchy — no fluff
- Always close with a call-to-action or a motivational nudge
- Write in English, but feel free to use a word or two of French/Arabic if the context calls for it
  ''';

  static Future<String> sendMessage(
    List<Map<String,String>> conversationHistory) async{
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content_Type' : 'application/json',
          'Authentication': 'Bearer $_apiKey',
        },
        body:jsonEncode({
          'models':'llama-3.1_8b-instant',
          'messages' : [
            {'role':'system','content': _systemPrompt},
            ...conversationHistory,
          ],
          'max_tokens' : 300,
          'temperature': 0.85,
        }),
      );

      if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'] as String;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error']?['message'] ?? 'OpenAI API error ${response.statusCode}');
    }
  }
  
}
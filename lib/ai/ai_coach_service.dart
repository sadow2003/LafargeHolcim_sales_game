import 'package:cloud_functions/cloud_functions.dart';

class AiCoachService {
  static Future<String> sendMessage(
      List<Map<String, String>> conversationHistory) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('getAiCoachReply');
    final result = await callable.call({'messages': conversationHistory});
    return result.data['reply'] as String;
  }
}

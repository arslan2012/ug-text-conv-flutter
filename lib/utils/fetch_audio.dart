import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import '../const.dart';

Future<BytesSource> fetchAudioOfText(String text) async {
  var response = await http.post(
    Uri.parse(textToSpeechApi),
    headers: {
      'Content-Type': 'application/json',
    },
    body: '"$text"',
  );

  if (response.statusCode == 200) {
    final bytes = response.bodyBytes;
    return BytesSource(bytes, mimeType: 'audio/wav');
  } else {
    throw Exception('Failed to fetch audio: ${response.reasonPhrase}');
  }
}

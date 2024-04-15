import 'package:flutter_dotenv/flutter_dotenv.dart';

var host = dotenv.env['API_HOST'] ?? 'http://localhost:8000';
var textToSpeechApi = '$host/api/t2s';
var speechToTextApi = '$host/api/s2t';

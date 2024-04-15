import 'dart:async';
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audio_session/audio_session.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:permission_handler/permission_handler.dart';

import '../const.dart';

class AudioRecorderService {
  FlutterSoundRecorder? _audioRecorder;

  Future<void> init() async {
    _audioRecorder = FlutterSoundRecorder();

    await _audioRecorder!.openRecorder();
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
      AVAudioSessionCategoryOptions.allowBluetooth |
      AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
      AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
  }

  Future<void> startRecording() async {
    if (_audioRecorder == null) {
      throw Exception('Recorder not initialized');
    }
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }

    await _audioRecorder!.startRecorder(
      toFile: 'audio_tmp.wav',
      codec: Codec.pcm16WAV,
    );
  }

  Future<String> stopRecordingAndSend() async {
    if (_audioRecorder == null) {
      throw Exception('Recorder not initialized');
    }

    final path = await _audioRecorder!.stopRecorder();
    if (path == null) {
      throw Exception('Recording failed to stop or was not started.');
    }

    // Read the audio file as bytes
    // final audioFile = await _audioRecorder!.getRecordURL(path: path!);
    // final audioBytes = await http.readBytes(Uri.parse(audioFile!));
    final file = File(path);
    final audioBytes = await file.readAsBytes();

    // Create a multipart request to send the audio
    var request = http.MultipartRequest('POST', Uri.parse(speechToTextApi));
    request.files.add(http.MultipartFile.fromBytes(
      'sound',
      audioBytes,
      filename: 'recording.wav',
      contentType: MediaType('audio', 'wav'),
    ));
    final response = await request.send();
    if (response.statusCode == 200) {
      var result = await response.stream.bytesToString();
      return result.replaceAll('"', '');
    } else {
      throw Exception('Failed to send audio: ${response.reasonPhrase}');
    }
  }

  Future<void> dispose() async {
    if (_audioRecorder != null) {
      await _audioRecorder!.closeRecorder();
      _audioRecorder = null;
    }
  }
}

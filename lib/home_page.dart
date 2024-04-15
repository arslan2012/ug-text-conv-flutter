import 'package:audioplayers/audioplayers.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';

import 'utils/audio_recorder.dart';
import 'utils/fetch_audio.dart';
import 'utils/ug_script_converter.dart';
import 'components/alphabet_switch.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String title = 'Almash';
  late TextEditingController textEditController;
  final AudioPlayer audioPlayer = AudioPlayer();
  final AudioRecorderService audioRecorderService = AudioRecorderService();
  bool isArabic = false;
  bool isRecording = false;
  bool loading = false;

  void onToggle(bool isArabic) {
    var currentText = textEditController.text;
    var convertedText = ugScriptConverter(currentText,
        sourceScript: isArabic ? 'ULS' : 'UAS',
        targetScript: isArabic ? 'UAS' : 'ULS');
    textEditController.text = convertedText;
    setState(() {
      title = isArabic ? 'ئالماش' : 'Almash';
      this.isArabic = isArabic;
    });
  }

  Future<void> recordAndSendAudio() async {
    if (loading) {
      return;
    }
    if (isRecording) {
      setState(() {
        isRecording = false;
        loading = true;
      });
      try {
        var text = await audioRecorderService.stopRecordingAndSend();
        textEditController.text = isArabic ? ugScriptConverter(text): text;
      } catch (e) {
        print(e);
      }
      setState(() {
        loading = false;
      });
    } else {
      await audioRecorderService.startRecording();
      setState(() {
        isRecording = true;
      });
    }
  }

  Future<void> fetchAndPlayAudio() async {
    if (loading) {
      return;
    }
    setState(() {
      loading = true;
    });
    var currentText = textEditController.text;
    var arabicText = isArabic ? currentText : ugScriptConverter(currentText);
    var audioSource = await fetchAudioOfText(arabicText);
    await audioPlayer.play(audioSource);
    setState(() {
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    textEditController = TextEditingController();
    audioRecorderService.init();
  }

  @override
  void dispose() {
    textEditController.dispose();
    audioPlayer.dispose();
    audioRecorderService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Column(
        children: <Widget>[
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: AlphabetSwitch(
                      onToggle: onToggle,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: recordAndSendAudio,
                  child: loading
                      ? AnimatedTextKit(
                          animatedTexts: [
                            TyperAnimatedText('...'),
                          ],
                          isRepeatingAnimation: true,
                        )
                      : Text(buttonText[isRecording ? 'stop' : 'record']![
                          isArabic]!),
                ),
                TextField(
                  controller: textEditController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                ElevatedButton(
                  onPressed: fetchAndPlayAudio,
                  child: loading
                      ? AnimatedTextKit(
                          animatedTexts: [
                            TyperAnimatedText('...'),
                          ],
                          isRepeatingAnimation: true,
                        )
                      : Text(isArabic ? 'وقۇپپې' : 'oquppe'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const buttonText = {
  'record': {
    true: 'سۆز كىرگۈز',
    false: 'söz kirgüz',
  },
  'stop': {
    true: 'توختات',
    false: 'toxtat',
  },
};

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
// import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final AudioPlayer _audioPlayer;
  final TextEditingController _controller = TextEditingController();
  bool isPlaying = false;

  @override
  void initState() {
    _audioPlayer = AudioPlayer();
    // file name: shower(15mins), wake_up(5mins), new_york(15mins)
    setAsset('shower');
    _audioPlayer.positionStream.listen((event) {
      print(event);
    });
    super.initState();
  }

  setAsset(String title) async {
    // var content = await rootBundle.load("assets/audio/$title.mp3");
    // final directory = await getApplicationDocumentsDirectory();
    // var file = File("${directory.path}/$title.mp3");
    // file.writeAsBytesSync(content.buffer.asUint8List());
    // await Future.delayed(Duration(seconds: 1));
    var filename = (await FilePicker.platform.pickFiles())?.files.single.path;
    if (filename != null) {
      await _audioPlayer.setFilePath(filename);
    }

    // await _audioPlayer.setFilePath(file.path);

    // await _audioPlayer.setUrl(
    //     'file:///Users/hyungjoo/Desktop/develop/flutter_just_audio_test/assets/audio/shower.mp3');
  }

  Future<File> saveFilePermanently(PlatformFile file) async {
    final appStorage = await getApplicationDocumentsDirectory();
    final newFile = File('${appStorage.path}/${file.name}');

    return File(file.path!).copy(newFile.path);
  }

  String _getTimeString(Duration time) {
    final minutes =
        time.inMinutes.remainder(Duration.minutesPerHour).toString();
    final seconds = time.inSeconds
        .remainder(Duration.secondsPerMinute)
        .toString()
        .padLeft(2, '0');
    return time.inHours > 0
        ? "${time.inHours}:${minutes.padLeft(2, "0")}:$seconds"
        : "$minutes:$seconds";
  }

  void openFile(PlatformFile file) async {
    print('${file.bytes}');
    print('${file.size}');
    print('${file.extension}');
    print('${file.path}');

    final newFile = await saveFilePermanently(file);

    await _audioPlayer.setFilePath(newFile.path);

    print('${file.path!}');
    print('${newFile.path}');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Builder(builder: (context) {
          return ListView(
            children: [
              const SizedBox(
                height: 100,
              ),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(
                height: 100,
              ),
              ElevatedButton(
                  onPressed: () {
                    final seekDuration = Duration(
                        seconds: int.parse(_controller.text) == 0
                            ? 1
                            : int.parse(_controller.text));
                    _audioPlayer.seek(seekDuration);
                  },
                  child: Text('seek to ${_controller.text} seconds')),
              const SizedBox(
                height: 100,
              ),
              ElevatedButton(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles();
                    if (result == null) {
                      return;
                    }

                    final file = result.files.first;
                    openFile(file);
                  },
                  child: Text('open file')),
              const SizedBox(
                height: 100,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StreamBuilder<Duration>(
                    builder: (_, snapshot) {
                      return Text(
                          _getTimeString(snapshot.data ?? Duration.zero));
                    },
                    stream: _audioPlayer.positionStream,
                  ),
                  StreamBuilder<Duration?>(
                    builder: (_, snapshot) {
                      return Text(
                          _getTimeString(snapshot.data ?? Duration.zero));
                    },
                    stream: _audioPlayer.durationStream,
                  ),
                ],
              ),
              const SizedBox(
                height: 100,
              ),
              StreamBuilder<PlayerState>(
                  stream: _audioPlayer.playerStateStream,
                  initialData: PlayerState(false, ProcessingState.ready),
                  builder: (_, snapshot) {
                    final audioState = snapshot.data;
                    return ElevatedButton(
                        onPressed: () {
                          if (audioState!.playing) {
                            _audioPlayer.pause();
                          } else {
                            _audioPlayer.play();
                          }
                        },
                        child: Text(audioState!.playing ? 'pause' : 'play'));
                  }),
            ],
          );
        }),
      ),
    );
  }
}

// ignore_for_file: camel_case_types, must_be_immutable

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class audioplay extends StatefulWidget {
  const audioplay({super.key});

  @override
  State<audioplay> createState() => _audioplayState();
}

class _audioplayState extends State<audioplay> {
  final audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  String url = "";

  @override
  void initState() {
    super.initState();
    setAudio();

    /// Listen to states: playing, paused, stopped
    audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        isPlaying = state == PlayerState.playing;
      });
    });

    /// Listen to audio duration
    audioPlayer.onDurationChanged.listen((newDuration) {
      setState(() {
        duration = newDuration;
      });
    });

    /// Listen to audio position
    audioPlayer.onPositionChanged.listen((newPosition) {
      setState(() {
        position = newPosition;
      });
    });
  }

  Future setAudio() async {
    // Repeat song when completed
    audioPlayer.setReleaseMode(ReleaseMode.loop);

    /// Load audio from Assets (audio/music.mp3)
    // final player = AudioCache(prefix: 'audio/');
    // final url = await player.load('music.mp3');
    // audioPlayer.setUrl(url.path, isLocal: true);
    url =
        "https://bibleoffice.com/BibleReplications/dev/v1/uploads/bible_audio/English/1/1.mp3";
    await audioPlayer.setSourceUrl(url);
    // await audioPlayer.play(url);
    // if (isPlaying) {
    //   await audioPlayer.pause();
    // }
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          "widget.playerdata!.title.toString()",
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // const SizedBox(height: 4),
          //  Padding(
          //    padding: const EdgeInsets.only(left: 8.0,right: 8),
          //    child: Text (widget.playerdata!.description.toString(),
          //       style: const TextStyle(letterSpacing: BibleInfo.letterSpacing ,  fontSize: BibleInfo.fontSizeScale * 14, color: Colors.white),textAlign: TextAlign.center,
          // ),
          //  ),
          const SizedBox(
            height: 10,
          ),
        ],
      ),
      bottomSheet: Container(
        color: Colors.grey[200],
        child: ListView(
          shrinkWrap: true,
          physics: const ScrollPhysics(),
          children: [
            CircleAvatar(
              radius: 30,
              child: IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                ),
                color: Colors.indigo,
                iconSize: 40,
                onPressed: () async {
                  // print(duration.inSeconds.toDouble());
                  // print(position.inSeconds.toDouble());
                  if (isPlaying) {
                    await audioPlayer.pause();
                  } else {
                    await audioPlayer.resume();
                    //await audioPlayer.play();
                  }
                },
              ),
            ),
            Slider(
              min: 0,
              max: duration.inSeconds.toDouble(),
              value: position.inSeconds.toDouble(),
              onChanged: (value) async {
                final position = Duration(seconds: value.toInt());
                await audioPlayer.seek(position);

                ///Optional:Play audio if was paused
                await audioPlayer.resume();
              },
              activeColor: Colors.orange,
              inactiveColor: Colors.black87,
              thumbColor: Colors.green,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatTime(position),
                    style: const TextStyle(color: Colors.black87),
                  ),
                  Text(
                    formatTime(duration - position),
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 50,
            )
          ],
        ),
      ),
    );
  }

  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return [
      if (duration.inHours > 0) hours,
      minutes,
      seconds,
    ].join(':');
  }
}

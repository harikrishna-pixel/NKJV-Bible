//
// import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
// import 'package:flutter/material.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:rxdart/rxdart.dart';
// import '../../constants/colors.dart';
//
// class PositionData{
//   const PositionData(
//         this.position,
//         this.bufferedPosition,
//         this.duration
//       );
//   final Duration position;
//   final Duration bufferedPosition;
//   final Duration duration;
// }
//
//
// class PlayerButtons extends StatelessWidget {
//   var progressBar;
//   PlayerButtons(this._audioPlayer, {Key? key, required this.progressBar}) : super(key: key);
//
//   final AudioPlayer _audioPlayer;
//
//   Stream<PositionData> get _positionDataStream =>
//       Rx.combineLatest3<Duration, Duration, Duration?,PositionData>(
//           _audioPlayer.positionStream,
//           _audioPlayer.bufferedPositionStream,
//           _audioPlayer.durationStream,
//               (position, bufferedPosition, duration) => PositionData(
//               position, bufferedPosition, duration ?? Duration.zero),
//       );
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         progressBar==1?
//         StreamBuilder<PositionData>(
//           stream: _positionDataStream,
//           builder: (context, snapshot) {
//             final positionData = snapshot.data;
//             return ProgressBar(
//               baseBarColor: Colors.grey,
//               timeLabelLocation: TimeLabelLocation.sides,
//               progressBarColor: CommanColor.lightDarkPrimary(context),
//               timeLabelTextStyle: TextStyle(color:CommanColor.lightDarkPrimary(context)),
//               thumbColor: CommanColor.lightDarkPrimary(context),
//               barHeight: 4,
//               bufferedBarColor: CommanColor.lightDarkPrimary(context),
//               thumbGlowColor: Colors.white,
//                 thumbRadius: 6,
//                 progress: positionData?.position ?? Duration.zero,
//                 // buffered: positionData?.bufferedPosition ?? Duration.zero,
//                 total: positionData?.duration ?? Duration.zero,
//                 onSeek: _audioPlayer.seek,
//             );
//           },
//         ):SizedBox(),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             StreamBuilder<LoopMode>(
//               stream: _audioPlayer.loopModeStream,
//               builder: (context, snapshot) {
//                 return _repeatButton(context, snapshot.data ?? LoopMode.off);
//               },
//             ),
//             StreamBuilder<SequenceState?>(
//               stream: _audioPlayer.sequenceStateStream,
//               builder: (_, __) {
//                 return _previousButton(context);
//               },
//             ),
//             StreamBuilder<PlayerState>(
//               stream: _audioPlayer.playerStateStream,
//               builder: (_, snapshot) {
//                 final playerState = snapshot.data;
//                 return _playPauseButton(playerState!,context);
//               },
//             ),
//             StreamBuilder<SequenceState?>(
//               stream: _audioPlayer.sequenceStateStream,
//               builder: (_, __) {
//                 return _nextButton(context);
//               },
//             ),
//             // Icon(Icons.pres,color: CommanColor.lightDarkPrimary(context),),
//             Padding(
//               padding: const EdgeInsets.only(right: 10.0),
//               child: Icon(Icons.square,color: CommanColor.lightDarkPrimary(context),),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Widget _playPauseButton(PlayerState playerState,context) {
//     final processingState = playerState?.processingState;
//     if (processingState == ProcessingState.loading ||
//         processingState == ProcessingState.buffering) {
//       return Container(
//
//         width: 25.0,
//         height: 25.0,
//         child:  CircularProgressIndicator(color:CommanColor.lightDarkPrimary(context)),
//       );
//     } else if (_audioPlayer.playing != true) {
//       return IconButton(
//         icon: Icon(Icons.play_circle_filled,color: CommanColor.lightDarkPrimary(context),),
//         iconSize: 35.0,
//         onPressed: _audioPlayer.play,
//       );
//     } else if (processingState != ProcessingState.completed) {
//       return IconButton(
//         icon: Icon(Icons.pause_circle_filled_outlined,color: CommanColor.lightDarkPrimary(context),),
//         iconSize: 35.0,
//         onPressed: _audioPlayer.pause,
//       );
//     } else {
//       return IconButton(
//         icon: Icon(Icons.replay,color: CommanColor.lightDarkPrimary(context),),
//         iconSize: 35.0,
//         onPressed: () => _audioPlayer.seek(Duration.zero,
//             index: _audioPlayer.effectiveIndices!.first),
//       );
//     }
//   }
//
//   Widget _shuffleButton(BuildContext context, bool isEnabled) {
//     return IconButton(
//       icon: isEnabled
//           ? Icon(Icons.shuffle, color: CommanColor.lightDarkPrimary(context))
//           : Icon(Icons.shuffle,color: CommanColor.lightDarkPrimary(context),),
//       onPressed: () async {
//         final enable = !isEnabled;
//         if (enable) {
//           await _audioPlayer.shuffle();
//         }
//         await _audioPlayer.setShuffleModeEnabled(enable);
//       },
//     );
//   }
//
//   Widget _previousButton(context) {
//     return IconButton(
//       icon: Icon(Icons.skip_previous,color: CommanColor.lightDarkPrimary(context),),
//       onPressed: _audioPlayer.hasPrevious ? _audioPlayer.seekToPrevious : null,
//     );
//   }
//
//   Widget _nextButton(context) {
//     return IconButton(
//       icon: Icon(Icons.skip_next,color: CommanColor.lightDarkPrimary(context),),
//       onPressed: _audioPlayer.hasNext ? _audioPlayer.seekToNext : null,
//     );
//   }
//
//   Widget _repeatButton(BuildContext context, LoopMode loopMode) {
//     final icons = [
//       Icon(Icons.repeat_rounded,color: CommanColor.lightDarkPrimary(context),),
//       Icon(Icons.repeat_rounded, color:CommanColor.lightDarkPrimary(context)),
//       Icon(Icons.repeat_one_rounded, color: CommanColor.lightDarkPrimary(context)),
//     ];
//     const cycleModes = [
//       LoopMode.off,
//       LoopMode.all,
//       LoopMode.one,
//     ];
//     final index = cycleModes.indexOf(loopMode);
//     return IconButton(
//       icon: icons[index],
//       onPressed: () {
//         _audioPlayer.setLoopMode(
//             cycleModes[(cycleModes.indexOf(loopMode) + 1) % cycleModes.length]);
//       },
//     );
//   }
// }
import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:biblebookapp/Model/get_audio_model.dart';
import 'package:biblebookapp/utils/internet_speed_checker.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:html/parser.dart';
import 'package:popover/popover.dart';
import 'package:provider/provider.dart';
import '../../../Model/verseBookContentModel.dart';
import '../../../Model/mainBookListModel.dart';
import '../../constants/colors.dart';
import '../../constants/theme_provider.dart';
import '../../widget/country.dart';
import '../../widget/laguage.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import '../../../controller/dashboard_controller.dart';
import '../../../controller/dpProvider.dart';

class floatingButton extends StatefulWidget {
  String bookName;
  String chapterNum;
  String bookNum;
  String chapterCount;
  List<VerseBookContentModel> contentList;
  GetAudioModel? audioData;
  List<ConnectivityResult>? internetConnection;
  bool textToSpeechLoad;
  late AudioPlayer audioPlayer;

  floatingButton(
      {super.key,
      required this.textToSpeechLoad,
      required this.bookName,
      required this.chapterNum,
      required this.contentList,
      required this.chapterCount,
      required this.audioData,
      required this.bookNum,
      required this.internetConnection,
      required this.audioPlayer});

  @override
  State<floatingButton> createState() => floatingButtonState();
}

enum TtsState { playing, stopped, paused, continued }

class floatingButtonState extends State<floatingButton>
    with WidgetsBindingObserver {
  bool audioLoad = false;
  // GetAudioModel?  audioData;
  bool isOpenAudio = false;

  ///  *************************Audio *******************

  bool repeat = false;
  bool isAudioPlaying = false;
  // Duration duration = Duration(minutes: 10);
  // Duration position = Duration(minutes: 3);
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  String audioBaseUrl = "";
  int audioBookNum = 1;
  int audioChapterNum = 1;
  int currentBookChapterCount = 1; // Track current book's chapter count for accurate completion checks
  bool isPrevTTSEnabled = false;
  late AudioPlayer audioPlayer;

  // Add this for background audio
  late AudioHandler _audioHandler;
  final bool _isAudioServiceInitialized = false;

  // Stream subscriptions for audio player - must be cancelled in dispose
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _durationSubscription;

  checkTTS() async {
    final ttsStatus =
        await SharPreferences.getBoolean(SharPreferences.isTtsActive);
    await Future.delayed(Duration(milliseconds: 2000));

    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (isSpeech) {
        if (mounted) {
          setState(() {
            isPrevTTSEnabled = ttsStatus ?? false;
          });
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    checknetwork();
    audioPlayer = widget.audioPlayer;
    setupAudioPlayer().then((_) {
      selectedChapter = int.parse(widget.chapterNum);
      audioChapterNum = int.parse(widget.chapterNum);
      audioBookNum = int.parse(widget.bookNum.toString()) + 1;
      currentBookChapterCount = int.parse(widget.chapterCount.toString());
      setChapterContent();
      initTts();
      checkTTS();
    });

    _playerStateSubscription = audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          isAudioPlaying = state == PlayerState.playing;
        });
      }
    });

    /// Listen to audio duration
    _durationSubscription = audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          duration = newDuration;
        });
      }
    });
  }

  Future<void> setupAudioPlayer() async {
    await AudioPlayer.global.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          // No defaultToSpeaker here for music
        ),
      ),
    );
  }

  initMusic() {
    /// Listen to s
    /// tates: playing, paused, stopped
    audioPlayer.onPlayerStateChanged.listen((state) {
      if (context.mounted) {
        setState(() {
          isAudioPlaying = state == PlayerState.playing;
        });
      }
    });

    /// Listen to audio duration
    audioPlayer.onDurationChanged.listen((newDuration) {
      if (context.mounted) {
        setState(() {
          duration = newDuration;
        });
      }
    });

    /// Listen to audio position
  }

  Future setAudio() async {
    // Set release mode based on repeat flag - default to release (no loop)
    String? audioBasePath =
        widget.audioData?.data?.bibleAudioInfo?.audioBasepath;
    try {
      await audioPlayer.setReleaseMode(
          repeat ? ReleaseMode.loop : ReleaseMode.release);
      audioBaseUrl = "$audioBasePath/$audioBookNum/$audioChapterNum.mp3";
      log('Audio Base Url:$audioBaseUrl');
      await audioPlayer.setSourceUrl(audioBaseUrl).whenComplete(() {
        log('Audio Set Completed');
        // setState(() {
        //   isAudioPlaying = true;
        // });
      });
    } catch (e, st) {
      log('Audio Set Error: $e,$st');
      debugPrintStack(stackTrace: st);
    }
  }

  /// Text To Speech

  bool isTTSLoop = false;
  bool shouldAutoAdvance = true; // Flag to control auto-advancement
  bool isManualNavigation = false; // Flag to track manual navigation to prevent double increment
  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isWindows => !kIsWeb && Platform.isWindows;
  bool get isWeb => kIsWeb;
  final Connectivity _connectivity = Connectivity();
  int curretNo = 0;
  String? speechText;
  int selectedChapter = 0;

  int languageSelectedColor = 0;
  List<VerseBookContentModel> selectedChapterContent = [];

  bool isSpeech = false;
  late FlutterTts flutterTts;
  bool _isTtsInitialized = false;
  String? language;
  String? engine;
  double volume = 0.5;
  double pitch = 1.25;
  double rate = 0.5;
  bool isCurrentLanguageInstalled = false;
  dynamic selectedVoice;
  List<dynamic>? availableVoices;
  double turns = 0.0;
  Future<void> changeRotation() async {
    turns += 1.0 / 1.0;
  }

  String? _newVoiceText;
  int? inputLength;

  TtsState ttsState = TtsState.stopped;

  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;
  get isPaused => ttsState == TtsState.paused;
  get isContinued => ttsState == TtsState.continued;
  int start = 0;
  int end = 0;
  String allText = "";

  bool hasConnection = true;

  bool isNext = false;
  initTts() async {
    flutterTts = FlutterTts();
    _isTtsInitialized = true;

    _setAwaitOptions();
    await Future.delayed(Duration(milliseconds: 2000));

    if (!mounted) return;
    if (isAndroid) {
      _getDefaultEngine();
      _getDefaultVoice();
    }

    flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() {
          ttsState = TtsState.playing;
        });
      }
    });

    flutterTts.setCancelHandler(() {
      if (mounted) {
        setState(() {
          ttsState = TtsState.stopped;
        });
      }
    });
    flutterTts.setPauseHandler(() {
      if (mounted) {
        setState(() {
          ttsState = TtsState.paused;
        });
      }
    });
    flutterTts.setContinueHandler(() {
      if (mounted) {
        setState(() {
          ttsState = TtsState.continued;
        });
      }
    });
    flutterTts.setCompletionHandler(() async {
      // Only auto-advance if not manually stopped or navigated
      if (!shouldAutoAdvance) {
        return;
      }
      // If we just manually navigated, skip incrementing and reset the flag
      if (isManualNavigation) {
        if (mounted) {
          setState(() {
            isManualNavigation = false; // Reset flag and allow future auto-advancement
          });
        }
        return;
      }
      if (isTTSLoop == false) {
        if (selectedChapter == int.parse(widget.chapterCount.toString()) &&
            selectedChapterContent.length == curretNo + 1) {
          // Last chapter, last verse - stop
          await _stop();
          if (mounted) {
            setState(() {
              isSpeech = false;
            });
          }
        } else {
          if (selectedChapter != int.parse(widget.chapterCount.toString()) &&
              selectedChapterContent.length == curretNo + 1) {
            // End of current chapter, move to next chapter
            if (mounted) {
              await _stop();
              // Clear old voice text to prevent speaking old verse
              _newVoiceText = null;
              setState(() {
                selectedChapter++;
                curretNo = 0; // Reset to first verse of new chapter
              });
              // Wait for setState to complete
              await Future.delayed(const Duration(milliseconds: 50));
              // Load chapter content and wait for it to complete
              await setChapterContent();
              if (mounted && selectedChapterContent.isNotEmpty && curretNo >= 0 && curretNo < selectedChapterContent.length) {
                setState(() {
                  _newVoiceText = selectedChapterContent[curretNo].content;
                });
                // Wait for UI to update before speaking
                await Future.delayed(const Duration(milliseconds: 50));
                if (mounted && isSpeech && _newVoiceText != null && _newVoiceText!.isNotEmpty) {
                  _speak();
                }
              }
            }
          } else {
            // Move to next verse in current chapter
            if (mounted && curretNo + 1 < selectedChapterContent.length) {
              setState(() {
                curretNo = curretNo + 1;
                if (curretNo >= 0 && curretNo < selectedChapterContent.length) {
                  _newVoiceText = selectedChapterContent[curretNo].content;
                }
              });
              // Wait for UI to update before speaking
              await Future.delayed(const Duration(milliseconds: 50));
              if (mounted && _newVoiceText != null && _newVoiceText!.isNotEmpty) {
                _speak();
              }
            }
          }
        }
      } else {
        // Loop mode - repeat current verse
        if (mounted) {
          _speak();
        }
      }
    });
    flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          ttsState = TtsState.stopped;
        });
      }
    });
  }

  Future<dynamic> _getLanguages() async => await flutterTts.getLanguages;
  
  Future<List<dynamic>> _getVoices() async {
    try {
      if (isAndroid || isIOS) {
        var voices = await flutterTts.getVoices;
        if (voices != null && voices is List) {
          return voices;
        }
      }
      return [];
    } catch (e) {
      debugPrint("Error getting voices: $e");
      return [];
    }
  }
  
  String _getVoiceDisplayName(dynamic voice) {
    if (voice == null) return "Default";
    if (voice is Map) {
      String? name = voice['name'];
      String? locale = voice['locale'];
      if (name != null) {
        return name;
      } else if (locale != null) {
        return locale;
      }
    }
    return voice.toString();
  }
  
  Future<void> _previewVoice() async {
    try {
      await _stop();
      await flutterTts.setVolume(volume);
      await flutterTts.setSpeechRate(rate);
      await flutterTts.setPitch(pitch);
      if (selectedVoice != null && (isAndroid || isIOS)) {
        // Convert Map<Object?, Object?> to Map<String, String> if needed
        if (selectedVoice is Map) {
          Map<String, String> voiceMap = {};
          selectedVoice.forEach((key, value) {
            voiceMap[key.toString()] = value.toString();
          });
          await flutterTts.setVoice(voiceMap);
        } else {
          await flutterTts.setVoice(selectedVoice);
        }
      }
      await flutterTts.speak("This is a preview of the selected voice.");
    } catch (e) {
      debugPrint("Error previewing voice: $e");
    }
  }
  checknetwork() async {
    await Future.delayed(Duration(milliseconds: 3000));
    await SharPreferences.setBoolean('closead', false);
    if (!mounted) return;
    if (context.mounted) {
      // final checkdata = await _connectivity.checkConnectivity();
      final speed = await InternetSpeedChecker.checkSpeed();
      if (speed != null) {
        setState(() {
          hasConnection = true;
        });
      } else {
        setState(() {
          hasConnection = false;
        });
      }
    }
    debugPrint("check network - $hasConnection");
  }

  Future _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {}
  }

  Future _getDefaultVoice() async {
    var voice = await flutterTts.getDefaultVoice;
    if (voice != null) {}
  }

  Future _speak() async {
    try {
      // TTS works offline, no need to check internet connection
      // But handle any TTS errors gracefully
      await flutterTts.setVolume(volume);
      await flutterTts.setSpeechRate(rate);
      await flutterTts.setPitch(pitch);
      if (_newVoiceText != null) {
        if (_newVoiceText?.isNotEmpty ?? false) {
          final parseText = parse(_newVoiceText).body?.text ?? '';
          if (parseText.isNotEmpty) {
            await flutterTts.awaitSpeakCompletion(true);
            await flutterTts.speak(parseText);
          }
        }
      }
    } catch (e) {
      // Handle TTS errors gracefully - TTS should work offline
      debugPrint("TTS speak error: $e");
      if (mounted) {
        setState(() {
          ttsState = TtsState.stopped;
          isSpeech = false;
        });
      }
      // Show error message only if it's a critical error, not for offline scenarios
      // TTS typically works offline, so most errors are handled silently
    }
  }

  Future _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future _stop() async {
    // await Future.delayed(Duration(seconds: 2));
    await SharPreferences.setBoolean('closead', true);
    if (!mounted) return;
    if (mounted && _isTtsInitialized) {
      try {
        var result = await flutterTts.stop();
        if (result == 1 && mounted) {
          setState(() => ttsState = TtsState.stopped);
        }
      } catch (e) {
        // Ignore errors if TTS is not available
        debugPrint("TTS stop error: $e");
      }
    }
  }

  bool isInitialTime = true;
  int isInitialProgress = 1;
  int totalStartOffset = 0;
  int totalEndOffset = 0;

  closeaudio() async {
    debugPrint(" audio  stopped ");

    if (!mounted) return;
    
    if (isAudioPlaying) {
      try {
        await audioPlayer.stop();
        await SharPreferences.setBoolean('closead', true);
        // await audioPlayer.dispose();
      } catch (e) {
        debugPrint("Error stopping audio: $e");
      }
    } else if (isSpeech && _isTtsInitialized) {
      try {
        flutterTts.stop();
      } catch (e) {
        debugPrint("Error stopping TTS: $e");
      }
    }
  }

  // Helper method to update reading screen when audio chapter changes
  Future<void> updateReadingScreenChapter(int chapterNum) async {
    try {
      // Update shared preferences first
      await SharPreferences.setString(
          SharPreferences.selectedChapter, chapterNum.toString());
      
      // Small delay to ensure SharedPreferences is fully written
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Update local selectedChapter to keep in sync
      if (mounted) {
        setState(() {
          selectedChapter = chapterNum;
        });
      }
      
      // Update the reading screen via controller
      try {
        final controller = Get.find<DashBoardController>();
        // Update controller's observable values directly first to ensure UI updates immediately
        controller.selectedChapter.value = chapterNum.toString();
        controller.selectChapterChange.value = chapterNum;
        
        // Also update the "ForRead" values which are used by getBookContentForRead
        controller.selectedChapterForRead.value = chapterNum.toString();
        
        // Then call getSelectedChapterAndBook to load content from database
        // This method reads from SharedPreferences (which we just updated) and updates controller values
        controller.getSelectedChapterAndBook();
        // Also call getBookContentForRead to ensure content is loaded
        controller.getBookContentForRead();
        // Give enough time for all nested async operations to complete
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Final update to ensure values are set after database operations
        controller.selectedChapter.value = chapterNum.toString();
        controller.selectChapterChange.value = chapterNum;
      } catch (e) {
        debugPrint("DashBoardController not available or error: $e");
        // Controller will be initialized when HomeScreen loads, and it will read from SharedPreferences
      }
    } catch (e, stackTrace) {
      debugPrint("Error updating reading screen chapter: $e");
      debugPrint("Stack trace: $stackTrace");
    }
  }

  // Helper method to get next book and update reading screen
  Future<MainBookListModel?> getNextBook(int currentBookNum) async {
    try {
      final db = await DBHelper().db;
      if (db == null) {
        debugPrint("Database is null");
        return null;
      }

      // Query for the next book (book_num = currentBookNum + 1)
      final nextBookNum = currentBookNum + 1;
      final result = await db.rawQuery(
        "SELECT * FROM book WHERE book_num = $nextBookNum LIMIT 1"
      );

      if (result.isNotEmpty) {
        return MainBookListModel.fromJson(result[0]);
      }
      return null;
    } catch (e, stackTrace) {
      debugPrint("Error getting next book: $e");
      debugPrint("Stack trace: $stackTrace");
      return null;
    }
  }

  // Helper method to update reading screen for next book
  Future<void> updateReadingScreenForNextBook(int bookNum, int chapterNum, String bookName, int chapterCount) async {
    try {
      // Update shared preferences for book and chapter - ensure all are saved
      await SharPreferences.setString(
          SharPreferences.selectedBook, bookName);
      await SharPreferences.setString(
          SharPreferences.selectedChapter, chapterNum.toString());
      await SharPreferences.setString(
          SharPreferences.selectedBookNum, bookNum.toString());
      
      // Small delay to ensure SharedPreferences is fully written
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Update local selectedChapter to keep in sync
      if (mounted) {
        setState(() {
          selectedChapter = chapterNum;
        });
      }
      
      // Update the reading screen via controller
      if (Get.isRegistered<DashBoardController>()) {
        final controller = Get.find<DashBoardController>();
        
        // Update controller's observable values directly first to ensure UI updates immediately
        controller.selectedBook.value = bookName;
        controller.selectedBookNum.value = bookNum.toString();
        controller.selectedChapter.value = chapterNum.toString();
        controller.selectChapterChange.value = chapterNum;
        controller.selectedBookChapterCount.value = chapterCount.toString();
        
        // Also update the "ForRead" values which are used by getBookContentForRead
        controller.selectedBookNameForRead.value = bookName;
        controller.selectedBookNumForRead.value = bookNum.toString();
        controller.selectedChapterForRead.value = chapterNum.toString();
        
        // Call getSelectedChapterAndBook to load content from database
        // This method reads from SharedPreferences (which we just updated) and updates controller values
        try {
          // First ensure controller values are set (they should already be set above, but ensure they are)
          controller.selectedBook.value = bookName;
          controller.selectedBookNum.value = bookNum.toString();
          controller.selectedChapter.value = chapterNum.toString();
          controller.selectChapterChange.value = chapterNum;
          controller.selectedBookChapterCount.value = chapterCount.toString();
          
          // Now call getSelectedChapterAndBook to load content from database
          // This will read from SharedPreferences and ensure all data is loaded
          controller.getSelectedChapterAndBook();
          // Also call getBookContentForRead to ensure content is loaded
          controller.getBookContentForRead();
          // Give enough time for all nested async operations to complete
          await Future.delayed(const Duration(milliseconds: 600));
          
          // One more update to ensure values are set after database operations
          controller.selectedBook.value = bookName;
          controller.selectedChapter.value = chapterNum.toString();
        } catch (controllerError) {
          debugPrint("Error in controller update: $controllerError");
          // Retry once after a short delay
          await Future.delayed(const Duration(milliseconds: 200));
          try {
            controller.selectedBook.value = bookName;
            controller.selectedBookNum.value = bookNum.toString();
            controller.selectedChapter.value = chapterNum.toString();
            controller.selectChapterChange.value = chapterNum;
            controller.selectedBookChapterCount.value = chapterCount.toString();
            controller.getSelectedChapterAndBook();
            controller.getBookContentForRead();
            await Future.delayed(const Duration(milliseconds: 600));
            controller.selectedBook.value = bookName;
            controller.selectedChapter.value = chapterNum.toString();
          } catch (retryError) {
            debugPrint("Error in controller retry: $retryError");
          }
        }
      } else {
        debugPrint("DashBoardController is not registered");
      }
    } catch (e, stackTrace) {
      debugPrint("Error updating reading screen for next book: $e");
      debugPrint("Stack trace: $stackTrace");
    }
  }

  Future<void> setChapterContent() async {
    await Future.delayed(Duration(milliseconds: 2000));

    if (!mounted) return;
    selectedChapterContent.clear();
    start = 0;
    end = 0;
    if (mounted) {
      setState(() {
        curretNo = 0;
      });
    }
    // Use Completer to ensure we wait for content to be loaded
    final completer = Completer<void>();
    Future.delayed(Duration.zero, () {
      if (!mounted) {
        completer.complete();
        return;
      }
      for (var i = 0; i < (widget.contentList.length ?? 0); i++) {
        if (selectedChapter ==
            int.parse((widget.contentList[i].chapterNum).toString()) + 1) {
          if (mounted) {
            setState(() {
              start = 0;
              end = isInitialTime ? 0 : (_newVoiceText?.length ?? 0);
              selectedChapterContent.add(widget.contentList[i]);
              // Only set _newVoiceText if list is not empty and curretNo is valid
              if (selectedChapterContent.isNotEmpty && curretNo >= 0 && curretNo < selectedChapterContent.length) {
                _newVoiceText = selectedChapterContent[curretNo].content;
              }
            });
          }
        }
      }
      completer.complete();
    });
    await completer.future;
  }

  @override
  void dispose() {
    // Cancel all stream subscriptions to prevent setState after dispose
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription = null;
    _durationSubscription = null;
    
    // Stop TTS if running - safely check if flutterTts is initialized
    // Note: TTS handlers already check 'mounted' before calling setState, so they're safe
    if (isSpeech && _isTtsInitialized) {
      try {
        // Try to stop TTS - stop() is safe to call even if not speaking
        flutterTts.stop();
      } catch (e) {
        // Ignore any errors during TTS cleanup (flutterTts might not be fully initialized)
        debugPrint("TTS cleanup error: $e");
      }
    }
    
    closeaudio();
    WidgetsBinding.instance.removeObserver(this);
    // audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    debugPrint("sz current width - $screenWidth ");

    bool isTTSEnabled = Platform.isAndroid
        ? widget.audioData?.data?.bibleAudioInfo
                ?.isTextToSpeechAvailableAndroid ==
            "1"
        : widget.audioData?.data?.bibleAudioInfo?.isTextToSpeechAvailableIos ==
            "1";

    if (widget.audioData?.data != null) {
      SharPreferences.setBoolean(SharPreferences.isTtsActive, isTTSEnabled);
      if (context.mounted) {
        setState(() {
          isPrevTTSEnabled = isTTSEnabled;
        });
      }
    }

    bool isMp3Enabled =
        widget.audioData?.data?.bibleAudioInfo?.isShowMp3Audio == "1";
    // TTS works offline, so allow it even without internet connection
    // MP3 audio requires internet, so check hasConnection for that
    if (hasConnection || isTTSEnabled) {
      if (isMp3Enabled || isTTSEnabled) {
        return Container(
          height: screenWidth > 450 ? 50 : 35,
          width: screenWidth > 450 ? 50 : 35,
          decoration: BoxDecoration(
            color: CommanColor.whiteLightModePrimary(context),
            shape: BoxShape.circle,
          ),
          child: GestureDetector(
            child: Center(
                child: isSpeech || isAudioPlaying
                    ? Icon(Icons.pause,
                        size: screenWidth > 450 ? 44 : 24,
                        color: CommanColor.darkModePrimaryWhite(context))
                    : audioLoad
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: CommanColor.darkModePrimaryWhite(context),
                              strokeWidth: 2,
                            ))
                        : Icon(
                            !isOpenAudio ? Icons.play_arrow : Icons.close,
                            color: CommanColor.darkModePrimaryWhite(context),
                            size: !isOpenAudio
                                ? screenWidth > 450
                                    ? 43
                                    : 28
                                : 22,
                          )),
            onTap: () async {
              log('On Tap');
              if (isSpeech) {
                _stop();
                setState(() {
                  isSpeech = false;
                });
              } else if (isAudioPlaying) {
                await audioPlayer.stop();
                setState(() {
                  isAudioPlaying = false;
                });
              } else if (isTTSEnabled && !isMp3Enabled) {
                textToSpeechBottomSheet();
              } else if (isMp3Enabled && !isTTSEnabled) {
                await setAudio();
                setState(() {
                  audioLoad = false;
                });
                audioPlayerBottomSheet().then((value) {
                  if (mounted) {
                    setState(() {});
                  }
                });
              } else {
                setState(() {
                  isOpenAudio = true;
                  audioLoad = true;
                });
                await setAudio();
                setState(() {
                  audioLoad = false;
                });
                showPopover(
                  context: context,
                  direction: PopoverDirection.left,
                  transitionDuration: const Duration(milliseconds: 250),
                  bodyBuilder: (context) {
                    return Container(
                      color: CommanColor.whiteLightModePrimary(context),
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      child: Center(
                        child: ListView(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  audioPlayerBottomSheet().then((value) {
                                    if (mounted) {
                                      setState(() {});
                                    }
                                  });
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0, vertical: 5),
                                child: Row(
                                  children: [
                                    Image.asset(
                                      "assets/musical_note.png",
                                      height: 22,
                                      width: 22,
                                      color: CommanColor.darkModePrimaryWhite(
                                          context),
                                    ),
                                    const SizedBox(
                                      width: 17,
                                    ),
                                    Text(
                                      "Audio",
                                      style: CommanStyle.pw14500(context),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            Divider(
                              color: CommanColor.darkModePrimaryWhite(context),
                              thickness: 1.2,
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                textToSpeechBottomSheet();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0, vertical: 5),
                                child: Row(
                                  children: [
                                    Image.asset(
                                      "assets/text_to_speech.png",
                                      height: 26,
                                      width: 26,
                                      color: CommanColor.darkModePrimaryWhite(
                                          context),
                                    ),
                                    const SizedBox(
                                      width: 15,
                                    ),
                                    Text(
                                      "Text to speech",
                                      style: CommanStyle.pw14500(context),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  width: 180,
                  height: 100,
                  arrowDyOffset: -20,
                  barrierColor: Colors.transparent,
                  backgroundColor:
                      Provider.of<ThemeProvider>(context, listen: false)
                                  .themeMode ==
                              ThemeMode.dark
                          ? Colors.white
                          : CommanColor.lightModePrimary,
                  arrowWidth: 24,
                ).then((value) {
                  if (context.mounted) {
                    setState(() {
                      isOpenAudio = false;
                    });
                  }
                });
              }

              await checknetwork();
              // if (hasConnection == false) {
              //   Constants.showToast("Check your Internet Connection");
              // }
            },
          ),
        );
      } else {
        ///
        /// If no internet just show tts
        ///
        ///
        if (isPrevTTSEnabled || isTTSEnabled) {
          return Container(
            height: 35,
            width: 35,
            decoration: BoxDecoration(
              color: CommanColor.whiteLightModePrimary(context),
              shape: BoxShape.circle,
            ),
            child: GestureDetector(
              child: Center(
                  child: isSpeech || isAudioPlaying
                      ? Icon(Icons.pause,
                          size: 24,
                          color: CommanColor.darkModePrimaryWhite(context))
                      : audioLoad == true
                          ? SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color:
                                    CommanColor.darkModePrimaryWhite(context),
                                strokeWidth: 2,
                              ))
                          : Icon(
                              isOpenAudio == false
                                  ? Icons.play_arrow
                                  : Icons.close,
                              color: CommanColor.darkModePrimaryWhite(context),
                              size: isOpenAudio == false ? 28 : 22,
                            )),
              onTap: () async {
                if (isSpeech) {
                  _stop();
                  setState(() {
                    isSpeech = false;
                  });
                } else if (isAudioPlaying) {
                  await audioPlayer.stop();
                  setState(() {
                    isAudioPlaying = false;
                  });
                } else {
                  textToSpeechBottomSheet();
                }
              },
            ),
          );
        }
      }
    } else {
      return Container(
        height: screenWidth > 450 ? 50 : 35,
        width: screenWidth > 450 ? 50 : 35,
        decoration: BoxDecoration(
          color: CommanColor.whiteLightModePrimary(context),
          shape: BoxShape.circle,
        ),
        child: GestureDetector(
          child: Center(
              child: isSpeech || isAudioPlaying
                  ? Icon(Icons.pause,
                      size: screenWidth > 450 ? 44 : 24,
                      color: CommanColor.darkModePrimaryWhite(context))
                  : audioLoad
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: CommanColor.darkModePrimaryWhite(context),
                            strokeWidth: 2,
                          ))
                      : Icon(
                          !isOpenAudio ? Icons.play_arrow : Icons.close,
                          color: CommanColor.darkModePrimaryWhite(context),
                          size: !isOpenAudio
                              ? screenWidth > 450
                                  ? 43
                                  : 28
                              : 22,
                        )),
          onTap: () async {
            Constants.showToast("Check your Internet Connection");
          },
        ),
      );
    }
    return SizedBox();
  }

  bool get supportPause => defaultTargetPlatform != TargetPlatform.android;
  bool get supportResume => defaultTargetPlatform != TargetPlatform.android;
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

  Widget _textFromInput(int start, int end, String text) => text.length < end
      ? const SizedBox.shrink()
      : RichText(
          textAlign: TextAlign.center,
          text: TextSpan(children: <TextSpan>[
            TextSpan(
                text: start != 0 ? text.substring(0, start) : "",
                style: TextStyle(
                    color: CommanColor.lightDarkPrimary(context),
                    letterSpacing: BibleInfo.letterSpacing,
                    fontSize: BibleInfo.fontSizeScale * 16,
                    fontWeight: FontWeight.w500,
                    height: 1.3)),
            TextSpan(
              text: text.substring(start, end),
              style: CommanStyle.HighLightWordStyle(context),
            ),
            TextSpan(
                text: text.substring(end),
                style: TextStyle(
                    color: CommanColor.lightDarkPrimary(context),
                    letterSpacing: BibleInfo.letterSpacing,
                    fontSize: BibleInfo.fontSizeScale * 16,
                    fontWeight: FontWeight.w500,
                    height: 1.3)),
          ]),
        );

  Future audioPlayerBottomSheet() {
    // local flags/subscriptions that persist for the sheet's lifetime
    bool listenersAttached = false;
    StreamSubscription<Duration>? positionSub;
    StreamSubscription<Duration>? durationSub;
    StreamSubscription<void>? completeSub;

    return showModalBottomSheet(
      backgroundColor: Colors.black12,
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          // Attach listeners only once for this sheet
          if (!listenersAttached) {
            listenersAttached = true;

            // Position updates
            positionSub = audioPlayer.onPositionChanged.listen((p) {
              if (!context.mounted) return;
              setState(() {
                position = p;
              });
            });

            // Duration updates (when a new source loads this will fire)
            durationSub = audioPlayer.onDurationChanged.listen((d) {
              if (!context.mounted) return;
              setState(() {
                duration = d;
              });
            });

            // Completion handler: mark position at end, optionally go to next chapter
            completeSub = audioPlayer.onPlayerComplete.listen((_) async {
              if (!context.mounted) return;

              // If not repeating, auto-advance to next chapter (if available)
              // and avoid re-entrant calls using isNext flag.
              if (!repeat && !isNext) {
                final lastChapter = currentBookChapterCount;
                if (audioChapterNum < lastChapter) {
                  setState(() {
                    isNext = true; // prevent duplicate triggers
                    audioChapterNum++;
                    audioBaseUrl =
                        "${widget.audioData?.data?.bibleAudioInfo?.audioBasepath}/$audioBookNum/$audioChapterNum.mp3";
                  });
                  // Update reading screen to match audio chapter - do this before loading audio
                  await updateReadingScreenChapter(audioChapterNum);
                  
                  // Additional delay to ensure UI updates before loading next audio
                  await Future.delayed(const Duration(milliseconds: 100));

                  // load next source, reset position and resume playback
                  bool loadSuccess = false;
                  int retryCount = 0;
                  const maxRetries = 2;
                  
                  while (!loadSuccess && retryCount < maxRetries && context.mounted) {
                    try {
                      await audioPlayer.setSourceUrl(audioBaseUrl);
                      // ensure position and duration will update from streams
                      await audioPlayer.seek(Duration.zero);
                      await audioPlayer.resume();
                      loadSuccess = true;
                      if (context.mounted) {
                        setState(() {
                          isAudioPlaying = true;
                          position = Duration.zero; // Reset position for new chapter
                        });
                      }
                    } catch (e) {
                      retryCount++;
                      debugPrint("Error loading next chapter audio (attempt $retryCount): $e");
                      if (retryCount < maxRetries) {
                        // Wait a bit before retrying
                        await Future.delayed(const Duration(milliseconds: 500));
                      } else {
                        // After max retries, still try to continue but log the error
                        debugPrint("Failed to load next chapter after $maxRetries attempts, but continuing");
                        // Don't stop - let it try to continue
                        if (context.mounted) {
                          setState(() {
                            isAudioPlaying = false;
                            position = Duration.zero;
                          });
                        }
                      }
                    }
                  }
                  
                  // Clear the isNext guard after a delay, regardless of success/failure
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted && context.mounted) {
                      setState(() => isNext = false);
                    }
                  });
                } else {
                  // Last chapter reached - check for next book
                  setState(() {
                    isNext = true; // prevent duplicate triggers
                  });
                  
                  // Get current book number (0-indexed from widget.bookNum)
                  final currentBookNum = int.parse(widget.bookNum.toString());
                  
                  // Try to get the next book
                  final nextBook = await getNextBook(currentBookNum);
                  
                  if (nextBook != null && nextBook.bookNum != null && nextBook.chapterCount != null) {
                    // Next book exists - load first chapter of next book
                    final nextBookNum = nextBook.bookNum!.toInt();
                    final nextBookChapterCount = nextBook.chapterCount!.toInt();
                    final nextBookName = nextBook.title ?? "";
                    
                    // Update audio book and chapter numbers
                    // audioBookNum is 1-indexed for URL (bookNum + 1)
                    setState(() {
                      audioBookNum = nextBookNum + 1;
                      audioChapterNum = 1;
                      currentBookChapterCount = nextBookChapterCount; // Update chapter count for new book
                      audioBaseUrl =
                          "${widget.audioData?.data?.bibleAudioInfo?.audioBasepath}/$audioBookNum/$audioChapterNum.mp3";
                    });
                    
                    // Update reading screen to match next book and first chapter
                    // Pass chapter count so it can be updated in the controller
                    await updateReadingScreenForNextBook(nextBookNum, 1, nextBookName, nextBookChapterCount);
                    
                    // Force a small delay and then refresh controller to ensure UI updates
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (Get.isRegistered<DashBoardController>()) {
                      final controller = Get.find<DashBoardController>();
                      // Trigger update again to ensure UI reflects changes
                      controller.getSelectedChapterAndBook();
                    }
                    
                    // Load next book's first chapter audio
                    bool loadSuccess = false;
                    int retryCount = 0;
                    const maxRetries = 2;
                    
                    while (!loadSuccess && retryCount < maxRetries && context.mounted) {
                      try {
                        await audioPlayer.setSourceUrl(audioBaseUrl);
                        // ensure position and duration will update from streams
                        await audioPlayer.seek(Duration.zero);
                        await audioPlayer.resume();
                        loadSuccess = true;
                        if (context.mounted) {
                          setState(() {
                            isAudioPlaying = true;
                            position = Duration.zero; // Reset position for new book
                          });
                        }
                      } catch (e) {
                        retryCount++;
                        debugPrint("Error loading next book audio (attempt $retryCount): $e");
                        if (retryCount < maxRetries) {
                          // Wait a bit before retrying
                          await Future.delayed(const Duration(milliseconds: 500));
                        } else {
                          // After max retries, stop audio
                          debugPrint("Failed to load next book after $maxRetries attempts");
                          if (context.mounted) {
                            setState(() {
                              isAudioPlaying = false;
                              position = Duration.zero;
                            });
                          }
                        }
                      }
                    }
                    
                    // Clear the isNext guard after a delay
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted && context.mounted) {
                        setState(() => isNext = false);
                      }
                    });
                  } else {
                    // No next book - stop audio and reset
                    try {
                      await audioPlayer.stop();
                      if (context.mounted) {
                        setState(() {
                          position = Duration.zero; // Reset position to zero
                          isAudioPlaying = false;
                          isNext = false; // Reset flag
                        });
                      }
                    } catch (e) {
                      // handle errors
                      if (context.mounted) {
                        setState(() {
                          position = Duration.zero;
                          isAudioPlaying = false;
                          isNext = false; // Reset flag
                        });
                      }
                    }
                  }
                }
              } else if (repeat) {
                // Repeat mode - restart current chapter
                try {
                  await audioPlayer.setSourceUrl(audioBaseUrl);
                  // ensure position and duration will update from streams
                  await audioPlayer.seek(Duration.zero);
                  await audioPlayer.resume();
                  if (context.mounted) {
                    setState(() {
                      isAudioPlaying = true;
                      position = Duration.zero; // Reset position when repeating
                    });
                  }
                } catch (e) {
                  // handle errors
                  if (context.mounted) {
                    setState(() {
                      position = Duration.zero;
                      isAudioPlaying = false;
                    });
                  }
                }
              } else {
                // Should not reach here, but ensure audio stops if it does
                try {
                  await audioPlayer.stop();
                  if (context.mounted) {
                    setState(() {
                      position = Duration.zero;
                      isAudioPlaying = false;
                    });
                  }
                } catch (e) {
                  // handle errors
                }
              }
            });
          } // end attach listeners

          // Build UI
          return Container(
            height: 130,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              color: Colors.white,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 60),
                    Text(
                      "${widget.bookName} - $audioChapterNum",
                      style: TextStyle(
                          color: CommanColor.lightDarkPrimary(context),
                          letterSpacing: BibleInfo.letterSpacing,
                          fontSize: BibleInfo.fontSizeScale * 14,
                          fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        InkWell(
                          onTap: () async {
                            setState(() => isAudioPlaying = false);
                            await audioPlayer.stop();
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: Icon(
                            Icons.close,
                            color: CommanColor.lightDarkPrimary(context),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Timeline row
                Row(
                  children: [
                    Text(
                      formatTime(position),
                      style: TextStyle(
                          color: CommanColor.lightDarkPrimary(context),
                          letterSpacing: BibleInfo.letterSpacing,
                          fontSize: BibleInfo.fontSizeScale * 10,
                          fontWeight: FontWeight.w400),
                    ),
                    Flexible(
                      child: Container(
                        height: 20,
                        margin: const EdgeInsets.only(left: 5, right: 3),
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4.0,
                            thumbColor: CommanColor.lightDarkPrimary(context),
                            overlayShape: SliderComponentShape.noOverlay,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            min: 0,
                            max: (duration.inSeconds > 0)
                                ? duration.inSeconds.toDouble()
                                : 1.0,
                            // clamp value to avoid errors when duration is shorter
                            value: position.inSeconds
                                .clamp(0, duration.inSeconds)
                                .toDouble(),
                            activeColor: CommanColor.lightDarkPrimary(context),
                            inactiveColor: CommanColor.lightGrey,
                            onChanged: (newValue) async {
                              final newPos =
                                  Duration(seconds: newValue.toInt());
                              await audioPlayer.seek(newPos);
                              // optionally resume if you'd like
                              await audioPlayer.resume();
                              if (mounted) setState(() {});
                            },
                          ),
                        ),
                      ),
                    ),
                    Text(formatTime(duration),
                        style: TextStyle(
                            color: CommanColor.lightDarkPrimary(context),
                            letterSpacing: BibleInfo.letterSpacing,
                            fontSize: BibleInfo.fontSizeScale * 10,
                            fontWeight: FontWeight.w400)),
                  ],
                ),

                // Controls row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Repeat
                    Padding(
                      padding: const EdgeInsets.only(left: 5.0),
                      child: InkWell(
                        onTap: () {
                          setState(() => repeat = !repeat);
                          audioPlayer.setReleaseMode(
                              repeat ? ReleaseMode.loop : ReleaseMode.release);
                        },
                        child: Stack(children: [
                          Image.asset(
                            "assets/repeat.png",
                            color: CommanColor.lightDarkPrimary(context),
                            height: 20,
                            width: 20,
                          ),
                          if (repeat)
                            Positioned.fill(
                                child: Center(
                                    child: Text(
                              "1",
                              style: TextStyle(
                                  letterSpacing: BibleInfo.letterSpacing,
                                  fontSize: BibleInfo.fontSizeScale * 10,
                                  fontWeight: FontWeight.w600,
                                  color: CommanColor.lightDarkPrimary(context)),
                              textAlign: TextAlign.center,
                            )))
                        ]),
                      ),
                    ),

                    // prev chapter
                    IconButton(
                      icon: Image.asset(
                        "assets/chapt_back.png",
                        color: CommanColor.lightDarkPrimary(context),
                        height: 20,
                        width: 20,
                      ),
                      onPressed: () async {
                        if (audioChapterNum > 1) {
                          setState(() {
                            audioChapterNum--;
                            audioBaseUrl =
                                "${widget.audioData?.data?.bibleAudioInfo?.audioBasepath}/$audioBookNum/$audioChapterNum.mp3";
                            isAudioPlaying = false;
                          });
                          // Update reading screen to match audio chapter
                          await updateReadingScreenChapter(audioChapterNum);
                          try {
                            await audioPlayer.setSourceUrl(audioBaseUrl);
                            await audioPlayer.seek(Duration.zero);
                            await audioPlayer.resume();
                            if (context.mounted) {
                              setState(() => isAudioPlaying = true);
                            }
                          } catch (e) {
                            // handle load errors
                          }
                        } else {
                          // at first chapter: maybe rewind to start
                          await audioPlayer.seek(Duration.zero);
                          await audioPlayer.resume();
                          if (context.mounted) {
                            setState(() => isAudioPlaying = true);
                          }
                        }
                      },
                    ),

                    // rewind 10s
                    IconButton(
                      icon: Image.asset(
                        "assets/previous_music.png",
                        color: CommanColor.lightDarkPrimary(context),
                        height: 20,
                        width: 20,
                      ),
                      onPressed: () async {
                        final current = position;
                        final newPos = current.inSeconds >= 10
                            ? current - const Duration(seconds: 10)
                            : Duration.zero;
                        await audioPlayer.seek(newPos);
                        await audioPlayer.resume();
                        if (mounted && context.mounted) setState(() {});
                      },
                    ),

                    // Play / Pause
                    InkWell(
                      onTap: () async {
                        if (isAudioPlaying) {
                          await audioPlayer.pause();
                          if (context.mounted) {
                            setState(() => isAudioPlaying = false);
                          }
                        } else {
                          await audioPlayer.resume();
                          if (context.mounted) {
                            setState(() => isAudioPlaying = true);
                          }
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: CommanColor.lightDarkPrimary(context)),
                        padding: const EdgeInsets.all(7),
                        child: Image.asset(
                          isAudioPlaying
                              ? "assets/pause.png"
                              : "assets/play.png",
                          color: Colors.white,
                          height: 15,
                          width: 15,
                        ),
                      ),
                    ),

                    // forward 10s
                    IconButton(
                      icon: Image.asset(
                        "assets/next_music.png",
                        color: CommanColor.lightDarkPrimary(context),
                        height: 20,
                        width: 20,
                      ),
                      onPressed: () async {
                        final current = position;
                        final newPos = (duration - current).inSeconds >= 10
                            ? current + const Duration(seconds: 10)
                            : duration;
                        await audioPlayer.seek(newPos);
                        await audioPlayer.resume();
                        if (mounted && context.mounted) setState(() {});
                      },
                    ),

                    // next chapter
                    IconButton(
                      icon: Image.asset(
                        "assets/chapt_next.png",
                        color: CommanColor.lightDarkPrimary(context),
                        height: 20,
                        width: 20,
                      ),
                      onPressed: () async {
                        final lastChapter = int.parse(widget.chapterCount);
                        if (widget.internetConnection?.first ==
                                ConnectivityResult.wifi ||
                            widget.internetConnection?.first ==
                                ConnectivityResult.mobile) {
                          if (audioChapterNum < lastChapter) {
                            setState(() {
                              isAudioPlaying = false;
                              audioChapterNum++;
                              audioBaseUrl =
                                  "${widget.audioData?.data?.bibleAudioInfo?.audioBasepath}/$audioBookNum/$audioChapterNum.mp3";
                            });
                            // Update reading screen to match audio chapter
                            await updateReadingScreenChapter(audioChapterNum);
                            try {
                              await audioPlayer.setSourceUrl(audioBaseUrl);
                              await audioPlayer.seek(Duration.zero);
                              await audioPlayer.resume();
                              if (context.mounted) {
                                setState(() => isAudioPlaying = true);
                              }
                            } catch (e) {
                              // handle load errors
                            }
                          } else {
                            // already at last chapter - optional feedback
                            Constants.showToast("Already at last chapter");
                          }
                        } else {
                          Constants.showToast("No Internet Connection");
                        }
                      },
                    ),

                    // stop
                    Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: InkWell(
                        onTap: () async {
                          await audioPlayer.stop();
                          if (context.mounted) {
                            setState(() => isAudioPlaying = false);
                          }
                        },
                        child: Image.asset(
                          "assets/stop.png",
                          color: CommanColor.lightDarkPrimary(context),
                          height: 18,
                          width: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
      },
    ).then((value) {
      // sheet closed: cancel listeners & refresh parent UI if needed
      if (positionSub != null) {
        positionSub!.cancel();
        positionSub = null;
      }
      if (durationSub != null) {
        durationSub!.cancel();
        durationSub = null;
      }
      if (completeSub != null) {
        completeSub!.cancel();
        completeSub = null;
      }
      if (mounted) {
        setState(() {}); // update parent if needed
      }
    });
  }

  // Future audioPlayerBottomSheet() {
  //   return showModalBottomSheet(
  //     backgroundColor: Colors.black12,
  //     context: context,
  //     builder: (context) {
  //       return StatefulBuilder(
  //         builder: (context, setState) {
  //           audioPlayer.onPositionChanged.listen((event) {
  //             if (context.mounted) {
  //               setState(() {
  //                 position = event;
  //               });
  //             }
  //             audioPlayer.getDuration().then((value) async {
  //               if (event.inSeconds == value?.inSeconds &&
  //                   repeat == false &&
  //                   isNext == false) {
  //                 if (context.mounted) {
  //                   setState(() {
  //                     isNext = true;
  //                     //audioChapterNum++;
  //                     audioChapterNum == int.parse(widget.chapterCount)
  //                         ? audioChapterNum = int.parse(widget.chapterCount)
  //                         : audioChapterNum++;
  //                     audioBaseUrl =
  //                         "${widget.audioData?.data?.bibleAudioInfo?.audioBasepath.toString()}/$audioBookNum/$audioChapterNum.mp3";
  //                   });
  //                 }
  //                 await audioPlayer.setSourceUrl(audioBaseUrl);
  //                 isAudioPlaying = true;
  //               }
  //             });

  //             Future.delayed(
  //               const Duration(seconds: 2),
  //               () {
  //                 if (context.mounted) {
  //                   setState(() {
  //                     isNext = false;
  //                   });
  //                 }
  //               },
  //             );
  //           });
  //           return Container(
  //               height: 130,
  //               decoration: const BoxDecoration(
  //                   borderRadius: BorderRadius.only(
  //                       topLeft: Radius.circular(20),
  //                       topRight: Radius.circular(20)),
  //                   color: Colors.white),
  //               padding: const EdgeInsets.symmetric(horizontal: 10),
  //               child: Column(
  //                 children: [
  //                   const SizedBox(height: 15),
  //                   Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     children: [
  //                       const SizedBox(
  //                         width: 60,
  //                       ),
  //                       Text(
  //                         "${widget.bookName} - $audioChapterNum",
  //                         style: TextStyle(
  //                             color: CommanColor.lightDarkPrimary(context),
  //                             letterSpacing: BibleInfo.letterSpacing,
  //                             fontSize: BibleInfo.fontSizeScale * 14,
  //                             fontWeight: FontWeight.w600),
  //                       ),
  //                       Row(
  //                         children: [
  //                           InkWell(
  //                               onTap: () async {
  //                                 setState(() {
  //                                   isAudioPlaying = false;
  //                                 });
  //                                 await audioPlayer.stop();
  //                                 if (context.mounted) {
  //                                   Navigator.pop(context);
  //                                 }
  //                               },
  //                               child: Icon(
  //                                 Icons.close,
  //                                 color: CommanColor.lightDarkPrimary(context),
  //                                 size: 20,
  //                               )),
  //                           const SizedBox(
  //                             width: 10,
  //                           ),
  //                         ],
  //                       ),
  //                     ],
  //                   ),
  //                   const SizedBox(height: 20),
  //                   Row(
  //                     children: [
  //                       Text(
  //                         formatTime(position),
  //                         style: TextStyle(
  //                             color: CommanColor.lightDarkPrimary(context),
  //                             letterSpacing: BibleInfo.letterSpacing,
  //                             fontSize: BibleInfo.fontSizeScale * 10,
  //                             fontWeight: FontWeight.w400),
  //                       ),
  //                       Flexible(
  //                         child: Container(
  //                           height: 20,
  //                           margin: const EdgeInsets.only(left: 5, right: 3),
  //                           child: SliderTheme(
  //                             data: SliderThemeData(
  //                               trackHeight: 4.0,
  //                               thumbColor:
  //                                   CommanColor.lightDarkPrimary(context),
  //                               overlayShape: SliderComponentShape.noOverlay,
  //                               thumbShape: const RoundSliderThumbShape(
  //                                   enabledThumbRadius: 6),
  //                             ),
  //                             child: Slider(
  //                               min: 0,
  //                               max: duration.inSeconds.toDouble(),
  //                               value: position.inSeconds.toDouble(),
  //                               activeColor:
  //                                   CommanColor.lightDarkPrimary(context),
  //                               inactiveColor: CommanColor.lightGrey,
  //                               thumbColor:
  //                                   CommanColor.lightDarkPrimary(context),
  //                               onChanged: (newValue) async {
  //                                 final position =
  //                                     Duration(seconds: newValue.toInt());
  //                                 await audioPlayer.seek(position);

  //                                 ///Optional:Play audio if was paused
  //                                 await audioPlayer.resume();
  //                                 setState(() {});
  //                               },

  //                               // divisions: 15,
  //                             ),
  //                           ),
  //                         ),
  //                       ),
  //                       Text(formatTime(duration),
  //                           style: TextStyle(
  //                               color: CommanColor.lightDarkPrimary(context),
  //                               letterSpacing: BibleInfo.letterSpacing,
  //                               fontSize: BibleInfo.fontSizeScale * 10,
  //                               fontWeight: FontWeight.w400)),
  //                     ],
  //                   ),

  //                   Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     children: [
  //                       Padding(
  //                         padding: const EdgeInsets.only(left: 5.0),
  //                         child: InkWell(
  //                             onTap: () {
  //                               setState(() {
  //                                 repeat = !repeat;
  //                               });
  //                               if (repeat == true) {
  //                                 audioPlayer.setReleaseMode(ReleaseMode.loop);
  //                               } else {}
  //                             },
  //                             child: Stack(children: [
  //                               Image.asset(
  //                                 "assets/repeat.png",
  //                                 color: CommanColor.lightDarkPrimary(context),
  //                                 height: 20,
  //                                 width: 20,
  //                               ),
  //                               repeat == true
  //                                   ? Positioned(
  //                                       left: 0,
  //                                       right: 0,
  //                                       top: 0,
  //                                       bottom: 0,
  //                                       child: Center(
  //                                           child: Text(
  //                                         "1",
  //                                         style: TextStyle(
  //                                             letterSpacing:
  //                                                 BibleInfo.letterSpacing,
  //                                             fontSize:
  //                                                 BibleInfo.fontSizeScale * 10,
  //                                             fontWeight: FontWeight.w600,
  //                                             color:
  //                                                 CommanColor.lightDarkPrimary(
  //                                                     context)),
  //                                         textAlign: TextAlign.center,
  //                                       )))
  //                                   : const SizedBox()
  //                             ])),
  //                       ),
  //                       IconButton(
  //                           icon: Image.asset(
  //                             "assets/chapt_back.png",
  //                             color: CommanColor.lightDarkPrimary(context),
  //                             height: 20,
  //                             width: 20,
  //                           ),
  //                           onPressed: () async {
  //                             setState(() {
  //                               audioChapterNum > 1
  //                                   ? audioChapterNum--
  //                                   : audioChapterNum = 1;
  //                               audioBaseUrl =
  //                                   "${widget.audioData?.data?.bibleAudioInfo?.audioBasepath.toString()}/$audioBookNum/$audioChapterNum.mp3";
  //                             });
  //                             await audioPlayer.setSourceUrl(audioBaseUrl);
  //                           }),
  //                       IconButton(
  //                         icon: Image.asset(
  //                           "assets/previous_music.png",
  //                           color: CommanColor.lightDarkPrimary(context),
  //                           height: 20,
  //                           width: 20,
  //                         ),
  //                         onPressed: () async {
  //                           setState(() {
  //                             position.inSeconds >= 10
  //                                 ? position =
  //                                     position - const Duration(seconds: 10)
  //                                 : position = Duration.zero;
  //                           });
  //                           await audioPlayer.seek(position);

  //                           ///Optional:Play audio if was paused
  //                           await audioPlayer.resume();
  //                           setState(() {});
  //                         },
  //                       ),
  //                       InkWell(
  //                           onTap: () async {
  //                             if (isAudioPlaying) {
  //                               await audioPlayer.pause();
  //                             } else {
  //                               await audioPlayer.resume();
  //                             }
  //                             setState(() {});
  //                           },
  //                           child: Container(
  //                               decoration: BoxDecoration(
  //                                   shape: BoxShape.circle,
  //                                   color:
  //                                       CommanColor.lightDarkPrimary(context)),
  //                               padding: const EdgeInsets.all(7),
  //                               child: Image.asset(
  //                                 isAudioPlaying
  //                                     ? "assets/pause.png"
  //                                     : "assets/play.png",
  //                                 color: Colors.white,
  //                                 height: 15,
  //                                 width: 15,
  //                               ))),
  //                       IconButton(
  //                         icon: Image.asset(
  //                           "assets/next_music.png",
  //                           color: CommanColor.lightDarkPrimary(context),
  //                           height: 20,
  //                           width: 20,
  //                         ),
  //                         onPressed: () async {
  //                           setState(() {
  //                             duration.inSeconds - position.inSeconds >= 10
  //                                 ? position =
  //                                     position + const Duration(seconds: 10)
  //                                 : position = duration;
  //                           });
  //                           await audioPlayer.seek(position);

  //                           ///Optional:Play audio if was paused
  //                           await audioPlayer.resume();
  //                           setState(() {});
  //                         },
  //                       ),
  //                       IconButton(
  //                           icon: Image.asset(
  //                             "assets/chapt_next.png",
  //                             color: CommanColor.lightDarkPrimary(context),
  //                             height: 20,
  //                             width: 20,
  //                           ),
  //                           onPressed: () async {
  //                             if (widget.internetConnection?.first ==
  //                                     ConnectivityResult.wifi ||
  //                                 widget.internetConnection?.first ==
  //                                     ConnectivityResult.mobile) {
  //                               setState(() {
  //                                 isAudioPlaying = false;
  //                                 audioChapterNum !=
  //                                         int.parse(widget.chapterCount)
  //                                     ? audioChapterNum++
  //                                     : audioChapterNum =₹
  
  //                                         int.parse(widget.chapterCount);
  //                                 audioBaseUrl =
  //                                     "${widget.audioData?.data?.bibleAudioInfo?.audioBasepath.toString()}/$audioBookNum/$audioChapterNum.mp3";
  //                                 audioPlayer
  //                                     .setSourceUrl(audioBaseUrl)
  //                                     .then((_) {
  //                                   isAudioPlaying = true;
  //                                 });
  //                               });
  //                             } else {
  //                               Constants.showToast("No Internet Connection");
  //                             }
  //                           }),
  //                       Padding(
  //                         padding: const EdgeInsets.only(right: 10.0),
  //                         child: InkWell(
  //                           onTap: () async {
  //                             await audioPlayer.stop();
  //                           },
  //                           child: Image.asset(
  //                             "assets/stop.png",
  //                             color: CommanColor.lightDarkPrimary(context),
  //                             height: 18,
  //                             width: 18,
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                   // PlayerButtons(_audioPlayer, progressBar:1),
  //                 ],
  //               ));
  //         },
  //       );
  //     },
  //   ).then((value) {
  //     if (context.mounted) {
  //       setState(() {});
  //     }
  //   });
  // }

  // Combined voice selection and settings screen
  Future<void> _showCombinedVoiceSettingsSheet() async {
    // Get voices if available
    if (availableVoices == null && (isAndroid || isIOS)) {
      availableVoices = await _getVoices();
      if (availableVoices != null && availableVoices!.isNotEmpty && selectedVoice == null) {
        selectedVoice = availableVoices!.first;
      }
    }
    
    return showModalBottomSheet(
      backgroundColor: Colors.black12,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                color: Colors.white,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Header with Close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      Text(
                        "Voice Settings",
                        style: TextStyle(
                          color: CommanColor.lightDarkPrimary(context),
                          letterSpacing: BibleInfo.letterSpacing,
                          fontSize: BibleInfo.fontSizeScale * 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Icon(
                          Icons.close,
                          color: CommanColor.lightDarkPrimary(context),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  
                  // Voice Selection
                  Text(
                    "Voice",
                    style: TextStyle(
                      color: CommanColor.lightDarkPrimary(context),
                      letterSpacing: BibleInfo.letterSpacing,
                      fontSize: BibleInfo.fontSizeScale * 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Voice Dropdown
                  FutureBuilder<List<dynamic>>(
                    future: _getVoices(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        // Remove duplicates based on identifier (primary) or name+locale combination
                        List<dynamic> uniqueVoices = [];
                        Set<String> seenKeys = {}; // Use a single set for all unique keys
                        
                        for (var voice in snapshot.data!) {
                          if (voice is Map) {
                            String? identifier = voice['identifier']?.toString();
                            String? name = voice['name']?.toString();
                            String? locale = voice['locale']?.toString();
                            
                            // Create a unique key: prefer identifier, fallback to name+locale combination
                            String uniqueKey;
                            if (identifier != null && identifier.isNotEmpty) {
                              uniqueKey = identifier;
                            } else if (name != null && locale != null) {
                              uniqueKey = '$name|$locale';
                            } else if (name != null) {
                              uniqueKey = name;
                            } else if (locale != null) {
                              uniqueKey = locale;
                            } else {
                              // If no identifier, name, or locale, use string representation
                              uniqueKey = voice.toString();
                            }
                            
                            // Only add if we haven't seen this unique key before
                            if (!seenKeys.contains(uniqueKey)) {
                              seenKeys.add(uniqueKey);
                              uniqueVoices.add(voice);
                            }
                          } else {
                            // For non-Map voices, check by string representation
                            String voiceStr = voice.toString();
                            if (!seenKeys.contains(voiceStr)) {
                              seenKeys.add(voiceStr);
                              uniqueVoices.add(voice);
                            }
                          }
                        }
                        
                        // If no unique voices found, use original list
                        if (uniqueVoices.isEmpty) {
                          uniqueVoices = snapshot.data!;
                        }
                        
                        // Find matching selectedVoice by identifier
                        dynamic matchedSelectedVoice;
                        if (selectedVoice != null && selectedVoice is Map && uniqueVoices.isNotEmpty) {
                          String? selectedIdentifier = selectedVoice['identifier']?.toString();
                          if (selectedIdentifier != null) {
                            try {
                              matchedSelectedVoice = uniqueVoices.firstWhere(
                                (voice) {
                                  if (voice is Map) {
                                    return voice['identifier']?.toString() == selectedIdentifier;
                                  }
                                  return false;
                                },
                              );
                            } catch (e) {
                              // No match found, use first voice
                              matchedSelectedVoice = uniqueVoices.first;
                            }
                          } else {
                            matchedSelectedVoice = uniqueVoices.first;
                          }
                        } else if (uniqueVoices.isNotEmpty) {
                          // If no selectedVoice or it's not a Map, use first voice
                          matchedSelectedVoice = uniqueVoices.first;
                        }
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: CommanColor.lightGrey,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<dynamic>(
                            isDense: true,
                            value: matchedSelectedVoice,
                            isExpanded: true,
                            underline: const SizedBox(),
                            dropdownColor: Colors.white,
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: CommanColor.lightDarkPrimary(context),
                            ),
                            items: uniqueVoices.map((voice) {
                              String displayName = _getVoiceDisplayName(voice);
                              bool isDefault = voice == uniqueVoices.first;
                              return DropdownMenuItem<dynamic>(
                                value: voice,
                                child: Text(
                                  isDefault ? "$displayName (Default)" : displayName,
                                  style: TextStyle(
                                    color: Colors.black,
                                    letterSpacing: BibleInfo.letterSpacing,
                                    fontSize: BibleInfo.fontSizeScale * 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (dynamic newValue) {
                              setModalState(() {
                                selectedVoice = newValue;
                              });
                              if (newValue != null && (isAndroid || isIOS)) {
                                // Convert Map<Object?, Object?> to Map<String, String> if needed
                                if (newValue is Map) {
                                  Map<String, String> voiceMap = {};
                                  newValue.forEach((key, value) {
                                    voiceMap[key.toString()] = value.toString();
                                  });
                                  flutterTts.setVoice(voiceMap);
                                } else {
                                  flutterTts.setVoice(newValue);
                                }
                              }
                              setState(() {});
                            },
                            selectedItemBuilder: (BuildContext context) {
                              return uniqueVoices.map<Widget>((voice) {
                                String displayName = _getVoiceDisplayName(voice);
                                bool isDefault = voice == uniqueVoices.first;
                                return Text(
                                  isDefault ? "$displayName (Default)" : displayName,
                                  style: TextStyle(
                                    color: CommanColor.lightDarkPrimary(context),
                                    letterSpacing: BibleInfo.letterSpacing,
                                    fontSize: BibleInfo.fontSizeScale * 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        );
                      } else {
                        // Fallback to language selection if voices not available
                        return FutureBuilder<dynamic>(
                          future: _getLanguages(),
                          builder: (context, langSnapshot) {
                            if (langSnapshot.hasData) {
                              List langList = [];
                              for (var i = 0; i < langSnapshot.data.length; i++) {
                                if (langSnapshot.data[i].toString().split("-").first == "en") {
                                  langList.add(langSnapshot.data[i]);
                                }
                              }
                              if (langList.isNotEmpty && language == null) {
                                language = langList[0];
                              }
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: CommanColor.lightGrey,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButton<String>(
                                  isDense: true,
                                  value: language,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  icon: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: CommanColor.lightDarkPrimary(context),
                                  ),
                                  items: langList.map((lang) {
                                    var languageConvert = LanguageLocal().getDisplayLanguage(
                                      lang.toString().split("-").first
                                    );
                                    String displayName = languageConvert["name"] ?? lang.toString();
                                    bool isDefault = lang == langList[0];
                                    return DropdownMenuItem<String>(
                                      value: lang.toString(),
                                      child: Text(
                                        isDefault ? "$displayName (Default)" : displayName,
                                        style: TextStyle(
                                          color: CommanColor.lightDarkPrimary(context),
                                          letterSpacing: BibleInfo.letterSpacing,
                                          fontSize: BibleInfo.fontSizeScale * 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setModalState(() {
                                      language = newValue;
                                      flutterTts.setLanguage(language ?? '');
                                    });
                                    setState(() {});
                                  },
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Preview Voice Button
                  InkWell(
                    onTap: () async {
                      await _previewVoice();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: CommanColor.lightDarkPrimary(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Preview Voice",
                            style: TextStyle(
                              color: Colors.white,
                              letterSpacing: BibleInfo.letterSpacing,
                              fontSize: BibleInfo.fontSizeScale * 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Pitch Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            "assets/lightMode/icons/Pitch.png",
                            height: 22,
                            width: 22,
                            color: CommanColor.lightDarkPrimary(context),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Pitch",
                            style: TextStyle(
                              color: CommanColor.lightDarkPrimary(context),
                              letterSpacing: BibleInfo.letterSpacing,
                              fontSize: BibleInfo.fontSizeScale * 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        pitch == 1.25 ? "Natural" : pitch.toStringAsFixed(1),
                        style: TextStyle(
                          color: CommanColor.lightDarkPrimary(context),
                          letterSpacing: BibleInfo.letterSpacing,
                          fontSize: BibleInfo.fontSizeScale * 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      thumbColor: CommanColor.lightDarkPrimary(context),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    ),
                    child: Slider(
                      activeColor: CommanColor.lightDarkPrimary(context),
                      inactiveColor: CommanColor.lightGrey,
                      thumbColor: CommanColor.lightDarkPrimary(context),
                      value: pitch,
                      onChanged: (newPitch) {
                        setModalState(() {
                          pitch = newPitch;
                          flutterTts.setPitch(newPitch);
                        });
                        setState(() {});
                      },
                      min: 0.5,
                      max: 2.0,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Speed Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            "assets/lightMode/icons/speed.png",
                            height: 22,
                            width: 22,
                            color: CommanColor.lightDarkPrimary(context),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Speed",
                            style: TextStyle(
                              color: CommanColor.lightDarkPrimary(context),
                              letterSpacing: BibleInfo.letterSpacing,
                              fontSize: BibleInfo.fontSizeScale * 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "${rate.toStringAsFixed(1)}x",
                        style: TextStyle(
                          color: CommanColor.lightDarkPrimary(context),
                          letterSpacing: BibleInfo.letterSpacing,
                          fontSize: BibleInfo.fontSizeScale * 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      thumbColor: CommanColor.lightDarkPrimary(context),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    ),
                    child: Slider(
                      activeColor: CommanColor.lightDarkPrimary(context),
                      inactiveColor: CommanColor.lightGrey,
                      thumbColor: CommanColor.lightDarkPrimary(context),
                      value: rate,
                      onChanged: (newRate) {
                        setModalState(() {
                          rate = newRate;
                          flutterTts.setSpeechRate(newRate);
                        });
                        setState(() {});
                      },
                      min: 0.0,
                      max: 1.0,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Volume Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            "assets/lightMode/icons/volume.png",
                            height: 22,
                            width: 22,
                            color: CommanColor.lightDarkPrimary(context),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Volume",
                            style: TextStyle(
                              color: CommanColor.lightDarkPrimary(context),
                              letterSpacing: BibleInfo.letterSpacing,
                              fontSize: BibleInfo.fontSizeScale * 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      thumbColor: CommanColor.lightDarkPrimary(context),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    ),
                    child: Slider(
                      activeColor: CommanColor.lightDarkPrimary(context),
                      inactiveColor: CommanColor.lightGrey,
                      thumbColor: CommanColor.lightDarkPrimary(context),
                      value: volume,
                      onChanged: (newVolume) {
                        setModalState(() {
                          volume = newVolume;
                          flutterTts.setVolume(newVolume);
                        });
                        setState(() {});
                      },
                      min: 0.0,
                      max: 1.0,
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Reset to Default Button at bottom
                  InkWell(
                    onTap: () {
                      changeRotation();
                      setModalState(() {
                        volume = 0.5;
                        pitch = 1.25;
                        rate = 0.5;
                        flutterTts.setVolume(volume);
                        flutterTts.setSpeechRate(rate);
                        flutterTts.setPitch(pitch);
                      });
                      setState(() {});
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: CommanColor.lightDarkPrimary(context),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedRotation(
                            turns: turns,
                            duration: const Duration(seconds: 1),
                            child: Icon(
                              Icons.refresh,
                              color: CommanColor.lightDarkPrimary(context),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Reset to Default",
                            style: TextStyle(
                              color: CommanColor.lightDarkPrimary(context),
                              letterSpacing: BibleInfo.letterSpacing,
                              fontSize: BibleInfo.fontSizeScale * 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future textToSpeechBottomSheet() {
    if (widget.textToSpeechLoad == false) {
      return showModalBottomSheet(
        backgroundColor: Colors.black12,
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              flutterTts.setProgressHandler(
                  (String text, int startOffset, int endOffset, String word) {
                Future.delayed(
                  Duration.zero,
                  () {
                    if (mounted && context.mounted) {
                      setState(() {
                        allText = text;
                        start = startOffset;
                        end = endOffset;
                      });
                    }
                  },
                );
              });
              return Container(
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20)),
                      color: Colors.white),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(
                            width: 80,
                          ),
                          Text(
                            "${widget.bookName} $selectedChapter - ${curretNo + 1}/${selectedChapterContent.length}",
                            style: TextStyle(
                                color: CommanColor.lightDarkPrimary(context),
                                letterSpacing: BibleInfo.letterSpacing,
                                fontSize: BibleInfo.fontSizeScale * 14,
                                fontWeight: FontWeight.w600),
                          ),
                          Row(
                            children: [
                              InkWell(
                                  onTap: () {
                                    _showCombinedVoiceSettingsSheet();
                                  },
                                  child: Icon(
                                    Icons.settings,
                                    color:
                                        CommanColor.lightDarkPrimary(context),
                                  )),
                              const SizedBox(
                                width: 10,
                              ),
                              InkWell(
                                  onTap: () {
                                    _stop();
                                    setState(() {
                                      isSpeech = false;
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: Icon(
                                    Icons.close,
                                    color:
                                        CommanColor.lightDarkPrimary(context),
                                  )),
                              const SizedBox(
                                width: 10,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                          width: MediaQuery.of(context).size.width * 0.86,
                          child: ttsState == TtsState.playing
                              ? _textFromInput(start, end, allText)
                              : Text(
                                  selectedChapterContent.length > curretNo
                                      ? parse(selectedChapterContent[curretNo]
                                                  .content)
                                              .body
                                              ?.text ??
                                          ''
                                      : 'Loading...',
                                  style: TextStyle(
                                      color:
                                          CommanColor.lightDarkPrimary(context),
                                      letterSpacing: BibleInfo.letterSpacing,
                                      fontSize: BibleInfo.fontSizeScale * 16,
                                      fontWeight: FontWeight.w500,
                                      height: 1.3),
                                  textAlign: TextAlign.center,
                                )),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                              onTap: () {
                                setState(() {
                                  isTTSLoop = !isTTSLoop;
                                });
                              },
                              child: Stack(children: [
                                Image.asset(
                                  "assets/repeat.png",
                                  color: CommanColor.lightDarkPrimary(context),
                                  height: 20,
                                  width: 20,
                                ),
                                isTTSLoop == true
                                    ? Positioned(
                                        left: 0,
                                        right: 0,
                                        top: 0,
                                        bottom: 0,
                                        child: Center(
                                            child: Text(
                                          "1",
                                          style: TextStyle(
                                              letterSpacing:
                                                  BibleInfo.letterSpacing,
                                              fontSize:
                                                  BibleInfo.fontSizeScale * 10,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  CommanColor.lightDarkPrimary(
                                                      context)),
                                          textAlign: TextAlign.center,
                                        )))
                                    : const SizedBox()
                              ])),
                          IconButton(
                              icon: Image.asset(
                                "assets/chapt_back.png",
                                color: CommanColor.lightDarkPrimary(context),
                                height: 20,
                                width: 20,
                              ),
                              onPressed: () async {
                                if (!mounted) return;
                                // Only allow going to previous chapter if not at chapter 1
                                if (selectedChapter > 1) {
                                  await _stop();
                                  // Clear old voice text to prevent speaking old verse
                                  _newVoiceText = null;
                                  if (mounted) {
                                    setState(() {
                                      selectedChapter--;
                                      curretNo = 0;
                                      isManualNavigation = true; // Mark as manual navigation to prevent double increment
                                      shouldAutoAdvance = true; // Re-enable auto-advance after manual navigation
                                    });
                                    // Wait for setState to complete
                                    await Future.delayed(const Duration(milliseconds: 50));
                                    // Load chapter content and wait for it to complete
                                    await setChapterContent();
                                    if (mounted && selectedChapterContent.isNotEmpty && curretNo >= 0 && curretNo < selectedChapterContent.length) {
                                      setState(() {
                                        _newVoiceText = selectedChapterContent[curretNo].content;
                                      });
                                      // Wait for UI to update before speaking
                                      await Future.delayed(const Duration(milliseconds: 50));
                                      if (mounted && isSpeech && _newVoiceText != null && _newVoiceText!.isNotEmpty) {
                                        _speak();
                                      }
                                    }
                                  }
                                }
                                // If at chapter 1, do nothing (already at first chapter)
                              }),
                          IconButton(
                            icon: Image.asset(
                              "assets/previous_music.png",
                              color: CommanColor.lightDarkPrimary(context),
                              height: 20,
                              width: 20,
                            ),
                            onPressed: () async {
                              if (!mounted) return;
                              await _stop();
                              if (curretNo > 0 && selectedChapterContent.isNotEmpty) {
                                // Go to previous verse in current chapter
                                if (mounted) {
                                  setState(() {
                                    curretNo = curretNo - 1;
                                    if (curretNo >= 0 && curretNo < selectedChapterContent.length) {
                                      _newVoiceText =
                                          selectedChapterContent[curretNo].content;
                                    }
                                    isManualNavigation = true; // Mark as manual navigation to prevent double increment
                                    shouldAutoAdvance = true; // Re-enable auto-advance after manual navigation
                                  });
                                  // Wait for UI to update before speaking
                                  await Future.delayed(const Duration(milliseconds: 50));
                                  if (mounted && isSpeech && _newVoiceText != null && _newVoiceText!.isNotEmpty) {
                                    _speak();
                                  }
                                }
                              } else if (selectedChapter > 1) {
                                // Go to previous chapter's last verse (only if not at chapter 1)
                                if (mounted) {
                                  // Clear old voice text to prevent speaking old verse
                                  _newVoiceText = null;
                                  setState(() {
                                    selectedChapter--;
                                    curretNo = 0; // Reset to 0, will be set after content loads
                                    isManualNavigation = true; // Mark as manual navigation to prevent double increment
                                    shouldAutoAdvance = true; // Re-enable auto-advance after manual navigation
                                  });
                                  // Wait for setState to complete
                                  await Future.delayed(const Duration(milliseconds: 50));
                                  // Load chapter content and wait for it to complete
                                  await setChapterContent();
                                  if (mounted && selectedChapterContent.isNotEmpty) {
                                    setState(() {
                                      curretNo = selectedChapterContent.length - 1;
                                      if (curretNo >= 0 && curretNo < selectedChapterContent.length) {
                                        _newVoiceText =
                                            selectedChapterContent[curretNo].content;
                                      }
                                    });
                                    // Wait for UI to update before speaking
                                    await Future.delayed(const Duration(milliseconds: 50));
                                    if (mounted && isSpeech && _newVoiceText != null && _newVoiceText!.isNotEmpty) {
                                      _speak();
                                    }
                                  }
                                }
                              }
                              // If at chapter 1 and first verse, do nothing (already at beginning)
                            },
                          ),
                          InkWell(
                              onTap: () {
                                if (!mounted) return;
                                if (mounted) {
                                  setState(() {
                                    isInitialProgress = isInitialProgress + 1;
                                    isSpeech = !isSpeech;
                                    if (isSpeech) {
                                      shouldAutoAdvance = true; // Re-enable auto-advance when playing
                                    } else {
                                      shouldAutoAdvance = false; // Disable auto-advance when paused
                                    }
                                  });
                                }

                                isSpeech == true ? _speak() : _stop();
                                if (isInitialTime == true && mounted) {
                                  setState(() {
                                    end = _newVoiceText?.length ?? 0;
                                    isInitialTime = false;
                                  });
                                }
                              },
                              child: Container(
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: CommanColor.lightDarkPrimary(
                                          context)),
                                  padding: const EdgeInsets.all(7),
                                  child: Image.asset(
                                    isSpeech == false
                                        ? "assets/play.png"
                                        : "assets/pause.png",
                                    color: Colors.white,
                                    height: 15,
                                    width: 15,
                                  ))),
                          IconButton(
                            icon: Image.asset(
                              "assets/next_music.png",
                              color: CommanColor.lightDarkPrimary(context),
                              height: 20,
                              width: 20,
                            ),
                            onPressed: () async {
                              await _stop();
                              if (mounted) {
                                if (curretNo < selectedChapterContent.length - 1) {
                                  // Move to next verse
                                  setState(() {
                                    curretNo = curretNo + 1;
                                    _newVoiceText =
                                        selectedChapterContent[curretNo].content;
                                    isManualNavigation = true; // Mark as manual navigation to prevent double increment
                                    shouldAutoAdvance = true; // Re-enable auto-advance after manual navigation
                                  });
                                  // Wait for UI to update before speaking
                                  await Future.delayed(const Duration(milliseconds: 50));
                                  if (mounted && isSpeech && _newVoiceText != null && _newVoiceText!.isNotEmpty) {
                                    _speak();
                                  }
                                } else {
                                  // Reached last verse - show toast and restart from verse 1 of same chapter
                                  Constants.showToast("Reached End");
                                  setState(() {
                                    curretNo = 0;
                                    if (selectedChapterContent.isNotEmpty) {
                                      _newVoiceText = selectedChapterContent[0].content;
                                    }
                                    isManualNavigation = true;
                                    shouldAutoAdvance = true;
                                  });
                                  // Wait for UI to update before speaking
                                  await Future.delayed(const Duration(milliseconds: 50));
                                  if (mounted && isSpeech && _newVoiceText != null && _newVoiceText!.isNotEmpty) {
                                    _speak();
                                  }
                                }
                              }
                            },
                          ),
                          IconButton(
                              icon: Image.asset(
                                "assets/chapt_next.png",
                                color: CommanColor.lightDarkPrimary(context),
                                height: 20,
                                width: 20,
                              ),
                              onPressed: () async {
                                if (selectedChapter !=
                                    int.parse(widget.chapterCount.toString())) {
                                  // Move to next chapter
                                  if (context.mounted) {
                                    await _stop();
                                    // Clear old voice text to prevent speaking old verse
                                    _newVoiceText = null;
                                    setState(() {
                                      selectedChapter++;
                                      curretNo = 0;
                                      isManualNavigation = true; // Mark as manual navigation to prevent double increment
                                      shouldAutoAdvance = true; // Re-enable auto-advance after manual navigation
                                    });
                                    // Wait for setState to complete
                                    await Future.delayed(const Duration(milliseconds: 50));
                                    // Load chapter content and wait for it to complete
                                    await setChapterContent();
                                    if (mounted && selectedChapterContent.isNotEmpty && curretNo >= 0 && curretNo < selectedChapterContent.length) {
                                      setState(() {
                                        _newVoiceText = selectedChapterContent[curretNo].content;
                                      });
                                      // Wait for UI to update before speaking
                                      await Future.delayed(const Duration(milliseconds: 50));
                                      if (mounted && isSpeech && _newVoiceText != null && _newVoiceText!.isNotEmpty) {
                                        _speak();
                                      }
                                    }
                                  }
                                } else {
                                  // At last chapter - show toast and restart from verse 1 of same chapter
                                  if (context.mounted) {
                                    await _stop();
                                    Constants.showToast("Reached End");
                                    setState(() {
                                      curretNo = 0;
                                      if (selectedChapterContent.isNotEmpty) {
                                        _newVoiceText = selectedChapterContent[0].content;
                                      }
                                      isManualNavigation = true;
                                      shouldAutoAdvance = true;
                                    });
                                    // Wait for UI to update before speaking
                                    await Future.delayed(const Duration(milliseconds: 50));
                                    if (mounted && isSpeech && _newVoiceText != null && _newVoiceText!.isNotEmpty) {
                                      _speak();
                                    }
                                  }
                                }
                              }),
                          // Icon(Icons.pres,color: CommanColor.lightDarkPrimary(context),),
                          Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: InkWell(
                              onTap: () {
                                if (context.mounted) {
                                  setState(() {
                                    isSpeech = false;
                                    shouldAutoAdvance = false; // Prevent auto-advancement when stopped
                                  });
                                  _stop();
                                }
                              },
                              child: Image.asset(
                                "assets/stop.png",
                                color: CommanColor.lightDarkPrimary(context),
                                height: 18,
                                width: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ));
            },
          );
        },
      ).then((value) {
        if (mounted && context.mounted) {
          setState(() {});
        }
      });
    } else {
      return Constants.showToast("Please wait");
    }
  }
}

// Define your audio handler class in a separate file (audio_handler.dart)

class AudioPlayerHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  MediaItem? _currentItem;

  AudioPlayerHandler() {
    _player.onPlayerStateChanged.listen((state) {
      playbackState.add(playbackState.value.copyWith(
        playing: state == PlayerState.playing,
        processingState: _getProcessingState(state),
      ));
    });

    _player.onDurationChanged.listen((duration) {
      if (_currentItem != null) {
        mediaItem.add(_currentItem!.copyWith(duration: duration));
      }
    });

    _player.onPositionChanged.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });
  }

  AudioProcessingState _getProcessingState(PlayerState state) {
    switch (state) {
      case PlayerState.playing:
        return AudioProcessingState.ready;
      case PlayerState.paused:
        return AudioProcessingState.ready;
      case PlayerState.stopped:
        return AudioProcessingState.idle;
      case PlayerState.completed:
        return AudioProcessingState.completed;
      case PlayerState.disposed:
        return AudioProcessingState.idle;
    }
  }

  @override
  Future<void> play() => _player.resume();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() {
    mediaItem.add(null);
    return _player.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> setAudio(String url, MediaItem item) async {
    _currentItem = item;
    await _player.setSourceUrl(url);
    mediaItem.add(item);
    playbackState.add(PlaybackState(
      controls: [MediaControl.play, MediaControl.pause, MediaControl.stop],
      systemActions: const {MediaAction.seek},
      processingState: AudioProcessingState.ready,
    ));
  }
}

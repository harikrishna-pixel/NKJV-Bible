import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:biblebookapp/Model/get_audio_model.dart';
import 'package:biblebookapp/utils/internet_speed_checker.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/utils/bible_version_config.dart';
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
  /// Display-only: Home repaints after audio/TTS chapter sync.
  final VoidCallback? onReadingChapterSynced;

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
      required this.audioPlayer,
      this.onReadingChapterSynced});

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
  /// Position to restore if Play must reload after pause (source was cleared).
  /// Cleared on new chapter / fresh load so existing start-from-zero logic stays.
  Duration _audioResumePosition = Duration.zero;
  String audioBaseUrl = "";
  int audioBookNum = 1;
  int audioChapterNum = 1;
  int currentBookChapterCount =
      1; // Track current book's chapter count for accurate completion checks
  bool isPrevTTSEnabled = false;
  late AudioPlayer audioPlayer;

  // Track if audio was playing when closed, to auto-resume on chapter change
  bool _wasAudioPlayingBeforeClose = false;
  // Store book name to preserve it when reopening
  String? _storedBookName;
  // Only newest audio→reader sync may apply (rapid next/prev race).
  int _readingChapterSyncGeneration = 0;

  // Add this for background audio
  late AudioHandler _audioHandler;
  final bool _isAudioServiceInitialized = false;

  // Stream subscriptions for audio player - must be cancelled in dispose
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  // Additive: MP3 chapter-complete lives on State (not sheet), so auto-next
  // continues after the player sheet is dismissed.
  StreamSubscription<void>? _completeSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  bool _handlingMp3Complete = false;
  bool _isAudioSheetOpen = false;
  void Function(void Function())? _audioSheetSetState;
  void Function(void Function())? _fullPlayerSetState;
  void Function(void Function())? _ttsSheetSetState;
  bool _audioSheetUiAlive = false;
  bool _fullPlayerUiAlive = false;
  bool _ttsSheetUiAlive = false;
  bool _ttsVolumeRestarting = false;
  double _playbackSpeed = 1.0;
  Timer? _sleepTimer;
  int? _sleepChoiceMinutes;
  bool _sleepEndOfChapter = false;
  bool _readerUseTts = false;
  bool _mp3Chosen = false;
  bool? _fullScreenTts;
  bool _fullPlayerOpen = false;
  double? _playerSliderDrag;
  DateTime? _playerSliderDragAt;
  int _ttsProgressEnd = 0;
  int _ttsSpokenEnd = 0;
  int _ttsProgressVerse = -1;
  int _ttsPosSecondsShown = 0;
  DateTime? _ttsPosAheadAt;
  bool _ttsProgressHandlerReady = false;
  DateTime? _ttsIgnoreUntil;
  bool _pausedForPhoneCall = false;
  bool _audioPlayingBeforeInterrupt = false;
  bool _ttsPausedForCall = false;

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
      if (!mounted) return;
      selectedChapter = int.tryParse(widget.chapterNum) ?? 1;
      audioChapterNum = selectedChapter;
      final parsedBookNum = int.tryParse(widget.bookNum.toString());
      audioBookNum = (parsedBookNum ?? 0) + 1;
      currentBookChapterCount =
          int.tryParse(widget.chapterCount.toString()) ?? 1;
      setChapterContent();
      initTts();
      checkTTS();
    });

    _playerStateSubscription = audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      final wasPlaying = isAudioPlaying;
      setState(() {
        isAudioPlaying = state == PlayerState.playing;
      });
      _fullPlayerSetState?.call(() {});
      if (state == PlayerState.playing) {
        _pausedForPhoneCall = false;
      } else if (state == PlayerState.paused && wasPlaying) {
        _markPausedIfPhoneCall();
      } else if (state == PlayerState.completed) {
        _handleMp3PlayerComplete();
      }
    });

    /// Listen to audio duration
    _durationSubscription = audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          duration = newDuration;
        });
      }
      _fullPlayerSetState?.call(() {});
    });

    _positionSubscription = audioPlayer.onPositionChanged.listen((p) {
      if (!mounted) return;
      position = p;
      _releaseStuckSliderDrag();
      setState(() {});
      _fullPlayerSetState?.call(() {});
    });

    // Additive: keep auto-next alive while FAB State is alive (sheet dismiss safe).
    _ensureMp3CompletionListener();

    // Store initial book name
    _storedBookName = widget.bookName;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // Screen off uses this same lifecycle. Do not pause MP3 here;
      // a real interrupt still pauses the player and is resumed on return.
      _audioPlayingBeforeInterrupt = isAudioPlaying ||
          audioPlayer.state == PlayerState.playing;
      final ttsPlaying = isSpeech || ttsState == TtsState.playing;
      if (ttsPlaying && _isTtsInitialized) {
        _ttsPausedForCall = true;
        _pauseTts();
      }
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted || !_audioPlayingBeforeInterrupt) return;
        if (audioPlayer.state != PlayerState.playing) {
          _pausedForPhoneCall = true;
          if (mounted) {
            setState(() => isAudioPlaying = false);
          }
          _fullPlayerSetState?.call(() {});
        }
      });
    } else if (state == AppLifecycleState.resumed) {
      _resumeAudioAfterPhoneCall();
      _resumeTtsAfterCall();
    }
  }

  void _markPausedIfPhoneCall() {
    final life = WidgetsBinding.instance.lifecycleState;
    if (life != null && life != AppLifecycleState.resumed) {
      _pausedForPhoneCall = true;
    }
  }

  Future<void> _resumeAudioAfterPhoneCall() async {
    if (!_pausedForPhoneCall) {
      _audioPlayingBeforeInterrupt = false;
      return;
    }
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted || !_pausedForPhoneCall) return;
    _pausedForPhoneCall = false;
    _audioPlayingBeforeInterrupt = false;
    try {
      await audioPlayer.setPlaybackRate(_playbackSpeed);
      await audioPlayer.setVolume(volume);
      await audioPlayer.resume();
      if (mounted) {
        setState(() => isAudioPlaying = true);
      }
      _fullPlayerSetState?.call(() {});
    } catch (_) {}
  }

  Future<void> _resumeTtsAfterCall() async {
    if (!_ttsPausedForCall) return;
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted || !_ttsPausedForCall) return;
    _ttsPausedForCall = false;
    try {
      isManuallyPaused = false;
      isSpeech = true;
      shouldAutoAdvance = true;
      ttsState = TtsState.playing;
      if (mounted) setState(() {});
      _notifyTtsPlayer();
      await _speak();
    } catch (_) {}
  }

  /// Rebuild FAB and open audio sheet (if any) from the same State fields.
  void _mp3UiSetState(void Function() fn) {
    if (mounted) {
      setState(fn);
    }
    final sheetSet = _audioSheetSetState;
    if (sheetSet != null) {
      sheetSet(fn);
    }
    _fullPlayerSetState?.call(fn);
  }

  void _ensureMp3CompletionListener() {
    if (_completeSubscription != null) return;
    _completeSubscription = audioPlayer.onPlayerComplete.listen((_) async {
      await _handleMp3PlayerComplete();
    });
  }

  /// Same auto-next / repeat behavior as the former sheet-scoped listener.
  Future<void> _handleMp3PlayerComplete() async {
    if (!mounted) return;
    if (_handlingMp3Complete) return;
    _handlingMp3Complete = true;
    try {
      await _advanceMp3AfterComplete();
    } finally {
      _handlingMp3Complete = false;
    }
  }

  /// Same auto-next / repeat behavior as the former sheet-scoped listener.
  Future<void> _advanceMp3AfterComplete() async {
    if (!mounted) return;

    if (_sleepEndOfChapter) {
      _sleepEndOfChapter = false;
      _sleepChoiceMinutes = null;
      _sleepTimer?.cancel();
      try {
        await audioPlayer.pause();
      } catch (_) {}
      if (mounted) {
        _mp3UiSetState(() {
          isAudioPlaying = false;
        });
      }
      return;
    }

    // Repeat mode - restart current chapter (unchanged behavior).
    if (repeat) {
      if (isSpeech && _isTtsInitialized) {
        await _stop();
        if (mounted) {
          _mp3UiSetState(() {
            isSpeech = false;
          });
        }
      }
      try {
        await audioPlayer.setSourceUrl(audioBaseUrl);
        await audioPlayer.seek(Duration.zero);
        await audioPlayer.resume();
        if (mounted) {
          _mp3UiSetState(() {
            isAudioPlaying = true;
            position = Duration.zero;
          });
        }
      } catch (e) {
        if (mounted) {
          _mp3UiSetState(() {
            position = Duration.zero;
            isAudioPlaying = false;
          });
        }
      }
      return;
    }

    // Additive: claim guard synchronously so a second onPlayerComplete
    // (common when setSourceUrl replaces the track) cannot skip a chapter.
    if (isNext) return;
    isNext = true;

    void releaseAdvanceGuard({int delayMs = 2000}) {
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (mounted) {
          isNext = false;
          _mp3UiSetState(() {});
        }
      });
    }

    try {
      // Prefer widget/controller chapter count (same as Next button) so
      // auto-advance does not stall when currentBookChapterCount is stale.
      final lastChapter =
          int.tryParse(widget.chapterCount) ?? currentBookChapterCount;
      if (Get.isRegistered<DashBoardController>()) {
        final countStr = Get.find<DashBoardController>()
            .selectedBookChapterCount
            .value
            .trim();
        final fromController = int.tryParse(countStr);
        if (fromController != null && fromController > 0) {
          currentBookChapterCount = fromController;
        }
      }
      var effectiveLastChapter = currentBookChapterCount > lastChapter
          ? currentBookChapterCount
          : lastChapter;
      final totalChapters = _chapterTotal();
      if (totalChapters > effectiveLastChapter) {
        effectiveLastChapter = totalChapters;
      }

      if (audioChapterNum < effectiveLastChapter) {
        // Reader first, then audio — prevents player showing N while header stays behind.
        final nextChapter = audioChapterNum + 1;
        await updateReadingScreenChapter(nextChapter);
        if (!mounted) {
          releaseAdvanceGuard(delayMs: 0);
          return;
        }
        audioChapterNum = nextChapter;
        selectedChapter = nextChapter;
        audioBaseUrl =
            "${_recordedAudioBase()}/$audioBookNum/$audioChapterNum.mp3";
        if (mounted) {
          _mp3UiSetState(() {});
        }
        _fullPlayerSetState?.call(() {});

        // Stop TTS if it's playing
        if (isSpeech && _isTtsInitialized) {
          await _stop();
          if (mounted) {
            _mp3UiSetState(() {
              isSpeech = false;
            });
          }
        }

        // Additional delay to ensure UI updates before loading next audio
        await Future.delayed(const Duration(milliseconds: 100));

        // load next source, reset position and resume playback
        bool loadSuccess = false;
        // Check internet connection before loading audio
        final hasInternet = await InternetConnection().hasInternetAccess;
        if (!hasInternet) {
          Constants.showToast("Check your internet connection.");
          releaseAdvanceGuard(delayMs: 0);
          return;
        }

        int retryCount = 0;
        const maxRetries = 2;

        while (!loadSuccess && retryCount < maxRetries && mounted) {
          try {
            await audioPlayer.setSourceUrl(audioBaseUrl);
            // ensure position and duration will update from streams
            await audioPlayer.seek(Duration.zero);
            try {
              await audioPlayer.setPlaybackRate(_playbackSpeed);
              await audioPlayer.setVolume(volume);
            } catch (_) {}
            await audioPlayer.resume();
            if (audioPlayer.state != PlayerState.playing) {
              await Future.delayed(const Duration(milliseconds: 80));
              await audioPlayer.resume();
            }
            loadSuccess = true;
            if (mounted) {
              _mp3UiSetState(() {
                isAudioPlaying = true;
                position = Duration.zero; // Reset position for new chapter
                _audioResumePosition = Duration.zero;
              });
            }
          } catch (e) {
            retryCount++;
            debugPrint(
                "Error loading next chapter audio (attempt $retryCount): $e");
            if (retryCount < maxRetries) {
              // Wait a bit before retrying
              await Future.delayed(const Duration(milliseconds: 500));
            } else {
              // After max retries, still try to continue but log the error
              debugPrint(
                  "Failed to load next chapter after $maxRetries attempts, but continuing");
              // Don't stop - let it try to continue
              if (mounted) {
                _mp3UiSetState(() {
                  isAudioPlaying = false;
                  position = Duration.zero;
                });
              }
            }
          }
        }

        releaseAdvanceGuard();
      } else {
        // Last chapter reached - check for next book
        // Get current book number (0-indexed from widget.bookNum)
        final currentBookNum = int.parse(widget.bookNum.toString());

        // Try to get the next book
        final nextBook = await getNextBook(currentBookNum);

        if (nextBook != null &&
            nextBook.bookNum != null &&
            nextBook.chapterCount != null) {
          // Next book exists - load first chapter of next book
          final nextBookNum = nextBook.bookNum!.toInt();
          final nextBookChapterCount = nextBook.chapterCount!.toInt();
          final nextBookName = nextBook.title ?? "";

          // Update audio book and chapter numbers
          // audioBookNum is 1-indexed for URL (bookNum + 1)
          audioBookNum = nextBookNum + 1;
          audioChapterNum = 1;
          currentBookChapterCount =
              nextBookChapterCount; // Update chapter count for new book
          audioBaseUrl =
              "${_recordedAudioBase()}/$audioBookNum/$audioChapterNum.mp3";
          if (mounted) {
            _mp3UiSetState(() {});
          }

          // Update reading screen to match next book and first chapter
          // Pass chapter count so it can be updated in the controller
          await updateReadingScreenForNextBook(
              nextBookNum, 1, nextBookName, nextBookChapterCount);

          // Update _storedBookName with the new book name
          if (mounted && nextBookName.isNotEmpty) {
            _mp3UiSetState(() {
              _storedBookName = nextBookName;
            });
          }

          // Force a small delay and then refresh controller to ensure UI updates
          await Future.delayed(const Duration(milliseconds: 100));
          if (Get.isRegistered<DashBoardController>()) {
            final controller = Get.find<DashBoardController>();
            // Trigger update again to ensure UI reflects changes
            controller.getSelectedChapterAndBook();
          }

          // Check internet connection before loading audio
          final hasInternet = await InternetConnection().hasInternetAccess;
          if (!hasInternet) {
            Constants.showToast("Check your internet connection.");
            releaseAdvanceGuard(delayMs: 0);
            return;
          }

          // Load next book's first chapter audio
          bool loadSuccess = false;
          int retryCount = 0;
          const maxRetries = 2;

          while (!loadSuccess && retryCount < maxRetries && mounted) {
            try {
              await audioPlayer.setSourceUrl(audioBaseUrl);
              // ensure position and duration will update from streams
              await audioPlayer.seek(Duration.zero);
              try {
                await audioPlayer.setPlaybackRate(_playbackSpeed);
                await audioPlayer.setVolume(volume);
              } catch (_) {}
              await audioPlayer.resume();
              if (audioPlayer.state != PlayerState.playing) {
                await Future.delayed(const Duration(milliseconds: 80));
                await audioPlayer.resume();
              }
              loadSuccess = true;
              if (mounted) {
                _mp3UiSetState(() {
                  isAudioPlaying = true;
                  position = Duration.zero; // Reset position for new book
                });
              }
            } catch (e) {
              retryCount++;
              debugPrint(
                  "Error loading next book audio (attempt $retryCount): $e");
              if (retryCount < maxRetries) {
                // Wait a bit before retrying
                await Future.delayed(const Duration(milliseconds: 500));
              } else {
                // After max retries, stop audio
                debugPrint(
                    "Failed to load next book after $maxRetries attempts");
                if (mounted) {
                  _mp3UiSetState(() {
                    isAudioPlaying = false;
                    position = Duration.zero;
                  });
                }
              }
            }
          }

          releaseAdvanceGuard();
        } else {
          // No next book - stop audio and reset
          try {
            await audioPlayer.stop();
            if (mounted) {
              _mp3UiSetState(() {
                position = Duration.zero; // Reset position to zero
                isAudioPlaying = false;
                isNext = false; // Reset flag
              });
            }
          } catch (e) {
            // handle errors
            if (mounted) {
              _mp3UiSetState(() {
                position = Duration.zero;
                isAudioPlaying = false;
                isNext = false; // Reset flag
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('_handleMp3PlayerComplete error: $e');
      releaseAdvanceGuard(delayMs: 0);
    }
  }

  @override
  void didUpdateWidget(floatingButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if chapter changed (swipe to next chapter)
    final oldChapterNum = int.tryParse(oldWidget.chapterNum) ?? audioChapterNum;
    final newChapterNum = int.tryParse(widget.chapterNum) ?? audioChapterNum;

    // Check if book number changed (in case user swiped to different book)
    final oldBookNum =
        int.tryParse(oldWidget.bookNum.toString()) ?? (audioBookNum - 1);
    final newBookNum =
        int.tryParse(widget.bookNum.toString()) ?? (audioBookNum - 1);

    if (oldChapterNum != newChapterNum) {
      // Chapter changed - update audio chapter number
      audioChapterNum = newChapterNum;
      selectedChapter = newChapterNum;

      // Also check if book number changed and update accordingly
      if (oldBookNum != newBookNum) {
        audioBookNum = newBookNum + 1;
        currentBookChapterCount =
            int.tryParse(widget.chapterCount.toString()) ??
                currentBookChapterCount;
        // Update book name from widget if available, otherwise keep stored name
        if (widget.bookName.isNotEmpty) {
          _storedBookName = widget.bookName;
        }
      }

      // If audio was playing before close, auto-start it on new chapter
      if (_wasAudioPlayingBeforeClose && !isAudioPlaying) {
        // Update book info if it changed
        if (widget.bookName != oldWidget.bookName || oldBookNum != newBookNum) {
          if (widget.bookName.isNotEmpty) {
            _storedBookName = widget.bookName;
          }
          audioBookNum = newBookNum + 1;
          currentBookChapterCount =
            int.tryParse(widget.chapterCount.toString()) ??
                currentBookChapterCount;
        }

        // Auto-start audio on new chapter
        Future.delayed(const Duration(milliseconds: 300), () async {
          if (mounted) {
            await setAudio();
            await audioPlayer.resume();
            if (mounted) {
              setState(() {
                isAudioPlaying = true;
              });
            }
          }
        });
      }
    }

    // Update book name if it changed
    if (widget.bookName != oldWidget.bookName && widget.bookName.isNotEmpty) {
      _storedBookName = widget.bookName;
      audioBookNum = newBookNum + 1;
      currentBookChapterCount =
          int.tryParse(widget.chapterCount.toString()) ??
              currentBookChapterCount;
    }

    // Additional check: if only book number changed without chapter change
    if (oldBookNum != newBookNum && oldChapterNum == newChapterNum) {
      audioBookNum = newBookNum + 1;
      currentBookChapterCount =
          int.tryParse(widget.chapterCount.toString()) ??
              currentBookChapterCount;
      // Update book name from widget if available, otherwise keep stored name
      if (widget.bookName.isNotEmpty) {
        _storedBookName = widget.bookName;
      }
    }
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

  String? _recordedAudioBase() {
    return widget.audioData?.data?.bibleAudioInfo?.audioBasepath;
  }

  void _releaseStuckSliderDrag() {
    final at = _playerSliderDragAt;
    if (_playerSliderDrag == null || at == null) return;
    if (DateTime.now().difference(at) < const Duration(seconds: 1)) return;
    _playerSliderDrag = null;
    _playerSliderDragAt = null;
  }

  void _notifyTtsPlayer({bool throttle = false}) {
    _releaseStuckSliderDrag();
    if (throttle) {
      final now = DateTime.now();
      if (_ttsUiNotifyAt != null &&
          now.difference(_ttsUiNotifyAt!) < const Duration(milliseconds: 220)) {
        return;
      }
      _ttsUiNotifyAt = now;
    }
    _safeCallSetter(_ttsSheetSetState);
    _safeCallSetter(_fullPlayerSetState);
  }

  DateTime? _ttsUiNotifyAt;

  void _ignoreTtsEngineEvents({int ms = 700}) {
    _ttsIgnoreUntil = DateTime.now().add(Duration(milliseconds: ms));
  }

  bool _ttsEngineEventIgnored() {
    final until = _ttsIgnoreUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  void _resetTtsProgressClock() {
    _ttsProgressEnd = 0;
    _ttsSpokenEnd = 0;
    _ttsProgressVerse = -1;
    _ttsPosSecondsShown = 0;
    _ttsPosAheadAt = null;
    _ttsProgressAt = DateTime.now();
  }

  void _safeCallSetter(void Function(void Function())? setter) {
    if (setter == null) return;
    setter(() {});
  }

  void _closeAudioSheetUi() {
    _audioSheetUiAlive = false;
    _audioSheetSetState = null;
  }

  void _closeTtsSheetUi() {
    _ttsSheetUiAlive = false;
    _ttsSheetSetState = null;
  }

  void _closeFullPlayerUi() {
    _fullPlayerUiAlive = false;
    _fullPlayerSetState = null;
    _playerSliderDrag = null;
    _playerSliderDragAt = null;
  }

  DateTime? _ttsProgressAt;

  void _attachTtsProgressHandler() {
    if (_ttsProgressHandlerReady) return;
    _ttsProgressHandlerReady = true;
    flutterTts.setProgressHandler(
        (String text, int startOffset, int endOffset, String word) {
      allText = text;
      final len = text.length;
      if (len <= 0) return;
      if (curretNo != _ttsProgressVerse) {
        _ttsProgressVerse = curretNo;
        _ttsProgressEnd = 0;
        _ttsSpokenEnd = 0;
        _ttsProgressAt = DateTime.now();
      }
      var wordCount = 1;
      if (curretNo >= 0 && curretNo < selectedChapterContent.length) {
        final n = _spokenWordCount(selectedChapterContent[curretNo].content);
        if (n > 0) wordCount = n;
      } else {
        final n = _spokenWordCount(text);
        if (n > 0) wordCount = n;
      }
      final now = DateTime.now();
      final dt = _ttsProgressAt == null
          ? 0.22
          : now.difference(_ttsProgressAt!).inMilliseconds / 1000.0;
      _ttsProgressAt = now;
      var maxDelta = ((len * (dt.clamp(0.0, 0.5) * 2.5 * _ttsSpeedFactor()) /
                  wordCount)
              .round())
          .clamp(0, len);
      final engineEnd = endOffset.clamp(0, len);
      // A rounded step of 0 freezes the bar while speech continues.
      if (engineEnd > _ttsProgressEnd && maxDelta < 1) maxDelta = 1;
      _ttsSpokenEnd = engineEnd;
      var nextEnd = engineEnd;
      if (nextEnd < _ttsProgressEnd) nextEnd = _ttsProgressEnd;
      if (nextEnd > _ttsProgressEnd + maxDelta) {
        nextEnd = _ttsProgressEnd + maxDelta;
      }
      _ttsProgressEnd = nextEnd;
      start = startOffset.clamp(0, len);
      end = nextEnd;
      if (end < start) end = start;
      _notifyTtsPlayer(throttle: true);
    });
  }

  void _applyOutputVolume(double value) {
    volume = value;
    if (_showTtsUi()) {
      flutterTts.setVolume(value);
    } else {
      audioPlayer.setVolume(value);
    }
  }

  Future<void> _applyTtsVolumeLive() async {
    if (!_showTtsUi()) return;
    final wasPlaying = isSpeech || ttsState == TtsState.playing;
    try {
      await flutterTts.setVolume(volume);
    } catch (_) {}
    if (!wasPlaying || !_isTtsInitialized) return;
    _ttsVolumeRestarting = true;
    try {
      try {
        await flutterTts.stop();
      } catch (_) {}
      isManuallyPaused = false;
      shouldAutoAdvance = true;
      isSpeech = true;
      ttsState = TtsState.playing;
      await _speak();
      await Future.delayed(const Duration(milliseconds: 80));
    } finally {
      _ttsVolumeRestarting = false;
      if (mounted) setState(() {});
      _notifyTtsPlayer();
    }
  }

  Future setAudio({Duration seekTo = Duration.zero}) async {
    // Fresh chapter/file load still starts at zero; resume passes seekTo.
    if (seekTo == Duration.zero) {
      _audioResumePosition = Duration.zero;
    }
    // Stop TTS if it's playing before starting audio
    if (isSpeech && _isTtsInitialized) {
      await _stop();
      if (mounted) {
        setState(() {
          isSpeech = false;
        });
      }
    }

    // Set release mode based on repeat flag - default to release (no loop)
    final cfg = await BibleVersionConfig.active();
    final fromCfg = (cfg?.audioBasePath ?? '').trim();
    String? audioBasePath =
        fromCfg.isNotEmpty ? fromCfg : _recordedAudioBase();
    audioBaseUrl = "$audioBasePath/$audioBookNum/$audioChapterNum.mp3";
    log('Audio Base Url:$audioBaseUrl');

    // Slow networks (2G): stop + reset, then retry setSourceUrl once on failure.
    // Default [seekTo] is zero — same as before for all existing callers.
    Future<void> loadSource() async {
      await audioPlayer
          .setReleaseMode(repeat ? ReleaseMode.loop : ReleaseMode.release);
      try {
        await audioPlayer.stop();
      } catch (_) {}
      await audioPlayer.setSourceUrl(audioBaseUrl);
      await audioPlayer.setVolume(volume);
      await audioPlayer.seek(seekTo);
    }

    try {
      await loadSource();
      log('Audio Set Completed');
    } catch (e, st) {
      log('Audio Set Error (retrying): $e,$st');
      try {
        await Future.delayed(const Duration(milliseconds: 800));
        await loadSource();
        log('Audio Set Completed after retry');
      } catch (e2, st2) {
        log('Audio Set Error: $e2,$st2');
        debugPrintStack(stackTrace: st2);
      }
    }
  }

  /// Text To Speech

  bool isTTSLoop = false;
  bool shouldAutoAdvance = true; // Flag to control auto-advancement
  // Additive: ignore TTS completion events fired by _stop() during chapter advance.
  bool _ttsAdvancingChapter = false;
  bool isManualNavigation =
      false; // Flag to track manual navigation to prevent double increment
  bool isManuallyPaused =
      false; // Flag to prevent auto-restart when manually paused
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

  /// Keep verse highlight visible while playing, paused, or resuming after pause.
  bool get _showTtsWordHighlight =>
      allText.isNotEmpty &&
      (ttsState == TtsState.playing ||
          ttsState == TtsState.paused ||
          ttsState == TtsState.continued);

  int start = 0;
  int end = 0;
  String allText = "";

  bool hasConnection = true;

  bool isNext = false;
  initTts() async {
    flutterTts = FlutterTts();
    _isTtsInitialized = true;
    await _applyTtsLanguageForActiveBible();

    _setAwaitOptions();
    _attachTtsProgressHandler();
    await Future.delayed(Duration(milliseconds: 2000));

    if (!mounted) return;
    if (isAndroid) {
      _getDefaultEngine();
      _getDefaultVoice();
    }

    flutterTts.setStartHandler(() {
      if (mounted) {
        isManualNavigation = false;
        setState(() {
          ttsState = TtsState.playing;
          isSpeech = true; // Sync isSpeech with TTS state
        });
        _notifyTtsPlayer();
      }
    });

    flutterTts.setCancelHandler(() {
      if (_ttsVolumeRestarting) return;
      if (_ttsEngineEventIgnored() || _ttsAdvancingChapter) return;
      if (isManualNavigation) {
        isManualNavigation = false;
        return;
      }
      if (mounted) {
        setState(() {
          ttsState = TtsState.stopped;
          isSpeech = false; // Sync isSpeech with TTS state
        });
        _notifyTtsPlayer();
      }
    });
    flutterTts.setPauseHandler(() {
      if (mounted) {
        setState(() {
          ttsState = TtsState.paused;
        });
        _notifyTtsPlayer();
      }
    });
    flutterTts.setContinueHandler(() {
      if (mounted) {
        setState(() {
          ttsState = TtsState.playing;
          isSpeech = true;
        });
        _notifyTtsPlayer();
      }
    });
    flutterTts.setCompletionHandler(() async {
      if (_ttsVolumeRestarting) {
        return;
      }
      if (_ttsEngineEventIgnored()) {
        return;
      }
      // Don't auto-advance if manually paused
      if (isManuallyPaused) {
        debugPrint(
            'Completion handler: TTS was manually paused, not auto-advancing');
        return;
      }

      // Additive: _stop() during chapter advance can re-fire completion — ignore it.
      if (_ttsAdvancingChapter) {
        debugPrint(
            'Completion handler: TTS chapter advance in progress, ignoring');
        return;
      }

      // Loop mode: repeat the current verse only (manual next/prev still works).
      if (isTTSLoop) {
        if (!mounted) return;
        if (curretNo >= 0 && curretNo < selectedChapterContent.length) {
          _newVoiceText = selectedChapterContent[curretNo].content;
        }
        await Future.delayed(const Duration(milliseconds: 80));
        if (mounted && !isManuallyPaused && isSpeech) {
          _speak();
        }
        return;
      }

      // Only auto-advance if not manually stopped or navigated
      if (!shouldAutoAdvance) {
        return;
      }
      // Stop() after skip must not eat the verse that then plays.
      if (isManualNavigation) {
        isManualNavigation = false;
        return;
      }
      if (isTTSLoop == false) {
        final lastChapter = _chapterTotal();
        final onLastVerse = selectedChapterContent.isNotEmpty &&
            curretNo + 1 >= selectedChapterContent.length;
        if (selectedChapter >= lastChapter && onLastVerse) {
          // Last chapter, last verse - stop
          await _stop();
          if (mounted) {
            setState(() {
              isSpeech = false;
            });
            _notifyTtsPlayer();
          }
        } else {
          if (_sleepEndOfChapter && onLastVerse) {
            _sleepEndOfChapter = false;
            _sleepChoiceMinutes = null;
            _sleepTimer?.cancel();
            await _stop();
            if (mounted) {
              setState(() {
                isSpeech = false;
              });
              _notifyTtsPlayer();
            }
            return;
          }
          if (onLastVerse && selectedChapter < lastChapter) {
            // End of current chapter, move to next chapter
            if (mounted) {
              _ttsAdvancingChapter = true;
              _ignoreTtsEngineEvents(ms: 250);
              bool shouldSpeakNext = false;
              try {
                _newVoiceText = null;
                setState(() {
                  selectedChapter++;
                  curretNo = 0;
                  isSpeech = true;
                  shouldAutoAdvance = true;
                });
                _resetTtsProgressClock();
                _notifyTtsPlayer();
                await setChapterContent();
                await updateReadingScreenChapter(selectedChapter);
                if (mounted &&
                    selectedChapterContent.isNotEmpty &&
                    curretNo >= 0 &&
                    curretNo < selectedChapterContent.length) {
                  setState(() {
                    _newVoiceText = selectedChapterContent[curretNo].content;
                  });
                  shouldSpeakNext = mounted &&
                      !isManuallyPaused &&
                      shouldAutoAdvance &&
                      _newVoiceText != null &&
                      _newVoiceText!.isNotEmpty;
                  if (shouldSpeakNext && !isSpeech) {
                    setState(() => isSpeech = true);
                  }
                }
              } finally {
                Future.delayed(const Duration(milliseconds: 400), () {
                  _ttsAdvancingChapter = false;
                });
              }
              if (shouldSpeakNext) {
                _speak();
              }
            }
          } else {
            // Move to next verse in current chapter
            if (mounted && curretNo + 1 < selectedChapterContent.length) {
              _ignoreTtsEngineEvents(ms: 250);
              setState(() {
                curretNo = curretNo + 1;
                if (curretNo >= 0 && curretNo < selectedChapterContent.length) {
                  _newVoiceText = selectedChapterContent[curretNo].content;
                }
              });
              _notifyTtsPlayer();
              if (mounted &&
                  !isManuallyPaused &&
                  shouldAutoAdvance &&
                  _newVoiceText != null &&
                  _newVoiceText!.isNotEmpty) {
                if (!isSpeech) {
                  setState(() => isSpeech = true);
                }
                _speak();
              }
            }
          }
        }
      }
    });
    flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          ttsState = TtsState.stopped;
        });
        _notifyTtsPlayer();
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

  String? _audioSettingsChoice;
  Future<bool>? _englishAudioLoads;

  Future<bool> _englishBibleAudioLoads() async {
    final url = BibleInfo.englishBibleAudio.trim();
    if (url.isEmpty) return false;
    final client = HttpClient();
    try {
      final request = await client
          .headUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      final response =
          await request.close().timeout(const Duration(seconds: 5));
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  String _fallbackAudioLanguageLabel(String url) {
    final parts = Uri.tryParse(url)?.pathSegments ?? const <String>[];
    final audioIndex = parts.indexOf('bible_audio');
    if (audioIndex >= 0 && audioIndex + 1 < parts.length) {
      final name = Uri.decodeComponent(parts[audioIndex + 1]).trim();
      if (name.isNotEmpty) {
        if (name.toLowerCase().endsWith('audio')) return name;
        return '$name Audio';
      }
    }
    return 'English Audio';
  }

  String _recordedAudioVoiceLabel() {
    final name = BibleInfo.bible_shortName.trim();
    if (name.isEmpty) return 'Audio';
    final withoutBible =
        name.replaceAll(RegExp(r'\s+Bible$', caseSensitive: false), '').trim();
    if (withoutBible.toLowerCase().endsWith('audio')) return withoutBible;
    return '$withoutBible Audio';
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
      await flutterTts.speak("Your preview voice is changed.");
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

  Future<void> _handleAudioOptionTap(BuildContext popoverContext) async {
    if (popoverContext.mounted) {
      Navigator.pop(popoverContext);
    }
    final hasInternet = await InternetConnection().hasInternetAccess;
    if (!hasInternet) {
      Constants.showToast('No internet connection');
      return;
    }
    _mp3Chosen = true;
    _readerUseTts = false;
    await setAudio();
    if (!mounted) return;
    setState(() {
      audioLoad = false;
    });
    await audioPlayerBottomSheet();
    if (mounted) setState(() {});
  }

  Future<void> _startReaderMp3() async {
    final hasInternet = await InternetConnection().hasInternetAccess;
    if (!hasInternet) {
      Constants.showToast('No internet connection');
      return;
    }
    _readerUseTts = false;
    _mp3Chosen = true;
    await setAudio();
    if (!mounted) return;
    try {
      await audioPlayer.setPlaybackRate(_playbackSpeed);
    } catch (_) {}
    await audioPlayer.resume();
    setState(() {
      audioLoad = false;
      isAudioPlaying = true;
    });
  }

  Future<void> _showAudioTtsPopover() async {
    if (!mounted) return;
    setState(() {
      isOpenAudio = true;
    });
    if (!mounted) return;
    await showPopover(
      context: context,
      direction: PopoverDirection.left,
      transitionDuration: const Duration(milliseconds: 250),
      bodyBuilder: (popoverContext) {
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
                  onTap: () => _handleAudioOptionTap(popoverContext),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 5),
                    child: Row(
                      children: [
                        Image.asset(
                          "assets/musical_note.png",
                          height: 22,
                          width: 22,
                          color:
                              CommanColor.darkModePrimaryWhite(context),
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
                  onTap: () async {
                    Navigator.pop(popoverContext);
                    await _switchFromAudioToTts();
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
                          color:
                              CommanColor.darkModePrimaryWhite(context),
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
      backgroundColor: Provider.of<ThemeProvider>(context, listen: false)
                  .themeMode ==
              ThemeMode.dark
          ? Colors.white
          : CommanColor.lightModePrimary,
      arrowWidth: 24,
    );
    if (mounted) {
      setState(() {
        isOpenAudio = false;
      });
    }
  }

  Future _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {}
  }

  Future _getDefaultVoice() async {
    var voice = await flutterTts.getDefaultVoice;
    if (voice != null) {}
  }

  Future<void> _applyTtsLanguageForActiveBible() async {
    if (!_isTtsInitialized) return;
    final cfg = await BibleVersionConfig.active();
    final lang = (cfg?.ttsLanguage ??
            widget.audioData?.data?.bibleAudioInfo?.textToSpeechLanguageCodeIos ??
            BibleInfo.textToSpeechLanguageCodeIos)
        .trim();
    if (lang.isEmpty) return;
    language = lang;
    await flutterTts.setLanguage(lang);
  }

  Future _speak() async {
    try {
      await _applyTtsLanguageForActiveBible();
      // Reset manual pause flag when TTS is manually started
      isManuallyPaused = false;
      shouldAutoAdvance = true; // Re-enable auto-advance when manually started

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

  /// Pause at current position (resume with [_speak] / play — uses flutter_tts pause).
  Future<void> _pauseTts() async {
    if (!mounted || !_isTtsInitialized) return;
    try {
      await flutterTts.pause();
      debugPrint('_pauseTts() called - TTS paused');
    } catch (e) {
      debugPrint("TTS pause error in _pauseTts(): $e");
    }
    if (mounted) {
      setState(() {
        ttsState = TtsState.paused;
        isSpeech = false;
        isManuallyPaused = true;
        shouldAutoAdvance = false;
      });
      _notifyTtsPlayer();
    }
  }

  Future _stop() async {
    if (!mounted) return;

    // Stop TTS immediately without waiting for SharedPreferences
    if (_isTtsInitialized) {
      try {
        await flutterTts.stop();
        debugPrint('_stop() called - TTS stopped');
      } catch (e) {
        debugPrint("TTS stop error in _stop(): $e");
      }
    }

    // Update state immediately
    if (mounted) {
      setState(() {
        ttsState = TtsState.stopped;
        isSpeech = false;
      });
      _notifyTtsPlayer();
      debugPrint('_stop() - State updated: isSpeech=false, ttsState=stopped');
    }

    // Update SharedPreferences in background (non-blocking)
    SharPreferences.setBoolean('closead', true);
  }

  bool isInitialTime = true;
  int isInitialProgress = 1;
  int totalStartOffset = 0;
  int totalEndOffset = 0;

  /// Called when the reading screen is left — not on scroll hide/rebuild.
  void stopPlaybackOnLeave() {
    closeaudio();
  }

  /// Additive: pause chapter audio / TTS while a fullscreen ad is showing.
  /// Does not stop/seek; only pause so we can resume after the ad.
  /// MP3 and TTS are handled independently — neither early-return blocks the other.
  bool _audioPausedForAd = false;
  bool _ttsPausedForAd = false;

  Future<void> pausePlaybackForAd() async {
    _audioPausedForAd = false;
    _ttsPausedForAd = false;
    if (!mounted) return;

    // MP3 path (unchanged behavior)
    try {
      final playing =
          isAudioPlaying || audioPlayer.state == PlayerState.playing;
      if (playing) {
        await audioPlayer.pause();
        _audioPausedForAd = true;
        if (mounted) {
          setState(() {
            isAudioPlaying = false;
          });
        }
      }
    } catch (e) {
      debugPrint('pausePlaybackForAd audio: $e');
    }

    // TTS path (additive only — Mark as Read ad overlap fix)
    try {
      final ttsPlaying = isSpeech || ttsState == TtsState.playing;
      if (ttsPlaying && _isTtsInitialized) {
        await flutterTts.pause();
        _ttsPausedForAd = true;
        if (mounted) {
          setState(() {
            ttsState = TtsState.paused;
            isSpeech = false;
            // Prevent completion handler from advancing while the ad is up.
            isManuallyPaused = true;
          });
        }
      }
    } catch (e) {
      debugPrint('pausePlaybackForAd tts: $e');
    }
  }

  /// Additive: resume only what we paused for an ad (no-op otherwise).
  Future<void> resumePlaybackAfterAd() async {
    if (!mounted) {
      _audioPausedForAd = false;
      _ttsPausedForAd = false;
      return;
    }

    // MP3 resume (unchanged behavior)
    if (_audioPausedForAd) {
      _audioPausedForAd = false;
      try {
        await audioPlayer.resume();
        if (mounted) {
          setState(() {
            isAudioPlaying = true;
          });
        }
      } catch (e) {
        debugPrint('resumePlaybackAfterAd audio: $e');
      }
    }

    // TTS resume (additive only)
    if (_ttsPausedForAd) {
      _ttsPausedForAd = false;
      try {
        if (mounted) {
          setState(() {
            isManuallyPaused = false;
            isSpeech = true;
          });
        }
        await _speak();
      } catch (e) {
        debugPrint('resumePlaybackAfterAd tts: $e');
      }
    }
  }

  closeaudio() async {
    debugPrint(" audio  stopped ");

    if (!mounted) return;

    if (isAudioPlaying) {
      try {
        // Store that audio was playing before close
        _wasAudioPlayingBeforeClose = true;
        await audioPlayer.stop();
        await SharPreferences.setBoolean('closead', true);
        // await audioPlayer.dispose();
      } catch (e) {
        debugPrint("Error stopping audio: $e");
      }
    } else if (isSpeech && _isTtsInitialized) {
      try {
        _wasAudioPlayingBeforeClose = false; // Reset if TTS was playing
        flutterTts.stop();
      } catch (e) {
        debugPrint("Error stopping TTS: $e");
      }
    } else {
      // Neither playing - reset flag
      _wasAudioPlayingBeforeClose = false;
    }
  }

  // Helper method to update reading screen when audio chapter changes
  Future<void> updateReadingScreenChapter(int chapterNum) async {
    // Newest sync wins — older in-flight syncs must not overwrite the reader.
    final syncId = ++_readingChapterSyncGeneration;
    try {
      // Update reader chapter first so header cannot stay behind audio UI.
      if (Get.isRegistered<DashBoardController>()) {
        final controller = Get.find<DashBoardController>();
        controller.selectedChapter.value = chapterNum.toString();
        controller.selectedChapterForRead.value = chapterNum.toString();
        controller.selectChapterChange.value = chapterNum;
        controller.selectedChapter.refresh();
        widget.onReadingChapterSynced?.call();
      }

      await SharPreferences.setString(
          SharPreferences.selectedChapter, chapterNum.toString());

      if (syncId != _readingChapterSyncGeneration || !mounted) return;

      setState(() {
        selectedChapter = chapterNum;
        audioChapterNum = chapterNum;
      });

      // Update the reading screen via controller
      try {
        final controller = Get.find<DashBoardController>();
        // Capture live book BEFORE touching ForRead — getBookContentForRead()
        // assigns selectedBook/Num FROM ForRead and can wipe a valid book when
        // ForRead is still empty/"null" from HomeScreen init.
        final liveBookNum = controller.selectedBookNum.value.trim();
        final liveBookName = controller.selectedBook.value.trim();
        final liveChapterCount =
            controller.selectedBookChapterCount.value.trim();

        // Re-assert chapter before reload (another sync may have started).
        controller.selectedChapter.value = chapterNum.toString();
        controller.selectedChapterForRead.value = chapterNum.toString();
        controller.selectChapterChange.value = chapterNum;

        if (liveBookNum.isNotEmpty && liveBookNum.toLowerCase() != 'null') {
          // Keep SharedPreferences consistent with the book currently playing.
          // forceReloadSelectedChapter() reads selectedBookNum from prefs.
          await SharPreferences.setString(
              SharPreferences.selectedBookNum, liveBookNum);
          controller.selectedBookNum.value = liveBookNum;
          controller.selectedBookNumForRead.value = liveBookNum;
        }
        if (liveBookName.isNotEmpty && liveBookName.toLowerCase() != 'null') {
          // Keep SharedPreferences consistent with the book currently playing.
          // forceReloadSelectedChapter() reads selectedBook from prefs.
          await SharPreferences.setString(
              SharPreferences.selectedBook, liveBookName);
          controller.selectedBook.value = liveBookName;
          controller.selectedBookNameForRead.value = liveBookName;
        }
        if (liveChapterCount.isNotEmpty) {
          currentBookChapterCount =
              int.tryParse(liveChapterCount) ?? currentBookChapterCount;
        }

        if (syncId != _readingChapterSyncGeneration || !mounted) return;

        // Force a fresh chapter load (clears skip/early-return cache).
        await controller.forceReloadSelectedChapter();

        if (syncId != _readingChapterSyncGeneration || !mounted) return;

        // Only call getBookContentForRead when the reader still doesn't match —
        // calling it always can re-apply stale ForRead and undo the reload.
        if (!controller.displayedContentMatchesSelection()) {
          await controller.getBookContentForRead();
        }

        if (syncId != _readingChapterSyncGeneration || !mounted) return;

        // Ensure the in-memory selected chapter matches what we just loaded.
        controller.selectedChapter.value = chapterNum.toString();
        controller.selectedChapterForRead.value = chapterNum.toString();
        controller.selectChapterChange.value = chapterNum;

        // One retry if verses still don't match the audio chapter.
        if (!controller.displayedContentMatchesSelection()) {
          await controller.forceReloadSelectedChapter();
          if (syncId != _readingChapterSyncGeneration || !mounted) return;
          controller.selectedChapter.value = chapterNum.toString();
          controller.selectedChapterForRead.value = chapterNum.toString();
          controller.selectChapterChange.value = chapterNum;
        }

        // New list instance so GetX/Home ListView cannot keep a stale identity.
        if (controller.selectedBookContent.isNotEmpty) {
          controller.selectedBookContent.value =
              List.from(controller.selectedBookContent);
        }
        controller.selectedChapter.refresh();
        widget.onReadingChapterSynced?.call();

        final scrollCtrl = controller.autoScrollController.value;
        if (scrollCtrl.hasClients) {
          scrollCtrl.jumpTo(0);
        }

        // Update _storedBookName from controller or SharedPreferences
        final updatedBookName = controller.selectedBook.value.isNotEmpty
            ? controller.selectedBook.value
            : await SharPreferences.getString(SharPreferences.selectedBook);
        if (syncId != _readingChapterSyncGeneration || !mounted) return;
        if (updatedBookName != null && updatedBookName.isNotEmpty) {
          setState(() {
            _storedBookName = updatedBookName;
            audioChapterNum = chapterNum;
            selectedChapter = chapterNum;
          });
        }
      } catch (e) {
        debugPrint("DashBoardController not available or error: $e");
        // Try to get book name from SharedPreferences as fallback
        try {
          final bookName =
              await SharPreferences.getString(SharPreferences.selectedBook);
          if (bookName != null && bookName.isNotEmpty && mounted) {
            setState(() {
              _storedBookName = bookName;
            });
          }
        } catch (prefError) {
          debugPrint(
              "Error getting book name from SharedPreferences: $prefError");
        }
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
      final result = await db
          .rawQuery("SELECT * FROM book WHERE book_num = $nextBookNum LIMIT 1");

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
  Future<void> updateReadingScreenForNextBook(
      int bookNum, int chapterNum, String bookName, int chapterCount) async {
    try {
      // Update shared preferences for book and chapter - ensure all are saved
      await SharPreferences.setString(SharPreferences.selectedBook, bookName);
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

          // Await chapter loads sequentially so ListView/AutoScrollTag does not
          // rebuild from overlapping content updates (avoids LateInitializationError).
          await controller.getSelectedChapterAndBook();
          await controller.getBookContentForRead();

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
            await controller.getSelectedChapterAndBook();
            await controller.getBookContentForRead();
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

  /// Candidate verse lists for TTS. Full-book lists first so next/prev chapter
  /// can resolve; on-screen chapter last for instant open.
  /// Do not gate on book_num equality — selectedBookNum and verse.bookNum can
  /// differ by ±1 for some books after candidate loading.
  List<List<VerseBookContentModel>> _ttsVerseSources() {
    final sources = <List<VerseBookContentModel>>[];

    if (widget.contentList.isNotEmpty) {
      sources.add(widget.contentList);
    }

    if (Get.isRegistered<DashBoardController>()) {
      final c = Get.find<DashBoardController>();
      if (c.selectedVersesContent.isNotEmpty) {
        sources.add(c.selectedVersesContent);
      }
      if (c.selectedBookContent.isNotEmpty) {
        sources.add(c.selectedBookContent);
      }
    }

    return sources;
  }

  /// Detect 0-based chapters from the full book when possible (chapter-only
  /// lists often lack chapter 0, which wrongly looks 1-based).
  bool _ttsChaptersAreZeroBased(List<VerseBookContentModel> verses) {
    if (Get.isRegistered<DashBoardController>()) {
      final full = Get.find<DashBoardController>().selectedVersesContent;
      if (full.isNotEmpty) {
        return full.any((v) => (v.chapterNum ?? -1) == 0);
      }
    }
    return verses.any((v) => (v.chapterNum ?? -1) == 0);
  }

  /// Same 0-/1-based chapter matching as the reader controller.
  List<VerseBookContentModel> _filterTtsChapter(
    List<VerseBookContentModel> verses,
    int uiChapter,
  ) {
    if (verses.isEmpty) return [];
    final safe = uiChapter <= 0 ? 1 : uiChapter;
    final zeroBased = _ttsChaptersAreZeroBased(verses);
    final stored = zeroBased ? safe - 1 : safe;

    var matched =
        verses.where((v) => v.chapterNum?.toInt() == stored).toList();
    if (matched.isNotEmpty) return matched;

    // Mixed/legacy DBs: try the alternate basis once (same as controller).
    final alt = zeroBased ? safe : safe - 1;
    if (alt >= 0 && alt != stored) {
      matched = verses.where((v) => v.chapterNum?.toInt() == alt).toList();
      if (matched.isNotEmpty) return matched;
    }

    // Already chapter-scoped list: accept only if it is that UI chapter.
    final chapters = verses
        .map((v) => v.chapterNum?.toInt())
        .whereType<int>()
        .toSet();
    if (chapters.length == 1 &&
        (chapters.first == stored ||
            chapters.first == safe ||
            chapters.first + 1 == safe)) {
      return List<VerseBookContentModel>.from(verses);
    }
    return [];
  }

  List<VerseBookContentModel> _resolveTtsChapterVerses({
    bool preferReaderChapter = false,
  }) {
    final uiChapter = selectedChapter <= 0 ? 1 : selectedChapter;

    // When opening the TTS sheet, always prefer verses already on screen.
    // Fixes Loading/1/0 when selectedChapter or full-book cache is stale.
    // Next/prev chapter calls omit this flag so existing advance logic is unchanged.
    if (preferReaderChapter && Get.isRegistered<DashBoardController>()) {
      final onScreen = Get.find<DashBoardController>().selectedBookContent;
      if (onScreen.isNotEmpty) {
        return List<VerseBookContentModel>.from(onScreen);
      }
    }

    for (final source in _ttsVerseSources()) {
      final matched = _filterTtsChapter(source, uiChapter);
      if (matched.isNotEmpty) return matched;
    }
    return const <VerseBookContentModel>[];
  }

  /// Applies matched verses to TTS state. Synchronous so the sheet can open
  /// with content already filled when data is ready.
  void _applyTtsChapterContent(List<VerseBookContentModel> matched) {
    selectedChapterContent
      ..clear()
      ..addAll(matched);
    start = 0;
    end = isInitialTime ? 0 : (_newVoiceText?.length ?? 0);
    curretNo = 0;
    if (selectedChapterContent.isNotEmpty) {
      _newVoiceText = selectedChapterContent[0].content;
    }
  }

  Future<void> setChapterContent({bool preferReaderChapter = false}) async {
    // Instant when verses for selectedChapter are already in memory.
    var matched =
        _resolveTtsChapterVerses(preferReaderChapter: preferReaderChapter);
    if (matched.isNotEmpty) {
      if (!mounted) return;
      setState(() => _applyTtsChapterContent(matched));
      return;
    }

    // Slow path only when content is not ready yet (rare / first load).
    for (var attempt = 0; attempt < 10; attempt++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      matched =
          _resolveTtsChapterVerses(preferReaderChapter: preferReaderChapter);
      if (matched.isNotEmpty) break;
    }

    if (!mounted) return;
    setState(() => _applyTtsChapterContent(matched));
  }

  @override
  void dispose() {
    // Cancel all stream subscriptions to prevent setState after dispose
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _completeSubscription?.cancel();
    _sleepTimer?.cancel();
    _playerStateSubscription = null;
    _durationSubscription = null;
    _positionSubscription = null;
    _completeSubscription = null;
    _closeAudioSheetUi();
    _closeTtsSheetUi();
    _closeFullPlayerUi();

    // Stop TTS if running - safely check if flutterTts is initialized
    // Note: TTS handlers already check 'mounted' before calling setState, so they're safe
    // Playback stop is handled by HomeScreen.dispose via stopPlaybackOnLeave().

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
      // Assign only — never setState during build (causes dispose crashes
      // when Home is hidden while navigating to Settings).
      isPrevTTSEnabled = isTTSEnabled;
    }

    bool isMp3Enabled =
        widget.audioData?.data?.bibleAudioInfo?.isShowMp3Audio == "1";
    // TTS works offline; MP3 audio needs internet when selected from the chooser.
    if (widget.audioData?.data != null &&
        (isMp3Enabled || isTTSEnabled || isPrevTTSEnabled)) {
      return Container(
          height: screenWidth > 450 ? 50 : 35,
          width: screenWidth > 450 ? 50 : 35,
          decoration: BoxDecoration(
            color: CommanColor.whiteLightModePrimary(context),
            shape: BoxShape.circle,
            boxShadow: CommanColor.isDarkTheme(context)
                ? const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: GestureDetector(
            child: Center(
                child: (isSpeech ||
                        isPlaying ||
                        isAudioPlaying ||
                        ttsState == TtsState.playing)
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
              final isTTSActive =
                  isSpeech || isPlaying || ttsState == TtsState.playing;

              if (isTTSActive) {
                isManuallyPaused = true;
                shouldAutoAdvance = false;
                if (_isTtsInitialized) {
                  try {
                    await flutterTts.stop();
                  } catch (e) {
                    debugPrint("TTS stop error: $e");
                  }
                }
                if (mounted) {
                  setState(() {
                    ttsState = TtsState.stopped;
                    isSpeech = false;
                  });
                }
              } else if (isAudioPlaying) {
                try {
                  _audioResumePosition =
                      await audioPlayer.getCurrentPosition() ?? position;
                } catch (_) {
                  _audioResumePosition = position;
                }
                await audioPlayer.pause();
                setState(() {
                  isAudioPlaying = false;
                });
              } else if (audioPlayer.state == PlayerState.paused) {
                await audioPlayer.resume();
                _audioResumePosition = Duration.zero;
                if (mounted) {
                  setState(() {
                    isAudioPlaying = true;
                  });
                }
                if (mounted && !_isAudioSheetOpen) {
                  audioPlayerBottomSheet().then((value) {
                    if (mounted) {
                      setState(() {});
                    }
                  });
                }
              } else {
                _mp3Chosen = true;
                _readerUseTts = false;
                await setAudio();
                if (!mounted) return;
                setState(() {
                  audioLoad = false;
                });
                audioPlayerBottomSheet().then((value) {
                  if (mounted) {
                    setState(() {});
                  }
                });
              }

              await checknetwork();
            },
          ),
        );
    }
    return const SizedBox.shrink();
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

  Widget _textFromInput(int start, int end, String text) {
    if (text.isEmpty) return const SizedBox.shrink();

    final len = text.length;
    var safeStart = start.clamp(0, len);
    var safeEnd = end.clamp(0, len);
    if (safeEnd < safeStart) {
      safeEnd = safeStart;
    }
    // Display only: an empty range still paints the word at this position.
    if (safeStart >= safeEnd && len > 0) {
      var wordStart = safeStart >= len ? len - 1 : safeStart;
      while (wordStart > 0 && text[wordStart - 1].trim().isNotEmpty) {
        wordStart--;
      }
      var wordEnd = wordStart;
      while (wordEnd < len && text[wordEnd].trim().isNotEmpty) {
        wordEnd++;
      }
      if (wordEnd > wordStart) {
        safeStart = wordStart;
        safeEnd = wordEnd;
      }
    }

    final baseStyle = TextStyle(
      color: CommanColor.lightDarkPrimary(context),
      letterSpacing: BibleInfo.letterSpacing,
      fontSize: BibleInfo.fontSizeScale * 16,
      fontWeight: FontWeight.w500,
      height: 1.3,
    );

    if (safeStart >= safeEnd) {
      return Text(
        text,
        textAlign: TextAlign.center,
        style: baseStyle,
      );
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(children: <TextSpan>[
        if (safeStart > 0)
          TextSpan(text: text.substring(0, safeStart), style: baseStyle),
        TextSpan(
          text: text.substring(safeStart, safeEnd),
          style: CommanStyle.HighLightWordStyle(context),
        ),
        if (safeEnd < len)
          TextSpan(text: text.substring(safeEnd), style: baseStyle),
      ]),
    );
  }

  Future audioPlayerBottomSheet() async {
    print("=== AUDIO BOTTOM SHEET: Opening ===");
    print("AUDIO: widget.bookName = '${widget.bookName}'");
    print("AUDIO: widget.bookNum = ${widget.bookNum}");
    print("AUDIO: widget.chapterNum = ${widget.chapterNum}");
    print("AUDIO: Current _storedBookName = '$_storedBookName'");
    print("AUDIO: Current audioBookNum = $audioBookNum");
    print("AUDIO: Current audioChapterNum = $audioChapterNum");

    // Sync audio position with current reading position before opening bottom sheet
    try {
      final currentBookNum = int.parse(widget.bookNum.toString());
      final currentChapterNum = int.parse(widget.chapterNum);
      String? currentBookName;

      // Get current book name from controller, widget, or SharedPreferences
      if (Get.isRegistered<DashBoardController>()) {
        final controller = Get.find<DashBoardController>();
        if (controller.selectedBook.value.isNotEmpty) {
          currentBookName = controller.selectedBook.value;
          print("AUDIO: Got book name from controller: '$currentBookName'");
        }
      }

      if (currentBookName == null || currentBookName.isEmpty) {
        if (widget.bookName.isNotEmpty) {
          currentBookName = widget.bookName;
          print("AUDIO: Got book name from widget: '$currentBookName'");
        } else {
          currentBookName =
              await SharPreferences.getString(SharPreferences.selectedBook);
          print(
              "AUDIO: Got book name from SharedPreferences: '$currentBookName'");
        }
      }

      // Update audioBookNum, audioChapterNum, and _storedBookName to match current reading position
      if (mounted) {
        setState(() {
          audioBookNum = currentBookNum + 1;
          audioChapterNum = currentChapterNum;
          currentBookChapterCount =
            int.tryParse(widget.chapterCount.toString()) ??
                currentBookChapterCount;
          if (currentBookName != null && currentBookName.isNotEmpty) {
            _storedBookName = currentBookName;
            print("AUDIO: Updated _storedBookName to: '$_storedBookName'");
          }
        });
      }

      print(
          "AUDIO: After sync - audioBookNum = $audioBookNum, audioChapterNum = $audioChapterNum");
      print("AUDIO: After sync - _storedBookName = '$_storedBookName'");
    } catch (e) {
      print("AUDIO: Error syncing audio position: $e");
      debugPrint("Error syncing audio position: $e");
    }

    // Additional refresh of _storedBookName from controller first (most current), then widget.bookName, then SharedPreferences
    try {
      String? finalBookName;

      // Always try to get from controller first (source of truth)
      if (Get.isRegistered<DashBoardController>()) {
        final controller = Get.find<DashBoardController>();
        if (controller.selectedBook.value.isNotEmpty) {
          finalBookName = controller.selectedBook.value;
          print(
              "AUDIO: Final check - got book from controller: '$finalBookName'");
        }
      }

      // Fallback to widget.bookName if controller doesn't have it
      if ((finalBookName == null || finalBookName.isEmpty) &&
          widget.bookName.isNotEmpty) {
        finalBookName = widget.bookName;
        print("AUDIO: Final check - got book from widget: '$finalBookName'");
      }

      // Fallback to SharedPreferences if both above are empty
      if (finalBookName == null || finalBookName.isEmpty) {
        finalBookName =
            await SharPreferences.getString(SharPreferences.selectedBook);
        print(
            "AUDIO: Final check - got book from SharedPreferences: '$finalBookName'");
      }

      // Update _storedBookName once with the final value
      if (finalBookName != null && finalBookName.isNotEmpty && mounted) {
        setState(() {
          _storedBookName = finalBookName;
        });
        print("AUDIO: Final _storedBookName set to: '$_storedBookName'");
        // Small delay to ensure setState completes before showing modal
        await Future.delayed(const Duration(milliseconds: 50));
      }
    } catch (e) {
      print("AUDIO: Error refreshing book name: $e");
      debugPrint("Error refreshing book name: $e");
    }

    print(
        "AUDIO: About to show modal - _storedBookName = '$_storedBookName', audioChapterNum = $audioChapterNum");

    // local flags/subscriptions that persist for the sheet's lifetime
    bool listenersAttached = false;
    StreamSubscription<Duration>? positionSub;
    StreamSubscription<Duration>? durationSub;

    // Additive: completion listener lives on State so minimize keeps auto-next.
    _ensureMp3CompletionListener();
    _isAudioSheetOpen = true;
    _audioSheetUiAlive = true;

    return showModalBottomSheet(
      backgroundColor: Colors.black12,
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          // Let State completion handler refresh this sheet UI when open.
          _audioSheetSetState = (fn) {
            if (!_audioSheetUiAlive) return;
            setState(fn);
          };

          // Attach listeners only once for this sheet
          if (!listenersAttached) {
            listenersAttached = true;

            // Position updates
            positionSub = audioPlayer.onPositionChanged.listen((p) {
              if (!_audioSheetUiAlive) return;
              setState(() {
                position = p;
              });
            });

            // Duration updates (when a new source loads this will fire)
            durationSub = audioPlayer.onDurationChanged.listen((d) {
              if (!_audioSheetUiAlive) return;
              setState(() {
                duration = d;
              });
            });
          } // end attach listeners

          // Build UI
          return PopScope(
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) _closeAudioSheetUi();
            },
            child: Container(
            height: 148,
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
                    SizedBox(
                      width: 60,
                    ),
                    Expanded(
                      child: Builder(
                      builder: (context) {
                        print(
                            "=== AUDIO BUILDER: Building book name display ===");
                        print(
                            "BUILDER: widget.bookName = '${widget.bookName}'");
                        print("BUILDER: _storedBookName = '$_storedBookName'");
                        print("BUILDER: audioChapterNum = $audioChapterNum");

                        String bookName = '';
                        if (widget.bookName.isNotEmpty) {
                          bookName = widget.bookName;
                          print("BUILDER: Using widget.bookName = '$bookName'");
                        } else if (_storedBookName != null &&
                            _storedBookName!.isNotEmpty) {
                          bookName = _storedBookName!;
                          print("BUILDER: Using _storedBookName = '$bookName'");
                        } else if (Get.isRegistered<DashBoardController>()) {
                          final controller = Get.find<DashBoardController>();
                          if (controller.selectedBook.value.isNotEmpty) {
                            bookName = controller.selectedBook.value;
                            print(
                                "BUILDER: Using controller book = '$bookName'");
                          }
                        }

                        print(
                            "BUILDER: Final display = '$bookName - $audioChapterNum'");

                        return Text(
                          "$bookName - $audioChapterNum",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: CommanColor.lightDarkPrimary(context),
                              letterSpacing: BibleInfo.letterSpacing,
                              fontSize: BibleInfo.fontSizeScale * 14,
                              fontWeight: FontWeight.w600),
                        );
                      },
                    ),
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
                          // Reader first, then audio UI/file.
                          final prevChapter = audioChapterNum - 1;
                          if (mounted) {
                            setState(() {
                              isAudioPlaying = false;
                            });
                          }
                          await updateReadingScreenChapter(prevChapter);
                          if (!mounted || !context.mounted) return;
                          final nextUrl =
                              "${_recordedAudioBase()}/$audioBookNum/$prevChapter.mp3";
                          setState(() {
                            audioChapterNum = prevChapter;
                            audioBaseUrl = nextUrl;
                          });
                          // Refresh book name after chapter update
                          try {
                            if (Get.isRegistered<DashBoardController>()) {
                              final controller =
                                  Get.find<DashBoardController>();
                              if (controller.selectedBook.value.isNotEmpty &&
                                  mounted) {
                                setState(() {
                                  _storedBookName =
                                      controller.selectedBook.value;
                                });
                              }
                            }
                          } catch (e) {
                            debugPrint(
                                "Error refreshing book name in Prev button: $e");
                          }
                          // Stop TTS if it's playing
                          if (isSpeech && _isTtsInitialized) {
                            await _stop();
                            if (context.mounted) {
                              setState(() {
                                isSpeech = false;
                              });
                            }
                          }
                          try {
                            await audioPlayer.setSourceUrl(audioBaseUrl);
                            await audioPlayer.seek(Duration.zero);
                            _audioResumePosition = Duration.zero;
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
                          _audioResumePosition = Duration.zero;
                          // If audio was stopped previously the source may have been
                          // cleared by the player. Ensure the source is set before
                          // calling resume so audio actually starts.
                          try {
                            if (duration == Duration.zero) {
                              // If we don't have a loaded duration, try to (re)load
                              // the source. Prefer using the current audioBaseUrl
                              // if available, otherwise fall back to setAudio().
                              if (audioBaseUrl.isNotEmpty) {
                                await audioPlayer.setSourceUrl(audioBaseUrl);
                                await audioPlayer.seek(Duration.zero);
                              } else {
                                await setAudio();
                              }
                            }

                            await audioPlayer.resume();
                            if (context.mounted) {
                              setState(() => isAudioPlaying = true);
                            }
                          } catch (e) {
                            debugPrint('Error resuming audio: $e');
                            // Fallback: try to set the source explicitly then resume.
                            try {
                              if (audioBaseUrl.isNotEmpty) {
                                await audioPlayer.setSourceUrl(audioBaseUrl);
                                await audioPlayer.seek(Duration.zero);
                                await audioPlayer.resume();
                                if (context.mounted) {
                                  setState(() => isAudioPlaying = true);
                                }
                              }
                            } catch (err) {
                              debugPrint('Fallback resume failed: $err');
                              if (context.mounted) {
                                setState(() => isAudioPlaying = false);
                              }
                            }
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
                          try {
                            _audioResumePosition =
                                await audioPlayer.getCurrentPosition() ??
                                    position;
                          } catch (_) {
                            _audioResumePosition = position;
                          }
                          await audioPlayer.pause();
                          if (context.mounted) {
                            setState(() => isAudioPlaying = false);
                          }
                        } else {
                          // Check internet connection before playing audio
                          final hasInternet =
                              await InternetConnection().hasInternetAccess;
                          if (!hasInternet) {
                            Constants.showToast(
                                "Check your internet connection.");
                            return;
                          }
                          // Stop TTS if it's playing before starting audio
                          if (isSpeech && _isTtsInitialized) {
                            await _stop();
                            if (context.mounted) {
                              setState(() {
                                isSpeech = false;
                              });
                            }
                          }
                          // Resume from pause without reloading (keeps position).
                          if (audioPlayer.state == PlayerState.paused) {
                            await audioPlayer.resume();
                          } else if (audioPlayer.state == PlayerState.stopped &&
                              audioBaseUrl.isNotEmpty) {
                            // Source cleared after stop — reload, but restore
                            // paused position when we have one (else start at 0).
                            final resumeAt = _audioResumePosition > Duration.zero
                                ? _audioResumePosition
                                : (position > Duration.zero
                                    ? position
                                    : Duration.zero);
                            await setAudio(seekTo: resumeAt);
                            await audioPlayer.resume();
                          } else {
                            await audioPlayer.resume();
                          }
                          _audioResumePosition = Duration.zero;
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
                        final lastChapter =
                            int.tryParse(widget.chapterCount) ??
                                currentBookChapterCount;
                        if (audioChapterNum < lastChapter) {
                          // Reader first, then audio UI/file.
                          final nextChapter = audioChapterNum + 1;
                          if (mounted) {
                            setState(() {
                              isAudioPlaying = false;
                            });
                          }
                          await updateReadingScreenChapter(nextChapter);
                          if (!mounted || !context.mounted) return;
                          final nextUrl =
                              "${_recordedAudioBase()}/$audioBookNum/$nextChapter.mp3";
                          setState(() {
                            audioChapterNum = nextChapter;
                            audioBaseUrl = nextUrl;
                          });
                          // Refresh book name after chapter update
                          try {
                            if (Get.isRegistered<DashBoardController>()) {
                              final controller =
                                  Get.find<DashBoardController>();
                              if (controller.selectedBook.value.isNotEmpty &&
                                  mounted) {
                                setState(() {
                                  _storedBookName =
                                      controller.selectedBook.value;
                                });
                              }
                            }
                          } catch (e) {
                            debugPrint(
                                "Error refreshing book name in Next button: $e");
                          }
                          // Stop TTS if it's playing
                          if (isSpeech && _isTtsInitialized) {
                            await _stop();
                            if (context.mounted) {
                              setState(() {
                                isSpeech = false;
                              });
                            }
                          }
                          try {
                            await audioPlayer.setSourceUrl(audioBaseUrl);
                            await audioPlayer.seek(Duration.zero);
                            _audioResumePosition = Duration.zero;
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
                      },
                    ),

                    // stop
                    Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: InkWell(
                        onTap: () async {
                          await audioPlayer.stop();
                          _audioResumePosition = Duration.zero;
                          position = Duration.zero;
                          if (_audioSheetUiAlive) {
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
          ),
          );
        });
      },
    ).then((value) {
      // sheet closed: cancel sheet-local listeners only (keep completion for auto-next).
      _isAudioSheetOpen = false;
      _closeAudioSheetUi();
      if (positionSub != null) {
        positionSub!.cancel();
        positionSub = null;
      }
      if (durationSub != null) {
        durationSub!.cancel();
        durationSub = null;
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
  //                         "${_recordedAudioBase().toString()}/$audioBookNum/$audioChapterNum.mp3";
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
  //                                   "${_recordedAudioBase().toString()}/$audioBookNum/$audioChapterNum.mp3";
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
  //                                     "${_recordedAudioBase().toString()}/$audioBookNum/$audioChapterNum.mp3";
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
      if (availableVoices != null &&
          availableVoices!.isNotEmpty &&
          selectedVoice == null) {
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

                  if (!_showTtsUi())
                    FutureBuilder<bool>(
                      future: _englishAudioLoads ??= _englishBibleAudioLoads(),
                      builder: (context, snapshot) {
                        final bibleLabel = _recordedAudioVoiceLabel();
                        final englishUrl = BibleInfo.englishBibleAudio.trim();
                        final showEnglish = false;
                        if (!showEnglish) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: CommanColor.lightGrey,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Default',
                              style: TextStyle(
                                color: CommanColor.lightDarkPrimary(context),
                                letterSpacing: BibleInfo.letterSpacing,
                                fontSize: BibleInfo.fontSizeScale * 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        final choices = <String>[
                          bibleLabel,
                          _fallbackAudioLanguageLabel(englishUrl),
                        ];
                        final selected = choices.contains(_audioSettingsChoice)
                            ? _audioSettingsChoice!
                            : bibleLabel;
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: CommanColor.lightGrey,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: selected,
                            underline: const SizedBox(),
                            dropdownColor: Colors.white,
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: CommanColor.lightDarkPrimary(context),
                            ),
                            items: choices
                                .map(
                                  (choice) => DropdownMenuItem<String>(
                                    value: choice,
                                    child: Text(
                                      choice,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.black,
                                        letterSpacing: BibleInfo.letterSpacing,
                                        fontSize: BibleInfo.fontSizeScale * 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setModalState(() {
                                _audioSettingsChoice = value;
                              });
                            },
                          ),
                        );
                      },
                    )
                  else
                  FutureBuilder<List<dynamic>>(
                    future: _getVoices(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        // Remove duplicates based on display name (what users see)
                        // This prevents duplicate narrator names from appearing
                        List<dynamic> uniqueVoices = [];
                        Set<String> seenDisplayNames =
                            {}; // Track display names to prevent duplicates

                        // Allowed voice names (case-insensitive)
                        final allowedVoiceNames = [
                          'Rishi',
                          'Daniel',
                          'Karen',
                          'Samantha'
                        ];

                        for (var voice in snapshot.data!) {
                          // Get the display name that will be shown to users
                          String displayName = _getVoiceDisplayName(voice);
                          String displayNameLower = displayName.toLowerCase();

                          // Only include voices with allowed names (check if display name contains any allowed name)
                          bool isAllowedVoice = allowedVoiceNames.any(
                              (allowedName) => displayNameLower
                                  .contains(allowedName.toLowerCase()));

                          // Only add if it's an allowed voice and we haven't seen this display name before
                          if (isAllowedVoice &&
                              !seenDisplayNames.contains(displayName)) {
                            seenDisplayNames.add(displayName);
                            uniqueVoices.add(voice);
                          }
                        }

                        // If no unique voices found, use original list
                        if (uniqueVoices.isEmpty) {
                          uniqueVoices = snapshot.data!;
                        }

                        // Find matching selectedVoice by identifier
                        dynamic matchedSelectedVoice;
                        if (selectedVoice != null &&
                            selectedVoice is Map &&
                            uniqueVoices.isNotEmpty) {
                          String? selectedIdentifier =
                              selectedVoice['identifier']?.toString();
                          if (selectedIdentifier != null) {
                            try {
                              matchedSelectedVoice = uniqueVoices.firstWhere(
                                (voice) {
                                  if (voice is Map) {
                                    return voice['identifier']?.toString() ==
                                        selectedIdentifier;
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
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
                                  isDefault
                                      ? "$displayName (Default)"
                                      : displayName,
                                  style: TextStyle(
                                    color: Colors.black,
                                    letterSpacing: BibleInfo.letterSpacing,
                                    fontSize: BibleInfo.fontSizeScale * 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (dynamic newValue) async {
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
                                  await flutterTts.setVoice(voiceMap);
                                } else {
                                  await flutterTts.setVoice(newValue);
                                }
                                // Additive: play preview when voice changes (button removed).
                                await _previewVoice();
                              }
                              setState(() {});
                            },
                            selectedItemBuilder: (BuildContext context) {
                              return uniqueVoices.map<Widget>((voice) {
                                String displayName =
                                    _getVoiceDisplayName(voice);
                                bool isDefault = voice == uniqueVoices.first;
                                return Text(
                                  isDefault
                                      ? "$displayName (Default)"
                                      : displayName,
                                  style: TextStyle(
                                    color:
                                        CommanColor.lightDarkPrimary(context),
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
                              for (var i = 0;
                                  i < langSnapshot.data.length;
                                  i++) {
                                if (langSnapshot.data[i]
                                        .toString()
                                        .split("-")
                                        .first ==
                                    "en") {
                                  langList.add(langSnapshot.data[i]);
                                }
                              }
                              if (langList.isNotEmpty && language == null) {
                                language = langList[0];
                              }
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
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
                                    color:
                                        CommanColor.lightDarkPrimary(context),
                                  ),
                                  items: langList.map((lang) {
                                    var languageConvert = LanguageLocal()
                                        .getDisplayLanguage(
                                            lang.toString().split("-").first);
                                    String displayName =
                                        languageConvert["name"] ??
                                            lang.toString();
                                    bool isDefault = lang == langList[0];
                                    return DropdownMenuItem<String>(
                                      value: lang.toString(),
                                      child: Text(
                                        isDefault
                                            ? "$displayName (Default)"
                                            : displayName,
                                        style: TextStyle(
                                          color: CommanColor.lightDarkPrimary(
                                              context),
                                          letterSpacing:
                                              BibleInfo.letterSpacing,
                                          fontSize:
                                              BibleInfo.fontSizeScale * 16,
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
                  if (_showTtsUi()) ...[
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
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 7),
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
                  ],
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
                        _showTtsUi()
                            ? "${(rate * 2).toStringAsFixed(1)}x"
                            : "${_playbackSpeed.toStringAsFixed(1)}x",
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
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 7),
                    ),
                    child: Slider(
                      activeColor: CommanColor.lightDarkPrimary(context),
                      inactiveColor: CommanColor.lightGrey,
                      thumbColor: CommanColor.lightDarkPrimary(context),
                      value: _showTtsUi()
                          ? rate
                          : _playbackSpeed.clamp(0.5, 2.0),
                      onChanged: (newRate) {
                        if (_showTtsUi()) {
                          setModalState(() {
                            rate = newRate;
                          });
                          flutterTts.setSpeechRate(newRate);
                        } else {
                          setModalState(() {
                            _playbackSpeed = newRate;
                          });
                          audioPlayer.setPlaybackRate(newRate);
                        }
                      },
                      min: _showTtsUi() ? 0.0 : 0.5,
                      max: _showTtsUi() ? 1.0 : 2.0,
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
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 7),
                    ),
                    child: Slider(
                      activeColor: CommanColor.lightDarkPrimary(context),
                      inactiveColor: CommanColor.lightGrey,
                      thumbColor: CommanColor.lightDarkPrimary(context),
                      value: volume,
                      onChanged: (newVolume) {
                        setModalState(() {
                          volume = newVolume;
                        });
                        _applyOutputVolume(newVolume);
                      },
                      onChangeEnd: (newVolume) {
                        volume = newVolume;
                        if (_showTtsUi()) {
                          _applyTtsVolumeLive();
                        }
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
                        if (_showTtsUi()) {
                          pitch = 1.25;
                          rate = 0.5;
                          flutterTts.setSpeechRate(rate);
                          flutterTts.setPitch(pitch);
                        } else {
                          _playbackSpeed = 1.0;
                          _applyOutputVolume(volume);
                          audioPlayer.setPlaybackRate(_playbackSpeed);
                        }
                      });
                      if (_showTtsUi()) {
                        _applyTtsVolumeLive();
                      }
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

  Future textToSpeechBottomSheet() async {
    // Sync audio position with current reading position before opening bottom sheet
    try {
      final currentBookNum = int.parse(widget.bookNum.toString());
      // Prefer controller chapter (what the reader shows) over possibly stale
      // local TTS selectedChapter / widget props.
      int currentChapterNum = int.tryParse(widget.chapterNum) ?? selectedChapter;
      if (Get.isRegistered<DashBoardController>()) {
        final fromController = int.tryParse(
            Get.find<DashBoardController>().selectedChapter.value);
        if (fromController != null && fromController > 0) {
          currentChapterNum = fromController;
        }
      }
      String? currentBookName;

      // Get current book name from controller, widget, or SharedPreferences
      if (Get.isRegistered<DashBoardController>()) {
        final controller = Get.find<DashBoardController>();
        if (controller.selectedBook.value.isNotEmpty) {
          currentBookName = controller.selectedBook.value;
        }
      }

      if (currentBookName == null || currentBookName.isEmpty) {
        if (widget.bookName.isNotEmpty) {
          currentBookName = widget.bookName;
        } else {
          currentBookName =
              await SharPreferences.getString(SharPreferences.selectedBook);
        }
      }

      // Update audioBookNum, audioChapterNum, and _storedBookName to match current reading position
      if (mounted) {
        setState(() {
          audioBookNum = currentBookNum + 1;
          audioChapterNum = currentChapterNum;
          // Keep TTS selectedChapter on the chapter the user is reading
          selectedChapter = currentChapterNum;
          currentBookChapterCount =
            int.tryParse(widget.chapterCount.toString()) ??
                currentBookChapterCount;
          if (currentBookName != null && currentBookName.isNotEmpty) {
            _storedBookName = currentBookName;
          }
        });
      }
    } catch (e) {
      debugPrint("Error syncing audio position: $e");
    }

    // Ensure chapter verses are ready before the sheet paints (avoids 1/0 Loading
    // on books that use a different chapter_num basis or load slightly later).
    try {
      await setChapterContent(preferReaderChapter: true);
    } catch (e) {
      debugPrint("Error preparing TTS chapter content: $e");
    }

    // Additional refresh of _storedBookName from widget.bookName first, then controller, then SharedPreferences
    try {
      String? finalBookName;

      // Always try to get from controller first (source of truth)
      if (Get.isRegistered<DashBoardController>()) {
        final controller = Get.find<DashBoardController>();
        if (controller.selectedBook.value.isNotEmpty) {
          finalBookName = controller.selectedBook.value;
        }
      }

      // Fallback to widget.bookName if controller doesn't have it
      if ((finalBookName == null || finalBookName.isEmpty) &&
          widget.bookName.isNotEmpty) {
        finalBookName = widget.bookName;
      }

      // Fallback to SharedPreferences if both above are empty
      if (finalBookName == null || finalBookName.isEmpty) {
        finalBookName =
            await SharPreferences.getString(SharPreferences.selectedBook);
      }

      // Update _storedBookName once with the final value
      if (finalBookName != null && finalBookName.isNotEmpty && mounted) {
        setState(() {
          _storedBookName = finalBookName;
        });
      }
    } catch (e) {
      debugPrint("Error refreshing book name: $e");
    }

    if (widget.textToSpeechLoad == false) {
      _ttsSheetUiAlive = true;
      return showModalBottomSheet(
        backgroundColor: Colors.black12,
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              void setState(VoidCallback fn) {
                if (!context.mounted) {
                  fn();
                  return;
                }
                setModalState(fn);
              }

              _ttsSheetSetState = (fn) {
                if (!_ttsSheetUiAlive) return;
                setState(fn);
              };
              return PopScope(
                onPopInvokedWithResult: (didPop, _) {
                  if (didPop) _closeTtsSheetUi();
                },
                child: Container(
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
                          SizedBox(
                            width: 80,
                          ),
                          Expanded(
                            child: Builder(
                            builder: (context) {
                              String bookName = '';
                              if (widget.bookName.isNotEmpty) {
                                bookName = widget.bookName;
                              } else if (_storedBookName != null &&
                                  _storedBookName!.isNotEmpty) {
                                bookName = _storedBookName!;
                              } else if (Get.isRegistered<
                                  DashBoardController>()) {
                                final controller =
                                    Get.find<DashBoardController>();
                                if (controller.selectedBook.value.isNotEmpty) {
                                  bookName = controller.selectedBook.value;
                                }
                              }
                              return Text(
                                "$bookName $selectedChapter - ${curretNo + 1}/${selectedChapterContent.length}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color:
                                        CommanColor.lightDarkPrimary(context),
                                    letterSpacing: BibleInfo.letterSpacing,
                                    fontSize: BibleInfo.fontSizeScale * 14,
                                    fontWeight: FontWeight.w600),
                              );
                            },
                          ),
                          ),
                          Row(
                            children: [
                              InkWell(
                                  onTap: () {
                                    _showCombinedVoiceSettingsSheet();
                                  },
                                  child: _voiceMicIcon(
                                    CommanColor.lightDarkPrimary(context),
                                    size: 22,
                                  )),
                              const SizedBox(
                                width: 10,
                              ),
                              InkWell(
                                  onTap: () {
                                    _closeTtsSheetUi();
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
                          child: _showTtsWordHighlight
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
                                  if (isTTSLoop) {
                                    shouldAutoAdvance = true;
                                  }
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
                                      isManualNavigation =
                                          true; // Mark as manual navigation to prevent double increment
                                      shouldAutoAdvance =
                                          true; // Re-enable auto-advance after manual navigation
                                    });
                                    // Wait for setState to complete
                                    await Future.delayed(
                                        const Duration(milliseconds: 50));
                                    // Load chapter content and wait for it to complete
                                    await setChapterContent();
                                    await updateReadingScreenChapter(
                                        selectedChapter);
                                    if (mounted &&
                                        selectedChapterContent.isNotEmpty &&
                                        curretNo >= 0 &&
                                        curretNo <
                                            selectedChapterContent.length) {
                                      setState(() {
                                        _newVoiceText =
                                            selectedChapterContent[curretNo]
                                                .content;
                                      });
                                      // Wait for UI to update before speaking
                                      await Future.delayed(
                                          const Duration(milliseconds: 50));
                                      if (mounted &&
                                          isSpeech &&
                                          _newVoiceText != null &&
                                          _newVoiceText!.isNotEmpty) {
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
                              if (curretNo > 0 &&
                                  selectedChapterContent.isNotEmpty) {
                                // Go to previous verse in current chapter
                                if (mounted) {
                                  setState(() {
                                    curretNo = curretNo - 1;
                                    if (curretNo >= 0 &&
                                        curretNo <
                                            selectedChapterContent.length) {
                                      _newVoiceText =
                                          selectedChapterContent[curretNo]
                                              .content;
                                    }
                                    isManualNavigation =
                                        true; // Mark as manual navigation to prevent double increment
                                    shouldAutoAdvance =
                                        true; // Re-enable auto-advance after manual navigation
                                  });
                                  // Wait for UI to update before speaking
                                  await Future.delayed(
                                      const Duration(milliseconds: 50));
                                  if (mounted &&
                                      isSpeech &&
                                      _newVoiceText != null &&
                                      _newVoiceText!.isNotEmpty) {
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
                                    curretNo =
                                        0; // Reset to 0, will be set after content loads
                                    isManualNavigation =
                                        true; // Mark as manual navigation to prevent double increment
                                    shouldAutoAdvance =
                                        true; // Re-enable auto-advance after manual navigation
                                  });
                                  // Wait for setState to complete
                                  await Future.delayed(
                                      const Duration(milliseconds: 50));
                                  // Load chapter content and wait for it to complete
                                  await setChapterContent();
                                  await updateReadingScreenChapter(
                                      selectedChapter);
                                  if (mounted &&
                                      selectedChapterContent.isNotEmpty) {
                                    setState(() {
                                      curretNo =
                                          selectedChapterContent.length - 1;
                                      if (curretNo >= 0 &&
                                          curretNo <
                                              selectedChapterContent.length) {
                                        _newVoiceText =
                                            selectedChapterContent[curretNo]
                                                .content;
                                      }
                                    });
                                    // Wait for UI to update before speaking
                                    await Future.delayed(
                                        const Duration(milliseconds: 50));
                                    if (mounted &&
                                        isSpeech &&
                                        _newVoiceText != null &&
                                        _newVoiceText!.isNotEmpty) {
                                      _speak();
                                    }
                                  }
                                }
                              }
                              // If at chapter 1 and first verse, do nothing (already at beginning)
                            },
                          ),
                          InkWell(
                              onTap: () async {
                                if (!mounted) return;
                                if (mounted) {
                                  setState(() {
                                    isInitialProgress = isInitialProgress + 1;
                                    isSpeech = !isSpeech;
                                    // Reset manual pause flag when user manually starts TTS
                                    if (isSpeech) {
                                      isManuallyPaused = false;
                                      shouldAutoAdvance =
                                          true; // Re-enable auto-advance when playing
                                    } else {
                                      isManuallyPaused =
                                          true; // Set manual pause flag when user pauses
                                      shouldAutoAdvance =
                                          false; // Disable auto-advance when paused
                                    }
                                  });
                                }

                                if (isSpeech == true) {
                                  // Stop audio if it's playing before starting TTS
                                  if (isAudioPlaying) {
                                    await audioPlayer.stop();
                                    if (mounted) {
                                      setState(() {
                                        isAudioPlaying = false;
                                        _wasAudioPlayingBeforeClose =
                                            false; // Reset flag since we stopped it
                                      });
                                    }
                                  }
                                  await _speak();
                                  if (context.mounted) {
                                    setState(() {});
                                  }
                                } else {
                                  await _pauseTts();
                                  if (context.mounted) {
                                    setState(() {});
                                  }
                                }
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
                              // Save TTS playing state before moving to next verse
                              final wasTTSPlaying =
                                  isSpeech || ttsState == TtsState.playing;

                              // Stop current TTS without resetting isSpeech state (for next verse continuation)
                              if (_isTtsInitialized && wasTTSPlaying) {
                                _ignoreTtsEngineEvents();
                                try {
                                  await flutterTts.stop();
                                  debugPrint(
                                      'Next verse: Stopped current TTS, will continue with next verse');
                                } catch (e) {
                                  debugPrint(
                                      "TTS stop error in next verse: $e");
                                }
                              }

                              if (mounted) {
                                if (curretNo <
                                    selectedChapterContent.length - 1) {
                                  // Move to next verse
                                  setState(() {
                                    curretNo = curretNo + 1;
                                    _newVoiceText =
                                        selectedChapterContent[curretNo]
                                            .content;
                                    isManualNavigation =
                                        true; // Mark as manual navigation to prevent double increment
                                    shouldAutoAdvance =
                                        true; // Re-enable auto-advance after manual navigation
                                    // Preserve TTS playing state for automatic continuation
                                    if (wasTTSPlaying) {
                                      isSpeech = true;
                                      ttsState = TtsState
                                          .stopped; // Will be set to playing when _speak() starts
                                    }
                                  });
                                  // Wait for UI to update before speaking
                                  await Future.delayed(
                                      const Duration(milliseconds: 50));
                                  // Continue playing next verse if TTS was playing before
                                  if (mounted &&
                                      wasTTSPlaying &&
                                      _newVoiceText != null &&
                                      _newVoiceText!.isNotEmpty) {
                                    _speak();
                                  }
                                } else {
                                  // Reached last verse - show toast and restart from verse 1 of same chapter
                                  Constants.showToast("Reached End");
                                  setState(() {
                                    curretNo = 0;
                                    if (selectedChapterContent.isNotEmpty) {
                                      _newVoiceText =
                                          selectedChapterContent[0].content;
                                    }
                                    isManualNavigation = true;
                                    shouldAutoAdvance = true;
                                    // Preserve TTS playing state for automatic continuation
                                    if (wasTTSPlaying) {
                                      isSpeech = true;
                                      ttsState = TtsState
                                          .stopped; // Will be set to playing when _speak() starts
                                    }
                                  });
                                  // Wait for UI to update before speaking
                                  await Future.delayed(
                                      const Duration(milliseconds: 50));
                                  // Continue playing if TTS was playing before
                                  if (mounted &&
                                      wasTTSPlaying &&
                                      _newVoiceText != null &&
                                      _newVoiceText!.isNotEmpty) {
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
                                    final wasSpeaking =
                                        isSpeech || ttsState == TtsState.playing;
                                    _ignoreTtsEngineEvents();
                                    await _stop();
                                    // Clear old voice text to prevent speaking old verse
                                    _newVoiceText = null;
                                    setState(() {
                                      selectedChapter++;
                                      curretNo = 0;
                                      isManualNavigation =
                                          true; // Mark as manual navigation to prevent double increment
                                      shouldAutoAdvance =
                                          true; // Re-enable auto-advance after manual navigation
                                      // _stop() clears isSpeech; restore when we intend to continue.
                                      if (wasSpeaking) {
                                        isSpeech = true;
                                        isManuallyPaused = false;
                                      }
                                    });
                                    // Wait for setState to complete
                                    await Future.delayed(
                                        const Duration(milliseconds: 50));
                                    // Load chapter content and wait for it to complete
                                    await setChapterContent();
                                    await updateReadingScreenChapter(
                                        selectedChapter);
                                    if (mounted &&
                                        selectedChapterContent.isNotEmpty &&
                                        curretNo >= 0 &&
                                        curretNo <
                                            selectedChapterContent.length) {
                                      setState(() {
                                        _newVoiceText =
                                            selectedChapterContent[curretNo]
                                                .content;
                                      });
                                      // Wait for UI to update before speaking
                                      await Future.delayed(
                                          const Duration(milliseconds: 50));
                                      if (mounted &&
                                          wasSpeaking &&
                                          !isManuallyPaused &&
                                          _newVoiceText != null &&
                                          _newVoiceText!.isNotEmpty) {
                                        if (!isSpeech) {
                                          setState(() => isSpeech = true);
                                        }
                                        await _speak();
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
                                        _newVoiceText =
                                            selectedChapterContent[0].content;
                                      }
                                      isManualNavigation = true;
                                      shouldAutoAdvance = true;
                                    });
                                    // Wait for UI to update before speaking
                                    await Future.delayed(
                                        const Duration(milliseconds: 50));
                                    if (mounted &&
                                        isSpeech &&
                                        _newVoiceText != null &&
                                        _newVoiceText!.isNotEmpty) {
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
                                if (!_ttsSheetUiAlive) return;
                                setState(() {
                                  isSpeech = false;
                                  shouldAutoAdvance =
                                      false; // Prevent auto-advancement when stopped
                                });
                                _stop();
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
                ),
              );
            },
          );
        },
      ).then((value) {
        _closeTtsSheetUi();
        if (mounted && context.mounted) {
          setState(() {});
        }
      });
    } else {
      return Constants.showToast("Please wait");
    }
  }

  bool _mp3On() =>
      widget.audioData?.data?.bibleAudioInfo?.isShowMp3Audio == "1";

  bool _ttsOn() {
    final info = widget.audioData?.data?.bibleAudioInfo;
    if (info == null) return isPrevTTSEnabled;
    if (Platform.isAndroid) {
      return info.isTextToSpeechAvailableAndroid == "1";
    }
    return info.isTextToSpeechAvailableIos == "1";
  }

  bool _showTtsUi() {
    if (_fullScreenTts != null) return _fullScreenTts!;
    if (_readerUseTts) return true;
    if (isAudioPlaying || audioPlayer.state == PlayerState.paused) {
      return false;
    }
    if (isSpeech ||
        ttsState == TtsState.playing ||
        ttsState == TtsState.paused) {
      return true;
    }
    return _ttsOn() && !_mp3On();
  }

  int _chapterTotal() =>
      int.tryParse(widget.chapterCount) ?? currentBookChapterCount;

  int _shownChapter(bool ttsUi) {
    if (ttsUi) {
      if (selectedChapter > 0) return selectedChapter;
    }
    return audioChapterNum;
  }

  String _readerTitle(bool ttsUi) {
    var name = widget.bookName.trim();
    if (name.isEmpty) name = (_storedBookName ?? '').trim();
    final chapter = _shownChapter(ttsUi);
    if (name.isEmpty) return 'Chapter $chapter';
    return '$name - $chapter';
  }

  Color _playerInk(BuildContext context) =>
      CommanColor.isDarkTheme(context) ? Colors.white : const Color(0xFF5C4033);

  Color _playerCard(BuildContext context) => CommanColor.isDarkTheme(context)
      ? const Color(0xFF2C2118)
      : const Color(0xFFFFF9F3);

  Future<void> _switchFromAudioToTts() async {
    final wasPlaying =
        isAudioPlaying || audioPlayer.state == PlayerState.playing;
    try {
      await audioPlayer.stop();
    } catch (_) {}
    _mp3Chosen = false;
    _readerUseTts = true;
    _fullScreenTts = null;
    rate = (_playbackSpeed / 2).clamp(0.0, 1.0);
    try {
      await flutterTts.setSpeechRate(rate);
    } catch (_) {}
    try {
      await flutterTts.setVolume(volume);
    } catch (_) {}
    curretNo = 0;
    start = 0;
    end = 0;
    allText = '';
    isInitialTime = true;
    if (audioChapterNum > 0) {
      selectedChapter = audioChapterNum;
    }
    try {
      await setChapterContent(preferReaderChapter: true);
    } catch (_) {}
    if (selectedChapterContent.isNotEmpty) {
      _newVoiceText = selectedChapterContent.first.content;
    }
    if (mounted) {
      setState(() {
        isAudioPlaying = false;
        position = Duration.zero;
        isSpeech = wasPlaying;
      });
    }
    await textToSpeechBottomSheet();
    if (!mounted) return;
    if (wasPlaying &&
        _newVoiceText != null &&
        _newVoiceText!.isNotEmpty) {
      isManuallyPaused = false;
      shouldAutoAdvance = true;
      isSpeech = true;
      ttsState = TtsState.playing;
      _notifyTtsPlayer();
      await _speak();
      _notifyTtsPlayer();
    }
  }

  Future<void> _startReaderTts() async {
    _readerUseTts = true;
    _mp3Chosen = false;
    if (isAudioPlaying || audioPlayer.state == PlayerState.playing) {
      try {
        await audioPlayer.pause();
      } catch (_) {}
      isAudioPlaying = false;
    }
    try {
      await setChapterContent(preferReaderChapter: true);
    } catch (_) {}
    if (selectedChapterContent.isNotEmpty) {
      if (curretNo < 0 || curretNo >= selectedChapterContent.length) {
        curretNo = 0;
      }
      _newVoiceText = selectedChapterContent[curretNo].content;
    }
    isManuallyPaused = false;
    shouldAutoAdvance = true;
    isSpeech = true;
    if (mounted) setState(() {});
    _fullPlayerSetState?.call(() {});
    await _speak();
  }

  Future<void> _onMiniPlay() async {
    final ttsUi = _showTtsUi();
    if (ttsUi && (isSpeech || ttsState == TtsState.playing)) {
      await _pauseTts();
      _fullPlayerSetState?.call(() {});
      return;
    }
    if (ttsUi &&
        (ttsState == TtsState.paused || _readerUseTts) &&
        _newVoiceText != null &&
        _newVoiceText!.isNotEmpty &&
        !isSpeech) {
      _readerUseTts = true;
      isManuallyPaused = false;
      shouldAutoAdvance = true;
      isSpeech = true;
      ttsState = TtsState.playing;
      if (mounted) setState(() {});
      _notifyTtsPlayer();
      await _speak();
      _notifyTtsPlayer();
      return;
    }
    if (!ttsUi && isAudioPlaying) {
      try {
        _audioResumePosition =
            await audioPlayer.getCurrentPosition() ?? position;
      } catch (_) {
        _audioResumePosition = position;
      }
      await audioPlayer.pause();
      if (mounted) setState(() => isAudioPlaying = false);
      _fullPlayerSetState?.call(() {});
      return;
    }
    if (!ttsUi && audioPlayer.state == PlayerState.paused) {
      _readerUseTts = false;
      try {
        await audioPlayer.setPlaybackRate(_playbackSpeed);
      } catch (_) {}
      await audioPlayer.resume();
      _audioResumePosition = Duration.zero;
      if (mounted) setState(() => isAudioPlaying = true);
      _fullPlayerSetState?.call(() {});
      return;
    }
    if (_showTtsUi()) {
      await _startReaderTts();
    } else {
      await _startReaderMp3();
    }
  }

  Future<void> _ttsSkipBySeconds(int seconds) async {
    if (selectedChapterContent.isEmpty) {
      try {
        await setChapterContent(preferReaderChapter: true);
      } catch (_) {}
    }
    if (selectedChapterContent.isEmpty) return;
    final speed = _playbackSpeed <= 0 ? 1.0 : _playbackSpeed;
    var wordsLeft = (2.5 * speed * seconds.abs()).round();
    if (wordsLeft < 1) wordsLeft = 1;
    var index = curretNo.clamp(0, selectedChapterContent.length - 1);
    if (seconds >= 0) {
      while (index < selectedChapterContent.length - 1 && wordsLeft > 0) {
        final count = _spokenWordCount(selectedChapterContent[index].content);
        wordsLeft -= count <= 0 ? 1 : count;
        index += 1;
      }
    } else {
      while (index > 0 && wordsLeft > 0) {
        index -= 1;
        final count = _spokenWordCount(selectedChapterContent[index].content);
        wordsLeft -= count <= 0 ? 1 : count;
      }
    }
    await _ttsGoToVerse(index);
  }

  int _spokenWordCount(String raw) {
    final text = (parse(raw).body?.text ?? raw).trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  double _ttsSpeedFactor() {
    final speed = rate * 2;
    return speed <= 0 ? 1.0 : speed;
  }

  Duration _ttsEstimatedChapterDuration() {
    var words = 0;
    for (final verse in selectedChapterContent) {
      words += _spokenWordCount(verse.content);
    }
    final secs = (words / (2.5 * _ttsSpeedFactor())).round();
    return Duration(seconds: secs < 1 ? 1 : secs);
  }

  int _ttsSecondsForCompletedVerses() {
    var words = 0;
    for (var i = 0; i < curretNo && i < selectedChapterContent.length; i++) {
      words += _spokenWordCount(selectedChapterContent[i].content);
    }
    final secs = (words / (2.5 * _ttsSpeedFactor())).round();
    return secs < 0 ? 0 : secs;
  }

  Duration _ttsEstimatedPosition() {
    var words = 0;
    for (var i = 0; i < curretNo && i < selectedChapterContent.length; i++) {
      words += _spokenWordCount(selectedChapterContent[i].content);
    }
    if (curretNo >= 0 && curretNo < selectedChapterContent.length) {
      final currentWords =
          _spokenWordCount(selectedChapterContent[curretNo].content);
      if (currentWords > 0 && allText.isNotEmpty) {
        final spoken = _ttsSpokenEnd.clamp(0, allText.length);
        final frac = spoken / allText.length;
        words += (currentWords * frac).round();
      }
    }
    final secs = (words / (2.5 * _ttsSpeedFactor())).round();
    final clamped = secs < 0 ? 0 : secs;
    // Hide a one-frame spike. If the later time stays, it is real playback
    // and the bar must move. Leaving it rejected freezes the bar.
    if (_ttsPosSecondsShown > 0 && clamped > _ttsPosSecondsShown + 2) {
      _ttsPosAheadAt ??= DateTime.now();
      if (DateTime.now().difference(_ttsPosAheadAt!) <
          const Duration(milliseconds: 350)) {
        return Duration(seconds: _ttsPosSecondsShown);
      }
    } else {
      _ttsPosAheadAt = null;
    }
    if (clamped < _ttsPosSecondsShown) return Duration(seconds: _ttsPosSecondsShown);
    _ttsPosAheadAt = null;
    _ttsPosSecondsShown = clamped;
    return Duration(seconds: clamped);
  }

  int _ttsVerseAtSeconds(int seconds) {
    if (selectedChapterContent.isEmpty) return 0;
    final targetWords = 2.5 * _ttsSpeedFactor() * seconds;
    var words = 0.0;
    var index = 0;
    while (index < selectedChapterContent.length - 1) {
      words += _spokenWordCount(selectedChapterContent[index].content);
      if (words >= targetWords) break;
      index += 1;
    }
    return index;
  }

  Future<void> _seekBy(int seconds) async {
    var next = position + Duration(seconds: seconds);
    if (next < Duration.zero) next = Duration.zero;
    if (duration > Duration.zero && next > duration) next = duration;
    await audioPlayer.seek(next);
    position = next;
    if (mounted) setState(() {});
    _fullPlayerSetState?.call(() {});
  }

  Future<void> _ttsGoToVerse(int index) async {
    if (selectedChapterContent.isEmpty) {
      try {
        await setChapterContent(preferReaderChapter: true);
      } catch (_) {}
    }
    if (selectedChapterContent.isEmpty) return;
    final was = isSpeech || ttsState == TtsState.playing;
    if (was && _isTtsInitialized) {
      _ignoreTtsEngineEvents();
      try {
        await flutterTts.stop();
      } catch (_) {}
    }
    isManualNavigation = true;
    if (index < 0) {
      if (selectedChapter > 1) {
        selectedChapter -= 1;
        curretNo = 0;
        await setChapterContent();
        await updateReadingScreenChapter(selectedChapter);
        if (selectedChapterContent.isNotEmpty) {
          curretNo = selectedChapterContent.length - 1;
        }
      } else {
        curretNo = 0;
      }
    } else if (index >= selectedChapterContent.length) {
      final last = _chapterTotal();
      if (selectedChapter < last) {
        selectedChapter += 1;
        curretNo = 0;
        await setChapterContent();
        await updateReadingScreenChapter(selectedChapter);
      } else {
        curretNo = selectedChapterContent.length - 1;
      }
    } else {
      curretNo = index;
    }
    if (curretNo >= 0 && curretNo < selectedChapterContent.length) {
      _newVoiceText = selectedChapterContent[curretNo].content;
    }
    _ttsProgressEnd = 0;
    _ttsSpokenEnd = 0;
    _ttsProgressVerse = curretNo;
    _ttsProgressAt = DateTime.now();
    _ttsPosAheadAt = null;
    _ttsPosSecondsShown = _ttsSecondsForCompletedVerses();
    if (was && _newVoiceText != null && _newVoiceText!.isNotEmpty) {
      isSpeech = true;
      isManuallyPaused = false;
      shouldAutoAdvance = true;
      await _speak();
    }
    if (mounted) setState(() {});
    _fullPlayerSetState?.call(() {});
  }

  Future<void> _jumpToChapter(int chapter) async {
    if (chapter < 1) return;
    if (chapter > _chapterTotal()) {
      Constants.showToast(
          _showTtsUi() ? "Reached End" : "Already at last chapter");
      return;
    }
    if (_showTtsUi()) {
      final was = isSpeech || ttsState == TtsState.playing;
      if (_isTtsInitialized) {
        _ignoreTtsEngineEvents();
        try {
          await flutterTts.stop();
        } catch (_) {}
      }
      isManualNavigation = true;
      selectedChapter = chapter;
      curretNo = 0;
      _ttsProgressEnd = 0;
      _ttsSpokenEnd = 0;
      _ttsPosSecondsShown = 0;
      _ttsPosAheadAt = null;
      _ttsProgressVerse = -1;
      _ttsProgressAt = DateTime.now();
      await setChapterContent();
      await updateReadingScreenChapter(chapter);
      if (selectedChapterContent.isNotEmpty) {
        _newVoiceText = selectedChapterContent.first.content;
      }
      if (was && _newVoiceText != null && _newVoiceText!.isNotEmpty) {
        isSpeech = true;
        isManuallyPaused = false;
        shouldAutoAdvance = true;
        await _speak();
      }
    } else {
      final was = isAudioPlaying || audioPlayer.state == PlayerState.playing;
      await updateReadingScreenChapter(chapter);
      final nextUrl =
          "${_recordedAudioBase()}/$audioBookNum/$chapter.mp3";
      audioChapterNum = chapter;
      audioBaseUrl = nextUrl;
      if (was) {
        try {
          await audioPlayer.setSourceUrl(nextUrl);
          await audioPlayer.seek(Duration.zero);
          await audioPlayer.setPlaybackRate(_playbackSpeed);
          await audioPlayer.setVolume(volume);
          await audioPlayer.resume();
          isAudioPlaying = true;
          position = Duration.zero;
        } catch (_) {}
      }
    }
    if (mounted) setState(() {});
    _fullPlayerSetState?.call(() {});
  }

  Future<void> _applySpeed(double speed) async {
    _playbackSpeed = speed;
    if (_showTtsUi()) {
      rate = (speed / 2).clamp(0.0, 1.0);
      try {
        await flutterTts.setSpeechRate(rate);
      } catch (_) {}
    } else {
      try {
        await audioPlayer.setPlaybackRate(speed);
      } catch (_) {}
    }
    if (mounted) setState(() {});
    _fullPlayerSetState?.call(() {});
  }

  void _chooseSleep(int? minutes) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepEndOfChapter = false;
    _sleepChoiceMinutes = minutes;
    if (minutes != null && minutes < 0) {
      _sleepEndOfChapter = true;
    } else if (minutes != null && minutes > 0) {
      _sleepTimer = Timer(Duration(minutes: minutes), () async {
        _sleepChoiceMinutes = null;
        _sleepEndOfChapter = false;
        if (_showTtsUi()) {
          await _pauseTts();
        } else {
          try {
            await audioPlayer.pause();
          } catch (_) {}
          if (mounted) setState(() => isAudioPlaying = false);
        }
        _fullPlayerSetState?.call(() {});
      });
    }
    if (mounted) setState(() {});
    _fullPlayerSetState?.call(() {});
  }

  bool _reopenOldSheet = false;

  Future<void> _openReaderFullPlayer({required bool tts}) async {
    if (!mounted) return;
    if (_fullPlayerOpen) return;
    _fullPlayerOpen = true;
    _fullPlayerUiAlive = true;
    _reopenOldSheet = false;
    _fullScreenTts = tts;
    _readerUseTts = tts;
    if (tts) {
      _attachTtsProgressHandler();
    }
    try {
      await Navigator.of(context).push(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (routeContext, animation, secondaryAnimation) {
            return StatefulBuilder(
              builder: (ctx, setModal) {
                _fullPlayerSetState = (fn) {
                  if (!_fullPlayerUiAlive || !ctx.mounted) return;
                  setModal(fn);
                };
                return _readerFullPlayer(ctx);
              },
            );
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slide = Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));
            return SlideTransition(position: slide, child: child);
          },
        ),
      );
    } finally {
      _fullScreenTts = null;
      _closeFullPlayerUi();
      _fullPlayerOpen = false;
    }
    if (!_reopenOldSheet || !mounted) return;
    _reopenOldSheet = false;
    if (tts) {
      await textToSpeechBottomSheet();
    } else {
      await audioPlayerBottomSheet();
    }
  }

  Widget _readerFullPlayer(BuildContext ctx) {
    final ttsUi = _showTtsUi();
    final ink = _playerInk(ctx);
    final card = CommanColor.isDarkTheme(ctx)
        ? _playerCard(ctx)
        : const Color(0xFFFFF8F2);
    final playing = ttsUi
        ? (isSpeech || ttsState == TtsState.playing)
        : isAudioPlaying;
    final chapter = _shownChapter(ttsUi);
    var book = widget.bookName.trim();
    if (book.isEmpty) book = (_storedBookName ?? '').trim();
    if (book.isEmpty) book = 'Bible';
    final ttsDuration = ttsUi ? _ttsEstimatedChapterDuration() : duration;
    final ttsPosition = ttsUi ? _ttsEstimatedPosition() : position;
    final ttsMaxSeconds =
        ttsDuration.inSeconds > 0 ? ttsDuration.inSeconds : 1;
    final ttsPosSeconds =
        ttsPosition.inSeconds.clamp(0, ttsMaxSeconds);
    final maxSeconds = duration.inSeconds > 0 ? duration.inSeconds : 1;
    final sliderMax = (ttsUi ? ttsMaxSeconds : maxSeconds).toDouble();
    final liveSeconds =
        (ttsUi ? ttsPosSeconds : position.inSeconds.clamp(0, maxSeconds))
            .toDouble();
    final sliderValue = (_playerSliderDrag ?? liveSeconds).clamp(0.0, sliderMax);
    final shownPosition = _playerSliderDrag == null
        ? (ttsUi ? ttsPosition : position)
        : Duration(seconds: sliderValue.round());
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _closeFullPlayerUi();
      },
      child: Scaffold(
      backgroundColor: card,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      _reopenOldSheet = true;
                      _closeFullPlayerUi();
                      Navigator.of(ctx).pop();
                    },
                    icon: Icon(Icons.keyboard_arrow_down, color: ink, size: 28),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$book - $chapter',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ttsUi ? 'Read Aloud' : 'NLT Audio',
                          style: TextStyle(
                            color: ink.withValues(alpha: 0.55),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _closeFullPlayerUi();
                      Navigator.of(ctx).pop();
                    },
                    icon: Icon(Icons.close, color: ink, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (ttsUi)
                        Image.asset(
                          'assets/reader_tts_cover.jpg',
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        )
                      else
                        Transform.scale(
                          scale: 1.45,
                          child: Image.asset(
                            'assets/reader_player_cover.png',
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                        ),
                      Align(
                        alignment: const Alignment(0, 0.82),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              book.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Georgia',
                                fontSize: 40,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Chapter $chapter',
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Georgia',
                                fontSize: 28,
                                fontWeight: FontWeight.w400,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      formatTime(shownPosition),
                      style: TextStyle(color: ink.withValues(alpha: 0.7), fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(ctx).copyWith(
                        trackHeight: 4,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 7),
                        overlayShape: SliderComponentShape.noOverlay,
                        activeTrackColor: ink,
                        inactiveTrackColor: ink.withValues(alpha: 0.18),
                        thumbColor: ink,
                      ),
                      child: Slider(
                        min: 0,
                        max: sliderMax,
                        value: sliderValue,
                        onChanged: (v) {
                          _playerSliderDrag = v;
                          _playerSliderDragAt = DateTime.now();
                          _fullPlayerSetState?.call(() {});
                        },
                        onChangeEnd: (v) async {
                          _playerSliderDrag = v;
                          _playerSliderDragAt = DateTime.now();
                          try {
                            if (ttsUi) {
                              await _ttsGoToVerse(_ttsVerseAtSeconds(v.round()));
                            } else {
                              position = Duration(seconds: v.toInt());
                              await audioPlayer.seek(position);
                            }
                          } finally {
                            if (_playerSliderDrag == v) {
                              _playerSliderDrag = null;
                              _playerSliderDragAt = null;
                            }
                            if (_fullPlayerUiAlive) {
                              _fullPlayerSetState?.call(() {});
                            }
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      formatTime(ttsUi ? ttsDuration : duration),
                      textAlign: TextAlign.right,
                      style: TextStyle(color: ink.withValues(alpha: 0.7), fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _secondJumpButton(
                    ctx,
                    seconds: 10,
                    backward: true,
                    onTap: () {
                      if (ttsUi) {
                        _ttsSkipBySeconds(-10);
                      } else {
                        _seekBy(-10);
                      }
                    },
                  ),
                  IconButton(
                    onPressed: () => _jumpToChapter(chapter - 1),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    icon: Icon(Icons.skip_previous, color: ink, size: 30),
                  ),
                  Material(
                    color: ink,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _onMiniPlay,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Icon(
                          playing ? Icons.pause : Icons.play_arrow,
                          color: card,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _jumpToChapter(chapter + 1),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    icon: Icon(Icons.skip_next, color: ink, size: 30),
                  ),
                  _secondJumpButton(
                    ctx,
                    seconds: 10,
                    backward: false,
                    onTap: () {
                      if (ttsUi) {
                        _ttsSkipBySeconds(10);
                      } else {
                        _seekBy(10);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _playerAction(
                        ctx,
                        iconWidget: _voiceMicIcon(_playerInk(ctx), size: 24),
                        label: 'Voice',
                        onTap: _showCombinedVoiceSettingsSheet,
                      ),
                    ),
                    Expanded(
                      child: _playerAction(
                        ctx,
                        iconWidget: Icon(
                          (_sleepChoiceMinutes != null)
                              ? Icons.nightlight_round
                              : Icons.nightlight_outlined,
                          color: (_sleepChoiceMinutes != null)
                              ? _playerInk(ctx)
                              : _playerInk(ctx).withValues(alpha: 0.38),
                          size: 24,
                        ),
                        label: 'Sleep Timer',
                        onTap: _showSleepSheet,
                      ),
                    ),
                    Expanded(
                      child: _playerAction(
                        ctx,
                        icon: Icons.queue_music,
                        label: 'Chapters',
                        onTap: _showChaptersSheet,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _secondJumpButton(
    BuildContext ctx, {
    required int seconds,
    required bool backward,
    required VoidCallback onTap,
  }) {
    final ink = _playerInk(ctx);
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.flip(
                flipX: !backward,
                child: Icon(Icons.replay, color: ink, size: 40),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '$seconds',
                  style: TextStyle(
                    color: ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _voiceMicIcon(Color color, {double size = 22}) {
    return Image.asset(
      'assets/lightMode/icons/voice_mic.png',
      height: size,
      width: size,
      color: color,
      fit: BoxFit.contain,
    );
  }

  Widget _playerAction(
    BuildContext ctx, {
    IconData? icon,
    Widget? iconWidget,
    required String label,
    required VoidCallback onTap,
  }) {
    final ink = _playerInk(ctx);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Center(
                child: iconWidget ?? Icon(icon!, color: ink, size: 24),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: ink, fontSize: 12, height: 1.15),
            ),
          ],
        ),
      ),
    );
  }

  String _speedLabel(double speed) {
    final text = speed.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
    return '${text.endsWith('.') ? text.substring(0, text.length - 1) : text}x';
  }

  Future<void> _showSpeedSheet() {
    const options = <(double, String)>[
      (0.5, 'Slower'),
      (0.75, 'Slower'),
      (1.0, 'Normal'),
      (1.25, 'A little faster'),
      (1.5, 'Faster'),
      (1.75, 'Faster'),
      (2.0, 'Fastest'),
    ];
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final ink = _playerInk(ctx);
        final card = _playerCard(ctx);
        return Material(
          color: card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHeader(ctx, 'Playback Speed'),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final option in options)
                          ListTile(
                            title: Text(
                              '${_speedLabel(option.$1)}   ${option.$2}',
                              style: TextStyle(
                                color: ink,
                                fontWeight: _playbackSpeed == option.$1
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            trailing: _playbackSpeed == option.$1
                                ? Icon(Icons.check, color: ink)
                                : null,
                            selected: _playbackSpeed == option.$1,
                            selectedTileColor: ink.withValues(alpha: 0.12),
                            onTap: () async {
                              await _applySpeed(option.$1);
                              if (ctx.mounted) Navigator.of(ctx).pop();
                            },
                          ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSleepSheet() {
    const options = <(int?, String)>[
      (5, '5 minutes'),
      (10, '10 minutes'),
      (15, '15 minutes'),
      (30, '30 minutes'),
      (45, '45 minutes'),
      (60, '60 minutes'),
      (-1, 'End of chapter'),
      (null, 'Off'),
    ];
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final ink = _playerInk(ctx);
        final card = _playerCard(ctx);
        return Material(
          color: card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHeader(ctx, 'Sleep Timer'),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final option in options)
                          ListTile(
                            title: Text(
                              option.$2,
                              style: TextStyle(
                                color: ink,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: _sleepChoiceMinutes == option.$1
                                ? Icon(Icons.check, color: ink)
                                : null,
                            selected: _sleepChoiceMinutes == option.$1,
                            selectedTileColor: ink.withValues(alpha: 0.12),
                            onTap: () {
                              _chooseSleep(option.$1);
                              Navigator.of(ctx).pop();
                            },
                          ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showChaptersSheet() {
    final total = _chapterTotal();
    final current = _shownChapter(_showTtsUi());
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final ink = _playerInk(ctx);
        final card = _playerCard(ctx);
        return Material(
          color: card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: SafeArea(
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.55,
              child: Column(
                children: [
                  _sheetHeader(ctx, 'Chapters'),
                  Expanded(
                    child: ListView.builder(
                      itemCount: total < 1 ? 0 : total,
                      itemBuilder: (_, index) {
                        final chapter = index + 1;
                        final selected = chapter == current;
                        return ListTile(
                          title: Text(
                            'Chapter $chapter',
                            style: TextStyle(
                              color: ink,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          trailing: selected
                              ? Icon(Icons.check, color: ink)
                              : null,
                          selected: selected,
                          selectedTileColor: ink.withValues(alpha: 0.12),
                          onTap: () async {
                            Navigator.of(ctx).pop();
                            await _jumpToChapter(chapter);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sheetHeader(BuildContext ctx, String title) {
    final ink = _playerInk(ctx);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          const SizedBox(width: 40),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: ink),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
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

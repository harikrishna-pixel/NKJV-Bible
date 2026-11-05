import 'dart:async';

import 'package:audio_service/audio_service.dart' show MediaItem;
import 'package:audio_session/audio_session.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;

/// The chapter waiting in the native playlist after the current one.
class QueuedChapter {
  const QueuedChapter({
    required this.audioBookNum,
    required this.chapter,
    this.bookIndex,
    this.bookName,
    this.bookChapterCount,
  });

  /// 1-based book number used in the MP3 URL.
  final int audioBookNum;
  final int chapter;

  /// Set only when the queued chapter starts a new book (0-based reader index).
  final int? bookIndex;
  final String? bookName;
  final int? bookChapterCount;

  bool get isNewBook => bookIndex != null;
  String get key => '$audioBookNum/$chapter';
}

/// Bible reader MP3 player on just_audio + just_audio_background.
///
/// Keeps the audioplayers-style API the reader already uses, and adds a native
/// next-chapter queue: the OS player moves to the next chapter by itself, so
/// auto-next keeps working when the app is minimised or the screen is off.
/// One shared instance (just_audio_background supports a single player).
class ReaderAudioPlayer {
  ReaderAudioPlayer._() {
    _bind();
  }

  static final ReaderAudioPlayer _instance = ReaderAudioPlayer._();
  factory ReaderAudioPlayer() => _instance;

  /// Lock-screen / notification album line.
  static String albumTitle = '';

  final ja.AudioPlayer _p = ja.AudioPlayer();

  final _stateCtl = StreamController<ap.PlayerState>.broadcast();
  final _completeCtl = StreamController<void>.broadcast();
  final _advanceCtl = StreamController<QueuedChapter>.broadcast();

  ap.PlayerState _state = ap.PlayerState.stopped;
  bool _sessionConfigured = false;
  Future<void> _ops = Future<void>.value();

  QueuedChapter? _queued;
  int? _queuedIndex;
  String? _queuedTarget;
  String? _currentTarget;
  int _itemSeq = 0;

  /// Title for the current item when a caller does not pass one.
  String Function()? titleBuilder;

  ap.PlayerState get state => _state;
  Stream<ap.PlayerState> get onPlayerStateChanged => _stateCtl.stream;
  Stream<Duration> get onDurationChanged =>
      _p.durationStream.where((d) => d != null).map((d) => d!);
  Stream<Duration> get onPositionChanged => _p.positionStream;

  /// End of playlist (no queued next chapter played).
  Stream<void> get onPlayerComplete => _completeCtl.stream;

  /// Native player moved to the queued next chapter.
  Stream<QueuedChapter> get onAutoAdvance => _advanceCtl.stream;

  bool get hasQueuedNext => _queued != null;
  String? get queuedKey => _queued?.key;

  /// URL or file path of the item playing now.
  String? get currentSource => _currentTarget;

  void _bind() {
    _p.playerStateStream.listen(_onPlayerState);
    _p.currentIndexStream.listen(_onIndex);
    _p.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace _) {
        debugPrint('ReaderAudioPlayer error: $e');
        _setState(ap.PlayerState.stopped);
      },
    );
  }

  void _setState(ap.PlayerState s) {
    if (s == _state) return;
    _state = s;
    _stateCtl.add(s);
    if (s == ap.PlayerState.completed) _completeCtl.add(null);
  }

  void _onPlayerState(ja.PlayerState s) {
    if (s.processingState == ja.ProcessingState.completed) {
      _setState(ap.PlayerState.completed);
      return;
    }
    if (s.playing) {
      _setState(ap.PlayerState.playing);
      return;
    }
    if (s.processingState == ja.ProcessingState.idle) {
      if (_state != ap.PlayerState.completed) {
        _setState(ap.PlayerState.stopped);
      }
      return;
    }
    if (_state == ap.PlayerState.playing) {
      _setState(ap.PlayerState.paused);
    }
  }

  void _onIndex(int? index) {
    final q = _queued;
    if (q == null || index == null || index != _queuedIndex) return;
    _currentTarget = _queuedTarget;
    _queued = null;
    _queuedIndex = null;
    _queuedTarget = null;
    debugPrint('ReaderAudioPlayer: native auto-next → ${q.key}');
    _advanceCtl.add(q);
    // Drop finished chapters so the playlist stays [current, next].
    unawaited(_serial(() async {
      final finished = _p.currentIndex ?? 0;
      for (var i = 0; i < finished && _p.sequence.length > 1; i++) {
        await _p.removeAudioSourceAt(0);
      }
    }));
  }

  Future<T> _serial<T>(Future<T> Function() op) {
    final done = Completer<T>();
    _ops = _ops.then((_) async {
      try {
        done.complete(await op());
      } catch (e, st) {
        done.completeError(e, st);
      }
    });
    return done.future;
  }

  Future<void> _ensureSession() async {
    if (_sessionConfigured) return;
    _sessionConfigured = true;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      debugPrint('ReaderAudioPlayer session config failed: $e');
    }
  }

  ja.AudioSource _sourceFor(String urlOrPath, {String? title}) {
    final isFile = !urlOrPath.startsWith('http');
    final item = MediaItem(
      id: '${_itemSeq++}:$urlOrPath',
      title: title ?? titleBuilder?.call() ?? 'Bible Audio',
      album: albumTitle.isEmpty ? null : albumTitle,
    );
    return isFile
        ? ja.AudioSource.file(urlOrPath, tag: item)
        : ja.AudioSource.uri(Uri.parse(urlOrPath), tag: item);
  }

  Future<void> _load(String urlOrPath, {String? title, Duration? at}) async {
    await _ensureSession();
    _queued = null;
    _queuedIndex = null;
    _queuedTarget = null;
    _currentTarget = urlOrPath;
    await _p.setAudioSources(
      [_sourceFor(urlOrPath, title: title)],
      initialPosition: at,
    );
  }

  /// Replace the playlist with one chapter (does not start playback).
  Future<void> setSourceUrl(String url, {String? title}) =>
      _serial(() => _load(url, title: title));

  Future<void> setSourceDeviceFile(String path, {String? title}) =>
      _serial(() => _load(path, title: title));

  /// Load [source] and start playing (audioplayers-compatible signature).
  Future<void> play(
    ap.Source source, {
    double? volume,
    ap.AudioContext? ctx,
    Duration? position,
    ap.PlayerMode? mode,
  }) async {
    final String target;
    if (source is ap.UrlSource) {
      target = source.url;
    } else if (source is ap.DeviceFileSource) {
      target = source.path;
    } else {
      throw UnsupportedError('ReaderAudioPlayer: unsupported $source');
    }
    if (volume != null) await setVolume(volume);
    await _serial(() => _load(target, at: position));
    await resume();
  }

  /// Start / continue playback. Never awaits just_audio's play() future,
  /// which only completes when playback stops.
  Future<void> resume() async {
    await _ensureSession();
    if (_p.processingState == ja.ProcessingState.completed) {
      await _p.seek(Duration.zero, index: 0);
    }
    unawaited(_p.play().catchError((Object e) {
      debugPrint('ReaderAudioPlayer play error: $e');
    }));
    _setState(ap.PlayerState.playing);
  }

  Future<void> pause() async {
    await _p.pause();
    _setState(ap.PlayerState.paused);
  }

  Future<void> stop() async {
    try {
      await _p.stop();
      await _p.seek(Duration.zero);
    } catch (_) {}
    _setState(ap.PlayerState.stopped);
  }

  Future<void> seek(Duration position) => _p.seek(position);

  Future<void> setVolume(double volume) => _p.setVolume(volume);

  Future<void> setPlaybackRate(double rate) => _p.setSpeed(rate);

  Future<void> setReleaseMode(ap.ReleaseMode mode) => _p.setLoopMode(
      mode == ap.ReleaseMode.loop ? ja.LoopMode.one : ja.LoopMode.off);

  Future<Duration?> getCurrentPosition() async => _p.position;

  Future<Duration?> getDuration() async => _p.duration;

  /// Queue [chapter] at [urlOrPath] to play right after the current item.
  /// Returns false if nothing is loaded.
  Future<bool> queueNext(
    QueuedChapter chapter,
    String urlOrPath, {
    String? title,
  }) =>
      _serial(() async {
        if (_p.sequence.isEmpty) return false;
        final current = _p.currentIndex ?? 0;
        while (_p.sequence.length > current + 1) {
          await _p.removeAudioSourceAt(_p.sequence.length - 1);
        }
        await _p.addAudioSource(_sourceFor(urlOrPath, title: title));
        _queued = chapter;
        _queuedIndex = current + 1;
        _queuedTarget = urlOrPath;
        debugPrint('ReaderAudioPlayer: queued next ${chapter.key}');
        return true;
      });

  /// Remove the queued next chapter (sleep "end of chapter", TTS, etc.).
  Future<void> clearQueuedNext() => _serial(() async {
        _queued = null;
        _queuedIndex = null;
        _queuedTarget = null;
        final current = _p.currentIndex ?? 0;
        while (_p.sequence.length > current + 1) {
          await _p.removeAudioSourceAt(_p.sequence.length - 1);
        }
      });

  /// Shared instance outlives screens; leaving only stops playback.
  Future<void> dispose() => stop();
}

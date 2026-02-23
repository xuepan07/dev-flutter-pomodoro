import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// Timer State Enum
// ============================================================
enum TimerState { idle, working, shortBreak, longBreak }

// ============================================================
// Log Entry Model
// ============================================================
class PomodoroLog {
  final String taskName;
  final int completedSets;
  final DateTime completedAt;

  PomodoroLog({
    required this.taskName,
    required this.completedSets,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'taskName': taskName,
        'completedSets': completedSets,
        'completedAt': completedAt.toIso8601String(),
      };

  factory PomodoroLog.fromJson(Map<String, dynamic> json) => PomodoroLog(
        taskName: json['taskName'] ?? '',
        completedSets: json['completedSets'] ?? 0,
        completedAt: DateTime.parse(json['completedAt']),
      );
}

// ============================================================
// Pomodoro Timer (ChangeNotifier)
// ============================================================
class PomodoroTimer extends ChangeNotifier {
  // ----- Timer Settings (seconds) -----
  static const int workDuration = 25 * 60; // 25分
  static const int shortBreakDuration = 5 * 60; // 5分
  static const int longBreakDuration = 20 * 60; // 20分
  static const int setsPerRound = 4;

  // ----- State -----
  TimerState _timerState = TimerState.idle;
  int _remainingSeconds = workDuration;
  int _totalDuration = workDuration;
  int _completedSets = 0;
  bool _isRunning = false;
  Timer? _timer;
  String _taskName = 'Task Name';  //'タスク名';
  List<PomodoroLog> _logs = [];

  // ----- Audio -----
  final AudioPlayer _audioPlayer = AudioPlayer();

  // ----- Getters -----
  TimerState get timerState => _timerState;
  int get remainingSeconds => _remainingSeconds;
  int get totalDuration => _totalDuration;
  int get completedSets => _completedSets;
  bool get isRunning => _isRunning;
  String get taskName => _taskName;
  List<PomodoroLog> get logs => _logs;

  double get progress {
    if (_totalDuration == 0) return 0;
    return 1.0 - (_remainingSeconds / _totalDuration);
  }

  String get formattedTime {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get stateLabel {
    switch (_timerState) {
      case TimerState.idle:
        return 'Stand-by';  //'スタンバイ';
      case TimerState.working:
        return 'Concentration';  //'集中タイム';
      case TimerState.shortBreak:
        return 'Short Break';  //'短い休憩';
      case TimerState.longBreak:
        return 'Long Break';  //'長い休憩';
    }
  }

  Color get stateColor {
    switch (_timerState) {
      case TimerState.idle:
        return const Color(0xFF95A5A6);
      case TimerState.working:
        return const Color(0xFFE74C3C);
      case TimerState.shortBreak:
        return const Color(0xFF27AE60);
      case TimerState.longBreak:
        return const Color(0xFF2980B9);
    }
  }

  bool get canSkipBreak =>
      _timerState == TimerState.shortBreak ||
      _timerState == TimerState.longBreak;

  // ============================================================
  // Persistence (SharedPreferences)
  // ============================================================
  Future<void> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final logsJson = prefs.getStringList('pomodoro_logs') ?? [];
    _logs = logsJson
        .map((e) => PomodoroLog.fromJson(jsonDecode(e)))
        .toList()
        .reversed
        .toList();
    notifyListeners();
  }

  Future<void> _saveLog(PomodoroLog log) async {
    final prefs = await SharedPreferences.getInstance();
    final logsJson = prefs.getStringList('pomodoro_logs') ?? [];
    logsJson.add(jsonEncode(log.toJson()));
    await prefs.setStringList('pomodoro_logs', logsJson);
    await loadLogs();
  }

  Future<void> clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pomodoro_logs');
    _logs = [];
    notifyListeners();
  }

  // ============================================================
  // Task Name
  // ============================================================
  void setTaskName(String name) {
    //_taskName = name.isEmpty ? 'タスク名' : name;
    _taskName = name.isEmpty ? 'Task Name' : name;
    notifyListeners();
  }

  // ============================================================
  // Timer Logic
  // ============================================================
  /// コールバック: タイマー完了時に呼ばれる（ダイアログ表示などUI側で使用）
  VoidCallback? onLongBreakStarted;

  void startTimer() {
    if (_isRunning) return;
    _isRunning = true;
    if (_timerState == TimerState.idle) {
      _timerState = TimerState.working;
      _remainingSeconds = workDuration;
      _totalDuration = workDuration;
    }
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _onTimerComplete();
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    _timerState = TimerState.idle;
    _remainingSeconds = workDuration;
    _totalDuration = workDuration;
    _completedSets = 0;
    _isRunning = false;
    notifyListeners();
  }

  void _onTimerComplete() {
    _timer?.cancel();
    _playAlarm();
    _vibrate();
    _isRunning = false;

    if (_timerState == TimerState.working) {
      _completedSets++;
      _saveLog(PomodoroLog(
        taskName: _taskName,
        completedSets: _completedSets,
        completedAt: DateTime.now(),
      ));

      if (_completedSets >= setsPerRound) {
        _timerState = TimerState.longBreak;
        _remainingSeconds = longBreakDuration;
        _totalDuration = longBreakDuration;
        notifyListeners();
        onLongBreakStarted?.call();
      } else {
        _timerState = TimerState.shortBreak;
        _remainingSeconds = shortBreakDuration;
        _totalDuration = shortBreakDuration;
        notifyListeners();
      }
      // 休憩タイマーを自動開始
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isRunning) startTimer();
      });
    } else {
      // 休憩完了 → 次の作業
      if (_timerState == TimerState.longBreak) {
        _completedSets = 0;
      }
      _timerState = TimerState.working;
      _remainingSeconds = workDuration;
      _totalDuration = workDuration;
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isRunning) startTimer();
      });
    }
  }

  void skipBreak() {
    if (!canSkipBreak) return;
    _timer?.cancel();
    _isRunning = false;
    if (_timerState == TimerState.longBreak) {
      _completedSets = 0;
    }
    _timerState = TimerState.working;
    _remainingSeconds = workDuration;
    _totalDuration = workDuration;
    notifyListeners();
    startTimer();
  }

  // ============================================================
  // Alarm & Vibration
  // ============================================================
  Future<void> _playAlarm() async {
    try {
      await _audioPlayer.play(AssetSource('alarm.mp3'));
    } catch (e) {
      debugPrint('Alarm sound not found: $e');
      SystemSound.play(SystemSoundType.alert);
    }
  }

  Future<void> _vibrate() async {
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 1000, amplitude: 255);
      }
    } catch (e) {
      debugPrint('Vibration not available: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}

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
  static const int longBreakDuration = 20 * 60; // 20分
  static const int setsPerRound = 4;
  
  // ----- Configurable Durations -----
  late int _workDuration; // 10-50分（5分刻み）
  late int _shortBreakDuration; // 1-5分（1分刻み）

  // ----- State -----
  TimerState _timerState = TimerState.idle;
  late int _remainingSeconds;
  late int _totalDuration;
  int _completedSets = 0;
  bool _isRunning = false;
  Timer? _timer;
  String _taskName = 'Task Name';  //'タスク名';
  List<PomodoroLog> _logs = [];
  
  // Constructor
  PomodoroTimer() {
    _workDuration = 25 * 60; // Default: 25分
    _shortBreakDuration = 5 * 60; // Default: 5分
    _remainingSeconds = _workDuration;
    _totalDuration = _workDuration;
  }

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
  int get workDuration => _workDuration;
  int get shortBreakDuration => _shortBreakDuration;

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
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _workDuration = prefs.getInt('work_duration') ?? (25 * 60);
    _shortBreakDuration = prefs.getInt('short_break_duration') ?? (5 * 60);
    _remainingSeconds = _workDuration;
    _totalDuration = _workDuration;
    notifyListeners();
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('work_duration', _workDuration);
    await prefs.setInt('short_break_duration', _shortBreakDuration);
  }
  
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
  // Task Name & Settings
  // ============================================================
  void setTaskName(String name) {
    //_taskName = name.isEmpty ? 'タスク名' : name;
    _taskName = name.isEmpty ? 'Task Name' : name;
    notifyListeners();
  }
  
  /// Set work duration (集中時間を設定: 10-50分を5分刻み)
  void setWorkDuration(int minutes) {
    if (minutes >= 10 && minutes <= 50 && minutes % 5 == 0) {
      _workDuration = minutes * 60;
      _saveSettings();
      
      // アイドル状態のときは画面表示も更新する
      if (_timerState == TimerState.idle) {
        _remainingSeconds = _workDuration;
        _totalDuration = _workDuration;
      }
      notifyListeners();
    }
  }
  
  /// Set short break duration (休憩時間を設定: 1-5分を1分刻み)
  void setShortBreakDuration(int minutes) {
    if (minutes >= 1 && minutes <= 5) {
      _shortBreakDuration = minutes * 60;
      _saveSettings();
      notifyListeners();
    }
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
      _remainingSeconds = _workDuration;
      _totalDuration = _workDuration;
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
    _remainingSeconds = _workDuration;
    _totalDuration = _workDuration;
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
        _remainingSeconds = _shortBreakDuration;
        _totalDuration = _shortBreakDuration;
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
      _remainingSeconds = _workDuration;
      _totalDuration = _workDuration;
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
    _remainingSeconds = _workDuration;
    _totalDuration = _workDuration;
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

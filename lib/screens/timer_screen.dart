import 'package:flutter/material.dart';
import '../pomodoro_timer.dart';
import '../widgets/circular_progress.dart';
import '../widgets/control_buttons.dart';
import '../widgets/log_list.dart';

// ============================================================
// Main Timer Screen
// ============================================================
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with TickerProviderStateMixin {
  final PomodoroTimer _pomodoroTimer = PomodoroTimer();

  // ----- Animation -----
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pomodoroTimer.loadLogs();
    _pomodoroTimer.addListener(_onTimerChanged);
    _pomodoroTimer.onLongBreakStarted = _showLongBreakDialog;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pomodoroTimer.removeListener(_onTimerChanged);
    _pomodoroTimer.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onTimerChanged() {
    setState(() {});
    // パルスアニメーション制御
    if (_pomodoroTimer.isRunning && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!_pomodoroTimer.isRunning && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  // ============================================================
  // Dialogs
  // ============================================================
  void _showLongBreakDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          //'おつかれさま！',
          'Good Job !!',
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),
        content: const Text(
          //'4セット完了しました！\n20分間の長い休憩をとりましょう。',
          '4 sets done! Time for a nice 20-minute break.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _pomodoroTimer.skipBreak();
            },
            //child: const Text('スキップ', style: TextStyle(color: Colors.grey)),
            child: const Text('Skip', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
            ),
            onPressed: () => Navigator.pop(ctx),
            //child: const Text('休憩する'),
            child: const Text('Have a Break.'),
          ),
        ],
      ),
    );
  }

  void _showEditTaskDialog() {
    final controller =
        TextEditingController(text: _pomodoroTimer.taskName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:
            //const Text('タスク名を変更', style: TextStyle(color: Colors.white)),
            const Text('Change Task Name', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: InputDecoration(
            //hintText: 'タスク名を入力',
            hintText: 'Input Task Name',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE74C3C)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            //child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
            ),
            onPressed: () {
              _pomodoroTimer.setTaskName(controller.text);
              Navigator.pop(ctx);
            },
            //child: const Text('保存'),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showClearLogsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        //title: const Text('ログを全て削除', style: TextStyle(color: Colors.white)),
        //content: const Text('全ての完了ログを削除しますか？',
        title: const Text('Delete All Logs', style: TextStyle(color: Colors.white)),
        content: const Text('Do you want to Delete All Logs ?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            //child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _pomodoroTimer.clearLogs();
              Navigator.pop(ctx);
            },
            //child: const Text('削除'),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Build
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final stateColor = _pomodoroTimer.stateColor;
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ----- Task Name (Editable) -----
            GestureDetector(
              onTap: _showEditTaskDialog,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _pomodoroTimer.taskName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.edit,
                        size: 18, color: Colors.white.withOpacity(0.5)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ----- State Label -----
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _pomodoroTimer.stateLabel,
                key: ValueKey(_pomodoroTimer.timerState),
                style: TextStyle(
                  color: stateColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // ----- Circular Progress Timer -----
            Expanded(
              flex: 3,
              child: CircularProgress(
                progress: _pomodoroTimer.progress,
                color: stateColor,
                formattedTime: _pomodoroTimer.formattedTime,
                completedSets: _pomodoroTimer.completedSets,
                setsPerRound: PomodoroTimer.setsPerRound,
                pulseAnimation: _pulseAnimation,
              ),
            ),

            // ----- Control Buttons -----
            ControlButtons(
              isRunning: _pomodoroTimer.isRunning,
              canSkipBreak: _pomodoroTimer.canSkipBreak,
              stateColor: stateColor,
              onReset: _pomodoroTimer.resetTimer,
              onStartPause: _pomodoroTimer.isRunning
                  ? _pomodoroTimer.pauseTimer
                  : _pomodoroTimer.startTimer,
              onSkip: _pomodoroTimer.skipBreak,
            ),

            const SizedBox(height: 20),

            // ----- Log Section -----
            Expanded(
              flex: 2,
              child: LogList(
                logs: _pomodoroTimer.logs,
                stateColor: stateColor,
                onClearLogs: _showClearLogsDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../pomodoro_timer.dart';

// ============================================================
// Log List Widget
// ============================================================
class LogList extends StatelessWidget {
  final List<PomodoroLog> logs;
  final Color stateColor;
  final VoidCallback onClearLogs;

  const LogList({
    super.key,
    required this.logs,
    required this.stateColor,
    required this.onClearLogs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
            child: Row(
              children: [
                Icon(Icons.history,
                    color: Colors.white.withOpacity(0.5), size: 18),
                const SizedBox(width: 8),
                Text(
                  //'完了ログ',
                  'Completed Log',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (logs.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: Colors.white.withOpacity(0.3), size: 18),
                    onPressed: onClearLogs,
                    //tooltip: 'ログを全て削除',
                    tooltip: 'Delete All Logs',
                  ),
              ],
            ),
          ),
          // Log items
          Expanded(
            child: logs.isEmpty
                ? Center(
                    child: Text(
                      //'まだログがありません',
                      'No Logs yet',
                      style:
                          TextStyle(color: Colors.white.withOpacity(0.25)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final dateStr =
                          DateFormat('MM/dd HH:mm').format(log.completedAt);
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text(
                              dateStr,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 13,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                log.taskName,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: stateColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${log.completedSets}セット',
                                style: TextStyle(
                                  color: stateColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

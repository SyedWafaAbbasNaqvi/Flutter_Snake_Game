import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../models/point.dart';
import 'widgets/board_painter.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  Timer? _timer;
  final FocusNode _focusNode = FocusNode();
  Offset? _panStartOffset;

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 160), (_) {
      ref.read(gameProvider.notifier).update();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final notifier = ref.read(gameProvider.notifier);
    final state = ref.read(gameProvider);

    if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.keyW) {
      notifier.changeDirection(Direction.up);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.keyS) {
      notifier.changeDirection(Direction.down);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.keyA) {
      notifier.changeDirection(Direction.left);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.keyD) {
      notifier.changeDirection(Direction.right);
    } else if (event.logicalKey == LogicalKeyboardKey.space) {
      if (state.isGameOver) {
        notifier.resetGame();
      } else {
        notifier.togglePause();
      }
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.keyR) {
      if (state.isGameOver) {
        notifier.resetGame();
      }
    }
  }

  void _onPanStart(DragStartDetails details) {
    _panStartOffset = details.localPosition;
    _focusNode.requestFocus();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_panStartOffset == null) return;
    final currentOffset = details.localPosition;
    final dx = currentOffset.dx - _panStartOffset!.dx;
    final dy = currentOffset.dy - _panStartOffset!.dy;
    const threshold = 20.0;

    if (dx.abs() > threshold || dy.abs() > threshold) {
      final notifier = ref.read(gameProvider.notifier);
      if (dx.abs() > dy.abs()) {
        if (dx > 0) {
          notifier.changeDirection(Direction.right);
        } else {
          notifier.changeDirection(Direction.left);
        }
      } else {
        if (dy > 0) {
          notifier.changeDirection(Direction.down);
        } else {
          notifier.changeDirection(Direction.up);
        }
      }
      // Reset start offset to enable chaining gestures continuously
      _panStartOffset = currentOffset;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _panStartOffset = null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Snake Game 🐍',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF1E293B),
          elevation: 2,
          actions: [
            IconButton(
              icon: Icon(
                state.isPaused ? Icons.play_arrow : Icons.pause,
                color: const Color(0xFF38BDF8),
              ),
              tooltip: state.isPaused ? 'Resume (Space)' : 'Pause (Space)',
              onPressed: state.isGameOver
                  ? null
                  : () {
                      ref.read(gameProvider.notifier).togglePause();
                      _focusNode.requestFocus();
                    },
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8)),
              tooltip: 'Restart Game',
              onPressed: () {
                ref.read(gameProvider.notifier).resetGame();
                _focusNode.requestFocus();
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Score Banner
              _buildScoreBanner(state),
              const SizedBox(height: 12),
              // Game Board Area with Gestures
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF020617),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF334155), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        onTap: () => _focusNode.requestFocus(),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CustomPaint(
                              painter: BoardPainter(
                                snake: state.snake,
                                food: state.food,
                                direction: state.direction,
                                gridSize: GameNotifier.gridSize,
                              ),
                            ),
                            if (state.isPaused && !state.isGameOver)
                              _buildPausedOverlay(),
                            if (state.isGameOver)
                              _buildGameOverOverlay(state),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // On-Screen D-Pad for Mobile / Touch
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildDPad(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBanner(GameState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn('SCORE', '${state.score}', const Color(0xFF34D399)),
          _buildStatColumn('BEST', '${state.highScore}', const Color(0xFFFBBF24)),
          _buildStatColumn('LENGTH', '${state.snake.length}', Colors.white),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPausedOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.pause_circle_outline,
              size: 56,
              color: Color(0xFF38BDF8),
            ),
            const SizedBox(height: 8),
            const Text(
              'PAUSED',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF38BDF8),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                ref.read(gameProvider.notifier).togglePause();
                _focusNode.requestFocus();
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Resume (Space)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay(GameState state) {
    final isWon = state.isWon;
    final primaryColor = isWon ? const Color(0xFFFBBF24) : const Color(0xFFEF4444);

    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isWon ? Icons.emoji_events : Icons.sentiment_very_dissatisfied,
              size: 56,
              color: primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              isWon ? 'VICTORY! 🏆' : 'GAME OVER',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryColor,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Score: ${state.score}  •  Best: ${state.highScore}',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                ref.read(gameProvider.notifier).resetGame();
                _focusNode.requestFocus();
              },
              icon: const Icon(Icons.replay),
              label: const Text('Play Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDPad() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDirectionButton(Icons.keyboard_arrow_up, Direction.up),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDirectionButton(Icons.keyboard_arrow_left, Direction.left),
            const SizedBox(width: 44),
            _buildDirectionButton(Icons.keyboard_arrow_right, Direction.right),
          ],
        ),
        const SizedBox(height: 4),
        _buildDirectionButton(Icons.keyboard_arrow_down, Direction.down),
      ],
    );
  }

  Widget _buildDirectionButton(IconData icon, Direction dir) {
    return Material(
      color: const Color(0xFF1E293B),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          ref.read(gameProvider.notifier).changeDirection(dir);
          _focusNode.requestFocus();
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 28, color: const Color(0xFF38BDF8)),
        ),
      ),
    );
  }
}

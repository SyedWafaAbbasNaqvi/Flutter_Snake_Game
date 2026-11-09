import 'package:flutter/material.dart';
import '../../models/point.dart';

class BoardPainter extends CustomPainter {
  final List<Point> snake;
  final Point food;
  final Direction direction;
  final int gridSize;

  BoardPainter({
    required this.snake,
    required this.food,
    required this.direction,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / gridSize;

    // Draw background grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= gridSize; i++) {
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        gridPaint,
      );
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        gridPaint,
      );
    }

    // Draw Food
    final foodPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;

    final foodPadding = cellSize * 0.12;
    final foodRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        food.x * cellSize + foodPadding,
        food.y * cellSize + foodPadding,
        cellSize - foodPadding * 2,
        cellSize - foodPadding * 2,
      ),
      const Radius.circular(5),
    );
    canvas.drawRRect(foodRect, foodPaint);

    // Food stem
    final stemPaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset((food.x + 0.5) * cellSize, food.y * cellSize + foodPadding),
      Offset((food.x + 0.6) * cellSize, food.y * cellSize + 2),
      stemPaint,
    );

    // Draw Snake
    for (int i = 0; i < snake.length; i++) {
      final segment = snake[i];
      final isHead = i == 0;
      final snakePaint = Paint()
        ..color = isHead ? const Color(0xFF34D399) : const Color(0xFF10B981)
        ..style = PaintingStyle.fill;

      final padding = cellSize * 0.08;
      final segmentRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          segment.x * cellSize + padding,
          segment.y * cellSize + padding,
          cellSize - padding * 2,
          cellSize - padding * 2,
        ),
        Radius.circular(isHead ? 6 : 3),
      );
      canvas.drawRRect(segmentRect, snakePaint);

      // Draw eyes on the snake head
      if (isHead) {
        _drawEyes(canvas, segment, cellSize);
      }
    }
  }

  void _drawEyes(Canvas canvas, Point head, double cellSize) {
    final eyePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = const Color(0xFF0F172A);

    final eyeRadius = cellSize * 0.12;
    final pupilRadius = cellSize * 0.06;

    final headLeft = head.x * cellSize;
    final headTop = head.y * cellSize;

    Offset eye1;
    Offset eye2;
    Offset pupilOffset;

    switch (direction) {
      case Direction.up:
        eye1 = Offset(headLeft + cellSize * 0.3, headTop + cellSize * 0.3);
        eye2 = Offset(headLeft + cellSize * 0.7, headTop + cellSize * 0.3);
        pupilOffset = const Offset(0, -1);
        break;
      case Direction.down:
        eye1 = Offset(headLeft + cellSize * 0.3, headTop + cellSize * 0.7);
        eye2 = Offset(headLeft + cellSize * 0.7, headTop + cellSize * 0.7);
        pupilOffset = const Offset(0, 1);
        break;
      case Direction.left:
        eye1 = Offset(headLeft + cellSize * 0.3, headTop + cellSize * 0.3);
        eye2 = Offset(headLeft + cellSize * 0.3, headTop + cellSize * 0.7);
        pupilOffset = const Offset(-1, 0);
        break;
      case Direction.right:
        eye1 = Offset(headLeft + cellSize * 0.7, headTop + cellSize * 0.3);
        eye2 = Offset(headLeft + cellSize * 0.7, headTop + cellSize * 0.7);
        pupilOffset = const Offset(1, 0);
        break;
    }

    canvas.drawCircle(eye1, eyeRadius, eyePaint);
    canvas.drawCircle(eye2, eyeRadius, eyePaint);

    canvas.drawCircle(eye1 + pupilOffset, pupilRadius, pupilPaint);
    canvas.drawCircle(eye2 + pupilOffset, pupilRadius, pupilPaint);
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return oldDelegate.snake != snake ||
        oldDelegate.food != food ||
        oldDelegate.direction != direction ||
        oldDelegate.gridSize != gridSize;
  }
}

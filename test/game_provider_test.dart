import 'package:flutter_test/flutter_test.dart';
import 'package:snake_game/features/game/models/point.dart';
import 'package:snake_game/features/game/providers/game_provider.dart';

void main() {
  group('GameNotifier Unit Tests', () {
    late GameNotifier notifier;

    setUp(() {
      notifier = GameNotifier();
    });

    test('Initial state is correctly set', () {
      final state = notifier.state;
      expect(state.snake, const [Point(10, 10), Point(10, 11), Point(10, 12)]);
      expect(state.food, const Point(5, 5));
      expect(state.direction, Direction.up);
      expect(state.isGameOver, false);
      expect(state.isWon, false);
      expect(state.isPaused, false);
      expect(state.score, 0);
      expect(state.highScore, 0);
    });

    test('Moving UP updates snake head and tail correctly', () {
      notifier.update();
      expect(notifier.state.snake.first, const Point(10, 9));
      expect(notifier.state.snake.length, 3);
      expect(notifier.state.snake.last, const Point(10, 11));
    });

    test('Direct 180-degree turn is ignored', () {
      expect(notifier.state.direction, Direction.up);
      notifier.changeDirection(Direction.down);
      notifier.update();
      // Should still be moving UP, not DOWN
      expect(notifier.state.direction, Direction.up);
      expect(notifier.state.snake.first, const Point(10, 9));
    });

    test('Rapid key presses do not cause 180-degree turn suicide (Queue buffering)', () {
      // Snake is moving UP. User quickly presses RIGHT then DOWN before update() runs.
      notifier.changeDirection(Direction.right);
      notifier.changeDirection(Direction.down);

      // Tick 1: should turn RIGHT
      notifier.update();
      expect(notifier.state.direction, Direction.right);
      expect(notifier.state.snake.first, const Point(11, 10));
      expect(notifier.state.isGameOver, false);

      // Tick 2: should turn DOWN
      notifier.update();
      expect(notifier.state.direction, Direction.down);
      expect(notifier.state.snake.first, const Point(11, 11));
      expect(notifier.state.isGameOver, false);
    });

    test('Opposite turn in queue is prevented', () {
      // Snake is moving UP. User queues RIGHT, then immediately tries to queue LEFT.
      notifier.changeDirection(Direction.right);
      notifier.changeDirection(Direction.left); // Opposite of RIGHT, should be rejected

      notifier.update();
      expect(notifier.state.direction, Direction.right);

      notifier.update();
      // Direction remains RIGHT because LEFT was rejected
      expect(notifier.state.direction, Direction.right);
    });

    test('Wall collision on top boundary triggers game over', () {
      // Move snake to top edge y = 0 then y < 0
      while (notifier.state.snake.first.y > 0) {
        notifier.update();
      }
      expect(notifier.state.snake.first.y, 0);
      expect(notifier.state.isGameOver, false);

      // Next tick crosses boundary
      notifier.update();
      expect(notifier.state.isGameOver, true);
    });

    test('Wall collision on left boundary triggers game over', () {
      notifier.changeDirection(Direction.left);
      while (notifier.state.snake.first.x > 0) {
        notifier.update();
      }
      expect(notifier.state.snake.first.x, 0);
      expect(notifier.state.isGameOver, false);

      notifier.update();
      expect(notifier.state.isGameOver, true);
    });

    test('Eating food increases score, length, and generates new food', () {
      // Set snake right next to food
      notifier.state = notifier.state.copyWith(
        snake: const [Point(5, 6), Point(5, 7), Point(5, 8)],
        food: const Point(5, 5),
        direction: Direction.up,
      );

      notifier.update();

      expect(notifier.state.snake.first, const Point(5, 5));
      expect(notifier.state.snake.length, 4); // Grew by 1
      expect(notifier.state.score, 10);
      expect(notifier.state.highScore, 10);
      expect(notifier.state.food, isNot(const Point(5, 5))); // New food generated
      expect(notifier.state.snake.contains(notifier.state.food), false);
    });

    test('Chasing tail does not cause false self-collision', () {
      // Create a 4-segment loop where head can step into the current tail cell
      // Head at (2, 1), body at (2, 2), (1, 2), tail at (1, 1).
      // Head moves LEFT to (1, 1).
      notifier.state = notifier.state.copyWith(
        snake: const [Point(2, 1), Point(2, 2), Point(1, 2), Point(1, 1)],
        food: const Point(10, 10), // Far away
        direction: Direction.left,
      );

      notifier.update();

      // Tail at (1, 1) moved forward to (1, 2), so head at (1, 1) is valid!
      expect(notifier.state.isGameOver, false);
      expect(notifier.state.snake.first, const Point(1, 1));
      expect(notifier.state.snake.length, 4);
    });

    test('True self-collision triggers game over', () {
      // Snake of length 5:
      // (2, 2) -> (2, 3) -> (3, 3) -> (3, 2) -> (3, 1)
      // Head at (2, 2) moving RIGHT into (3, 2) which is NOT the tail
      notifier.state = notifier.state.copyWith(
        snake: const [
          Point(2, 2),
          Point(2, 3),
          Point(3, 3),
          Point(3, 2),
          Point(3, 1),
        ],
        food: const Point(10, 10),
        direction: Direction.right,
      );

      notifier.update();

      expect(notifier.state.isGameOver, true);
    });

    test('Pause prevents game from updating', () {
      notifier.togglePause();
      expect(notifier.state.isPaused, true);

      final initialHead = notifier.state.snake.first;
      notifier.update();
      expect(notifier.state.snake.first, initialHead);

      notifier.togglePause();
      expect(notifier.state.isPaused, false);
      notifier.update();
      expect(notifier.state.snake.first, isNot(initialHead));
    });

    test('Resetting game resets score and snake but preserves high score', () {
      // Set high score
      notifier.state = notifier.state.copyWith(
        score: 50,
        highScore: 50,
        isGameOver: true,
      );

      notifier.resetGame();

      expect(notifier.state.score, 0);
      expect(notifier.state.highScore, 50);
      expect(notifier.state.isGameOver, false);
      expect(notifier.state.snake.length, 3);
    });

    test('Full board triggers victory', () {
      // Fill the board almost completely (all 400 points except food at (0, 0))
      final allPoints = <Point>[];
      for (int x = 0; x < GameNotifier.gridSize; x++) {
        for (int y = 0; y < GameNotifier.gridSize; y++) {
          if (x != 0 || y != 0) {
            allPoints.add(Point(x, y));
          }
        }
      }

      // Head is at (0, 1), food is at (0, 0), moving UP
      // When head moves into (0, 0), snake takes all 400 cells
      allPoints.remove(const Point(0, 1));
      allPoints.insert(0, const Point(0, 1));

      notifier.state = notifier.state.copyWith(
        snake: allPoints,
        food: const Point(0, 0),
        direction: Direction.up,
      );

      notifier.update();

      expect(notifier.state.isWon, true);
      expect(notifier.state.isGameOver, true);
      expect(notifier.state.snake.length, 400);
    });
  });
}


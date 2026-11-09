import 'dart:collection';
import 'dart:math' show Random, max;
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/point.dart';

class GameState extends Equatable {
  final List<Point> snake;
  final Point food;
  final Direction direction;
  final bool isGameOver;
  final bool isWon;
  final bool isPaused;
  final int score;
  final int highScore;

  const GameState({
    required this.snake,
    required this.food,
    required this.direction,
    required this.isGameOver,
    this.isWon = false,
    this.isPaused = false,
    required this.score,
    this.highScore = 0,
  });

  GameState copyWith({
    List<Point>? snake,
    Point? food,
    Direction? direction,
    bool? isGameOver,
    bool? isWon,
    bool? isPaused,
    int? score,
    int? highScore,
  }) {
    return GameState(
      snake: snake ?? this.snake,
      food: food ?? this.food,
      direction: direction ?? this.direction,
      isGameOver: isGameOver ?? this.isGameOver,
      isWon: isWon ?? this.isWon,
      isPaused: isPaused ?? this.isPaused,
      score: score ?? this.score,
      highScore: highScore ?? this.highScore,
    );
  }

  @override
  List<Object?> get props => [
        snake,
        food,
        direction,
        isGameOver,
        isWon,
        isPaused,
        score,
        highScore,
      ];
}

class GameNotifier extends StateNotifier<GameState> {
  static const int gridSize = 20;

  // Queue to buffer rapid user inputs and prevent 180-degree suicide turns
  final Queue<Direction> _inputQueue = Queue<Direction>();

  GameNotifier()
      : super(const GameState(
          snake: [Point(10, 10), Point(10, 11), Point(10, 12)],
          food: Point(5, 5),
          direction: Direction.up,
          isGameOver: false,
          isWon: false,
          isPaused: false,
          score: 0,
          highScore: 0,
        ));

  void togglePause() {
    if (state.isGameOver) return;
    state = state.copyWith(isPaused: !state.isPaused);
  }

  void changeDirection(Direction newDirection) {
    if (state.isGameOver || state.isPaused) return;

    // Use the last queued direction, or the current state direction if queue is empty
    final referenceDirection =
        _inputQueue.isNotEmpty ? _inputQueue.last : state.direction;

    // Prevent turning directly into the opposite direction or duplicating the same direction
    if (_isOpposite(referenceDirection, newDirection) ||
        referenceDirection == newDirection) {
      return;
    }

    // Limit queue size to 2 to prevent sluggish input lag while allowing smooth cornering
    if (_inputQueue.length < 2) {
      _inputQueue.add(newDirection);
    }
  }

  bool _isOpposite(Direction d1, Direction d2) {
    return (d1 == Direction.up && d2 == Direction.down) ||
        (d1 == Direction.down && d2 == Direction.up) ||
        (d1 == Direction.left && d2 == Direction.right) ||
        (d1 == Direction.right && d2 == Direction.left);
  }

  void update() {
    if (state.isGameOver || state.isPaused) return;

    // Dequeue next direction if available
    Direction currentDirection = state.direction;
    if (_inputQueue.isNotEmpty) {
      currentDirection = _inputQueue.removeFirst();
    }

    final head = state.snake.first;
    Point newHead;

    switch (currentDirection) {
      case Direction.up:
        newHead = Point(head.x, head.y - 1);
        break;
      case Direction.down:
        newHead = Point(head.x, head.y + 1);
        break;
      case Direction.left:
        newHead = Point(head.x - 1, head.y);
        break;
      case Direction.right:
        newHead = Point(head.x + 1, head.y);
        break;
    }

    // Wall collision check
    if (newHead.x < 0 ||
        newHead.x >= gridSize ||
        newHead.y < 0 ||
        newHead.y >= gridSize) {
      _inputQueue.clear();
      state = state.copyWith(
        direction: currentDirection,
        isGameOver: true,
      );
      return;
    }

    // Self collision check:
    // If the snake eats food, the tail does not move forward.
    // If the snake does not eat food, the tail moves forward, so moving into the current
    // tail position is NOT a self collision (tail chasing).
    final isEatingFood = newHead == state.food;
    final bodyToCheck = isEatingFood
        ? state.snake
        : state.snake.sublist(0, state.snake.length - 1);

    if (bodyToCheck.contains(newHead)) {
      _inputQueue.clear();
      state = state.copyWith(
        direction: currentDirection,
        isGameOver: true,
      );
      return;
    }

    final List<Point> newSnake = [newHead, ...state.snake];
    Point newFood = state.food;
    int newScore = state.score;
    bool isWon = false;

    if (isEatingFood) {
      newScore += 10;
      final generatedFood = _generateFood(newSnake);
      if (generatedFood == null) {
        // Snake has filled the entire grid!
        isWon = true;
      } else {
        newFood = generatedFood;
      }
    } else {
      newSnake.removeLast();
    }

    final newHighScore = max(state.highScore, newScore);

    state = state.copyWith(
      snake: newSnake,
      food: newFood,
      direction: currentDirection,
      score: newScore,
      highScore: newHighScore,
      isGameOver: isWon,
      isWon: isWon,
    );
  }

  Point? _generateFood(List<Point> currentSnake) {
    final snakeSet = currentSnake.toSet();
    final availablePoints = <Point>[];

    for (int x = 0; x < gridSize; x++) {
      for (int y = 0; y < gridSize; y++) {
        final p = Point(x, y);
        if (!snakeSet.contains(p)) {
          availablePoints.add(p);
        }
      }
    }

    if (availablePoints.isEmpty) {
      return null;
    }

    final random = Random();
    return availablePoints[random.nextInt(availablePoints.length)];
  }

  void resetGame() {
    _inputQueue.clear();
    state = GameState(
      snake: const [Point(10, 10), Point(10, 11), Point(10, 12)],
      food: const Point(5, 5),
      direction: Direction.up,
      isGameOver: false,
      isWon: false,
      isPaused: false,
      score: 0,
      highScore: state.highScore, // Preserve session high score
    );
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier();
});

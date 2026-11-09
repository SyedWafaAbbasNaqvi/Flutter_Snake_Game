import 'package:equatable/equatable.dart';

class Point extends Equatable {
  final int x;
  final int y;

  const Point(this.x, this.y);

  @override
  List<Object?> get props => [x, y];
}

enum Direction { up, down, left, right }
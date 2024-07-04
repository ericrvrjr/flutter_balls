import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class MyBall extends CircleComponent with HasGameRef {
  static const double ballRadius = 20.0;
  static const double ballSpeed = 100.0; // Adjust speed as needed
  Vector2 _velocity = Vector2(0, 0);
  final Paint _originalPaint = Paint()..color = Colors.red;
  final Paint _collisionPaint = Paint()
    ..color = Colors.red; // New color for collision

  bool _isColliding = false;
  double _collisionDuration = 1; // Duration in seconds to keep collision color

  MyBall(Vector2 position, Color color)
      : super(
          position: position,
          radius: ballRadius,
          paint: Paint()..color = color, // Red color
        );

  bool isOnScreen() {
    return position.x >= 0 &&
        position.x <= game.size.x &&
        position.y >= 0 &&
        position.y <= game.size.y;
  }

  Vector2 collides(MyBall other) {
    // Calculate distance between centers of circles
    double dx = position.x - other.position.x;
    double dy = position.y - other.position.y;
    double distance = sqrt(dx * dx + dy * dy);

    bool isColliding = distance < radius + other.radius;

    // Change color if colliding
    if (isColliding) {
      _isColliding = true;
      // paint = _collisionPaint;
      Vector2 collisionNormal = (other.position - position).normalized();
      Vector2 relativeVelocity = other.velocity - velocity;
      double relativeVelocityAlongNormal =
          relativeVelocity.dot(collisionNormal);
      if (relativeVelocityAlongNormal < 0) {
        double restitution = 1; // Restitution coefficient (elastic collision)
        double impulseMagnitude =
            -(1 + restitution) * relativeVelocityAlongNormal;
        impulseMagnitude /= 1 / radius + 1 / other.radius;
        return collisionNormal * impulseMagnitude;
      }
    }
    return Vector2.zero();
  }

  Vector2 get velocity => _velocity;
  set velocity(Vector2 value) {
    _velocity = value.normalized() * MyBall.ballSpeed;
  }

  void reverseDirection() {
    _velocity *= -1;
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += _velocity * dt;

    // Check for screen boundaries and remove ball if needed
    if (!isOnScreen()) {
      removeFromParent();
    }
  }

  void updateWithCollision(double dt, MyBall otherBall) {
    // Apply impulse if received from collision
    final impulse = collides(otherBall);
    if (impulse.x != 0 || impulse.y != 0) {
      _velocity -= impulse / MyBall.ballSpeed * 10;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(position.toOffset(), radius, paint);
  }
}

class BouncingBalls extends FlameGame {
  bool onTapDown(TapDownDetails details) {
    final tapPosition = details.localPosition;
    final random = Random();
    final randomDirection = Vector2(
      random.nextDouble() * 2 - 1, // Random number between -1 and 1
      random.nextDouble() * 2 - 1, // Random number between -1 and 1
    );

    final randomColor = Color.fromRGBO(
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
      1.0,
    );

    final normalizedDirection = randomDirection.normalized();

    final ball = MyBall(Vector2(tapPosition.dx, tapPosition.dy), randomColor);
    ball.velocity = normalizedDirection.normalized() * MyBall.ballSpeed;
    add(ball);
    // print("Adding MyBall at $tapPosition, Children count: ${children.length}");
    return true; // Absorb the tap event
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Check for collisions between all balls
    for (final ball1 in children.whereType<MyBall>()) {
      for (final ball2 in children.whereType<MyBall>()) {
        if (ball1 != ball2) {
          ball1.updateWithCollision(
              dt, ball2); // Apply collision logic with other ball
          // ... (optional) other logic for ball interactions
        }else{
          ball2.updateWithCollision(
              dt, ball1);
        }
      }
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  BouncingBalls _game = BouncingBalls();
  @override
  void initState() {
    super.initState();
    _game = BouncingBalls();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: GestureDetector(
          onTapDown: (details) =>
              _game.onTapDown(details), // Pass tap handling to game logic
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: GameWidget(
              game: _game,
            ),
          ), // Your game widget here
        ),
      ),
    );
  }
}

void main() {
  runApp(const MyApp());
}

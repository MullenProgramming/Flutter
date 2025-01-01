import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const FireworksApp());
}

class FireworksApp extends StatelessWidget {
  const FireworksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: const FireworksCanvas(),
      ),
    );
  }
}

class FireworksCanvas extends StatefulWidget {
  const FireworksCanvas({super.key});

  @override
  FireworksCanvasState createState() => FireworksCanvasState();
}

class FireworksCanvasState extends State<FireworksCanvas> with SingleTickerProviderStateMixin {
  final List<Particle> particles = [];
  final List<Rocket> rockets = [];
  final Random random = Random();
  late Timer timer;

  final List<Color> colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      setState(() {
        updateParticles();
        updateRockets();
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void updateParticles() {
    for (int i = particles.length - 1; i >= 0; i--) {
      final particle = particles[i];
      particle.update();
      if (particle.life <= 0) {
        particles.removeAt(i);
      }
    }
  }

  void updateRockets() {
    for (int i = rockets.length - 1; i >= 0; i--) {
      final rocket = rockets[i];
      rocket.update();
      if (rocket.y <= rocket.targetY) {
        rockets.removeAt(i);
        explode(rocket.x, rocket.y, rocket.color);
      }
    }

    if (random.nextDouble() < 0.04) {
      createRocket();
    }
  }

  void createRocket() {
    rockets.add(Rocket(
      x: random.nextDouble() * MediaQuery.of(context).size.width,
      y: MediaQuery.of(context).size.height,
      targetY: 100 + random.nextDouble() * 200,
      color: colors[random.nextInt(colors.length)],
    ));
  }

  void explode(double x, double y, Color color) {
    for (int i = 0; i < 50; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final velocity = 2 + random.nextDouble() * 2;
      particles.add(Particle(
        x: x,
        y: y,
        vx: cos(angle) * velocity,
        vy: sin(angle) * velocity,
        color: color,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: FireworksPainter(particles, rockets),
      size: Size.infinite,
    );
  }
}

class FireworksPainter extends CustomPainter {
  final List<Particle> particles;
  final List<Rocket> rockets;

  FireworksPainter(this.particles, this.rockets);

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: particle.life / 100)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        2 * particle.life / 100,
        paint,
      );
    }

    for (final rocket in rockets) {
      final paint = Paint()
        ..color = rocket.color
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTWH(rocket.x, rocket.y, 2, 8),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(FireworksPainter oldDelegate) => true;
}

class Particle {
  double x;
  double y;
  final double vx;
  double vy;
  double life;
  final Color color;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    this.life = 100,
  });

  void update() {
    x += vx;
    y += vy;
    vy += 0.1;
    life -= 1;
  }
}

class Rocket {
  double x;
  double y;
  final double targetY;
  final Color color;

  Rocket({
    required this.x,
    required this.y,
    required this.targetY,
    required this.color,
  });

  void update() {
    y -= 5;
  }
}

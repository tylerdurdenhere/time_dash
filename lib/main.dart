import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TimeDash',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const TimeDashGame(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TimeDashGame extends StatefulWidget {
  const TimeDashGame({super.key});

  @override
  State<TimeDashGame> createState() => _TimeDashGameState();
}

class _TimeDashGameState extends State<TimeDashGame>
    with SingleTickerProviderStateMixin {
  static const int initialMs = 1500;
  static const int minMs = 500;
  static const int decrementMs = 100;

  late int allowedMs;
  late AnimationController _controller;
  DateTime? _roundStart;

  int score = 0;
  int streak = 0;
  int highScore = 0;
  int lastReaction = 0;
  double avgReaction = 0.0;
  int rounds = 0;
  bool playing = false;
  double _tapScale = 1.0;

  @override
  void initState() {
    super.initState();
    allowedMs = initialMs;
    _controller =
        AnimationController(
            vsync: this,
            duration: Duration(milliseconds: allowedMs),
          )
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) _onFail();
          })
          ..addListener(() => setState(() {}));
  }

  void _startGame() {
    setState(() {
      score = 0;
      streak = 0;
      rounds = 0;
      avgReaction = 0.0;
      allowedMs = initialMs;
      playing = true;
    });
    _startRound();
  }

  void _startRound() {
    _controller.stop();
    _controller.duration = Duration(milliseconds: allowedMs);
    _controller.reset();
    _roundStart = DateTime.now();
    _controller.forward(from: 0.0);
  }

  void _onTap() {
    if (!playing) return;
    if (_controller.isAnimating) {
      final reaction = DateTime.now().difference(_roundStart!).inMilliseconds;
      lastReaction = reaction;
      rounds++;
      avgReaction = ((avgReaction * (rounds - 1)) + reaction) / rounds;

      setState(() {
        score++;
        streak++;
        if (score > highScore) highScore = score;
        allowedMs = allowedMs - decrementMs;
        if (allowedMs < minMs) allowedMs = minMs;
        _tapScale = 1.15;
      });

      Future.delayed(const Duration(milliseconds: 120), () {
        setState(() => _tapScale = 1.0);
        _startRound();
      });
    }
  }

  void _onFail() {
    setState(() {
      playing = false;
      streak = 0;
    });
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Game over'),
        content: Text(
          'Score: $score\nAvg reaction: ${avgReaction.toStringAsFixed(0)} ms',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _startGame();
            },
            child: const Text('Play again'),
          ),
        ],
      ),
    );
  }

  void _resetHighScore() {
    setState(() {
      highScore = 0;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1.0 - _controller.value; // remaining fraction
    return Scaffold(
      appBar: AppBar(title: const Text('TimeDash')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Score: $score',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('Streak: $streak', style: const TextStyle(fontSize: 18)),
                Text('High: $highScore', style: const TextStyle(fontSize: 18)),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress, minHeight: 12),
            const SizedBox(height: 32),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: _onTap,
                  child: AnimatedScale(
                    scale: _tapScale,
                    duration: const Duration(milliseconds: 120),
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        color: playing ? Colors.green : Colors.grey.shade400,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          playing ? 'TAP' : 'START',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              playing ? 'Tap before the bar ends!' : 'Press circle to start',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [const Text('Last'), Text('$lastReaction ms')],
                ),
                Column(
                  children: [
                    const Text('Avg'),
                    Text('${avgReaction.toStringAsFixed(0)} ms'),
                  ],
                ),
                ElevatedButton(
                  onPressed: playing ? null : _startGame,
                  child: const Text('Start'),
                ),
                TextButton(
                  onPressed: _resetHighScore,
                  child: const Text('Reset High'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Tip: each success reduces allowed time by 100ms (min 500ms).',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

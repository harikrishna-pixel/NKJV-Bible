import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class CountdownTimerPage extends StatefulWidget {
  const CountdownTimerPage({super.key});

  @override
  _CountdownTimerPageState createState() => _CountdownTimerPageState();
}

class _CountdownTimerPageState extends State<CountdownTimerPage> {
  late SharedPreferences _prefs;
  late Timer _timer;
  final int _countdownDuration =
      3 * 24 * 60 * 60; // Countdown duration in seconds
  int _remainingTime = 0;

  @override
  void initState() {
    super.initState();
    _initPreferences();
  }

  void _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _startTimer();
  }

  void _startTimer() {
    int? startTime = _prefs.getInt('countdownStartTime');
    int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _remainingTime = _countdownDuration - (currentTime - startTime!);
    if (_remainingTime <= 0) {
      // Countdown timer has ended
      _remainingTime = 0;
    } else {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _remainingTime--;
          if (_remainingTime <= 0) {
            // Countdown timer has ended
            _remainingTime = 0;
            timer.cancel();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int hours = (_remainingTime ~/ 3600).toInt();
    int minutes = ((_remainingTime ~/ 60) % 60).toInt();
    int seconds = (_remainingTime % 60).toInt();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/lightMode/day_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: AlertDialog(
            title: const Text(
              'Successfully you have earned the reward',
            ),
            content: SizedBox(
              height: 70,
              child: Column(
                children: [
                  const Text('The ads will stop untill',
                      style: TextStyle(
                          letterSpacing: BibleInfo.letterSpacing,
                          fontSize: BibleInfo.fontSizeScale * 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: TextStyle(
                        letterSpacing: BibleInfo.letterSpacing,
                        fontSize: BibleInfo.fontSizeScale * 25,
                        color: Colors.red),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

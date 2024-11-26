import 'package:flutter/material.dart';
import '../services/progress_service.dart';
import '../models/achievement_data.dart';
import '../widgets/achievement_card.dart';
import '../widgets/streak_calendar.dart'; 
// ignore: unused_import
import '../widgets/loading_overlay.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late Future<List<Achievement>> _achievementsFuture;
  late Future<int> _currentStreakFuture;
  late Future<List<DateTime>> _streakDatesFuture;
  late Future<List<DateTime>> _missedDatesFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _updateStreakOnLogin();
  }

  void _fetchData() {
    _achievementsFuture = ProgressService.getAllAchievements();
    _currentStreakFuture = ProgressService.getCurrentStreak();
    _streakDatesFuture = ProgressService.getStreakDates();
    _missedDatesFuture = ProgressService.getMissedDates();
  }

  Future<void> _updateStreakOnLogin() async {
    await ProgressService.updateStreak();
    setState(() {
      _fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF66D7D1),
        elevation: 0,
        title: const Text(
          'Your Progress',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentStreakCard(),
            const SizedBox(height: 32),
            _buildStreakCalendar(),
            const SizedBox(height: 32),
            _buildAchievementsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStreakCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF66D7D1),
            Color.fromARGB(203, 233, 157, 131),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 25, 50, 49).withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Icon(
            Icons.whatshot,
            size: 40,
            color: Colors.white,
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Streak',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<int>(
                future: _currentStreakFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    );
                  } else if (snapshot.hasError) {
                    return Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    );
                  } else {
                    final streak = snapshot.data ?? 0;
                    return Text(
                      '$streak day${streak == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCalendar() {
    return FutureBuilder<List<List<DateTime>>>(
      future: Future.wait([_streakDatesFuture, _missedDatesFuture]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('Calendar: Loading dates...');
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          print('Calendar Error: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData) {
          print('Calendar: No data available');
          return const Center(child: Text('No streak data found.'));
        }

        final streakDates = snapshot.data![0];
        final missedDates = snapshot.data![1];

        print('Calendar Rendering:');
        print('Streak dates count: ${streakDates.length}');
        streakDates.forEach((date) => print('Streak date: ${date.toIso8601String()}'));
        print('Missed dates count: ${missedDates.length}');
        missedDates.forEach((date) => print('Missed date: ${date.toIso8601String()}'));

        return StreakCalendar(
          streakDates: streakDates,
          missedDates: missedDates,
        );
      },
    );
}

  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: TextStyle(
            color: const Color(0xFF18314F),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Achievement>>(
          future: _achievementsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('No achievements found.'));
            }

            final achievements = snapshot.data!;

            return GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: achievements.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                return AchievementCard(achievement: achievement);
              },
            );
          },
        ),
      ],
    );
  }
}
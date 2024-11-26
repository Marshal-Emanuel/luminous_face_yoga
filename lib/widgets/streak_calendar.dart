import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StreakCalendar extends StatefulWidget {
  final List<DateTime> streakDates;
  final List<DateTime> missedDates;

  const StreakCalendar({
    Key? key,
    required this.streakDates,
    required this.missedDates,
  }) : super(key: key);

  @override
  _StreakCalendarState createState() => _StreakCalendarState();
}

class _StreakCalendarState extends State<StreakCalendar> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  /// Helper method to compare two dates by year, month, and day.
  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMonthHeader(),
        const SizedBox(height: 16),
        _buildDayLabels(),
        const SizedBox(height: 8),
        _buildCalendar(),
      ],
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _currentMonth =
                  DateTime(_currentMonth.year, _currentMonth.month - 1);
            });
          },
        ),
        Text(
          DateFormat.yMMMM().format(_currentMonth),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF18314F),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () {
            setState(() {
              _currentMonth =
                  DateTime(_currentMonth.year, _currentMonth.month + 1);
            });
          },
        ),
      ],
    );
  }

  Widget _buildDayLabels() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        return Expanded(
          child: Center(
            child: Text(
              DateFormat.E()
                  .format(DateTime(2021, 1, index + 3)), // Start from Sunday
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF748395),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCalendar() {
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday;
    final totalDays = daysInMonth + firstWeekday - 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: totalDays,
      itemBuilder: (context, index) {
        if (index < firstWeekday - 1) {
          return const SizedBox.shrink();
        }

        final day = index - firstWeekday + 2;
        final date = DateTime(_currentMonth.year, _currentMonth.month, day);
        final isStreak = widget.streakDates.any((d) => _isSameDate(d, date));
        final isMissed = widget.missedDates.any((d) => _isSameDate(d, date));
        final isFuture = date.isAfter(DateTime.now());
        final isInactive = widget.streakDates.isEmpty
            ? false
            : date.isBefore(widget.streakDates.first);

        Color? bgColor;

        if (isStreak) {
          bgColor = Color.fromARGB(
              198, 73, 207, 140); // Desired green color for streak
        } else if (isMissed) {
          bgColor = Color.fromARGB(
              255, 233, 131, 131); // Desired red color for missed
        } else if (isFuture) {
          bgColor = const Color(0xFFE9E9E9); // Light grey for future days
        } else if (isInactive) {
          bgColor = const Color(0xFF6F6F6E)
              .withOpacity(0.3); // Dark grey for inactive days
        } else {
          bgColor = const Color(0xFFE9E9E9); // Default color for other days
        }

        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(
                color: isStreak || isMissed || isInactive
                    ? Colors.white
                    : const Color(0xFF748395),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}

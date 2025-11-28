import 'package:flutter/material.dart';

class EventDetailPage extends StatelessWidget {
  final VoidCallback? onJoin;
  const EventDetailPage({super.key, this.onJoin});

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: const Color(0xFF2E2A68),
          fontWeight: FontWeight.w800,
        );
    final labelStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.black87,
          height: 1.4,
        );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF512DA8),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                'lib/screens/assets/beach_clean_up.png',
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Beach Clean-Up - Saturday', style: titleStyle),
                  const SizedBox(height: 8),
                  Text('Falmouth Beach, Cornwall', style: bodyStyle),
                  const SizedBox(height: 4),
                  Text('Free - 10:00-13:00', style: bodyStyle),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 20),
                                const SizedBox(width: 8),
                                Text('Date & time', style: labelStyle),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Saturday, 20 October\n10:00-13:00', style: bodyStyle),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                const Icon(Icons.group_outlined, size: 20),
                                const SizedBox(width: 8),
                                Text('Group size', style: labelStyle),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Up to 20 volunteers', style: bodyStyle),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 20),
                                const SizedBox(width: 8),
                                Text('Meeting point', style: labelStyle),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Falmouth Beach car park', style: bodyStyle),
                            const SizedBox(height: 4),
                            Text(
                              'View on map',
                              style: bodyStyle?.copyWith(
                                color: const Color(0xFF4A148C),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                const Icon(Icons.public_outlined, size: 20),
                                const SizedBox(width: 8),
                                Text('Eco impact', style: labelStyle),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Help remove approx. 20-30 kg of waste from the beach in one morning.',
                              style: bodyStyle,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('What you\'ll do', style: labelStyle),
                  const SizedBox(height: 10),
                  _bullet('Collect litter along the shoreline.'),
                  _bullet('Separate recycling and waste.'),
                  _bullet('Short intro on ocean plastics.'),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A148C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () {
                        onJoin?.call();
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Join this activity',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Today',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildNotificationItem(
            icon: Icons.star,
            iconColor: const Color(0xFF7FBFB6),
            title: 'Weekly New Recipes!',
            message: 'Discover our new recipes of the week!',
            time: '2 Min Ago',
            backgroundColor: const Color(0xFFFFF4E9),
          ),
          const SizedBox(height: 12),
          _buildNotificationItem(
            icon: Icons.notifications,
            iconColor: const Color(0xFF7FBFB6),
            title: 'Meal Reminder',
            message: 'Time to cook your healthy meal of the day',
            time: '35 Min Ago',
            backgroundColor: const Color(0xFFFFF4E9),
          ),
          const SizedBox(height: 24),
          const Text(
            'Wednesday',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildNotificationItem(
            icon: Icons.notifications,
            iconColor: const Color(0xFF7FBFB6),
            title: 'New Update Available',
            message: 'Performance improvements and bug fixes.',
            time: '25 April 2024',
            backgroundColor: const Color(0xFFFFF4E9),
          ),
          const SizedBox(height: 12),
          _buildNotificationItem(
            icon: Icons.star,
            iconColor: const Color(0xFF7FBFB6),
            title: 'Reminder',
            message:
                "Don't forget to complete your profile to access all app features",
            time: '25 April 2024',
            backgroundColor: const Color(0xFFFFF4E9),
          ),
          const SizedBox(height: 12),
          _buildNotificationItem(
            icon: Icons.star,
            iconColor: const Color(0xFF7FBFB6),
            title: 'Important Notice',
            message:
                'Remember to change your password regularly to keep your account secure',
            time: '25 April 2024',
            backgroundColor: const Color(0xFFFFF4E9),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String time,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7FBFB6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

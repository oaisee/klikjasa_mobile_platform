import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';

class AdminChatListItem extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isSelected;
  final VoidCallback onTap;

  const AdminChatListItem({
    super.key,
    required this.user,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String fullName = user['full_name'] ?? 'Pengguna';
    final String lastMessage = user['last_message'] ?? '';
    final int unreadCount = user['unread_count'] ?? 0;
    final String? lastMessageTime = user['last_message_time'];
    
    // Format waktu pesan terakhir
    String formattedTime = '';
    if (lastMessageTime != null && lastMessageTime.isNotEmpty) {
      try {
        final DateTime messageTime = DateTime.parse(lastMessageTime);
        final DateTime now = DateTime.now();
        final Duration difference = now.difference(messageTime);
        
        if (difference.inDays > 0) {
          formattedTime = DateFormat('dd/MM').format(messageTime);
        } else {
          formattedTime = DateFormat('HH:mm').format(messageTime);
        }
      } catch (e) {
        debugPrint('Error formatting time: $e');
      }
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        color: isSelected ? Colors.grey[200] : Colors.transparent,
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.accent,
              backgroundImage: user['avatar_url'] != null && user['avatar_url'].isNotEmpty
                  ? NetworkImage(user['avatar_url'])
                  : null,
              child: user['avatar_url'] == null || user['avatar_url'].isEmpty
                  ? Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Info pengguna dan pesan terakhir
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          fullName,
                          style: TextStyle(
                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: unreadCount > 0 ? AppColors.primary : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: unreadCount > 0 ? Colors.black : Colors.grey[600],
                            fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
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

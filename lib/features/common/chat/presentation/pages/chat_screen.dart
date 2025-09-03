import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';
import 'package:klik_jasa/features/common/auth/application/bloc/auth_bloc.dart';
import '../bloc/chat_list_bloc.dart';

// Enum untuk tipe user
enum UserType {
  user,
  provider,
  admin,
}

class ChatScreen extends StatefulWidget {
  final UserType userType;
  
  const ChatScreen({
    super.key,
    required this.userType,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    // Load chat list saat screen dibuka
    _loadChatList();
    // Start real-time subscription
    _startChatListSubscription();
  }
  
  @override
  void dispose() {
    // Stop real-time subscription
    context.read<ChatListBloc>().add(const StopChatListSubscription());
    super.dispose();
  }

  void _loadChatList() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final currentUserId = authState.user.id;
      context.read<ChatListBloc>().add(LoadChatList(userId: currentUserId));
    }
  }
  
  void _startChatListSubscription() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final currentUserId = authState.user.id;
      context.read<ChatListBloc>().add(StartChatListSubscription(userId: currentUserId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<ChatListBloc, ChatListState>(
        builder: (context, state) {
          if (state is ChatListLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (state is ChatListError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Terjadi kesalahan',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final authState = context.read<AuthBloc>().state;
                      if (authState is AuthAuthenticated) {
                        final currentUserId = authState.user.id;
                        context.read<ChatListBloc>().add(RefreshChatList(userId: currentUserId));
                      }
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }
          
          if (state is ChatListLoaded) {
            if (state.chatList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada percakapan',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getEmptyMessage(),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            
            return RefreshIndicator(
              onRefresh: () async {
                final authState = context.read<AuthBloc>().state;
                if (authState is AuthAuthenticated) {
                  final currentUserId = authState.user.id;
                  context.read<ChatListBloc>().add(RefreshChatList(userId: currentUserId));
                }
              },
              child: ListView.builder(
                itemCount: state.chatList.length,
                itemBuilder: (context, index) {
                  final chat = state.chatList[index];
                  return _buildChatListItem(chat);
                },
              ),
            );
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }
  
  String _getAppBarTitle() {
    switch (widget.userType) {
      case UserType.user:
        return 'Chat';
      case UserType.provider:
        return 'Chat Pelanggan';
      case UserType.admin:
        return 'Chat Admin';
    }
  }
  
  String _getEmptyMessage() {
    switch (widget.userType) {
      case UserType.user:
        return 'Mulai percakapan dengan penyedia jasa';
      case UserType.provider:
        return 'Belum ada chat dari pelanggan';
      case UserType.admin:
        return 'Belum ada chat dari pengguna';
    }
  }
  
  Widget _buildChatListItem(Map<String, dynamic> chat) {
    final String? avatarUrl = chat['other_user_avatar'] as String?;
    final String userName = chat['other_user_name'] as String? ?? 'Unknown User';
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary,
        radius: 24,
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: avatarUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 48,
                    height: 48,
                    color: AppColors.primary.withValues(alpha: 0.3),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              )
            : Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: userName.isNotEmpty
                      ? Text(
                          userName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 28,
                        ),
                ),
              ),
      ),
      title: Text(
        chat['other_user_name'] as String? ?? 'Unknown User',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        chat['last_message'] as String? ?? 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(chat['last_message_time']),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if ((chat['unread_count'] as int? ?? 0) > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${chat['unread_count']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        _navigateToChatDetail(chat['other_user_id'] as String);
      },
    );
  }
  
  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    
    try {
      final DateTime dateTime = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'now';
      }
    } catch (e) {
      return '';
    }
  }
  
  void _navigateToChatDetail(String otherUserId) {
    // Get current state from ChatListBloc
    final currentState = context.read<ChatListBloc>().state;
    
    // Find the chat data for this user
    Map<String, dynamic> chatData = {};
    if (currentState is ChatListLoaded) {
      chatData = currentState.chatList.firstWhere(
        (chat) => chat['other_user_id'] == otherUserId,
        orElse: () => <String, dynamic>{},
      );
    }
    
    final extraData = {
      'otherUserName': chatData['other_user_name'] as String? ?? 'Unknown User',
      'profilePicture': chatData['other_user_avatar'] as String?,
    };
    
    switch (widget.userType) {
      case UserType.user:
        context.goNamed(
          'userChatDetail',
          pathParameters: {'otherUserId': otherUserId},
          extra: extraData,
        );
        break;
      case UserType.provider:
        context.goNamed(
          'providerChatDetail',
          queryParameters: {'userId': otherUserId},
          extra: {
            'otherUserName': chatData['other_user_name'] as String? ?? 'Unknown User',
            'profilePicture': chatData['other_user_avatar'] as String?,
          },
        );
        break;
      case UserType.admin:
        // TODO: Implement admin chat detail navigation
        break;
    }
  }
}
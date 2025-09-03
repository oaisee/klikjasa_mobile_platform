import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';
import 'package:klik_jasa/features/admin_mode/presentation/widgets/admin_chat_list_item.dart';
import 'package:klik_jasa/features/admin_mode/presentation/widgets/admin_chat_detail.dart';

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({super.key});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _chatUsers = [];
  List<Map<String, dynamic>> _filteredChatUsers = [];
  Map<String, dynamic>? _selectedUser;
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChatUsers();
    _searchController.addListener(_filterChatUsers);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _filterChatUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredChatUsers = _chatUsers;
      } else {
        _filteredChatUsers = _chatUsers.where((user) {
          final fullName = user['full_name']?.toString().toLowerCase() ?? '';
          final lastMessage = user['last_message']?.toString().toLowerCase() ?? '';
          return fullName.contains(query) || lastMessage.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadChatUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Ambil semua user yang pernah mengirim pesan ke admin
      final response = await _supabase
          .from('messages')
          .select('sender_id, receiver_id, created_at')
          .or('receiver_id.eq.${_supabase.auth.currentUser!.id},sender_id.eq.${_supabase.auth.currentUser!.id}')
          .order('created_at', ascending: false);

      // Kumpulkan semua ID user unik (selain admin)
      final Set<String> userIds = {};
      for (final message in response) {
        final String senderId = message['sender_id'];
        final String receiverId = message['receiver_id'];
        
        // Tambahkan ID yang bukan milik admin saat ini
        if (senderId != _supabase.auth.currentUser!.id) {
          userIds.add(senderId);
        }
        if (receiverId != _supabase.auth.currentUser!.id) {
          userIds.add(receiverId);
        }
      }

      // Ambil detail profil untuk semua user tersebut
      final List<Map<String, dynamic>> chatUsers = [];
      for (final userId in userIds) {
        final userProfile = await _supabase
            .from('profiles')
            .select('id, full_name, avatar_url')
            .eq('id', userId)
            .maybeSingle();
        
        if (userProfile != null) {
          // Hitung jumlah pesan yang belum dibaca
          final unreadCount = await _supabase
              .from('messages')
              .select('id')
              .eq('receiver_id', _supabase.auth.currentUser!.id)
              .eq('sender_id', userId)
              .neq('status', 'dibaca')
              .count();
          
          // Ambil pesan terakhir
          final lastMessage = await _supabase
              .from('messages')
              .select('content, created_at')
              .or('and(sender_id.eq.$userId,receiver_id.eq.${_supabase.auth.currentUser!.id}),and(sender_id.eq.${_supabase.auth.currentUser!.id},receiver_id.eq.$userId)')
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
          
          chatUsers.add({
            ...userProfile,
            'unread_count': unreadCount,
            'last_message': lastMessage?['content'] ?? '',
            'last_message_time': lastMessage?['created_at'] ?? '',
          });
        }
      }

      // Urutkan berdasarkan waktu pesan terakhir
      chatUsers.sort((a, b) {
        final aTime = a['last_message_time'] ?? '';
        final bTime = b['last_message_time'] ?? '';
        return bTime.compareTo(aTime); // Descending order
      });

      if (mounted) {
        setState(() {
          _chatUsers = chatUsers;
          _filteredChatUsers = chatUsers; // Inisialisasi filtered list
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading chat users: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat daftar chat: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _selectUser(Map<String, dynamic> user) {
    setState(() {
      _selectedUser = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Pelanggan'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Row(
                  children: [
                    // Daftar chat (sepertiga layar)
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.3,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            color: Colors.grey[200],
                            child: Row(
                              children: [
                                const Icon(Icons.search),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: const InputDecoration(
                                      hintText: 'Cari pengguna...',
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _chatUsers.isEmpty
                                ? const Center(
                                    child: Text('Belum ada chat dari pelanggan'),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _loadChatUsers,
                                    child: ListView.builder(
                                      itemCount: _filteredChatUsers.length,
                                      itemBuilder: (context, index) {
                                        final user = _filteredChatUsers[index];
                                        return AdminChatListItem(
                                          user: user,
                                          isSelected: _selectedUser != null &&
                                              _selectedUser!['id'] == user['id'],
                                          onTap: () => _selectUser(user),
                                        );
                                      },
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    // Vertical divider
                    const VerticalDivider(width: 1, thickness: 1),
                    // Detail chat (dua pertiga layar)
                    Expanded(
                      child: _selectedUser == null
                          ? const Center(
                              child: Text('Pilih chat untuk melihat percakapan'),
                            )
                          : AdminChatDetail(
                              user: _selectedUser!,
                              onMessageSent: () {
                                // Refresh daftar chat setelah mengirim pesan
                                _loadChatUsers();
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}

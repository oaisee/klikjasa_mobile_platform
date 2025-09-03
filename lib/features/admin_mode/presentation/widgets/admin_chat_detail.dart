import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';
import 'package:uuid/uuid.dart';

class AdminChatDetail extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onMessageSent;

  const AdminChatDetail({
    super.key,
    required this.user,
    required this.onMessageSent,
  });

  @override
  State<AdminChatDetail> createState() => _AdminChatDetailState();
}

class _AdminChatDetailState extends State<AdminChatDetail> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;
  late Stream<List<Map<String, dynamic>>> _messagesStream;

  @override
  void initState() {
    super.initState();
    _setupMessagesStream();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupMessagesStream() {
    final userId = widget.user['id'];
    final adminId = _supabase.auth.currentUser!.id;

    // Karena Supabase stream tidak mendukung query kompleks seperti OR,
    // kita gunakan polling dengan Stream.periodic sebagai alternatif
        
    // Gabungkan kedua stream
    _messagesStream = Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
      try {
        final response = await _supabase
            .from('messages')
            .select()
            .or('and(sender_id.eq.$userId,receiver_id.eq.$adminId),and(sender_id.eq.$adminId,receiver_id.eq.$userId)')
            .order('created_at');
        
        return List<Map<String, dynamic>>.from(response);
      } catch (e) {
        debugPrint('Error fetching messages: $e');
        // Kembalikan list kosong jika terjadi error, tapi jangan reset _messages yang sudah ada
        // sehingga pesan yang sudah di-load tetap ditampilkan
        return _messages.isNotEmpty ? _messages : <Map<String, dynamic>>[];
      }
    }).asBroadcastStream();
    
    _messagesStream.listen(
      (messages) {
        if (mounted) {
          setState(() {
            _messages = messages;
            _isLoading = false;
            _errorMessage = null; // Reset error message jika berhasil
          });
          if (messages.isNotEmpty) {
            _scrollToBottom();
          }
        }
      },
      onError: (error) {
        debugPrint('Error on messages stream: $error');
        if (mounted) {
          setState(() {
            _errorMessage = 'Gagal memuat pesan. Silakan coba lagi nanti.';
            _isLoading = false;
          });
        }
      },
    );
  }

  // Fungsi _loadMessages dihapus karena sudah digantikan oleh _setupMessagesStream

  Future<void> _markMessagesAsRead() async {
    try {
      final userId = widget.user['id'];
      final adminId = _supabase.auth.currentUser!.id;

      // Tandai semua pesan dari user ke admin sebagai sudah dibaca
      await _supabase
          .from('messages')
          .update({'status': 'dibaca'})
          .eq('sender_id', userId)
          .eq('receiver_id', adminId)
          .neq('status', 'dibaca');
          
      debugPrint('Pesan dari user $userId ke admin $adminId ditandai sudah dibaca');
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
      // Tidak perlu menampilkan error ke UI karena ini proses background
      // Jika gagal, akan dicoba lagi saat user membuka chat lain atau refresh
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageContent = _messageController.text.trim();
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = widget.user['id'];
      final adminId = _supabase.auth.currentUser!.id;

      // Kirim pesan
      await _supabase.from('messages').insert({
        'id': const Uuid().v4(),
        'sender_id': adminId,
        'receiver_id': userId,
        'content': messageContent,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'terkirim',
      });

      _messageController.clear();
      widget.onMessageSent();
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim pesan: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients && _messages.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header chat
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.accent,
                backgroundImage: widget.user['avatar_url'] != null && widget.user['avatar_url'].isNotEmpty
                    ? NetworkImage(widget.user['avatar_url'])
                    : null,
                child: widget.user['avatar_url'] == null || widget.user['avatar_url'].isEmpty
                    ? Text(
                        widget.user['full_name'] != null && widget.user['full_name'].isNotEmpty
                            ? widget.user['full_name'][0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user['full_name'] ?? 'Pengguna',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      'Online',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Isi chat
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : _messages.isEmpty
                      ? const Center(
                          child: Text('Belum ada pesan'),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isFromAdmin = message['sender_id'] == _supabase.auth.currentUser!.id;
                            final createdAt = DateTime.parse(message['created_at']);
                            final formattedTime = DateFormat('HH:mm').format(createdAt);

                            // Tampilkan tanggal jika berbeda dari pesan sebelumnya
                            bool showDate = false;
                            String? dateString;
                            if (index == 0) {
                              showDate = true;
                              dateString = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(createdAt);
                            } else {
                              final prevMessage = _messages[index - 1];
                              final prevCreatedAt = DateTime.parse(prevMessage['created_at']);
                              if (prevCreatedAt.day != createdAt.day ||
                                  prevCreatedAt.month != createdAt.month ||
                                  prevCreatedAt.year != createdAt.year) {
                                showDate = true;
                                dateString = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(createdAt);
                              }
                            }

                            return Column(
                              children: [
                                if (showDate)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(16.0),
                                        ),
                                        child: Text(
                                          dateString!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                Align(
                                  alignment: isFromAdmin ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8.0),
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * 0.6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isFromAdmin ? AppColors.primary : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(16.0),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          message['content'],
                                          style: TextStyle(
                                            color: isFromAdmin ? Colors.white : Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              formattedTime,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isFromAdmin ? Colors.white70 : Colors.grey,
                                              ),
                                            ),
                                            if (isFromAdmin)
                                              Padding(
                                                padding: const EdgeInsets.only(left: 4.0),
                                                child: Icon(
                                                  message['status'] == 'dibaca' ? Icons.done_all : 
                                                  message['status'] == 'diterima' ? Icons.done_all : Icons.done,
                                                  size: 12,
                                                  color: message['status'] == 'dibaca' ? Colors.green : Colors.white70,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
        ),
        // Input pesan
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: () {
                  // TODO: Implementasi lampiran file
                },
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Ketik pesan...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(24.0)),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Color(0xFFf5f5f5),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (text) {
                    if (text.trim().isNotEmpty) {
                      _sendMessage();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: AppColors.primary,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

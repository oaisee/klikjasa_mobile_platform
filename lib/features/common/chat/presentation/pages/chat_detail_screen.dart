import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';
import 'package:klik_jasa/features/user_mode/home/domain/repositories/service_repository.dart';
import 'package:klik_jasa/injection_container.dart';
import '../bloc/chat_bloc.dart';
import 'chat_screen.dart'; // Import untuk UserType

class ChatDetailScreen extends StatefulWidget {
  final String otherUserId;
  final String? otherUserName;
  final UserType userType;
  final String? profilePicture;
  final Map<String, dynamic>? orderData;
  final Map<String, dynamic>? serviceData; // Data layanan untuk thumbnail
  
  const ChatDetailScreen({
    super.key,
    required this.otherUserId,
    this.otherUserName,
    required this.userType,
    this.profilePicture,
    this.orderData,
    this.serviceData,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Map<String, dynamic>? _attachedService; // Layanan yang dilampirkan
  bool _showServiceAttachment = false; // Menampilkan attachment area
  
  @override
  void initState() {
    super.initState();
    
    // Jika ada data layanan dari navigasi detail layanan, tampilkan sebagai attachment
    if (widget.serviceData != null) {
      _attachedService = widget.serviceData;
      _showServiceAttachment = true;
      // Set template message
      _messageController.text = "Halo, saya tertarik dengan layanan ${widget.serviceData!['title']}. Bisakah kita diskusikan lebih lanjut?";
    }
    
    // Load chat messages when screen initializes
    context.read<ChatBloc>().add(LoadChatMessages(widget.otherUserId));
    // Mark messages as read
    context.read<ChatBloc>().add(MarkMessagesAsReadEvent(widget.otherUserId));
    // Start real-time subscription
    context.read<ChatBloc>().add(StartChatSubscription(widget.otherUserId));
    
    // Listen untuk pesan baru dan auto-scroll
    context.read<ChatBloc>().stream.listen((state) {
      if (state is ChatLoaded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    });
  }
  
  @override
  void dispose() {
    // Stop real-time subscription
    context.read<ChatBloc>().add(const StopChatSubscription());
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Navigasi ke detail layanan berdasarkan mode pengguna saat ini
  void _navigateToServiceDetail(BuildContext context, dynamic service, String heroTag) {
    if (widget.userType == UserType.provider) {
      // Untuk provider mode, gunakan rute provider service detail
      context.go('/provider-services/detail/${service.id}');
    } else {
      // Untuk user mode, gunakan rute user service detail
      context.go('/home/service-detail', extra: {
        'service': service,
        'heroTag': heroTag,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Row(
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 20,
              child: widget.profilePicture != null && 
                     widget.profilePicture!.isNotEmpty && 
                     widget.profilePicture!.startsWith('http')
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: widget.profilePicture!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) {
                          // Fallback ke inisial nama jika gambar gagal dimuat
                          return Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: widget.otherUserName?.isNotEmpty == true
                                  ? Text(
                                      widget.otherUserName![0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                            ),
                          );
                        },
                      ),
                    )
                  : Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: widget.otherUserName?.isNotEmpty == true
                            ? Text(
                                widget.otherUserName![0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 24,
                              ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            // Name
            Expanded(
              child: Text(
                widget.otherUserName ?? 'Pengguna',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (widget.orderData != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                _showOrderInfo(context);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Order info banner (jika ada orderData dan bukan dari navigasi detail layanan)
          if (widget.orderData != null && widget.serviceData == null) _buildOrderInfoBanner(),
          
          // Messages list
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is ChatLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  
                  if (state is ChatError) {
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
                              context.read<ChatBloc>().add(
                                LoadChatMessages(widget.otherUserId),
                              );
                            },
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  if (state is ChatLoaded) {
                    if (state.messages.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.chat_bubble_outline,
                                  size: 48,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Belum ada pesan',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Mulai percakapan dengan mengirim pesan di bawah',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    // Auto scroll ke bawah setelah pesan dimuat
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });
                    
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final message = state.messages[index];
                        return _buildMessageBubble(message);
                      },
                    );
                  }
                  
                  return const SizedBox.shrink();
                },
              ),
            ),
            
            // Service attachment area (jika ada)
            if (_showServiceAttachment && _attachedService != null) _buildServiceAttachment(),
            
            // Message input
            _buildMessageInput(),
          ],
        ),
    );
  }
  
  Widget _buildOrderInfoBanner() {
    final orderData = widget.orderData!;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Pesanan',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            orderData['service_name'] as String? ?? 'Layanan',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (orderData['total_price'] != null)
            Text(
              _formatPrice(orderData['total_price']),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final bool isSender = message['is_sender'] as bool? ?? false;
    final String messageText = message['message'] as String? ?? '';
    final String? imageUrl = message['image_url'] as String?;
    final DateTime? timestamp = message['created_at'] != null
        ? DateTime.tryParse(message['created_at'].toString())
        : null;

    final bool hasServiceAttachment = _hasServiceAttachment(messageText);
    final Map<String, String>? serviceInfo = hasServiceAttachment ? _extractServiceInfo(messageText) : null;

    final messageContent = Column(
      crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasServiceAttachment && serviceInfo != null)
          _buildServiceThumbnail(serviceInfo, isSender),
        if (imageUrl != null && imageUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 200,
                height: 200,
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                width: 200,
                height: 200,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
        if (messageText.isNotEmpty && (!hasServiceAttachment || _hasAdditionalText(messageText)))
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 5),
            child: Text(
              hasServiceAttachment ? _extractMessageText(messageText) : messageText,
              style: TextStyle(
                color: isSender ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
          ),
        if (timestamp != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(
              _formatMessageTime(timestamp),
              style: TextStyle(
                color: isSender ? Colors.white70 : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
      ],
    );

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isSender ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isSender ? 18 : 0),
            bottomRight: Radius.circular(isSender ? 0 : 18),
          ),
        ),
        child: messageContent,
      ),
    );
  }

  Widget _buildServiceThumbnail(Map<String, String> serviceInfo, bool isSender) {
    final String title = serviceInfo['title'] ?? 'Layanan';
    final String price = serviceInfo['price'] ?? 'Harga tidak tersedia';
    final String imageUrl = serviceInfo['imageUrl'] ?? serviceInfo['image'] ?? '';
    final String? serviceId = serviceInfo['id'];

    return GestureDetector(
      onTap: () async {
        // Navigasi ke detail layanan
        if (serviceId != null && serviceId.isNotEmpty) {
          try {
            final serviceIdInt = int.parse(serviceId);
            final serviceRepository = sl<ServiceRepository>();
            final result = await serviceRepository.getServiceById(serviceIdInt);
            
            result.fold(
              (failure) {
                // Jika gagal mendapatkan data service, arahkan ke pencarian
                if (mounted) {
                  context.go('/search?query=${Uri.encodeComponent(title)}');
                }
              },
              (service) {
                // Navigasi ke detail layanan berdasarkan mode saat ini
                if (mounted) {
                  _navigateToServiceDetail(context, service, 'chat_thumbnail_${service.id}');
                }
              },
            );
          } catch (e) {
            // Jika ID tidak valid, arahkan ke pencarian
            if (mounted) {
              context.go('/search?query=${Uri.encodeComponent(title)}');
            }
          }
        } else {
          // Jika tidak ada ID, arahkan ke pencarian
          if (mounted) {
            context.go('/search?query=${Uri.encodeComponent(title)}');
          }
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isSender ? 18 : 0),
          bottomRight: Radius.circular(isSender ? 0 : 18),
        ),
        child: Container(
          width: double.infinity,
          color: isSender ? AppColors.primary.withValues(alpha: 0.8) : Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    height: 120,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSender ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      price,
                      style: TextStyle(
                        color: isSender ? Colors.white.withValues(alpha: 0.9) : Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 14,
                          color: isSender ? Colors.white.withValues(alpha: 0.7) : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tap untuk melihat detail',
                          style: TextStyle(
                            color: isSender ? Colors.white.withValues(alpha: 0.7) : Colors.grey[600],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
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
      ),
    );
  }
  
  Widget _buildMessageInput() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey[300]!,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Ketik pesan...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(width: 8),
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                final bool isLoading = state is MessageSending;
                
                return IconButton(
                  onPressed: isLoading ? null : _sendMessage,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    // Jika ada attachment layanan, tambahkan info layanan ke pesan
    String finalMessage = message;
    if (_attachedService != null) {
      finalMessage += '\n\n📋 Layanan: ${_attachedService!['title']}';
      finalMessage += '\n💰 Harga: ${_formatPrice(_attachedService!['price']?.toDouble() ?? 0)}';
      if (_attachedService!['priceUnit'] != null) {
        finalMessage += ' / ${_attachedService!['priceUnit']}';
      }
      // Tambahkan ID layanan dan URL gambar untuk navigasi
      finalMessage += '\n🔗 ID: ${_attachedService!['id']}';
      if (_attachedService!['imageUrl'] != null) {
        finalMessage += '\n🖼️ IMG: ${_attachedService!['imageUrl']}';
      }
    }
    
    context.read<ChatBloc>().add(
      SendMessageEvent(
        receiverId: widget.otherUserId,
        message: finalMessage,
      ),
    );
    
    _messageController.clear();
    
    // Hapus attachment setelah mengirim pesan
    if (_attachedService != null) {
      setState(() {
        _attachedService = null;
        _showServiceAttachment = false;
      });
    }
    
    // Scroll to bottom after sending message
    _scrollToBottom();
  }
  
  void _showOrderInfo(BuildContext context) {
    if (widget.orderData == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informasi Pesanan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Layanan', widget.orderData!['service_name']),
            _buildInfoRow('Harga', _formatPrice(widget.orderData!['total_price'])),
            if (widget.orderData!['status'] != null)
              _buildInfoRow('Status', widget.orderData!['status']),
            if (widget.orderData!['created_at'] != null)
              _buildInfoRow('Tanggal Pesanan', _formatDate(widget.orderData!['created_at'])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value?.toString() ?? '-'),
          ),
        ],
      ),
    );
  }
  
  String _formatPrice(dynamic price) {
    if (price == null) return 'Rp 0';
    
    try {
      // Konversi ke double terlebih dahulu, kemudian ke int untuk menghilangkan desimal
      final double doublePrice = double.parse(price.toString());
      final int amount = doublePrice.toInt();
      final formattedAmount = amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
      return 'Rp $formattedAmount';
    } catch (e) {
      return 'Rp 0';
    }
  }
  
  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
  
  String _formatDate(dynamic date) {
    if (date == null) return '-';
    
    try {
      final DateTime dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date.toString();
    }
  }
  
  // Fungsi untuk mendeteksi apakah pesan berisi attachment layanan
  bool _hasServiceAttachment(String message) {
    return message.contains('📋 Layanan:') && message.contains('💰 Harga:');
  }
  
  // Fungsi untuk mengecek apakah ada teks tambahan selain attachment
  bool _hasAdditionalText(String message) {
    final lines = message.split('\n');
    for (String line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isNotEmpty && 
          !trimmedLine.startsWith('📋') && 
          !trimmedLine.startsWith('💰') && 
          !trimmedLine.startsWith('🔗') && 
          !trimmedLine.startsWith('🖼️')) {
        return true;
      }
    }
    return false;
  }
  
  // Fungsi untuk mengekstrak teks pesan tanpa attachment info
  String _extractMessageText(String message) {
    final lines = message.split('\n');
    final textLines = <String>[];
    
    for (String line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isNotEmpty && 
          !trimmedLine.startsWith('📋') && 
          !trimmedLine.startsWith('💰') && 
          !trimmedLine.startsWith('🔗') && 
          !trimmedLine.startsWith('🖼️')) {
        textLines.add(line);
      }
    }
    
    return textLines.join('\n').trim();
  }
  
  // Fungsi untuk mengekstrak informasi layanan dari pesan
  Map<String, String>? _extractServiceInfo(String message) {
    try {
      final lines = message.split('\n');
      String? serviceName;
      String? servicePrice;
      String? serviceId;
      String? imageUrl;
      
      for (String line in lines) {
        if (line.contains('📋 Layanan:')) {
          serviceName = line.replaceFirst('📋 Layanan:', '').trim();
        }
        if (line.contains('💰 Harga:')) {
          servicePrice = line.replaceFirst('💰 Harga:', '').trim();
        }
        if (line.contains('🔗 ID:')) {
          serviceId = line.replaceFirst('🔗 ID:', '').trim();
        }
        if (line.contains('🖼️ IMG:')) {
          imageUrl = line.replaceFirst('🖼️ IMG:', '').trim();
        }
      }
      
      if (serviceName != null && servicePrice != null) {
        final result = {
          'title': serviceName,
          'price': servicePrice,
        };
        if (serviceId != null) result['id'] = serviceId;
        if (imageUrl != null) result['imageUrl'] = imageUrl;
        return result;
      }
    } catch (e) {
      // Jika terjadi error, return null
    }
    return null;
  }
  

  
  // Widget untuk menampilkan attachment layanan
  Widget _buildServiceAttachment() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [
              Colors.blue.shade50,
              Colors.blue.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan judul dan tombol hapus
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.attach_file,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Lampiran Layanan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue.shade900,
                ),
              ),
              const Spacer(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _attachedService = null;
                      _showServiceAttachment = false;
                      _messageController.clear();
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.red.shade300,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Thumbnail layanan (dapat di-tap untuk navigasi)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                // Navigasi ke detail layanan
                if (_attachedService!['id'] != null && _attachedService!['id'].toString().isNotEmpty) {
                  try {
                    final serviceId = int.parse(_attachedService!['id'].toString());
                    final serviceRepository = sl<ServiceRepository>();
                    final result = await serviceRepository.getServiceById(serviceId);
                    
                    result.fold(
                      (failure) {
                        // Jika gagal mendapatkan data service, arahkan ke pencarian
                        if (mounted) {
                          context.go('/search?query=${Uri.encodeComponent(_attachedService!['title'] ?? '')}');
                        }
                      },
                      (service) {
                        // Navigasi ke detail layanan berdasarkan mode saat ini
                        if (mounted) {
                          _navigateToServiceDetail(context, service, 'chat_attachment_${service.id}');
                        }
                      },
                    );
                  } catch (e) {
                    // Jika ID tidak valid, arahkan ke pencarian
                    if (mounted) {
                      context.go('/search?query=${Uri.encodeComponent(_attachedService!['title'] ?? '')}');
                    }
                  }
                } else {
                  if (mounted) {
                    context.go('/search?query=${Uri.encodeComponent(_attachedService!['title'] ?? '')}');
                  }
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.shade100,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Gambar layanan
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _attachedService!['imageUrl'] != null
                            ? CachedNetworkImage(
                                imageUrl: _attachedService!['imageUrl'],
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.work_outline,
                                    color: Colors.blue.shade600,
                                    size: 32,
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.work_outline,
                                    color: Colors.blue.shade600,
                                    size: 32,
                                  ),
                                ),
                              )
                            : Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.work_outline,
                                  color: Colors.blue.shade600,
                                  size: 32,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Info layanan
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.business_center,
                                size: 16,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _attachedService!['title'] ?? 'Layanan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Colors.blue.shade900,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.attach_money,
                                size: 16,
                                color: Colors.green.shade600,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _formatPrice(_attachedService!['price']?.toDouble() ?? 0),
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_attachedService!['priceUnit'] != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '/ ${_attachedService!['priceUnit']}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Ikon navigasi
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Template pesan yang bisa di-tap
          GestureDetector(
            onTap: () {
              _messageController.text = "Halo, saya tertarik dengan layanan ${_attachedService!['title']}. Bisakah kita diskusikan lebih lanjut?";
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Halo, saya tertarik dengan layanan ${_attachedService!['title']}. Bisakah kita diskusikan lebih lanjut?",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/service_with_location.dart';
import '../../../wishlist/presentation/bloc/wishlist_bloc.dart';
import '../../../../common/auth/application/bloc/auth_bloc.dart';
import 'package:klik_jasa/features/common/utils/app_message_utils.dart';

class ServiceDetailScreen extends StatelessWidget {
  final ServiceWithLocation service;
  final String? heroTag;

  const ServiceDetailScreen({
    super.key,
    required this.service,
    this.heroTag,
  });

  // Fungsi untuk memformat harga dengan pemisah ribuan
  String _formatPrice(double price) {
    final priceInt = price.toInt();
    final priceString = priceInt.toString();
    final buffer = StringBuffer();
    
    for (int i = 0; i < priceString.length; i++) {
      if ((priceString.length - i) % 3 == 0 && i > 0) {
        buffer.write('.');
      }
      buffer.write(priceString[i]);
    }
    
    return buffer.toString();
  }

  // Fungsi untuk membagikan layanan
  void _shareService(BuildContext context) {
    final String shareText = "${service.title}\n\nHarga: Rp${_formatPrice(service.price)}${service.priceUnit != null ? ' / ${service.priceUnit}' : ''}\n\nDeskripsi: ${service.description}\n\nLayanan ini tersedia di aplikasi Klik Jasa";
    
    SharePlus.instance.share(ShareParams(text: shareText));
  }
  
  // Fungsi untuk menampilkan dialog login
  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Diperlukan'),
          content: const Text('Anda perlu login untuk menggunakan fitur ini.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/login');
              },
              child: const Text('Login / Register'),
            ),
          ],
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar dengan gambar full dan gradasi
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Theme.of(context).primaryColor,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color.fromRGBO(0, 0, 0, 0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),
            actions: [
              // Tombol Share
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(0, 0, 0, 0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {
                    // Implementasi fungsi share
                    _shareService(context);
                  },
                ),
              ),
              // Tombol Wishlist
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(0, 0, 0, 0.5),
                  shape: BoxShape.circle,
                ),
                child: BlocProvider(
                  create: (context) => WishlistBloc()
                    ..add(CheckWishlistStatus(service.id.toString())),
                  child: BlocConsumer<WishlistBloc, WishlistState>(
                    listener: (context, state) {
                      if (state is WishlistItemAdded) {
                        AppMessageUtils.showSnackbar(
                          context: context,
                          message: 'Ditambahkan ke wishlist',
                          type: MessageType.success,
                        );
                      } else if (state is WishlistItemRemoved) {
                        AppMessageUtils.showSnackbar(
                          context: context,
                          message: 'Dihapus dari wishlist',
                          type: MessageType.warning,
                        );
                      } else if (state is WishlistError) {
                        AppMessageUtils.showSnackbar(
                          context: context,
                          message: state.message,
                          type: MessageType.error,
                        );
                      }
                    },
                    builder: (context, state) {
                      bool isInWishlist = false;
                      if (state is WishlistStatusChecked) {
                        isInWishlist = state.isInWishlist;
                      }
                      
                      return IconButton(
                        onPressed: () {
                          if (isInWishlist) {
                            context.read<WishlistBloc>().add(
                              RemoveFromWishlist(service.id.toString()),
                            );
                          } else {
                            context.read<WishlistBloc>().add(
                              AddToWishlist(
                                serviceId: service.id.toString(),
                                serviceTitle: service.title,
                                serviceDescription: service.description,
                                servicePrice: service.price,
                                servicePriceUnit: service.priceUnit,
                                serviceImages: service.imagesUrls,
                                serviceRating: service.averageRating,
                                serviceRatingCount: service.ratingCount,
                                providerId: service.providerId,
                                providerName: service.providerName,
                                providerLocation: service.kabupatenKota,
                              ),
                            );
                          }
                        },
                        icon: Icon(
                          isInWishlist ? Icons.favorite : Icons.favorite_border,
                          color: isInWishlist ? Colors.red : Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gambar layanan
                  service.imagesUrls?.isNotEmpty == true
                      ? CachedNetworkImage(
                          imageUrl: service.imagesUrls!.first,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 50,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_outlined,
                            color: Colors.grey,
                            size: 50,
                          ),
                        ),
                  // Gradasi 10% di bagian atas
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color.fromRGBO(0, 0, 0, 0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Badge promosi
                  if (service.isPromoted)
                    Positioned(
                      top: 100,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Promosi',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Konten detail layanan
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul dan rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          service.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(51),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              service.averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              ' (${service.ratingCount})',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Provider info section - CLICKABLE
                  GestureDetector(
                    onTap: () {
                      // Navigate to provider profile
                      context.pushNamed('userProviderProfile', pathParameters: {
                        'providerId': service.providerId,
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              service.providerName.isNotEmpty
                                  ? service.providerName[0].toUpperCase()
                                  : 'P',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        service.providerName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (service.kabupatenKota != null)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: Colors.grey[600],
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${service.kecamatan ?? ''}, ${service.kabupatenKota}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ketuk untuk melihat profil lengkap',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Deskripsi layanan
                  const Text(
                    'Deskripsi Layanan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    service.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Harga
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withAlpha(77),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Harga Layanan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Rp ${_formatPrice(service.price)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            if (service.priceUnit != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '/ ${service.priceUnit}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // Space untuk bottom buttons
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom buttons
      bottomNavigationBar: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final bool isLoggedIn = authState is AuthAuthenticated;
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(0, 0, 0, 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
              // Tambahkan border radius atas untuk tampilan yang lebih halus
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            // Tambahkan SafeArea untuk menghindari notch/home indicator
            child: SafeArea(
              child: Row(
                children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (isLoggedIn) {
                        // Navigasi ke chat dengan provider spesifik
                        context.push(
                          '/chat/detail/${service.providerId}',
                          extra: {
                            'otherUserName': service.providerName,
                            'profilePicture': service.avatarUrl,
                            'serviceData': {
                              'id': service.id,
                              'title': service.title,
                              'price': service.price,
                              'priceUnit': service.priceUnit,
                              'imageUrl': service.imagesUrls?.isNotEmpty == true ? service.imagesUrls!.first : null,
                              'providerId': service.providerId,
                              'providerName': service.providerName,
                            },
                            'userType': 'user', // Tentukan tipe pengguna
                          },
                        );
                      } else {
                        // Tampilkan dialog login jika belum login
                        _showLoginDialog(context);
                      }
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Hubungi Penyedia'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                      side: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (isLoggedIn) {
                        // Navigasi ke halaman pemesanan dengan data layanan
                        context.pushNamed('checkout', extra: service);
                      } else {
                        // Tampilkan dialog login jika belum login
                        _showLoginDialog(context);
                      }
                    },
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Pesan Layanan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ));
  }
}

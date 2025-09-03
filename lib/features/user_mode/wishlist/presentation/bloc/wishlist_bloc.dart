import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/wishlist_item.dart';

// Events
abstract class WishlistEvent extends Equatable {
  const WishlistEvent();

  @override
  List<Object?> get props => [];
}

class LoadWishlist extends WishlistEvent {}

class AddToWishlist extends WishlistEvent {
  final String serviceId;
  final String serviceTitle;
  final String? serviceDescription;
  final double servicePrice;
  final String? servicePriceUnit;
  final List<String>? serviceImages;
  final double? serviceRating;
  final int? serviceRatingCount;
  final String providerId;
  final String providerName;
  final String? providerLocation;

  const AddToWishlist({
    required this.serviceId,
    required this.serviceTitle,
    this.serviceDescription,
    required this.servicePrice,
    this.servicePriceUnit,
    this.serviceImages,
    this.serviceRating,
    this.serviceRatingCount,
    required this.providerId,
    required this.providerName,
    this.providerLocation,
  });

  @override
  List<Object?> get props => [
        serviceId,
        serviceTitle,
        serviceDescription,
        servicePrice,
        servicePriceUnit,
        serviceImages,
        serviceRating,
        serviceRatingCount,
        providerId,
        providerName,
        providerLocation,
      ];
}

class RemoveFromWishlist extends WishlistEvent {
  final String serviceId;

  const RemoveFromWishlist(this.serviceId);

  @override
  List<Object?> get props => [serviceId];
}

class CheckWishlistStatus extends WishlistEvent {
  final String serviceId;

  const CheckWishlistStatus(this.serviceId);

  @override
  List<Object?> get props => [serviceId];
}

// States
abstract class WishlistState extends Equatable {
  const WishlistState();

  @override
  List<Object?> get props => [];
}

class WishlistInitial extends WishlistState {}

class WishlistLoading extends WishlistState {}

class WishlistLoaded extends WishlistState {
  final List<WishlistItem> items;

  const WishlistLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class WishlistError extends WishlistState {
  final String message;

  const WishlistError(this.message);

  @override
  List<Object?> get props => [message];
}

class WishlistStatusChecked extends WishlistState {
  final bool isInWishlist;
  final String serviceId;

  const WishlistStatusChecked({
    required this.isInWishlist,
    required this.serviceId,
  });

  @override
  List<Object?> get props => [isInWishlist, serviceId];
}

class WishlistItemAdded extends WishlistState {
  final String serviceId;

  const WishlistItemAdded(this.serviceId);

  @override
  List<Object?> get props => [serviceId];
}

class WishlistItemRemoved extends WishlistState {
  final String serviceId;

  const WishlistItemRemoved(this.serviceId);

  @override
  List<Object?> get props => [serviceId];
}

// BLoC
class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  final SupabaseClient _supabase = Supabase.instance.client;

  WishlistBloc() : super(WishlistInitial()) {
    on<LoadWishlist>(_onLoadWishlist);
    on<AddToWishlist>(_onAddToWishlist);
    on<RemoveFromWishlist>(_onRemoveFromWishlist);
    on<CheckWishlistStatus>(_onCheckWishlistStatus);
  }

  Future<void> _onLoadWishlist(
    LoadWishlist event,
    Emitter<WishlistState> emit,
  ) async {
    try {
      emit(WishlistLoading());

      final user = _supabase.auth.currentUser;
      if (user == null) {
        emit(const WishlistError('User not authenticated'));
        return;
      }

      final response = await _supabase
          .from('wishlists')
          .select('''
            service_id,
            service_title,
            service_description,
            service_price,
            service_price_unit,
            service_images,
            service_rating,
            service_rating_count,
            provider_id,
            provider_name,
            provider_location,
            created_at
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final items = (response as List).map((item) {
        return WishlistItem(
          serviceId: item['service_id'],
          serviceTitle: item['service_title'],
          serviceDescription: item['service_description'],
          servicePrice: (item['service_price'] as num).toDouble(),
          servicePriceUnit: item['service_price_unit'],
          serviceImages: item['service_images'] != null
              ? List<String>.from(item['service_images'])
              : null,
          serviceRating: item['service_rating']?.toDouble(),
          serviceRatingCount: item['service_rating_count'],
          providerId: item['provider_id'],
          providerName: item['provider_name'],
          providerLocation: item['provider_location'],
          addedAt: DateTime.parse(item['created_at']),
        );
      }).toList();

      emit(WishlistLoaded(items));
    } catch (e) {
      emit(WishlistError('Gagal memuat wishlist: ${e.toString()}'));
    }
  }

  Future<void> _onAddToWishlist(
    AddToWishlist event,
    Emitter<WishlistState> emit,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        emit(const WishlistError('User not authenticated'));
        return;
      }

      // Check if already in wishlist
      final existing = await _supabase
          .from('wishlists')
          .select('id')
          .eq('user_id', user.id)
          .eq('service_id', event.serviceId)
          .maybeSingle();

      if (existing != null) {
        emit(const WishlistError('Layanan sudah ada di wishlist'));
        return;
      }

      await _supabase.from('wishlists').insert({
        'user_id': user.id,
        'service_id': event.serviceId,
        'service_title': event.serviceTitle,
        'service_description': event.serviceDescription,
        'service_price': event.servicePrice,
        'service_price_unit': event.servicePriceUnit,
        'service_images': event.serviceImages,
        'service_rating': event.serviceRating,
        'service_rating_count': event.serviceRatingCount,
        'provider_id': event.providerId,
        'provider_name': event.providerName,
        'provider_location': event.providerLocation,
      });

      emit(WishlistItemAdded(event.serviceId));
      
      // Reload wishlist
      add(LoadWishlist());
    } catch (e) {
      emit(WishlistError('Gagal menambahkan ke wishlist: ${e.toString()}'));
    }
  }

  Future<void> _onRemoveFromWishlist(
    RemoveFromWishlist event,
    Emitter<WishlistState> emit,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        emit(const WishlistError('User not authenticated'));
        return;
      }

      await _supabase
          .from('wishlists')
          .delete()
          .eq('user_id', user.id)
          .eq('service_id', event.serviceId);

      emit(WishlistItemRemoved(event.serviceId));
      
      // Reload wishlist
      add(LoadWishlist());
    } catch (e) {
      emit(WishlistError('Gagal menghapus dari wishlist: ${e.toString()}'));
    }
  }

  Future<void> _onCheckWishlistStatus(
    CheckWishlistStatus event,
    Emitter<WishlistState> emit,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        emit(WishlistStatusChecked(
          isInWishlist: false,
          serviceId: event.serviceId,
        ));
        return;
      }

      final existing = await _supabase
          .from('wishlists')
          .select('id')
          .eq('user_id', user.id)
          .eq('service_id', event.serviceId)
          .maybeSingle();

      emit(WishlistStatusChecked(
        isInWishlist: existing != null,
        serviceId: event.serviceId,
      ));
    } catch (e) {
      emit(WishlistStatusChecked(
        isInWishlist: false,
        serviceId: event.serviceId,
      ));
    }
  }
}
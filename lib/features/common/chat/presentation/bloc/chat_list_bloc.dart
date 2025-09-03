import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klik_jasa/features/common/chat/domain/usecases/get_chat_list.dart';

// Events
abstract class ChatListEvent extends Equatable {
  const ChatListEvent();
  
  @override
  List<Object> get props => [];
}

class LoadChatList extends ChatListEvent {
  final String userId;
  
  const LoadChatList({required this.userId});
  
  @override
  List<Object> get props => [userId];
}

class RefreshChatList extends ChatListEvent {
  final String userId;
  
  const RefreshChatList({required this.userId});
  
  @override
  List<Object> get props => [userId];
}

class StartChatListSubscription extends ChatListEvent {
  final String userId;
  
  const StartChatListSubscription({required this.userId});
  
  @override
  List<Object> get props => [userId];
}

class StopChatListSubscription extends ChatListEvent {
  const StopChatListSubscription();
}

class ChatListUpdated extends ChatListEvent {
  final List<Map<String, dynamic>> chatList;
  
  const ChatListUpdated(this.chatList);
  
  @override
  List<Object> get props => [chatList];
}

// States
abstract class ChatListState extends Equatable {
  const ChatListState();

  @override
  List<Object?> get props => [];
}

class ChatListInitial extends ChatListState {}

class ChatListLoading extends ChatListState {}

class ChatListLoaded extends ChatListState {
  final List<Map<String, dynamic>> chatList;
  
  const ChatListLoaded(this.chatList);
  
  @override
  List<Object?> get props => [chatList];
}

class ChatListError extends ChatListState {
  final String message;
  
  const ChatListError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// BLoC
class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final GetChatList getChatList;
  RealtimeChannel? _chatListSubscription;

  ChatListBloc({
    required this.getChatList,
  }) : super(ChatListInitial()) {
    on<LoadChatList>(_onLoadChatList);
    on<RefreshChatList>(_onRefreshChatList);
    on<StartChatListSubscription>(_onStartChatListSubscription);
    on<StopChatListSubscription>(_onStopChatListSubscription);
    on<ChatListUpdated>(_onChatListUpdated);
  }
  
  @override
  Future<void> close() {
    _chatListSubscription?.unsubscribe();
    return super.close();
  }

  Future<void> _onLoadChatList(
    LoadChatList event,
    Emitter<ChatListState> emit,
  ) async {
    try {
      emit(ChatListLoading());
      
      final result = await getChatList(GetChatListParams(
        userId: event.userId,
      ));
      
      result.fold(
        (failure) => emit(ChatListError(failure.message)),
        (chatList) {
          
          emit(ChatListLoaded(chatList));
        },
      );
    } catch (e) {
      emit(ChatListError('Failed to load chat list: $e'));
    }
  }

  Future<void> _onRefreshChatList(
    RefreshChatList event,
    Emitter<ChatListState> emit,
  ) async {
    try {
      emit(ChatListLoading());
      
      final result = await getChatList(GetChatListParams(
        userId: event.userId,
      ));
      
      result.fold(
        (failure) => emit(ChatListError(failure.message)),
        (chatList) {
          
          emit(ChatListLoaded(chatList));
        },
      );
    } catch (e) {
      emit(ChatListError('Failed to refresh chat list: $e'));
    }
  }
  
  Future<void> _onStartChatListSubscription(
    StartChatListSubscription event,
    Emitter<ChatListState> emit,
  ) async {
    try {
      // Stop existing subscription if any
      _chatListSubscription?.unsubscribe();
      
      // Create new subscription for chat_messages table
      _chatListSubscription = Supabase.instance.client
          .channel('chat_list_${event.userId}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'chat_messages',
            callback: (payload) {
              // Refresh chat list when there's any change in chat_messages
              add(RefreshChatList(userId: event.userId));
            },
          )
          .subscribe();
    } catch (e) {
      // Silently fail for subscription
    }
  }
  
  Future<void> _onStopChatListSubscription(
    StopChatListSubscription event,
    Emitter<ChatListState> emit,
  ) async {
    _chatListSubscription?.unsubscribe();
    _chatListSubscription = null;
  }
  
  Future<void> _onChatListUpdated(
    ChatListUpdated event,
    Emitter<ChatListState> emit,
  ) async {
    emit(ChatListLoaded(event.chatList));
  }
}
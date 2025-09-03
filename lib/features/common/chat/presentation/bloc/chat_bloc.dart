import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klik_jasa/features/common/chat/domain/usecases/send_message.dart';
import 'package:klik_jasa/features/common/chat/domain/usecases/get_chat_messages.dart';
import 'package:klik_jasa/features/common/chat/domain/usecases/mark_messages_as_read.dart';
import 'package:klik_jasa/features/common/chat/data/datasources/chat_realtime_subscription.dart';

// Events
abstract class ChatEvent extends Equatable {
  const ChatEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadChatMessages extends ChatEvent {
  final String otherUserId;
  
  const LoadChatMessages(this.otherUserId);
  
  @override
  List<Object?> get props => [otherUserId];
}

class SendMessageEvent extends ChatEvent {
  final String receiverId;
  final String message;
  final String? imageUrl;
  
  const SendMessageEvent({
    required this.receiverId,
    required this.message,
    this.imageUrl,
  });
  
  @override
  List<Object?> get props => [receiverId, message, imageUrl];
}

class MarkMessagesAsReadEvent extends ChatEvent {
  final String otherUserId;
  
  const MarkMessagesAsReadEvent(this.otherUserId);
  
  @override
  List<Object?> get props => [otherUserId];
}

class StartChatSubscription extends ChatEvent {
  final String otherUserId;
  
  const StartChatSubscription(this.otherUserId);
  
  @override
  List<Object?> get props => [otherUserId];
}

class StopChatSubscription extends ChatEvent {
  const StopChatSubscription();
}

class NewMessageReceived extends ChatEvent {
  final Map<String, dynamic> message;
  
  const NewMessageReceived(this.message);
  
  @override
  List<Object?> get props => [message];
}

class MessageUpdated extends ChatEvent {
  final Map<String, dynamic> message;
  
  const MessageUpdated(this.message);
  
  @override
  List<Object?> get props => [message];
}

// States
abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<Map<String, dynamic>> messages;
  
  const ChatLoaded(this.messages);
  
  @override
  List<Object?> get props => [messages];
}

class ChatError extends ChatState {
  final String message;
  
  const ChatError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class MessageSent extends ChatState {}

class MessageSending extends ChatState {}

// BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final SendMessage sendMessage;
  final GetChatMessages getChatMessages;
  final MarkMessagesAsRead markMessagesAsRead;
  
  ChatRealtimeSubscription? _realtimeSubscription;
  List<Map<String, dynamic>> _currentMessages = [];

  ChatBloc({
    required this.sendMessage,
    required this.getChatMessages,
    required this.markMessagesAsRead,
  }) : super(ChatInitial()) {
    on<LoadChatMessages>(_onLoadChatMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<MarkMessagesAsReadEvent>(_onMarkMessagesAsRead);
    on<StartChatSubscription>(_onStartChatSubscription);
    on<StopChatSubscription>(_onStopChatSubscription);
    on<NewMessageReceived>(_onNewMessageReceived);
    on<MessageUpdated>(_onMessageUpdated);
  }
  
  @override
  Future<void> close() {
    _realtimeSubscription?.stopSubscription();
    return super.close();
  }

  Future<void> _onLoadChatMessages(
    LoadChatMessages event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(ChatLoading());
      
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        emit(const ChatError('User not authenticated'));
        return;
      }
      
      final result = await getChatMessages(GetChatMessagesParams(
        userId: currentUser.id,
        otherUserId: event.otherUserId,
      ));
      
      result.fold(
        (failure) => emit(ChatError(failure.message)),
        (messages) {
          // Convert ChatMessage entities to Map format for UI compatibility
          final messagesList = messages.map((message) => {
            'id': message.id,
            'sender_id': message.senderId,
            'receiver_id': message.receiverId,
            'message': message.message,
            'message_type': message.messageType,
            'created_at': message.createdAt.toIso8601String(),
            'image_url': message.imageUrl,
            'status': message.status,
            'is_sender': message.senderId == currentUser.id,
          }).toList();
          
          _currentMessages = messagesList;
          emit(ChatLoaded(messagesList));
        },
      );
    } catch (e) {
      emit(ChatError('Failed to load messages: $e'));
    }
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(MessageSending());
      
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        emit(const ChatError('User not authenticated'));
        return;
      }
      
      final result = await sendMessage(SendMessageParams(
        senderId: currentUser.id,
        receiverId: event.receiverId,
        message: event.message,
        imageUrl: event.imageUrl,
      ));
      
      result.fold(
        (failure) => emit(ChatError(failure.message)),
        (sentMessage) {
          emit(MessageSent());
          // Reload messages after sending
          add(LoadChatMessages(event.receiverId));
        },
      );
    } catch (e) {
      emit(ChatError('Failed to send message: $e'));
    }
  }

  Future<void> _onMarkMessagesAsRead(
    MarkMessagesAsReadEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        return;
      }
      
      final result = await markMessagesAsRead(MarkMessagesAsReadParams(
        userId: currentUser.id,
        otherUserId: event.otherUserId,
      ));
      
      result.fold(
        (failure) => {}, // Silently fail for mark as read
        (_) => {}, // Success, no action needed
      );
    } catch (e) {
      // Silently fail for mark as read
    }
  }
  
  Future<void> _onStartChatSubscription(
    StartChatSubscription event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        return;
      }
      
      // Stop existing subscription if any
      _realtimeSubscription?.stopSubscription();
      
      // Create new subscription
      _realtimeSubscription = ChatRealtimeSubscription(
        supabaseClient: Supabase.instance.client,
        currentUserId: currentUser.id,
        otherUserId: event.otherUserId,
        onNewMessage: (message) {
          add(NewMessageReceived(message));
        },
        onMessageUpdated: (message) {
          add(MessageUpdated(message));
        },
      );
      
      _realtimeSubscription!.startSubscription();
    } catch (e) {
      // Silently fail for subscription
    }
  }
  
  Future<void> _onStopChatSubscription(
    StopChatSubscription event,
    Emitter<ChatState> emit,
  ) async {
    _realtimeSubscription?.stopSubscription();
    _realtimeSubscription = null;
  }
  
  Future<void> _onNewMessageReceived(
    NewMessageReceived event,
    Emitter<ChatState> emit,
  ) async {
    // Add new message to current messages list
    final updatedMessages = List<Map<String, dynamic>>.from(_currentMessages);
    updatedMessages.add(event.message);
    
    // Sort by created_at to maintain chronological order
    updatedMessages.sort((a, b) {
      final aTime = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.now();
      final bTime = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.now();
      return aTime.compareTo(bTime);
    });
    
    _currentMessages = updatedMessages;
    emit(ChatLoaded(updatedMessages));
  }
  
  Future<void> _onMessageUpdated(
    MessageUpdated event,
    Emitter<ChatState> emit,
  ) async {
    // Update existing message in the list
    final updatedMessages = _currentMessages.map((message) {
      if (message['id'] == event.message['id']) {
        return event.message;
      }
      return message;
    }).toList();
    
    _currentMessages = updatedMessages;
    emit(ChatLoaded(updatedMessages));
  }
}
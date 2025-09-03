import 'package:get_it/get_it.dart';
import 'package:klik_jasa/features/common/chat/presentation/bloc/chat_bloc.dart';
import 'package:klik_jasa/features/common/chat/presentation/bloc/chat_list_bloc.dart';
import 'package:klik_jasa/features/common/chat/data/datasources/chat_remote_data_source.dart';
import 'package:klik_jasa/features/common/chat/data/datasources/supabase_chat_remote_data_source.dart';
import 'package:klik_jasa/features/common/chat/data/repositories/chat_repository_impl.dart';
import 'package:klik_jasa/features/common/chat/domain/repositories/chat_repository.dart';
import 'package:klik_jasa/features/common/chat/domain/usecases/send_message.dart';
import 'package:klik_jasa/features/common/chat/domain/usecases/get_chat_messages.dart';
import 'package:klik_jasa/features/common/chat/domain/usecases/mark_messages_as_read.dart';
import 'package:klik_jasa/features/common/chat/domain/usecases/get_chat_list.dart';

/// Dependency injection container untuk fitur chat
class ChatInjectionContainer {
  static void init() {
    final sl = GetIt.instance;
    
    // BLoCs
    sl.registerFactory(() => ChatBloc(
      sendMessage: sl(),
      getChatMessages: sl(),
      markMessagesAsRead: sl(),
    ));
    sl.registerFactory(() => ChatListBloc(
      getChatList: sl(),
    ));
    
    // Use Cases
    sl.registerLazySingleton(() => SendMessage(sl()));
    sl.registerLazySingleton(() => GetChatMessages(sl()));
    sl.registerLazySingleton(() => MarkMessagesAsRead(sl()));
    sl.registerLazySingleton(() => GetChatList(sl()));
    
    // Repository
    sl.registerLazySingleton<ChatRepository>(
      () => ChatRepositoryImpl(remoteDataSource: sl()),
    );
    
    // Data Sources
    sl.registerLazySingleton<ChatRemoteDataSource>(
      () => SupabaseChatRemoteDataSource(supabaseClient: sl()),
    );
  }
}

/// Function untuk inisialisasi dependency injection chat
void initChatDependencies() {
  ChatInjectionContainer.init();
}
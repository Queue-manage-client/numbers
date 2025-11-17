import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/chat/data/repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ChatRepository(supabase);
});

final chatRoomsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final repository = ref.watch(chatRepositoryProvider);
  return await repository.getChatRooms(user.id);
});

final messagesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
    (ref, roomId) async {
  final repository = ref.watch(chatRepositoryProvider);
  return await repository.getMessages(roomId);
});

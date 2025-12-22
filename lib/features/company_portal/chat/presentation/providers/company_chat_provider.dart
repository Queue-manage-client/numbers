// features/company_portal/chat/presentation/providers/company_chat_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/company_portal/chat/data/repositories/company_chat_repository.dart';
import 'package:numbers/features/company_portal/providers/company_portal_provider.dart';

// Repository Provider
final companyChatRepositoryProvider = Provider<CompanyChatRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return CompanyChatRepository(supabase);
});

// 企業のチャットルーム一覧（名前変更: 重複回避）
final companyChatRoomsListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final companyId = ref.watch(currentCompanyIdProvider);
  if (companyId == null) return [];

  final repository = ref.watch(companyChatRepositoryProvider);
  return await repository.getCompanyChatRooms(companyId);
});

// 特定のチャットルームの詳細
final chatRoomByIdProvider = FutureProvider.family<Map<String, dynamic>?, String>(
  (ref, roomId) async {
    final repository = ref.watch(companyChatRepositoryProvider);
    return await repository.getChatRoom(roomId);
  },
);

// 特定のチャットルームのメッセージ一覧
final chatMessagesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, roomId) async {
    final repository = ref.watch(companyChatRepositoryProvider);
    return await repository.getMessages(roomId);
  },
);
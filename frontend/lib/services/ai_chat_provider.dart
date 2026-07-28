import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/chat_message_model.dart';
import '../data/repositories/ai_repository.dart';

/// AI 聊天状态
class AIChatState {
  final List<ChatMessageModel> messages;
  final bool isLoading;
  final bool isStreaming;
  final String? errorMessage;

  const AIChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isStreaming = false,
    this.errorMessage,
  });

  AIChatState copyWith({
    List<ChatMessageModel>? messages,
    bool? isLoading,
    bool? isStreaming,
    String? errorMessage,
  }) {
    return AIChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      errorMessage: errorMessage,
    );
  }
}

class AIChatNotifier extends StateNotifier<AIChatState> {
  final AIRepository _repository;

  AIChatNotifier(this._repository) : super(const AIChatState());

  /// 加载聊天历史
  Future<void> loadHistory({int? turtleId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final messages = await _repository.getChatHistory(turtleId: turtleId);
      if (messages.isEmpty) {
        // 添加欢迎消息
        state = AIChatState(
          messages: [
            ChatMessageModel(
              id: 0,
              role: 'assistant',
              content: '你好！我是懂养龟AI助手。有什么可以帮你的？',
              createdAt: DateTime.now(),
            ),
          ],
        );
      } else {
        state = state.copyWith(messages: messages, isLoading: false);
      }
    } catch (e) {
      // 失败时也显示欢迎消息
      state = AIChatState(
        messages: [
          ChatMessageModel(
            id: 0,
            role: 'assistant',
            content: '你好！我是懂养龟AI助手。有什么可以帮你的？',
            createdAt: DateTime.now(),
          ),
        ],
        errorMessage: '加载历史记录失败',
      );
    }
  }

  /// 发送消息
  Future<void> sendMessage(String content, {int? turtleId}) async {
    if (content.trim().isEmpty) return;

    // 立即添加用户消息到列表
    final userMessage = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch,
      role: 'user',
      content: content,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isStreaming: true,
      errorMessage: null,
    );

    try {
      final reply = await _repository.sendChatMessage(
        turtleId: turtleId,
        content: content,
      );
      state = state.copyWith(
        messages: [...state.messages, reply],
        isStreaming: false,
      );
    } catch (e) {
      // 添加错误提示
      final errorMessage = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch,
        role: 'assistant',
        content: '抱歉，回复失败，请稍后重试。',
        createdAt: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isStreaming: false,
        errorMessage: '发送失败',
      );
    }
  }

  /// 清空聊天
  void clearChat() {
    state = const AIChatState();
  }
}

final aiChatProvider =
    StateNotifierProvider<AIChatNotifier, AIChatState>((ref) {
  return AIChatNotifier(ref.watch(aiRepositoryProvider));
});

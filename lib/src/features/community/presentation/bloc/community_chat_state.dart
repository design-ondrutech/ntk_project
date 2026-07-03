import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/community/data/models/community_message_model.dart';
import 'package:ntk_project/src/features/community/data/models/community_model.dart';

class CommunityChatState extends Equatable {
  final bool isLoading;
  final bool isSendingMessage;
  final List<CommunityMessageModel> messages;
  final List<String> typingUsers;
  final CommunityModel? currentCommunitySettings;
  final String? error;

  const CommunityChatState({
    this.isLoading = false,
    this.isSendingMessage = false,
    this.messages = const [],
    this.typingUsers = const [],
    this.currentCommunitySettings,
    this.error,
  });

  CommunityChatState copyWith({
    bool? isLoading,
    bool? isSendingMessage,
    List<CommunityMessageModel>? messages,
    List<String>? typingUsers,
    CommunityModel? currentCommunitySettings,
    String? error,
    bool clearError = false,
  }) {
    return CommunityChatState(
      isLoading: isLoading ?? this.isLoading,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
      messages: messages ?? this.messages,
      typingUsers: typingUsers ?? this.typingUsers,
      currentCommunitySettings:
          currentCommunitySettings ?? this.currentCommunitySettings,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isSendingMessage,
    messages,
    typingUsers,
    currentCommunitySettings,
    error,
  ];
}

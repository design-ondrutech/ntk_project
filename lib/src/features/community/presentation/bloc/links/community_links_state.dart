import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/community/data/models/community_link_doc_model.dart';

class CommunityLinksState extends Equatable {
  final bool isLoading;
  final bool isUploading;
  final List<CommunityLinkDocModel> links;
  final String? error;
  final String? successMessage;

  const CommunityLinksState({
    this.isLoading = false,
    this.isUploading = false,
    this.links = const [],
    this.error,
    this.successMessage,
  });

  CommunityLinksState copyWith({
    bool? isLoading,
    bool? isUploading,
    List<CommunityLinkDocModel>? links,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return CommunityLinksState(
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      links: links ?? this.links,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [isLoading, isUploading, links, error, successMessage];
}

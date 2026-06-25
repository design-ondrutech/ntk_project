import 'package:equatable/equatable.dart';

class PendingJoinRequestModel extends Equatable {
  final int id;
  final String? reason;
  final String createdAt;
  final Map<String, dynamic>? user;

  const PendingJoinRequestModel({
    required this.id,
    this.reason,
    required this.createdAt,
    this.user,
  });

  factory PendingJoinRequestModel.fromJson(Map<String, dynamic> json) {
    return PendingJoinRequestModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      reason: json['reason'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      user: json['user'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [id, reason, createdAt, user];
}

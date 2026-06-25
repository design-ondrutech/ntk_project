import 'package:equatable/equatable.dart';

class CommunityBanModel extends Equatable {
  final int id;
  final int userId;
  final String reason;
  final String bannedUntil;
  final String? userName;
  final String? userPhone;

  const CommunityBanModel({
    required this.id,
    required this.userId,
    required this.reason,
    required this.bannedUntil,
    this.userName,
    this.userPhone,
  });

  factory CommunityBanModel.fromJson(Map<String, dynamic> json) {
    return CommunityBanModel(
      id: json['id'] as int,
      userId: json['userId'] as int,
      reason: json['reason'] as String,
      bannedUntil: json['bannedUntil'] as String,
      userName: json['user']?['name'] as String?,
      userPhone: json['user']?['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'reason': reason,
      'bannedUntil': bannedUntil,
      'user': {
        if (userName != null) 'name': userName,
        if (userPhone != null) 'phone': userPhone,
      },
    };
  }

  @override
  List<Object?> get props => [id, userId, reason, bannedUntil, userName, userPhone];
}

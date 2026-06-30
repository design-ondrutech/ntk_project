import 'package:equatable/equatable.dart';

class CommunityMemberModel extends Equatable {
  final int id;
  final String name;
  final String? phone;
  final String? image;
  final String? role;
  final bool isGroupAdmin;
  final bool isMuted;
  final String? joinedAt;

  const CommunityMemberModel({
    required this.id,
    required this.name,
    this.phone,
    this.image,
    this.role,
    this.isGroupAdmin = false,
    this.isMuted = false,
    this.joinedAt,
  });

  factory CommunityMemberModel.fromJson(Map<String, dynamic> json) {
    return CommunityMemberModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      phone: json['phone'] as String?,
      image: json['image'] as String?,
      role: json['role'] as String?,
      isGroupAdmin: json['isGroupAdmin'] as bool? ?? (json['role'] == 'ADMIN'),
      isMuted: json['isMuted'] as bool? ?? false,
      joinedAt: json['memberSince'] as String? ?? json['joinedAt'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    image,
    role,
    isGroupAdmin,
    isMuted,
    joinedAt,
  ];
}

enum CommunityRole {
  owner,
  admin,
  moderator,
  member,
  nonMember,
}

extension CommunityRoleExtension on CommunityRole {
  String get name {
    switch (this) {
      case CommunityRole.owner:
        return 'OWNER';
      case CommunityRole.admin:
        return 'ADMIN';
      case CommunityRole.moderator:
        return 'MODERATOR';
      case CommunityRole.member:
        return 'MEMBER';
      case CommunityRole.nonMember:
        return 'NON_MEMBER';
    }
  }

  static CommunityRole fromString(String? role) {
    switch (role?.toUpperCase()) {
      case 'OWNER':
        return CommunityRole.owner;
      case 'ADMIN':
        return CommunityRole.admin;
      case 'MODERATOR':
        return CommunityRole.moderator;
      case 'MEMBER':
        return CommunityRole.member;
      default:
        return CommunityRole.nonMember;
    }
  }
}

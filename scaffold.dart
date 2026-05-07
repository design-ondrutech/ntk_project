import 'dart:io';

void main() {
  final directories = [
    'lib/core/constants',
    'lib/core/theme',
    'lib/core/utils',
    'lib/core/common_widgets',
    'lib/core/network',
    'lib/features/auth/presentation/screens',
    'lib/features/auth/presentation/widgets',
    'lib/features/auth/domain',
    'lib/features/auth/data',
    'lib/features/dashboard/presentation/screens',
    'lib/features/requests_broadcasts/presentation/screens',
    'lib/features/members/presentation/screens',
    'lib/features/events/presentation/screens',
    'lib/features/community/presentation/screens',
    'lib/features/notifications/presentation/screens',
  ];

  for (var dir in directories) {
    Directory(dir).createSync(recursive: true);
  }

  final files = {
    'lib/features/auth/presentation/screens/login_screen.dart': 'LoginScreen',
    'lib/features/auth/presentation/widgets/login_card.dart': 'LoginCard',
    'lib/features/dashboard/presentation/screens/dashboard_screen.dart': 'DashboardScreen',
    'lib/features/requests_broadcasts/presentation/screens/requests_broadcasts_screen.dart': 'RequestsBroadcastsScreen',
    'lib/features/members/presentation/screens/members_list_screen.dart': 'MembersListScreen',
    'lib/features/members/presentation/screens/member_profile_screen.dart': 'MemberProfileScreen',
    'lib/features/events/presentation/screens/events_overview_screen.dart': 'EventsOverviewScreen',
    'lib/features/events/presentation/screens/event_details_screen.dart': 'EventDetailsScreen',
    'lib/features/community/presentation/screens/community_feed_screen.dart': 'CommunityFeedScreen',
    'lib/features/notifications/presentation/screens/notifications_screen.dart': 'NotificationsScreen',
  };

  files.forEach((path, className) {
    final file = File(path);
    if (!file.existsSync()) {
      String content = '''
import 'package:flutter/material.dart';

class $className extends StatelessWidget {
  const $className({super.key});

  @override
  Widget build(BuildContext context) {
''' + (path.contains('login_card') ? '''
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('$className'),
      ),
    );
  }
}
''' : '''
    return Scaffold(
      appBar: AppBar(
        title: const Text('$className'),
      ),
      body: const Center(
        child: Text('$className Content'),
      ),
    );
  }
}
''');

      file.writeAsStringSync(content);
    }
  });

  print('Project structure generated successfully!');
}

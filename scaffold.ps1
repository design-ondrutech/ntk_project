$directories = @(
    "lib/core/constants",
    "lib/core/theme",
    "lib/core/utils",
    "lib/core/common_widgets",
    "lib/core/network",
    "lib/features/auth/presentation/screens",
    "lib/features/auth/presentation/widgets",
    "lib/features/auth/domain",
    "lib/features/auth/data",
    "lib/features/dashboard/presentation/screens",
    "lib/features/requests_broadcasts/presentation/screens",
    "lib/features/members/presentation/screens",
    "lib/features/events/presentation/screens",
    "lib/features/community/presentation/screens",
    "lib/features/notifications/presentation/screens"
)

foreach ($dir in $directories) {
    if (-Not (Test-Path -Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
}

$files = @{
    "lib/features/auth/presentation/screens/login_screen.dart" = "LoginScreen"
    "lib/features/auth/presentation/widgets/login_card.dart" = "LoginCard"
    "lib/features/dashboard/presentation/screens/dashboard_screen.dart" = "DashboardScreen"
    "lib/features/requests_broadcasts/presentation/screens/requests_broadcasts_screen.dart" = "RequestsBroadcastsScreen"
    "lib/features/members/presentation/screens/members_list_screen.dart" = "MembersListScreen"
    "lib/features/members/presentation/screens/member_profile_screen.dart" = "MemberProfileScreen"
    "lib/features/events/presentation/screens/events_overview_screen.dart" = "EventsOverviewScreen"
    "lib/features/events/presentation/screens/event_details_screen.dart" = "EventDetailsScreen"
    "lib/features/community/presentation/screens/community_feed_screen.dart" = "CommunityFeedScreen"
    "lib/features/notifications/presentation/screens/notifications_screen.dart" = "NotificationsScreen"
}

foreach ($path in $files.Keys) {
    $className = $files[$path]
    if (-Not (Test-Path -Path $path)) {
        $content = ""
        if ($path -match "login_card") {
            $content = @"
import 'package:flutter/material.dart';

class $className extends StatelessWidget {
  const ${className}({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('$className'),
      ),
    );
  }
}
"@
        } else {
            $content = @"
import 'package:flutter/material.dart';

class $className extends StatelessWidget {
  const ${className}({super.key});

  @override
  Widget build(BuildContext context) {
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
"@
        }
        Set-Content -Path $path -Value $content
    }
}

Write-Host "Project structure generated successfully!"

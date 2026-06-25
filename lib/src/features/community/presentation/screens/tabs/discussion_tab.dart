import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/animated_like_button.dart';
import 'package:ntk_project/src/features/community/data/models/community_model.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_posts_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_posts_event.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_posts_state.dart';
import 'package:ntk_project/src/features/community/presentation/screens/create_community_post_screen.dart';
import 'package:ntk_project/src/features/community/presentation/screens/community_post_details_screen.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/utils/date_helper.dart';
import 'package:ntk_project/src/features/community/presentation/screens/community_chat_screen.dart';

class DiscussionTab extends StatefulWidget {
  final CommunityModel community;

  const DiscussionTab({Key? key, required this.community}) : super(key: key);

  @override
  State<DiscussionTab> createState() => _DiscussionTabState();
}

class _DiscussionTabState extends State<DiscussionTab> {
  @override
  void initState() {
    super.initState();
    context.read<CommunityPostsBloc>().add(FetchCommunityPostsList(widget.community.id));
  }

  @override
  Widget build(BuildContext context) {
    return CommunityChatScreen(
      community: widget.community,
      showAppBar: false,
    );
  }
}

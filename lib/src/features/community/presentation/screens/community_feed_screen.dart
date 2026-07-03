import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/utils/date_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/core/widgets/ntk_snackbar.dart';
import 'package:ntk_project/src/core/widgets/ntk_dropdown_field.dart';
import 'package:ntk_project/src/core/widgets/async_base64_image.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/community/data/models/comment_model.dart';
import 'package:ntk_project/src/features/community/data/models/community_model.dart';
import 'package:ntk_project/src/features/community/data/models/poll_model.dart';
import 'package:ntk_project/src/features/community/data/models/post_model.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_event.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_polls_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_polls_event.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_polls_state.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_state.dart';
import 'package:ntk_project/src/features/community/presentation/screens/community_chat_screen.dart';
import 'package:ntk_project/src/features/community/presentation/screens/community_details_screen.dart';
import 'package:ntk_project/src/features/community/presentation/screens/community_admin_screen.dart';
import 'package:ntk_project/l10n/app_localizations.dart';
import 'package:ntk_project/src/features/community/presentation/screens/community_settings_screen.dart';
import 'package:ntk_project/src/features/community/presentation/screens/create_community_group_screen.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:ntk_project/src/features/location/data/models/location_model.dart';
import 'package:ntk_project/src/features/location/domain/repositories/location_repository.dart';
import 'package:ntk_project/src/injection_container.dart';

const _primary = Color(0xFF0A3D28);
const _secondary = Color(0xFF0F8A4B);
const _bg = Color(0xFFF6F8F7);
const _line = Color(0xFFE7ECE9);
const _text = Color(0xFF111827);
const _muted = Color(0xFF667085);

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  CommunityModel? _selectedCommunity;
  String _activeFilter = 'All';
  String _groupsFilter = 'All';
  final TextEditingController _groupSearchController = TextEditingController();
  String _groupSearchQuery = '';

  bool _hasFetchedCommunities = false;
  bool _hasFetchedFeed = false;
  bool _hasFetchedPolls = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, initialIndex: 1, vsync: this);
    _tabController.addListener(_onTabChanged);
    _fetchForTab(1); // Initially on Feed tab
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _fetchForTab(_tabController.index);
    }
  }

  void _fetchForTab(int index) {
    if (index == 0 && !_hasFetchedCommunities) {
      context.read<CommunityBloc>().add(const FetchCommunities());
      _hasFetchedCommunities = true;
    } else if (index == 1 && !_hasFetchedFeed) {
      _fetchFeed();
      _hasFetchedFeed = true;
    } else if (index == 2 && !_hasFetchedPolls) {
      _fetchPolls();
      _hasFetchedPolls = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _groupSearchController.dispose();
    super.dispose();
  }

  int? get _locationId {
    final globalLoc = context.read<DashboardBloc>().state.globalLocation;
    final auth = context.read<AuthBloc>().state.loginData;
    return globalLoc?.id ?? auth?.locationId;
  }

  String get _locationName {
    final globalLoc = context.watch<DashboardBloc>().state.globalLocation;
    final auth = context.watch<AuthBloc>().state.loginData;
    return localizeLocationName(
      context,
      globalLoc?.name ?? auth?.locationName ?? 'Nagapattinam',
    );
  }

  void _fetchFeed() {
    if (_selectedCommunity != null) {
      context.read<CommunityBloc>().add(
        FetchCommunityPosts(_selectedCommunity!.id),
      );
      return;
    }
    context.read<CommunityBloc>().add(
      FetchCommunityFeed(locationId: _locationId),
    );
  }

  void _fetchPolls() {
    context.read<CommunityPollsBloc>().add(
      FetchPollsEvent(
        communityId: _selectedCommunity?.id,
        locationId: _selectedCommunity == null ? _locationId : null,
      ),
    );
  }

  Future<void> _openCreatePost(String category) async {
    final locationId = _locationId;
    if (locationId == null) {
      NTKSnackbar.showError(context, message: 'Location not found');
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CreatePostScreen(
          initialCategory: category,
          locationId: locationId,
          locationName: _locationName,
        ),
      ),
    );
    // Refresh feed to sync from server after create
    if (mounted) _fetchFeed();
  }

  Future<void> _openCreatePoll() async {
    final locationId = _locationId;
    if (locationId == null) {
      NTKSnackbar.showError(context, message: 'Location not found');
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CreatePollScreen(
          locationId: locationId,
          selectedCommunity: _selectedCommunity,
          locationName: _locationName,
        ),
      ),
    );
  }

  void _openChat(CommunityModel community) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityChatScreen(community: community),
      ),
    );
  }

  void _openCreateGroupScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateCommunityGroupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CommunityBloc, CommunityState>(
          listener: (context, state) {
            if (state.message != null) {
              NTKSnackbar.showSuccess(context, message: state.message!);
              context.read<CommunityBloc>().add(const ClearCommunityMessage());
            }
            if (state.error != null) {
              String msg = state.error!;
              if (msg.toLowerCase().contains('already reported') ||
                  msg.toLowerCase().contains('already resolved')) {
                msg =
                    'You have already reported this post / நீங்கள் ஏற்கனவே இந்த பதிவைப் பற்றி புகார் அளித்துள்ளீர்கள்.';
              }
              NTKSnackbar.showError(context, message: msg);
              context.read<CommunityBloc>().add(const ClearCommunityError());
            }
          },
        ),
        BlocListener<CommunityPollsBloc, CommunityPollsState>(
          listener: (context, state) {
            if (state.successMessage != null) {
              NTKSnackbar.showSuccess(context, message: state.successMessage!);
              context.read<CommunityPollsBloc>().add(const ClearPollsMessage());
            }
            if (state.error != null) {
              NTKSnackbar.showError(context, message: state.error!);
              context.read<CommunityPollsBloc>().add(const ClearPollsError());
            }
          },
        ),
        BlocListener<DashboardBloc, DashboardState>(
          listenWhen: (previous, current) =>
              previous.globalLocation?.id != current.globalLocation?.id,
          listener: (context, state) {
            _hasFetchedFeed = false;
            _hasFetchedPolls = false;
            _fetchForTab(_tabController.index);
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: _bg,
        appBar: NTKAppBar(
          title: _selectedCommunity?.name ?? 'Community',
          subtitle: _locationName,
          actions: [
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                if (_tabController.index == 0) {
                  final userRole = context
                      .watch<AuthBloc>()
                      .state
                      .loginData
                      ?.role;
                  if (userRole != 'SUB_ADMIN' &&
                      userRole != 'ADMIN' &&
                      userRole != 'SUPER_ADMIN') {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                    icon: const Icon(CupertinoIcons.add, color: Colors.white),
                    onPressed: () => _openCreateGroupScreen(context),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.bell, color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, '/notifications'),
            ),
          ],
        ),
        body: Column(
          children: [
            _Tabs(controller: _tabController),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGroupsTab(),
                  _buildFeedTab(),
                  _buildPollsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommunitySelector() {
    final communities = context.read<CommunityBloc>().state.communities;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select community',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _CommunityOption(
                icon: Icons.public_rounded,
                title: 'All communities',
                subtitle: _locationName,
                selected: _selectedCommunity == null,
                onTap: () {
                  setState(() => _selectedCommunity = null);
                  Navigator.pop(context);
                  _hasFetchedFeed = false;
                  _hasFetchedPolls = false;
                  _fetchForTab(_tabController.index);
                },
              ),
              ...communities
                  .take(8)
                  .map(
                    (community) => _CommunityOption(
                      icon: _groupIcon(community.name),
                      title: community.name,
                      subtitle: '${community.memberCount} members',
                      selected: _selectedCommunity?.id == community.id,
                      onTap: () {
                        setState(() => _selectedCommunity = community);
                        Navigator.pop(context);
                        _hasFetchedFeed = false;
                        _hasFetchedPolls = false;
                        _fetchForTab(_tabController.index);
                      },
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedTab() {
    return RefreshIndicator(
      color: _primary,
      onRefresh: () async {
        _fetchFeed();
        _fetchPolls();
      },
      child: BlocBuilder<CommunityBloc, CommunityState>(
        buildWhen: (prev, curr) {
          // Prevent full list rebuild just because likes changed
          return prev.isFeedLoading != curr.isFeedLoading ||
              prev.isLoading != curr.isLoading ||
              prev.posts.length != curr.posts.length ||
              prev.feedPosts.length != curr.feedPosts.length ||
              prev.posts.firstOrNull?.id != curr.posts.firstOrNull?.id ||
              prev.feedPosts.firstOrNull?.id != curr.feedPosts.firstOrNull?.id;
        },
        builder: (context, state) {
          final posts = _selectedCommunity == null
              ? state.feedPosts
              : state.posts;

          if (state.isFeedLoading || state.isLoading) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              children: [
                _CreatePostCard(
                  onPhoto: () => _openCreatePost('Information'),
                  onVideo: () => _openCreatePost('Information'),
                  onPoll: _openCreatePoll,
                  onPost: () => _openCreatePost('Discussion'),
                ),
                const SizedBox(height: 14),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CupertinoActivityIndicator()),
                ),
              ],
            );
          }

          if (posts.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              children: [
                _CreatePostCard(
                  onPhoto: () => _openCreatePost('Information'),
                  onVideo: () => _openCreatePost('Information'),
                  onPoll: _openCreatePoll,
                  onPost: () => _openCreatePost('Discussion'),
                ),
                const SizedBox(height: 14),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No posts yet. Be the first to post!',
                      style: TextStyle(color: _muted, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            itemCount: posts.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  children: [
                    _CreatePostCard(
                      onPhoto: () => _openCreatePost('Information'),
                      onVideo: () => _openCreatePost('Information'),
                      onPoll: _openCreatePoll,
                      onPost: () => _openCreatePost('Discussion'),
                    ),
                    const SizedBox(height: 14),
                  ],
                );
              }
              final post = posts[index - 1];
              return _PostCard(
                key: ValueKey(post.id),
                post: post,
                onLike: () =>
                    context.read<CommunityBloc>().add(LikePost(post.id)),
                onComment: () => _openPostDetails(post, autoFocusComment: true),
                onOpen: () => _openPostDetails(post),
                onDelete: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                        'Delete Post',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      content: const Text(
                        'This post will be permanently deleted. Are you sure?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.read<CommunityBloc>().add(
                              DeletePost(post.id),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildGroupsTab() {
    return BlocBuilder<CommunityBloc, CommunityState>(
      builder: (context, state) {
        if (state.isLoading && state.communities.isEmpty) {
          return const _GroupsLoadingSkeleton();
        }

        final allCommunities = state.communities;

        // Apply filter
        List<CommunityModel> filtered;
        switch (_groupsFilter) {
          case 'Joined':
            filtered = allCommunities.where((c) => c.isJoined).toList();
            break;
          case 'Featured':
            filtered = allCommunities
                .where((c) => c.privacyType == 'PUBLIC')
                .toList();
            break;
          case 'Nearby':
            filtered = allCommunities
                .where((c) => c.locationId != null)
                .toList();
            break;
          default:
            filtered = allCommunities;
        }

        // Apply search
        if (_groupSearchQuery.isNotEmpty) {
          filtered = filtered
              .where(
                (c) => c.name.toLowerCase().contains(
                  _groupSearchQuery.toLowerCase(),
                ),
              )
              .toList();
        }

        return RefreshIndicator(
          color: _primary,
          onRefresh: () async =>
              context.read<CommunityBloc>().add(const FetchCommunities()),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Filter Chips ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final label in ['All', 'Joined', 'Featured', 'Nearby'])
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: _GroupFilterChip(
                              label: label == 'All'
                                  ? AppLocalizations.of(context)!.all
                                  : label == 'Joined'
                                      ? AppLocalizations.of(context)!.joinedFilter
                                      : label == 'Featured'
                                          ? AppLocalizations.of(context)!.featuredFilter
                                          : AppLocalizations.of(context)!.nearbyFilter,
                              selected: _groupsFilter == label,
                              onTap: () => setState(() => _groupsFilter = label),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // ── Divider ──────────────────────────────────────────
              const SliverToBoxAdapter(
                child: Divider(height: 1, color: Color(0xFFEEF2F0)),
              ),
              // ── Count Bar ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        '${filtered.length} ${filtered.length == 1 ? AppLocalizations.of(context)!.communitySingleText : AppLocalizations.of(context)!.communitiesCountText}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _muted,
                        ),
                      ),
                      const Spacer(),
                      if (state.isLoading)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _primary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // ── Empty State ──────────────────────────────────────
              if (filtered.isEmpty && !state.isLoading)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF4EE),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.group_outlined,
                            size: 36,
                            color: _primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No communities found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _text,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Try a different filter or search term',
                          style: TextStyle(fontSize: 13, color: _muted),
                        ),
                      ],
                    ),
                  ),
                ),
              // ── Community Cards ──────────────────────────────────
              if (filtered.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _CommunityCard(
                        community: filtered[index],
                        isJoined: filtered[index].isJoined,
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPollsTab() {
    return BlocBuilder<CommunityPollsBloc, CommunityPollsState>(
      builder: (context, state) {
        return RefreshIndicator(
          color: _primary,
          onRefresh: () async => _fetchPolls(),
          child: Builder(
            builder: (context) {
              if (state.isLoading) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                  children: [
                    _CreatePollPrompt(onTap: _openCreatePoll),
                    const SizedBox(height: 14),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CupertinoActivityIndicator()),
                    ),
                  ],
                );
              }
              if (state.polls.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                  children: [
                    _CreatePollPrompt(onTap: _openCreatePoll),
                    const SizedBox(height: 14),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.poll_outlined,
                              size: 56,
                              color: Color(0xFFCBD5E1),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No polls yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Be the first to create a poll',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }

              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                itemCount: state.polls.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      children: [
                        _CreatePollPrompt(onTap: _openCreatePoll),
                        const SizedBox(height: 14),
                      ],
                    );
                  }
                  final poll = state.polls[index - 1];
                  return _PollCard(
                    key: ValueKey(poll.id),
                    poll: poll,
                    onTap: () => _openPollDetails(poll),
                    onVote: (optionId) =>
                        context.read<CommunityPollsBloc>().add(
                          VoteInPollEvent(pollId: poll.id, optionId: optionId),
                        ),
                    onLike: () => context.read<CommunityPollsBloc>().add(
                      LikePollEvent(pollId: poll.id),
                    ),
                    onComment: () => _openPollDetails(
                      poll,
                    ), // Can open details for full comments
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _openPollDetails(PollModel poll) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _PollDetailsScreen(poll: poll)),
    );
  }

  void _openPostDetails(PostModel post, {bool autoFocusComment = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _PostDetailsScreen(post: post, autoFocusComment: autoFocusComment),
      ),
    );
  }
}

class _CreatePostScreen extends StatefulWidget {
  const _CreatePostScreen({
    required this.initialCategory,
    required this.locationId,
    required this.locationName,
  });

  final String initialCategory;
  final int locationId;
  final String locationName;

  @override
  State<_CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<_CreatePostScreen> {
  late String _category = widget.initialCategory.isEmpty
      ? 'General'
      : widget.initialCategory;
  final _content = TextEditingController();
  final _picker = ImagePicker();
  final List<File> _images = [];

  late LocationRepository _locationRepo;

  final List<String> _states = ['Tamil Nadu'];
  String? _selectedState = 'Tamil Nadu';

  List<LocationModel> _districts = [];
  LocationModel? _selectedDistrict;
  bool _loadingDistricts = false;

  List<LocationModel> _constituencies = [];
  LocationModel? _selectedConstituency;
  bool _loadingConstituencies = false;

  List<LocationModel> _areas = [];
  LocationModel? _selectedArea;
  bool _loadingAreas = false;

  List<LocationModel> _streets = [];
  LocationModel? _selectedStreet;
  bool _loadingStreets = false;

  @override
  void initState() {
    super.initState();
    _locationRepo = sl<LocationRepository>();
    _initLocationForRole();
  }

  Future<void> _initLocationForRole() async {
    final authState = context.read<AuthBloc>().state;
    final role = authState.loginData?.role ?? 'MEMBER';
    final locationId = authState.loginData?.locationId;
    final globalLocation = context.read<DashboardBloc>().state.globalLocation;

    if (role == 'SUPER_ADMIN') {
      _loadDistricts();
      return;
    }

    if (role == 'DISTRICT_INCHARGE' && locationId != null) {
      int distId = locationId;
      LocationModel? preSelectedTaluk;

      if (globalLocation != null) {
        if (globalLocation.type?.toUpperCase() == 'TALUK' || globalLocation.type?.toUpperCase() == 'CONSTITUENCY') {
          preSelectedTaluk = globalLocation;
          if (globalLocation.parentId != null) distId = globalLocation.parentId!;
        } else if (globalLocation.type?.toUpperCase() == 'DISTRICT') {
          distId = globalLocation.id;
        }
      } else {
        final assignedDistricts = context.read<DashboardBloc>().state.assignedLocations
            .where((l) => l.location?.type?.toUpperCase() == 'DISTRICT')
            .map((l) => l.location!)
            .toList();
        if (assignedDistricts.isNotEmpty) {
           distId = assignedDistricts.firstWhere((d) => d.id == locationId, orElse: () => assignedDistricts.first).id;
        }
      }

      if (mounted) {
        setState(() {
          _loadingConstituencies = true;
        });
      }
      
      try {
        final allDistricts = await _locationRepo.getLocationList(type: 'DISTRICT');
        final match = allDistricts.where((d) => d.id == distId).firstOrNull;
        if (match != null && mounted) {
          setState(() {
            _selectedDistrict = match;
            _districts = [match];
          });
        }
      } catch (e) {
        debugPrint('_initLocationForRole: error resolving district: $e');
      }
      
      try {
        final taluks = await _locationRepo.getLocationList(type: 'TALUK', parentId: distId);
        if (mounted) {
          setState(() {
            _constituencies = taluks;
            _loadingConstituencies = false;
          });
          
          if (preSelectedTaluk != null) {
            final match = _constituencies.where((c) => c.id == preSelectedTaluk!.id).firstOrNull;
            if (match != null) {
              setState(() {
                _selectedConstituency = match;
                _loadingAreas = true;
              });
              final areas = await _locationRepo.getLocationList(type: 'AREA', parentId: match.id);
              if (mounted) {
                setState(() {
                  _areas = areas;
                  _loadingAreas = false;
                });
              }
            }
          }
        }
      } catch (_) {
        if (mounted) setState(() => _loadingConstituencies = false);
      }
      return;
    }

    if (locationId != null) {
      setState(() {
        _loadingDistricts = true;
        _loadingConstituencies = true;
        _loadingAreas = true;
      });
      try {
        final districts = await _locationRepo.getLocationList(type: 'DISTRICT');
        bool found = false;

        if (districts.any((d) => d.id == locationId)) {
          final district = districts.firstWhere((d) => d.id == locationId);
          if (mounted) {
            setState(() {
              _selectedDistrict = district;
              _districts = [district];
              _loadingDistricts = false;
              _loadingConstituencies = false;
              _loadingAreas = false;
            });
          }
          found = true;
        }

        if (!found) {
          for (final district in districts) {
            final taluks = await _locationRepo.getLocationList(
              parentId: district.id,
              type: 'TALUK',
            );

            if (taluks.any((t) => t.id == locationId)) {
              final taluk = taluks.firstWhere((t) => t.id == locationId);
              if (mounted) {
                setState(() {
                  _selectedDistrict = district;
                  _districts = [district];
                  _selectedConstituency = taluk;
                  _constituencies = [taluk];
                  _loadingDistricts = false;
                  _loadingConstituencies = false;
                  _loadingAreas = false;
                });
              }
              found = true;
              break;
            }

            for (final taluk in taluks) {
              final areas = await _locationRepo.getLocationList(
                parentId: taluk.id,
                type: 'AREA',
              );
              if (areas.any((a) => a.id == locationId)) {
                final area = areas.firstWhere((a) => a.id == locationId);
                if (mounted) {
                  setState(() {
                    _selectedDistrict = district;
                    _districts = [district];
                    _selectedConstituency = taluk;
                    _constituencies = [taluk];
                    _selectedArea = area;
                    _areas = [area];
                    _loadingDistricts = false;
                    _loadingConstituencies = false;
                    _loadingAreas = false;
                  });
                  _loadStreetsForSubAdmin(area.id);
                }
                found = true;
                break;
              }
              // Check streets
              for (final area in areas) {
                final streets = await _locationRepo.getLocationList(
                  parentId: area.id,
                  type: 'STREET',
                );
                if (streets.any((s) => s.id == locationId)) {
                  final street = streets.firstWhere((s) => s.id == locationId);
                  if (mounted) {
                    setState(() {
                      _selectedDistrict = district;
                      _districts = [district];
                      _selectedConstituency = taluk;
                      _constituencies = [taluk];
                      _selectedArea = area;
                      _areas = [area];
                      _selectedStreet = street;
                      _streets = [street];
                      _loadingDistricts = false;
                      _loadingConstituencies = false;
                      _loadingAreas = false;
                      _loadingStreets = false;
                    });
                  }
                  found = true;
                  break;
                }
              }
              if (found) break;
            }
            if (found) break;
          }
        }
        if (!found && mounted) {
          setState(() {
            _loadingDistricts = false;
            _loadingConstituencies = false;
            _loadingAreas = false;
          });
          _loadDistricts();
        }
      } catch (e) {
        debugPrint('Error finding location hierarchy: $e');
        if (mounted) {
          setState(() {
            _loadingDistricts = false;
            _loadingConstituencies = false;
            _loadingAreas = false;
          });
          _loadDistricts();
        }
      }
    } else {
      _loadDistricts();
    }
  }

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  Future<void> _loadDistricts() async {
    setState(() => _loadingDistricts = true);
    try {
      final list = await _locationRepo.getLocationList(type: 'DISTRICT');
      setState(() {
        _districts = list;
        _loadingDistricts = false;
      });
    } catch (_) {
      setState(() => _loadingDistricts = false);
    }
  }

  Future<void> _loadStreetsForSubAdmin(int areaId) async {
    setState(() => _loadingStreets = true);
    try {
      final list = await _locationRepo.getLocationList(
        type: 'STREET',
        parentId: areaId,
      );
      setState(() {
        _streets = list;
        _loadingStreets = false;
      });
    } catch (_) {
      setState(() => _loadingStreets = false);
    }
  }

  Future<void> _onDistrictChanged(LocationModel? district) async {
    setState(() {
      _selectedDistrict = district;
      _selectedConstituency = null;
      _selectedArea = null;
      _selectedStreet = null;
      _constituencies = [];
      _areas = [];
      _streets = [];
    });
    if (district == null) return;
    setState(() => _loadingConstituencies = true);
    try {
      final list = await _locationRepo.getLocationList(
        type: 'TALUK',
        parentId: district.id,
      );
      setState(() {
        _constituencies = list;
        _loadingConstituencies = false;
      });
    } catch (_) {
      setState(() => _loadingConstituencies = false);
    }
  }

  Future<void> _onConstituencyChanged(LocationModel? taluk) async {
    setState(() {
      _selectedConstituency = taluk;
      _selectedArea = null;
      _selectedStreet = null;
      _areas = [];
      _streets = [];
    });
    if (taluk == null) return;
    setState(() => _loadingAreas = true);
    try {
      final list = await _locationRepo.getLocationList(
        type: 'AREA',
        parentId: taluk.id,
      );
      setState(() {
        _areas = list;
        _loadingAreas = false;
      });
    } catch (_) {
      setState(() => _loadingAreas = false);
    }
  }

  Future<void> _onAreaChanged(LocationModel? area) async {
    setState(() {
      _selectedArea = area;
      _selectedStreet = null;
      _streets = [];
    });
    if (area == null) return;
    setState(() => _loadingStreets = true);
    try {
      final list = await _locationRepo.getLocationList(
        type: 'STREET',
        parentId: area.id,
      );
      setState(() {
        _streets = list;
        _loadingStreets = false;
      });
    } catch (_) {
      setState(() => _loadingStreets = false);
    }
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(
      imageQuality: 55,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (picked.isEmpty) return;
    setState(() {
      _images.addAll(picked.take(6 - _images.length).map((x) => File(x.path)));
    });
  }

  Future<void> _publish() async {
    final content = _content.text.trim();
    if (content.isEmpty) {
      NTKSnackbar.showError(context, message: 'Please enter post content');
      return;
    }

    final authState = context.read<AuthBloc>().state;
    final userRole = authState.loginData?.role ?? '';

    int eventLocationId;
    if (userRole == 'SUB_ADMIN') {
      eventLocationId = _selectedStreet?.id ?? widget.locationId;
    } else {
      // Use manual selection if available, else fall back to user's registered location
      final finalLocation =
          _selectedStreet ??
          _selectedArea ??
          _selectedConstituency ??
          _selectedDistrict;
      eventLocationId = finalLocation?.id ?? widget.locationId;
    }

    final auth = authState.loginData;
    final images = <String>[];
    for (final image in _images) {
      images.add(
        'data:image/jpeg;base64,${base64Encode(await image.readAsBytes())}',
      );
    }
    context.read<CommunityBloc>().add(
      CreateCommunityPost(
        title: _category,
        content: content,
        category: _category,
        images: images,
        authorName: auth?.name ?? 'Community Member',
        authorRole: auth?.role ?? 'MEMBER',
        locationId: eventLocationId,
      ),
    );
    Navigator.pop(context);
  }

  Widget _buildDropdownField<T>({
    required List<T> items,
    required T? value,
    required ValueChanged<T?>? onChanged,
    required String Function(T) itemLabel,
    required String hintText,
  }) {
    final bool isDisabled = onChanged == null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDisabled ? const Color(0xFFF9FAFB) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: Icon(
            isDisabled ? CupertinoIcons.lock : CupertinoIcons.chevron_down,
            size: isDisabled ? 14 : 16,
            color: isDisabled ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
          hint: Text(
            hintText,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabel(item),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDisabled ? const Color(0xFF9CA3AF) : const Color(0xFF1F2937),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildLoadingField(String label) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Color(0xFF004D2A)),
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Loading...',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledField(String message) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.lock, size: 14, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 10),
          Text(
            message,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final role = authState.loginData?.role ?? 'MEMBER';

    final canChangeDistrict = role == 'SUPER_ADMIN';
    final canChangeTaluk = canChangeDistrict || role == 'DISTRICT_ADMIN' || role == 'DISTRICT_INCHARGE';
    final canChangeArea = canChangeTaluk || role == 'ADMIN' || role == 'CONSTITUENCY_INCHARGE';
    final canChangeStreet = role != 'MEMBER' && role != 'STREET_INCHARGE';

    final remaining = 500 - _content.text.length;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF004D2A), // Dark Green
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          AppLocalizations.of(context)!.createPost,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  _FormLabel(AppLocalizations.of(context)!.selectCategory),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _CategoryChip(
                        label: AppLocalizations.of(context)!.general,
                        icon: Icons.public_rounded,
                        active: _category == 'General',
                        onTap: () => setState(() => _category = 'General'),
                      ),
                      _CategoryChip(
                        label: AppLocalizations.of(context)!.discussion,
                        icon: Icons.forum_outlined,
                        active: _category == 'Discussion',
                        onTap: () => setState(() => _category = 'Discussion'),
                      ),
                      _CategoryChip(
                        label: AppLocalizations.of(context)!.suggestion,
                        icon: Icons.lightbulb_outline,
                        active: _category == 'Suggestion',
                        onTap: () => setState(() => _category = 'Suggestion'),
                      ),
                      _CategoryChip(
                        label: AppLocalizations.of(context)!.complaint,
                        icon: Icons.warning_amber_rounded,
                        active: _category == 'Complaint',
                        onTap: () => setState(() => _category = 'Complaint'),
                      ),
                      _CategoryChip(
                        label: AppLocalizations.of(context)!.information,
                        icon: Icons.info_outline_rounded,
                        active: _category == 'Information',
                        onTap: () => setState(() => _category = 'Information'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _FormLabel(AppLocalizations.of(context)!.whatIsHappening),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _content,
                    maxLength: 500,
                    minLines: 6,
                    maxLines: 10,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.writeYourPost,
                      counterText: '',
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${remaining.clamp(0, 500)}/500',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FormLabel(AppLocalizations.of(context)!.addPhotos),
                  const SizedBox(height: 10),
                  _ImagePreviewGrid(
                    images: _images,
                    onAdd: _pickImages,
                    onRemove: (index) =>
                        setState(() => _images.removeAt(index)),
                  ),
                  const SizedBox(height: 20),
                  _FormLabel(AppLocalizations.of(context)!.location),
                  const SizedBox(height: 8),
                  // Show user's registered location as default
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF6EF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF004D2A).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFF004D2A),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${AppLocalizations.of(context)!.defaultText}: ${widget.locationName}',
                            style: const TextStyle(
                              color: Color(0xFF004D2A),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Text(
                          'Auto',
                          style: TextStyle(
                            color: Color(0xFF004D2A),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppLocalizations.of(context)!.orSelectSpecificLocation,
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Builder(
                    builder: (context) {
                      final loc = AppLocalizations.of(context)!;
                      final authState = context.read<AuthBloc>().state;
                      final userRole = authState.loginData?.role ?? '';
                      final isSubAdmin = userRole == 'SUB_ADMIN';

                      if (isSubAdmin) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FormLabel(loc.street),
                            const SizedBox(height: 6),
                            _loadingStreets
                                ? _buildLoadingField(loc.street)
                                : _buildDropdownField<LocationModel>(
                                    items: _streets,
                                    value: _selectedStreet,
                                    onChanged: (val) =>
                                        setState(() => _selectedStreet = val),
                                    itemLabel: (item) => item.name,
                                    hintText: loc.selectStreetOptional,
                                  ),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. State
                          _FormLabel(loc.state),
                          const SizedBox(height: 6),
                          _buildDropdownField<String>(
                            items: _states,
                            value: _selectedState,
                            onChanged: (val) =>
                                setState(() => _selectedState = val),
                            itemLabel: (item) => item,
                            hintText: loc.selectState,
                          ),
                          const SizedBox(height: 16),

                          // 2. District
                          _FormLabel(loc.district),
                          const SizedBox(height: 6),
                          _loadingDistricts
                              ? _buildLoadingField(loc.district)
                              : _buildDropdownField<LocationModel>(
                                  items: _districts,
                                  value: _selectedDistrict,
                                  onChanged: canChangeDistrict
                                      ? _onDistrictChanged
                                      : null,
                                  itemLabel: (item) => item.name,
                                  hintText: loc.selectDistrictOptional,
                                ),
                          const SizedBox(height: 16),

                          // 3. Constituency (Taluk)
                          _FormLabel(loc.constituencyTaluk),
                          const SizedBox(height: 6),
                          _loadingConstituencies
                              ? _buildLoadingField(loc.constituencyTaluk)
                              : _selectedDistrict == null
                              ? _buildDisabledField(loc.selectDistrictFirst)
                              : _buildDropdownField<LocationModel>(
                                  items: _constituencies,
                                  value: _selectedConstituency,
                                  onChanged: canChangeTaluk
                                      ? _onConstituencyChanged
                                      : null,
                                  itemLabel: (item) => item.name,
                                  hintText: loc.selectConstituency,
                                ),
                          const SizedBox(height: 16),

                          // 4. Area (Town)
                          _FormLabel(loc.areaTown),
                          const SizedBox(height: 6),
                          _loadingAreas
                              ? _buildLoadingField(loc.areaTown)
                              : _selectedConstituency == null
                              ? _buildDisabledField(loc.selectConstituencyFirst)
                              : _buildDropdownField<LocationModel>(
                                  items: _areas,
                                  value: _selectedArea,
                                  onChanged: canChangeArea
                                      ? _onAreaChanged
                                      : null,
                                  itemLabel: (item) => item.name,
                                  hintText: loc.selectArea,
                                ),
                          const SizedBox(height: 16),

                          // 5. Street
                          _FormLabel(loc.street),
                          const SizedBox(height: 6),
                          _loadingStreets
                              ? _buildLoadingField(loc.street)
                              : _selectedArea == null
                              ? _buildDisabledField(loc.selectAreaFirst)
                              : _buildDropdownField<LocationModel>(
                                  items: _streets,
                                  value: _selectedStreet,
                                  onChanged: canChangeStreet
                                      ? (val) => setState(
                                          () => _selectedStreet = val,
                                        )
                                      : null,
                                  itemLabel: (item) => item.name,
                                  hintText: loc.selectStreet,
                                ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            _BottomAction(label: AppLocalizations.of(context)!.post, onTap: _publish),
          ],
        ),
      ),
    );
  }
}

class _CreatePollScreen extends StatefulWidget {
  const _CreatePollScreen({
    required this.locationId,
    required this.locationName,
    this.selectedCommunity,
  });

  final int locationId;
  final String locationName;
  final CommunityModel? selectedCommunity;

  @override
  State<_CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<_CreatePollScreen> {
  final _question = TextEditingController();
  final List<TextEditingController> _options = [
    TextEditingController(),
    TextEditingController(),
  ];
  int _duration = 1;

  late LocationRepository _locationRepo;

  final List<String> _states = ['Tamil Nadu'];
  String? _selectedState = 'Tamil Nadu';

  List<LocationModel> _districts = [];
  LocationModel? _selectedDistrict;
  bool _loadingDistricts = false;

  List<LocationModel> _constituencies = [];
  LocationModel? _selectedConstituency;
  bool _loadingConstituencies = false;

  List<LocationModel> _areas = [];
  LocationModel? _selectedArea;
  bool _loadingAreas = false;

  List<LocationModel> _streets = [];
  LocationModel? _selectedStreet;
  bool _loadingStreets = false;

  @override
  void initState() {
    super.initState();
    _locationRepo = sl<LocationRepository>();
    _initLocationForRole();
  }

  Future<void> _initLocationForRole() async {
    final authState = context.read<AuthBloc>().state;
    final role = authState.loginData?.role ?? 'MEMBER';
    final locationId = authState.loginData?.locationId;
    final globalLocation = context.read<DashboardBloc>().state.globalLocation;

    if (role == 'SUPER_ADMIN') {
      _loadDistricts();
      return;
    }

    if (role == 'DISTRICT_INCHARGE' && locationId != null) {
      int distId = locationId;
      LocationModel? preSelectedTaluk;

      if (globalLocation != null) {
        if (globalLocation.type?.toUpperCase() == 'TALUK' || globalLocation.type?.toUpperCase() == 'CONSTITUENCY') {
          preSelectedTaluk = globalLocation;
          if (globalLocation.parentId != null) distId = globalLocation.parentId!;
        } else if (globalLocation.type?.toUpperCase() == 'DISTRICT') {
          distId = globalLocation.id;
        }
      } else {
        final assignedDistricts = context.read<DashboardBloc>().state.assignedLocations
            .where((l) => l.location?.type?.toUpperCase() == 'DISTRICT')
            .map((l) => l.location!)
            .toList();
        if (assignedDistricts.isNotEmpty) {
           distId = assignedDistricts.firstWhere((d) => d.id == locationId, orElse: () => assignedDistricts.first).id;
        }
      }

      if (mounted) {
        setState(() {
          _loadingConstituencies = true;
        });
      }
      
      try {
        final allDistricts = await _locationRepo.getLocationList(type: 'DISTRICT');
        final match = allDistricts.where((d) => d.id == distId).firstOrNull;
        if (match != null && mounted) {
          setState(() {
            _selectedDistrict = match;
            _districts = [match];
          });
        }
      } catch (e) {
        debugPrint('_initLocationForRole: error resolving district: $e');
      }
      
      try {
        final taluks = await _locationRepo.getLocationList(type: 'TALUK', parentId: distId);
        if (mounted) {
          setState(() {
            _constituencies = taluks;
            _loadingConstituencies = false;
          });
          
          if (preSelectedTaluk != null) {
            final match = _constituencies.where((c) => c.id == preSelectedTaluk!.id).firstOrNull;
            if (match != null) {
              setState(() {
                _selectedConstituency = match;
                _loadingAreas = true;
              });
              final areas = await _locationRepo.getLocationList(type: 'AREA', parentId: match.id);
              if (mounted) {
                setState(() {
                  _areas = areas;
                  _loadingAreas = false;
                });
              }
            }
          }
        }
      } catch (_) {
        if (mounted) setState(() => _loadingConstituencies = false);
      }
      return;
    }

    if (locationId != null) {
      setState(() {
        _loadingDistricts = true;
        _loadingConstituencies = true;
        _loadingAreas = true;
      });
      try {
        final districts = await _locationRepo.getLocationList(type: 'DISTRICT');
        bool found = false;

        if (districts.any((d) => d.id == locationId)) {
          final district = districts.firstWhere((d) => d.id == locationId);
          if (mounted) {
            setState(() {
              _selectedDistrict = district;
              _districts = [district];
              _loadingDistricts = false;
              _loadingConstituencies = false;
              _loadingAreas = false;
            });
          }
          found = true;
        }

        if (!found) {
          for (final district in districts) {
            final taluks = await _locationRepo.getLocationList(
              parentId: district.id,
              type: 'TALUK',
            );

            if (taluks.any((t) => t.id == locationId)) {
              final taluk = taluks.firstWhere((t) => t.id == locationId);
              if (mounted) {
                setState(() {
                  _selectedDistrict = district;
                  _districts = [district];
                  _selectedConstituency = taluk;
                  _constituencies = [taluk];
                  _loadingDistricts = false;
                  _loadingConstituencies = false;
                  _loadingAreas = false;
                });
              }
              found = true;
              break;
            }

            for (final taluk in taluks) {
              final areas = await _locationRepo.getLocationList(
                parentId: taluk.id,
                type: 'AREA',
              );
              if (areas.any((a) => a.id == locationId)) {
                final area = areas.firstWhere((a) => a.id == locationId);
                if (mounted) {
                  setState(() {
                    _selectedDistrict = district;
                    _districts = [district];
                    _selectedConstituency = taluk;
                    _constituencies = [taluk];
                    _selectedArea = area;
                    _areas = [area];
                    _loadingDistricts = false;
                    _loadingConstituencies = false;
                    _loadingAreas = false;
                  });
                  _loadStreetsForSubAdmin(area.id);
                }
                found = true;
                break;
              }
              // Check streets
              for (final area in areas) {
                final streets = await _locationRepo.getLocationList(
                  parentId: area.id,
                  type: 'STREET',
                );
                if (streets.any((s) => s.id == locationId)) {
                  final street = streets.firstWhere((s) => s.id == locationId);
                  if (mounted) {
                    setState(() {
                      _selectedDistrict = district;
                      _districts = [district];
                      _selectedConstituency = taluk;
                      _constituencies = [taluk];
                      _selectedArea = area;
                      _areas = [area];
                      _selectedStreet = street;
                      _streets = [street];
                      _loadingDistricts = false;
                      _loadingConstituencies = false;
                      _loadingAreas = false;
                      _loadingStreets = false;
                    });
                  }
                  found = true;
                  break;
                }
              }
              if (found) break;
            }
            if (found) break;
          }
        } // Close if (!found)
        if (!found && mounted) {
          setState(() {
            _loadingDistricts = false;
            _loadingConstituencies = false;
            _loadingAreas = false;
          });
          _loadDistricts();
        }
      } catch (e) {
        debugPrint('Error finding location hierarchy: $e');
        if (mounted) {
          setState(() {
            _loadingDistricts = false;
            _loadingConstituencies = false;
            _loadingAreas = false;
          });
          _loadDistricts();
        }
      }
    } else {
      _loadDistricts();
    }
  }

  @override
  void dispose() {
    _question.dispose();
    for (final controller in _options) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDistricts() async {
    setState(() => _loadingDistricts = true);
    try {
      final list = await _locationRepo.getLocationList(type: 'DISTRICT');
      setState(() {
        _districts = list;
        _loadingDistricts = false;
      });
    } catch (_) {
      setState(() => _loadingDistricts = false);
    }
  }

  Future<void> _loadStreetsForSubAdmin(int areaId) async {
    setState(() => _loadingStreets = true);
    try {
      final list = await _locationRepo.getLocationList(
        type: 'STREET',
        parentId: areaId,
      );
      setState(() {
        _streets = list;
        _loadingStreets = false;
      });
    } catch (_) {
      setState(() => _loadingStreets = false);
    }
  }

  Future<void> _onDistrictChanged(LocationModel? district) async {
    final authState = context.read<AuthBloc>().state;
    final role = authState.loginData?.role ?? 'MEMBER';
    if (role != 'ADMIN' && role != 'SUPER_ADMIN') {
      return; // Lock changes for non-admins
    }
    setState(() {
      _selectedDistrict = district;
      _selectedConstituency = null;
      _selectedArea = null;
      _selectedStreet = null;
      _constituencies = [];
      _areas = [];
      _streets = [];
    });
    if (district == null) return;
    setState(() => _loadingConstituencies = true);
    try {
      final list = await _locationRepo.getLocationList(
        type: 'TALUK',
        parentId: district.id,
      );
      setState(() {
        _constituencies = list;
        _loadingConstituencies = false;
      });
    } catch (_) {
      setState(() => _loadingConstituencies = false);
    }
  }

  Future<void> _onConstituencyChanged(LocationModel? taluk) async {
    final authState = context.read<AuthBloc>().state;
    final role = authState.loginData?.role ?? 'MEMBER';
    if (role != 'ADMIN' && role != 'SUPER_ADMIN' && role != 'DISTRICT_ADMIN') {
      return; // District Admin and above can change Taluk
    }
    setState(() {
      _selectedConstituency = taluk;
      _selectedArea = null;
      _selectedStreet = null;
      _areas = [];
      _streets = [];
    });
    if (taluk == null) return;
    setState(() => _loadingAreas = true);
    try {
      final list = await _locationRepo.getLocationList(
        type: 'AREA',
        parentId: taluk.id,
      );
      setState(() {
        _areas = list;
        _loadingAreas = false;
      });
    } catch (_) {
      setState(() => _loadingAreas = false);
    }
  }

  Future<void> _onAreaChanged(LocationModel? area) async {
    final authState = context.read<AuthBloc>().state;
    final role = authState.loginData?.role ?? 'MEMBER';
    if (role == 'MEMBER') {
      return; // Members cannot change Area
    }
    setState(() {
      _selectedArea = area;
      _selectedStreet = null;
      _streets = [];
    });
    if (area == null) return;
    setState(() => _loadingStreets = true);
    try {
      final list = await _locationRepo.getLocationList(
        type: 'STREET',
        parentId: area.id,
      );
      setState(() {
        _streets = list;
        _loadingStreets = false;
      });
    } catch (_) {
      setState(() => _loadingStreets = false);
    }
  }

  void _createPoll() {
    final question = _question.text.trim();
    final options = _options
        .map((x) => x.text.trim())
        .where((x) => x.isNotEmpty)
        .toList();
    if (question.isEmpty || options.length < 2) {
      NTKSnackbar.showError(
        context,
        message: 'Add a question and at least two options',
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    final userRole = authState.loginData?.role ?? '';

    int eventLocationId;
    if (userRole == 'SUB_ADMIN') {
      eventLocationId = _selectedStreet?.id ?? widget.locationId;
    } else {
      // Use manual selection if available, else fall back to user's registered location
      final finalLocation =
          _selectedStreet ??
          _selectedArea ??
          _selectedConstituency ??
          _selectedDistrict;
      eventLocationId = finalLocation?.id ?? widget.locationId;
    }

    context.read<CommunityPollsBloc>().add(
      CreatePollEvent(
        question: question,
        options: options,
        durationDays: _duration,
        locationId: eventLocationId,
        communityId: widget.selectedCommunity?.id,
      ),
    );
    Navigator.pop(context);
  }

  Widget _buildDropdownField<T>({
    required List<T> items,
    required T? value,
    required ValueChanged<T?>? onChanged,
    required String Function(T) itemLabel,
    required String hintText,
  }) {
    final bool isDisabled = onChanged == null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDisabled ? const Color(0xFFF9FAFB) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: Icon(
            isDisabled ? CupertinoIcons.lock : CupertinoIcons.chevron_down,
            size: isDisabled ? 14 : 16,
            color: isDisabled ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
          hint: Text(
            hintText,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabel(item),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDisabled ? const Color(0xFF9CA3AF) : const Color(0xFF1F2937),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildLoadingField(String label) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Color(0xFF004D2A)),
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Loading...',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledField(String message) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.lock, size: 14, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 10),
          Text(
            message,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final role = authState.loginData?.role ?? 'MEMBER';

    final canChangeDistrict = role == 'SUPER_ADMIN';
    final canChangeTaluk = canChangeDistrict || role == 'DISTRICT_ADMIN' || role == 'DISTRICT_INCHARGE';
    final canChangeArea = canChangeTaluk || role == 'ADMIN' || role == 'CONSTITUENCY_INCHARGE';
    final canChangeStreet = role != 'MEMBER' && role != 'STREET_INCHARGE';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF004D2A), // Dark Green
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          AppLocalizations.of(context)!.createPollTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  _FormLabel(AppLocalizations.of(context)!.pollQuestion),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _question,
                    maxLength: 100,
                    minLines: 3,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.enterYourQuestion,
                      counterText: '0/100',
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FormLabel(AppLocalizations.of(context)!.options),
                  const SizedBox(height: 10),
                  ...List.generate(_options.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _options[index],
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(context)!.optionIndex(index + 1),
                              ),
                            ),
                          ),
                          if (_options.length > 2)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded),
                              onPressed: () =>
                                  setState(() => _options.removeAt(index)),
                            ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: _options.length >= 6
                        ? null
                        : () => setState(
                            () => _options.add(TextEditingController()),
                          ),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(AppLocalizations.of(context)!.addOption),
                  ),
                  const SizedBox(height: 18),
                  _FormLabel(AppLocalizations.of(context)!.pollDuration),
                  const SizedBox(height: 8),
                  _DurationRadios(
                    value: _duration,
                    onChanged: (value) => setState(() => _duration = value),
                  ),
                  const SizedBox(height: 18),
                  _FormLabel(AppLocalizations.of(context)!.targetLocation),
                  const SizedBox(height: 10),
                  Builder(
                    builder: (context) {
                      final authState = context.read<AuthBloc>().state;
                      final userRole = authState.loginData?.role ?? '';
                      final isSubAdmin = userRole == 'SUB_ADMIN';

                      if (isSubAdmin) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FormLabel(AppLocalizations.of(context)!.street),
                            const SizedBox(height: 6),
                            _loadingStreets
                                ? _buildLoadingField(AppLocalizations.of(context)!.street)
                                : _buildDropdownField<LocationModel>(
                                    items: _streets,
                                    value: _selectedStreet,
                                    onChanged: (val) =>
                                        setState(() => _selectedStreet = val),
                                    itemLabel: (item) => item.name,
                                    hintText: AppLocalizations.of(context)!.selectStreetOptional,
                                  ),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. State
                          _FormLabel(AppLocalizations.of(context)!.state),
                          const SizedBox(height: 6),
                          _buildDropdownField<String>(
                            items: _states,
                            value: _selectedState,
                            onChanged: (val) =>
                                setState(() => _selectedState = val),
                            itemLabel: (item) => item,
                            hintText: AppLocalizations.of(context)!.selectState,
                          ),
                          const SizedBox(height: 16),

                          // 2. District
                          _FormLabel(AppLocalizations.of(context)!.districtAsterisk),
                          const SizedBox(height: 6),
                          _loadingDistricts
                              ? _buildLoadingField(AppLocalizations.of(context)!.district)
                              : _buildDropdownField<LocationModel>(
                                  items: _districts,
                                  value: _selectedDistrict,
                                  onChanged: canChangeDistrict
                                      ? _onDistrictChanged
                                      : null,
                                  itemLabel: (item) => item.name,
                                  hintText: AppLocalizations.of(context)!.selectDistrict,
                                ),
                          const SizedBox(height: 16),

                          // 3. Constituency (Taluk)
                          _FormLabel(AppLocalizations.of(context)!.constituencyTaluk),
                          const SizedBox(height: 6),
                          _loadingConstituencies
                              ? _buildLoadingField(AppLocalizations.of(context)!.constituencyTaluk)
                              : _selectedDistrict == null
                              ? _buildDisabledField(AppLocalizations.of(context)!.selectDistrictFirst)
                              : _buildDropdownField<LocationModel>(
                                  items: _constituencies,
                                  value: _selectedConstituency,
                                  onChanged: canChangeTaluk
                                      ? _onConstituencyChanged
                                      : null,
                                  itemLabel: (item) => item.name,
                                  hintText: AppLocalizations.of(context)!.selectConstituency,
                                ),
                          const SizedBox(height: 16),

                          // 4. Area (Town)
                          _FormLabel(AppLocalizations.of(context)!.areaTown),
                          const SizedBox(height: 6),
                          _loadingAreas
                              ? _buildLoadingField(AppLocalizations.of(context)!.areaTown)
                              : _selectedConstituency == null
                              ? _buildDisabledField(AppLocalizations.of(context)!.selectConstituencyFirst)
                              : _buildDropdownField<LocationModel>(
                                  items: _areas,
                                  value: _selectedArea,
                                  onChanged: canChangeArea
                                      ? _onAreaChanged
                                      : null,
                                  itemLabel: (item) => item.name,
                                  hintText: AppLocalizations.of(context)!.selectArea,
                                ),
                          const SizedBox(height: 16),

                          // 5. Street
                          _FormLabel(AppLocalizations.of(context)!.street),
                          const SizedBox(height: 6),
                          _loadingStreets
                              ? _buildLoadingField(AppLocalizations.of(context)!.street)
                              : _selectedArea == null
                              ? _buildDisabledField('Select Area first')
                              : _buildDropdownField<LocationModel>(
                                  items: _streets,
                                  value: _selectedStreet,
                                  onChanged: canChangeStreet
                                      ? (val) => setState(
                                          () => _selectedStreet = val,
                                        )
                                      : null,
                                  itemLabel: (item) => item.name,
                                  hintText: AppLocalizations.of(context)!.selectStreetOptional,
                                ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            _BottomAction(label: AppLocalizations.of(context)!.createPollTitle, onTap: _createPoll),
          ],
        ),
      ),
    );
  }
}

class _PollDetailsScreen extends StatefulWidget {
  const _PollDetailsScreen({required this.poll});

  final PollModel poll;

  @override
  State<_PollDetailsScreen> createState() => _PollDetailsScreenState();
}

class _PollDetailsScreenState extends State<_PollDetailsScreen> {
  final _comment = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  CommentModel? _replyingToComment;

  @override
  void initState() {
    super.initState();
    context.read<CommunityPollsBloc>().add(
      FetchPollDetailsEvent(pollId: widget.poll.id),
    );
  }

  @override
  void dispose() {
    _comment.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 150,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _addComment(int pollId) {
    final text = _comment.text.trim();
    if (text.isEmpty) return;
    final auth = context.read<AuthBloc>().state.loginData;
    context.read<CommunityPollsBloc>().add(
      AddPollCommentEvent(
        pollId: pollId,
        content: text,
        authorName: auth?.name ?? 'Community Member',
        authorRole: auth?.role ?? 'MEMBER',
        parentId: _replyingToComment?.id,
      ),
    );
    _comment.clear();
    setState(() {
      _replyingToComment = null;
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Poll Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<CommunityPollsBloc, CommunityPollsState>(
                builder: (context, state) {
                  final livePoll = state.polls.firstWhere(
                    (p) => p.id == widget.poll.id,
                    orElse: () => widget.poll,
                  );
                  final liveTotal = livePoll.votesCount == 0
                      ? livePoll.options.fold<int>(
                          0,
                          (sum, o) => sum + o.votesCount,
                        )
                      : livePoll.votesCount;
                  final liveHasVoted = livePoll.userVoteOptionId != null;

                  bool isExpired = false;
                  if (livePoll.expiresAt != null &&
                      livePoll.expiresAt!.isNotEmpty) {
                    try {
                      final parsed = DateHelper.parseUtcToLocal(
                        livePoll.expiresAt!,
                      );
                      isExpired = parsed.isBefore(DateTime.now());
                    } catch (_) {}
                  }

                  final comments = livePoll.comments;
                  final rootComments = comments
                      .where((c) => c.parentId == null)
                      .toList();

                  return ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(18),
                    children: [
                      _AuthorLine(
                        name:
                            livePoll.createdBy?['name']?.toString() ??
                            'Community Poll',
                        location: livePoll.location?['name']?.toString() ?? '',
                        time: _timeAgo(livePoll.createdAt),
                        image: livePoll.createdBy?['image']?.toString(),
                        role: livePoll.createdBy?['role']?.toString(),
                        category: isExpired
                            ? 'Expired'
                            : (liveHasVoted ? 'Voted' : 'Active'),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        livePoll.question,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _text,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Column(
                        children: livePoll.options.map((option) {
                          final pct = liveTotal == 0
                              ? 0.0
                              : option.votesCount / liveTotal;
                          if (liveHasVoted || isExpired) {
                            return _ResultBar(
                              label: option.text,
                              percent: pct,
                              votes: option.votesCount,
                              highlighted:
                                  livePoll.userVoteOptionId == option.id,
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: OutlinedButton(
                              onPressed: () =>
                                  context.read<CommunityPollsBloc>().add(
                                    VoteInPollEvent(
                                      pollId: livePoll.id,
                                      optionId: option.id,
                                    ),
                                  ),
                              style: OutlinedButton.styleFrom(
                                alignment: Alignment.centerLeft,
                                minimumSize: const Size(double.infinity, 48),
                                side: const BorderSide(
                                  color: _primary,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                foregroundColor: _text,
                              ),
                              child: Text(
                                option.text,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              title: 'Total Votes',
                              value: '$liveTotal',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MetricCard(
                              title: 'Ends in',
                              value: _remainingTime(livePoll.expiresAt),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SocialActions(
                        postId: livePoll.id,
                        likes: livePoll.likes,
                        comments: livePoll.commentCount,
                        isLiked: livePoll.isLiked,
                        onLike: () {
                          context.read<CommunityPollsBloc>().add(
                            LikePollEvent(pollId: livePoll.id),
                          );
                        },
                        onComment: () {
                          _focusNode.requestFocus();
                        },
                        onShare: () {
                          Share.share(
                            '${livePoll.question}\n\nShared via NTK App',
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      const _SectionHeader(title: 'Comments'),
                      const SizedBox(height: 8),
                      if (rootComments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No comments yet. Be the first to comment!',
                              style: TextStyle(color: _muted, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        ...rootComments.map(
                          (comment) => _CommentTile(
                            comment: comment,
                            onLike: (c) {
                              context.read<CommunityPollsBloc>().add(
                                LikePollCommentEvent(pollCommentId: c.id),
                              );
                            },
                            onReply: (c) {
                              setState(() {
                                _replyingToComment = c;
                              });
                              _focusNode.requestFocus();
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            if (_replyingToComment != null)
              Container(
                color: const Color(0xFFEAF6EF),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Replying to ${_replyingToComment!.authorName}: "${_replyingToComment!.content}"',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        setState(() {
                          _replyingToComment = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            _CommentComposer(
              controller: _comment,
              focusNode: _focusNode,
              onSend: () => _addComment(widget.poll.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostDetailsScreen extends StatefulWidget {
  const _PostDetailsScreen({required this.post, this.autoFocusComment = false});

  final PostModel post;
  final bool autoFocusComment;

  @override
  State<_PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<_PostDetailsScreen> {
  final _comment = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  CommentModel? _replyingToComment;

  @override
  void dispose() {
    _comment.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 150,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _addComment(int postId) {
    final text = _comment.text.trim();
    if (text.isEmpty) return;
    final auth = context.read<AuthBloc>().state.loginData;
    context.read<CommunityBloc>().add(
      AddComment(
        postId: postId,
        content: text,
        authorName: auth?.name ?? 'Community Member',
        authorRole: auth?.role ?? 'MEMBER',
        parentId: _replyingToComment?.id,
      ),
    );
    _comment.clear();
    setState(() {
      _replyingToComment = null;
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  /// Find the live post from bloc state, falling back to the original snapshot.
  PostModel _livePost(CommunityState state) {
    final fromFeed = state.feedPosts.cast<PostModel?>().firstWhere(
      (p) => p?.id == widget.post.id,
      orElse: () => null,
    );
    if (fromFeed != null) return fromFeed;
    final fromPosts = state.posts.cast<PostModel?>().firstWhere(
      (p) => p?.id == widget.post.id,
      orElse: () => null,
    );
    return fromPosts ?? widget.post;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF004D2A),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Post Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<CommunityBloc, CommunityState>(
                buildWhen: (prev, curr) {
                  return _livePost(prev) != _livePost(curr);
                },
                builder: (context, state) {
                  final post = _livePost(state);
                  final comments = post.comments;
                  final rootComments = comments
                      .where((c) => c.parentId == null)
                      .toList();
                  return ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(14),
                    children: [
                      _PostCard(
                        post: post,
                        onLike: () => context.read<CommunityBloc>().add(
                          LikePost(post.id),
                        ),
                        onComment: () {
                          _focusNode.requestFocus();
                        },
                        onOpen: () {},
                        onDelete: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: const Text(
                                'Delete Post',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              content: const Text(
                                'This post will be permanently deleted. Are you sure?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    context.read<CommunityBloc>().add(
                                      DeletePost(post.id),
                                    );
                                    Navigator.pop(context); // back to feed
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF4444),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      const _SectionHeader(title: 'Comments'),
                      const SizedBox(height: 8),
                      if (rootComments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No comments yet. Be the first to comment!',
                              style: TextStyle(color: _muted, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        ...rootComments.map(
                          (comment) => _CommentTile(
                            comment: comment,
                            onLike: (c) {
                              context.read<CommunityBloc>().add(
                                LikeComment(c.id),
                              );
                            },
                            onReply: (c) {
                              setState(() {
                                _replyingToComment = c;
                              });
                              _focusNode.requestFocus();
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            if (_replyingToComment != null)
              Container(
                color: const Color(0xFFEAF6EF),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Replying to ${_replyingToComment!.authorName}: "${_replyingToComment!.content}"',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        setState(() {
                          _replyingToComment = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            _CommentComposer(
              controller: _comment,
              focusNode: _focusNode,
              autofocus: widget.autoFocusComment,
              onSend: () => _addComment(widget.post.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: controller,
        indicatorColor: _secondary,
        indicatorWeight: 3,
        labelColor: _primary,
        unselectedLabelColor: _muted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        tabs: [
          Tab(text: AppLocalizations.of(context)!.groupsTab),
          Tab(text: AppLocalizations.of(context)!.feedTab),
          Tab(text: AppLocalizations.of(context)!.pollsTab),
        ],
      ),
    );
  }
}

class _QuickFilters extends StatelessWidget {
  const _QuickFilters({required this.active, required this.onChanged});

  final String active;
  final ValueChanged<String> onChanged;

  static const filters = [
    ('All', Icons.grid_view_rounded, Color(0xFF009A62)),
    ('My Street', Icons.home_rounded, Color(0xFFF6A93B)),
    ('My Area', Icons.location_on_rounded, Color(0xFF8057E6)),
    ('My Constituency', Icons.account_balance_rounded, Color(0xFFE6A11D)),
    ('Nearby', Icons.groups_rounded, Color(0xFF2F6DE0)),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, index) {
          final item = filters[index];
          final selected = active == item.$1;
          return InkWell(
            onTap: () => onChanged(item.$1),
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 72,
              child: Column(
                children: [
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: selected ? item.$3 : item.$3.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      item.$2,
                      color: selected ? Colors.white : item.$3,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    item.$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? _primary : _text,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CreatePostCard extends StatelessWidget {
  const _CreatePostCard({
    required this.onPhoto,
    required this.onVideo,
    required this.onPoll,
    required this.onPost,
  });

  final VoidCallback onPhoto;
  final VoidCallback onVideo;
  final VoidCallback onPoll;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFEAF6EF),
                child: Icon(Icons.person_rounded, color: _primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: onPost,
                  child: Text(
                    AppLocalizations.of(context)!.whatIsHappening,
                    style: const TextStyle(color: _muted, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 22, color: _line),
          Row(
            children: [
              Expanded(
                child: _InlineAction(
                  icon: Icons.image_outlined,
                  label: AppLocalizations.of(context)!.photo,
                  onTap: onPhoto,
                ),
              ),
              Expanded(
                child: _InlineAction(
                  icon: Icons.poll_outlined,
                  label: AppLocalizations.of(context)!.poll,
                  onTap: onPoll,
                ),
              ),
              SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: onPost,
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: Text(AppLocalizations.of(context)!.post),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _secondary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(80, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onOpen,
    this.onDelete,
  });

  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;

  void _showReportDialog(BuildContext context) {
    final reasons = [
      'Spam or irrelevant content',
      'Misinformation / Fake news',
      'Offensive or inappropriate',
      'Harassment or bullying',
      'Other',
    ];
    String? selectedReason;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.flag_rounded, color: Color(0xFFF59E0B), size: 20),
              SizedBox(width: 8),
              Text(
                'Report Post',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select a reason:',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 10),
              ...reasons.map(
                (reason) => RadioListTile<String>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(reason, style: const TextStyle(fontSize: 13)),
                  value: reason,
                  groupValue: selectedReason,
                  activeColor: _primary,
                  onChanged: (v) => setState(() => selectedReason = v),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () {
                      String apiReason = 'Other';
                      if (selectedReason == 'Spam or irrelevant content') {
                        apiReason = 'Spam';
                      } else if (selectedReason ==
                          'Misinformation / Fake news') {
                        apiReason = 'Fake Information';
                      } else if (selectedReason ==
                          'Offensive or inappropriate') {
                        apiReason = 'Inappropriate Content';
                      } else if (selectedReason == 'Harassment or bullying') {
                        apiReason = 'Abuse/Harassment';
                      }

                      context.read<CommunityBloc>().add(
                        ReportPost(postId: post.id, reason: apiReason),
                      );
                      Navigator.pop(ctx);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }

  void _showModerateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.gavel_rounded, color: Color(0xFF0F8A4B), size: 20),
            SizedBox(width: 8),
            Text(
              'Moderate Post',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Select moderation action for this post:',
          style: TextStyle(fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              icon: const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF0F8A4B),
              ),
              label: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Keep Post',
                  style: TextStyle(color: Color(0xFF0F8A4B)),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _showConfirmKeepDialog(context);
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              icon: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
              ),
              label: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Send Warning',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _showSendWarningDialog(context);
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEF4444),
              ),
              label: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Delete Post',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                onDelete?.call();
              },
            ),
          ),
          const Divider(),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmKeepDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Keep Post',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to approve and keep this post? This will clear any pending reviews.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CommunityBloc>().add(
                ModeratePost(postId: post.id, action: 'KEEP'),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F8A4B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showSendWarningDialog(BuildContext context) {
    final TextEditingController msgController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Send Warning',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Send a warning to the author of this post. The post will remain visible but marked with a warning.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: msgController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter warning message to the user...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CommunityBloc>().add(
                ModeratePost(
                  postId: post.id,
                  action: 'WARN',
                  warningMessage: msgController.text.trim().isNotEmpty
                      ? msgController.text.trim()
                      : null,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<AuthBloc>().state.loginData?.id;
    final role =
        context.watch<AuthBloc>().state.loginData?.role.toUpperCase() ??
        'MEMBER';
    final isAdmin =
        role == 'SUB_ADMIN' || role == 'ADMIN' || role == 'SUPER_ADMIN';
    final isOwner =
        myId != null && post.createdById != null && myId == post.createdById;

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(16),
      child: _Card(
        margin: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _AuthorLine(
                    name: post.authorName,
                    location: _postLocation(post),
                    time: _timeAgo(post.createdAt),
                    role: post.authorRole,
                    image: post.createdBy?['image']?.toString(),
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: _muted,
                    size: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'delete') {
                      onDelete?.call();
                    } else if (value == 'report') {
                      _showReportDialog(context);
                    } else if (value == 'moderate') {
                      _showModerateDialog(context);
                    }
                  },
                  itemBuilder: (context) => [
                    if (isOwner || isAdmin)
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFEF4444),
                              size: 18,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Delete Post',
                              style: TextStyle(color: Color(0xFFEF4444)),
                            ),
                          ],
                        ),
                      ),
                    if (isAdmin)
                      const PopupMenuItem<String>(
                        value: 'moderate',
                        child: Row(
                          children: [
                            Icon(
                              Icons.gavel_rounded,
                              color: Color(0xFF0F8A4B),
                              size: 18,
                            ),
                            SizedBox(width: 10),
                            Text('Moderate Post'),
                          ],
                        ),
                      ),
                    if (!isOwner && !isAdmin)
                      const PopupMenuItem<String>(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(
                              Icons.flag_outlined,
                              color: Color(0xFFF59E0B),
                              size: 18,
                            ),
                            SizedBox(width: 10),
                            Text('Report Post'),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (post.category != null && post.category!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _CategoryBadge(category: post.category!),
            ],
            const SizedBox(height: 10),
            Text(
              _cleanContent(post.content),
              style: const TextStyle(
                color: _text,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            _PostImageGrid(
              images: post.images.isNotEmpty
                  ? post.images
                  : (post.image == null ? const [] : [post.image!]),
            ),
            if (_postLocation(post).isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: _secondary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _postLocation(post),
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 22, color: _line),
            _SocialActions(
              postId: post.id,
              likes: post.likes,
              comments: post.commentCount,
              isLiked: post.isLiked,
              onLike: onLike,
              onComment: onComment,
              onShare: () {
                Share.share(
                  '${_cleanContent(post.content)}\n\nShared via NTK App',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PollCard extends StatelessWidget {
  const _PollCard({
    super.key,
    required this.poll,
    required this.onTap,
    required this.onVote,
    this.onLike,
    this.onComment,
  });

  final PollModel poll;
  final VoidCallback onTap;
  final ValueChanged<int> onVote;
  final VoidCallback? onLike;
  final VoidCallback? onComment;

  @override
  Widget build(BuildContext context) {
    final total = poll.votesCount == 0
        ? poll.options.fold<int>(0, (sum, option) => sum + option.votesCount)
        : poll.votesCount;
    final hasVoted = poll.userVoteOptionId != null;

    bool isExpired = false;
    if (poll.expiresAt != null && poll.expiresAt!.isNotEmpty) {
      try {
        final parsed = DateHelper.parseUtcToLocal(poll.expiresAt!);
        isExpired = parsed.isBefore(DateTime.now());
      } catch (_) {}
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: _Card(
        margin: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AuthorLine(
              name: poll.createdBy?['name']?.toString() ?? 'Community Poll',
              location: poll.location?['name']?.toString() ?? '',
              time: _timeAgo(poll.createdAt),
              role: poll.createdBy?['role']?.toString(),
              category: isExpired ? 'Expired' : (hasVoted ? 'Voted' : 'Active'),
              image: poll.createdBy?['image']?.toString(),
            ),
            const SizedBox(height: 14),
            Text(
              poll.question,
              style: const TextStyle(
                color: _text,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            ...poll.options.map((option) {
              final pct = total == 0 ? 0.0 : option.votesCount / total;
              if (hasVoted || isExpired) {
                return _ResultBar(
                  label: option.text,
                  percent: pct,
                  votes: option.votesCount,
                  highlighted: poll.userVoteOptionId == option.id,
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: OutlinedButton(
                  onPressed: () => onVote(option.id),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    minimumSize: const Size(double.infinity, 44),
                    side: const BorderSide(color: _line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(option.text),
                ),
              );
            }),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '$total votes',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  _remainingTime(poll.expiresAt),
                  style: const TextStyle(
                    color: _secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const Divider(height: 22, color: _line),
            _SocialActions(
              postId: poll.id,
              likes: poll.likes,
              comments: poll.commentCount,
              isLiked: poll.isLiked,
              onLike: onLike ?? () {},
              onComment: onComment ?? () {},
              onShare: () {
                Share.share('${poll.question}\n\nShared via NTK App');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.margin = EdgeInsets.zero});

  final Widget child;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AuthorLine extends StatelessWidget {
  const _AuthorLine({
    required this.name,
    required this.location,
    required this.time,
    this.category,
    this.role,
    this.image,
  });

  final String name;
  final String location;
  final String time;
  final String? category;
  final String? role;
  final String? image;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: const Color(0xFFEAF6EF),
          child: ClipOval(
            child: SizedBox(
              width: 38,
              height: 38,
              child: image != null && image!.trim().isNotEmpty
                  ? (image!.startsWith('http://') ||
                            image!.startsWith('https://')
                        ? Image.network(
                            image!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                name.isEmpty
                                    ? 'C'
                                    : name.characters.first.toUpperCase(),
                                style: const TextStyle(
                                  color: _primary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          )
                        : AsyncBase64Image(
                            base64String: image!.contains('base64,')
                                ? image!.substring(
                                    image!.indexOf('base64,') + 7,
                                  )
                                : image!,
                            fit: BoxFit.cover,
                            placeholderBuilder: (_) => Center(
                              child: Text(
                                name.isEmpty
                                    ? 'C'
                                    : name.characters.first.toUpperCase(),
                                style: const TextStyle(
                                  color: _primary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                name.isEmpty
                                    ? 'C'
                                    : name.characters.first.toUpperCase(),
                                style: const TextStyle(
                                  color: _primary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ))
                  : Center(
                      child: Text(
                        name.isEmpty
                            ? 'C'
                            : name.characters.first.toUpperCase(),
                        style: const TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (role != null && role!.trim().isNotEmpty && role != 'MEMBER' && role != 'USER') ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        role!.replaceAll('_', ' '),
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  if (location.isNotEmpty) ...[
                    const Icon(
                      Icons.location_on_rounded,
                      color: _secondary,
                      size: 13,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                    ),
                  ],
                  if (time.isNotEmpty)
                    Text(
                      location.isNotEmpty ? '  -  $time' : time,
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (category != null) _TinyBadge(label: category!),
      ],
    );
  }
}

class _SocialActions extends StatelessWidget {
  const _SocialActions({
    required this.postId,
    required this.likes,
    required this.comments,
    this.isLiked = false,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });

  final int postId;
  final int likes;
  final int comments;
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _AnimatedLikeButton(
          postId: postId,
          initialLikes: likes,
          initialIsLiked: isLiked,
          onLike: onLike,
        ),
        const SizedBox(width: 18),
        _InlineAction(
          icon: Icons.chat_bubble_outline_rounded,
          label: '$comments',
          onTap: onComment,
        ),
        const Spacer(),
        _InlineAction(
          icon: Icons.share_outlined,
          label: 'Share',
          onTap: onShare,
        ),
      ],
    );
  }
}

class _AnimatedLikeButton extends StatefulWidget {
  const _AnimatedLikeButton({
    required this.postId,
    required this.initialLikes,
    required this.initialIsLiked,
    required this.onLike,
  });

  final int postId;
  final int initialLikes;
  final bool initialIsLiked;
  final VoidCallback onLike;

  @override
  State<_AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<_AnimatedLikeButton>
    with SingleTickerProviderStateMixin {
  late bool _isLiked;
  late int _likes;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initialIsLiked;
    _likes = widget.initialLikes;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.35,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.35,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant _AnimatedLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postId != widget.postId) {
      _isLiked = widget.initialIsLiked;
      _likes = widget.initialLikes;
    } else {
      // If parent rebuilds but post is same, we ONLY sync if the server
      // updated the like count. We don't overwrite our optimistic state
      // if it's currently running an animation.
      if (!_controller.isAnimating) {
        _isLiked = widget.initialIsLiked;
        _likes = widget.initialLikes;
      }
    }
  }

  void _handleLike() {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likes += 1;
        _controller.forward(from: 0.0);
      } else {
        _likes -= 1;
        if (_likes < 0) _likes = 0;
      }
    });
    // Trigger bloc action in background
    widget.onLike();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _handleLike,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(
                _isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: _isLiked ? const Color(0xFFE91E63) : _muted,
                size: 22,
              ),
            ),
            const SizedBox(width: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, -0.2),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Text(
                '$_likes',
                key: ValueKey<int>(_likes),
                style: TextStyle(
                  color: _isLiked ? const Color(0xFFE91E63) : _text,
                  fontSize: 14,
                  fontWeight: _isLiked ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineAction extends StatelessWidget {
  const _InlineAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? _muted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: effectiveColor, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: effectiveColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostImageGrid extends StatelessWidget {
  const _PostImageGrid({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();
    final shown = images.take(4).toList();
    if (shown.length == 1) {
      // Single image: fixed height to prevent scroll layout shifts
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: 280,
          color: const Color(0xFFF1F5F2),
          child: _ImageSource(value: shown.first, fit: BoxFit.contain),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: shown.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (_, index) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _ImageSource(
          value: shown[index],
          fit: BoxFit.contain,
          backgroundColor: const Color(0xFFF1F5F2),
        ),
      ),
    );
  }
}

class _ImageSource extends StatelessWidget {
  const _ImageSource({
    required this.value,
    this.fit = BoxFit.contain,
    this.backgroundColor,
  });

  final String value;
  final BoxFit fit;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Colors.transparent;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return ColoredBox(
        color: bg,
        child: Image.network(
          value,
          fit: fit,
          width: double.infinity,
          errorBuilder: (_, __, ___) => _SampleImage(seed: value),
        ),
      );
    }
    if (value.startsWith('sample')) return _SampleImage(seed: value);
    try {
      final clean = value.contains('base64,')
          ? value.substring(value.indexOf('base64,') + 7)
          : value;
      return ColoredBox(
        color: bg,
        child: AsyncBase64Image(
          base64String: clean,
          fit: fit,
          width: double.infinity,
          placeholderBuilder: (_) => _SampleImage(seed: value),
          errorBuilder: (_, __, ___) => _SampleImage(seed: value),
        ),
      );
    } catch (_) {
      return _SampleImage(seed: value);
    }
  }
}

class _SampleImage extends StatelessWidget {
  const _SampleImage({required this.seed});

  final String seed;

  @override
  Widget build(BuildContext context) {
    final isRoad = seed.contains('road') || seed.contains('pothole');
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isRoad
              ? const [Color(0xFF374151), Color(0xFF9CA3AF)]
              : const [Color(0xFF0F172A), Color(0xFF1E5F43)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          isRoad ? Icons.construction_rounded : Icons.lightbulb_outline_rounded,
          color: Colors.white.withOpacity(0.86),
          size: 42,
        ),
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({required this.community, required this.isJoined});

  final CommunityModel community;
  final bool isJoined;

  void _handleJoin(BuildContext context) {
    if (community.privacyType == 'SECRET') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.inviteOnly)),
      );
      return;
    }
    if (community.privacyType == 'PRIVATE') {
      final inputController = TextEditingController();
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            AppLocalizations.of(context)!.requestToJoin,
            style: const TextStyle(color: _primary, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.provideReason),
              const SizedBox(height: 12),
              TextField(
                controller: inputController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.yourReason,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              onPressed: () {
                final text = inputController.text.trim();
                Navigator.pop(dialogContext);
                context.read<CommunityBloc>().add(
                  JoinCommunity(communityId: community.id, reason: text),
                );
              },
              child: Text(
                AppLocalizations.of(context)!.sendRequest,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    } else {
      context.read<CommunityBloc>().add(
        JoinCommunity(communityId: community.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationName = community.location?['name'] as String?;
    final privacy = community.privacyType.toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          onTap: null,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEEF2F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Card Body ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar / API Image
                              Container(
                                height: 48,
                                width: 48,
                                decoration: BoxDecoration(
                                  color: _avatarTint(community.name),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: community.image != null && community.image!.isNotEmpty
                                      ? Image.network(
                                          community.image!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                            _groupIcon(community.name),
                                            color: _primary,
                                            size: 24,
                                          ),
                                        )
                                      : Icon(
                                          _groupIcon(community.name),
                                          color: _primary,
                                          size: 24,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Name + Meta
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(right: 60), // Space for privacy badge
                                      child: Text(
                                        community.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: _text,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.people_alt_outlined,
                                      size: 12,
                                      color: _muted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${community.memberCount} ${AppLocalizations.of(context)!.members}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: _muted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (locationName != null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 3,
                                        height: 3,
                                        decoration: const BoxDecoration(
                                          color: _muted,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 12,
                                        color: _muted,
                                      ),
                                      const SizedBox(width: 2),
                                      Flexible(
                                        child: Text(
                                          locationName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: _muted,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (isJoined) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF004D2A), size: 12),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context)!.joinedStatus,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF004D2A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Description
                      if (community.description != null &&
                          community.description!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          community.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _muted,
                            height: 1.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      // ── Action Buttons ────────────────────────────
                      Row(
                        children: [
                          if (isJoined) ...[
                            Expanded(
                              child: _CardActionButton(
                                label: AppLocalizations.of(context)!.openAction,
                                icon: Icons.arrow_forward_rounded,
                                filled: true,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CommunityDetailsScreen(
                                      community: community,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            Expanded(
                              child: _CardActionButton(
                                label: privacy == 'SECRET'
                                    ? AppLocalizations.of(context)!.inviteOnly
                                    : privacy == 'PRIVATE'
                                    ? AppLocalizations.of(context)!.requestToJoin
                                    : AppLocalizations.of(context)!.joinGroup,
                                icon: privacy == 'SECRET'
                                    ? Icons.lock_rounded
                                    : Icons.add_rounded,
                                filled: privacy != 'SECRET',
                                onTap: () => _handleJoin(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  // Privacy badge positioned top-right
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _PrivacyBadge(privacy: privacy),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CommunityBanner extends StatelessWidget {
  const _CommunityBanner({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final hue = name.codeUnits.fold(0, (a, b) => a + b) % 60;
    final color1 = HSLColor.fromAHSL(1, 150.0 + hue, 0.55, 0.22).toColor();
    final color2 = HSLColor.fromAHSL(1, 160.0 + hue, 0.40, 0.35).toColor();
    return Container(
      height: 110,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative pattern
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            left: -10,
            bottom: -15,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Center(
            child: Icon(
              _groupIcon(name),
              color: Colors.white.withOpacity(0.35),
              size: 52,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyBadge extends StatelessWidget {
  const _PrivacyBadge({required this.privacy});
  final String privacy;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    switch (privacy) {
      case 'PRIVATE':
        bg = const Color(0xFFFFF4E5);
        fg = const Color(0xFFE67E00);
        icon = Icons.lock_outline_rounded;
        break;
      case 'SECRET':
        bg = const Color(0xFFEEF2FF);
        fg = const Color(0xFF4F46E5);
        icon = Icons.shield_outlined;
        break;
      default: // PUBLIC
        bg = const Color(0xFFEAF6EF);
        fg = const Color(0xFF1A7F45);
        icon = Icons.public_rounded;
    }
    String privacyText = privacy == 'PRIVATE'
        ? AppLocalizations.of(context)!.privacyPrivate
        : privacy == 'SECRET'
            ? AppLocalizations.of(context)!.privacySecret
            : AppLocalizations.of(context)!.privacyPublic;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            privacyText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: fg,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = true,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return SizedBox(
        height: 40,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 16),
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _muted,
          side: const BorderSide(color: Color(0xFFD0D5DD)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _GroupFilterChip extends StatelessWidget {
  const _GroupFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? _primary : const Color(0xFFF3F5F4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : const Color(0xFF4B5563),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupsLoadingSkeleton extends StatefulWidget {
  const _GroupsLoadingSkeleton();
  @override
  State<_GroupsLoadingSkeleton> createState() => _GroupsLoadingSkeletonState();
}

class _GroupsLoadingSkeletonState extends State<_GroupsLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.4,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: 4,
          itemBuilder: (_, i) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEEF2F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(_anim.value * 0.3),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(_anim.value * 0.3),
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 140,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(
                                    _anim.value * 0.3,
                                  ),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 90,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(
                                    _anim.value * 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(_anim.value * 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _line),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (action != null)
          Text(
            action!,
            style: const TextStyle(
              color: _secondary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
      ],
    );
  }
}

class _CreatePollPrompt extends StatelessWidget {
  const _CreatePollPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFEAF6EF),
            child: Icon(Icons.poll_outlined, color: _primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.askYourCommunity,
                  style: const TextStyle(color: _text, fontWeight: FontWeight.w900),
                ),
                Text(
                  AppLocalizations.of(context)!.createPollDescription,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: onTap,
            icon: const Icon(Icons.add_rounded),
            style: IconButton.styleFrom(
              backgroundColor: _secondary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: _primary,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _text,
        fontWeight: FontWeight.w900,
        fontSize: 13,
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = label == 'Complaint'
        ? const Color(0xFFE53935)
        : label == 'Suggestion'
        ? const Color(0xFFE59F24)
        : label == 'Information'
        ? const Color(0xFF2F6DE0)
        : _primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: (MediaQuery.of(context).size.width - 48) / 2,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? color : _line,
            width: active ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePreviewGrid extends StatelessWidget {
  const _ImagePreviewGrid({
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  final List<File> images;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: images.length + 1,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (_, index) {
        if (index == images.length) {
          return InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _line),
              ),
              child: const Icon(Icons.add_rounded, color: _primary, size: 30),
            ),
          );
        }
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                images[index],
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: InkWell(
                onTap: () => onRemove(index),
                child: const CircleAvatar(
                  radius: 11,
                  backgroundColor: Colors.black54,
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: _secondary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              location,
              style: const TextStyle(
                color: _text,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _muted),
        ],
      ),
    );
  }
}

class _DurationRadios extends StatelessWidget {
  const _DurationRadios({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [1, 3, 7].map((days) {
        return RadioListTile<int>(
          value: days,
          groupValue: value,
          onChanged: (v) => onChanged(v ?? days),
          activeColor: _secondary,
          contentPadding: EdgeInsets.zero,
          title: Text(
            '$days Day${days == 1 ? '' : 's'}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      }).toList(),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: _secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class _ResultBar extends StatelessWidget {
  const _ResultBar({
    required this.label,
    required this.percent,
    required this.votes,
    this.highlighted = false,
  });

  final String label;
  final double percent;
  final int votes;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              if (highlighted)
                const Icon(
                  Icons.check_circle_rounded,
                  color: _primary,
                  size: 15,
                ),
              if (highlighted) const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: highlighted ? _primary : _text,
                    fontSize: 13,
                    fontWeight: highlighted ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(percent * 100).round()}% ($votes votes)',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: percent.clamp(0, 1),
              minHeight: 7,
              color: highlighted ? _primary : _secondary,
              backgroundColor: const Color(0xFFE9ECEA),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: _text,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.onLike,
    required this.onReply,
    this.isReply = false,
  });

  final CommentModel comment;
  final ValueChanged<CommentModel> onLike;
  final ValueChanged<CommentModel> onReply;
  final bool isReply;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isReply) ...[
              const Padding(
                padding: EdgeInsets.only(left: 8, right: 8, top: 12),
                child: Text(
                  '↳',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _muted,
                  ),
                ),
              ),
            ],
            Expanded(
              child: _Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AuthorLine(
                      name: comment.authorName,
                      location: '',
                      time: _timeAgo(comment.createdAt),
                      role: comment.authorRole,
                      image: comment.createdBy?['image']?.toString(),
                    ),
                    const SizedBox(height: 8),
                    _ExpandableText(text: comment.content),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _InlineAction(
                          icon: comment.isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          label: '${comment.likesCount}',
                          color: comment.isLiked
                              ? const Color(0xFFE91E63)
                              : _muted,
                          onTap: () => onLike(comment),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: () => onReply(comment),
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              'Reply',
                              style: TextStyle(
                                color: _secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (comment.replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              children: comment.replies
                  .map(
                    (reply) => _CommentTile(
                      comment: reply,
                      onLike: onLike,
                      onReply: onReply,
                      isReply: true,
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _ExpandableText extends StatefulWidget {
  const _ExpandableText({required this.text});
  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, size) {
        final span = TextSpan(
          text: widget.text,
          style: const TextStyle(
            color: _text,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        );
        final tp = TextPainter(
          maxLines: 4,
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
          text: span,
        );
        tp.layout(maxWidth: size.maxWidth);

        if (tp.didExceedMaxLines) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                span,
                maxLines: _expanded ? null : 4,
                overflow: _expanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? 'Read less' : 'Read more',
                  style: const TextStyle(
                    color: _secondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          );
        } else {
          return Text.rich(span);
        }
      },
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.onSend,
    this.focusNode,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: autofocus,
                decoration: const InputDecoration(
                  hintText: 'Write a comment...',
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: onSend,
              icon: const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(
                backgroundColor: _secondary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (category) {
      case 'Complaint':
        color = const Color(0xFFE53935);
        icon = Icons.warning_amber_rounded;
        break;
      case 'Suggestion':
        color = const Color(0xFFE59F24);
        icon = Icons.lightbulb_outline;
        break;
      case 'Information':
        color = const Color(0xFF2F6DE0);
        icon = Icons.info_outline_rounded;
        break;
      case 'Discussion':
        color = const Color(0xFF004D2A); // _primary
        icon = Icons.forum_outlined;
        break;
      case 'General':
      default:
        color = const Color(0xFF0F8A4B); // _secondary
        icon = Icons.public_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            category,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6EF),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _secondary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  const _JoinButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 36),
          foregroundColor: _primary,
          side: const BorderSide(color: Color(0xFFB8C9C1)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Join',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _CommunityOption extends StatelessWidget {
  const _CommunityOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFEAF6EF),
        child: Icon(icon, color: _primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: _secondary)
          : null,
    );
  }
}

void _noop() {}

IconData _groupIcon(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('doctor')) return Icons.medical_services_outlined;
  if (lower.contains('farmer')) return Icons.agriculture_outlined;
  if (lower.contains('teacher')) return Icons.menu_book_outlined;
  if (lower.contains('lawyer')) return Icons.balance_outlined;
  if (lower.contains('women')) return Icons.diversity_3_outlined;
  if (lower.contains('police')) return Icons.local_police_outlined;
  if (lower.contains('business')) return Icons.business_center_outlined;
  return Icons.groups_rounded;
}

Color _avatarTint(String name) {
  final colors = [
    const Color(0xFFDFF7E8),
    const Color(0xFFFFEAC2),
    const Color(0xFFEDE4FF),
    const Color(0xFFDDF0FF),
  ];
  return colors[name.length % colors.length];
}

String _postLocation(PostModel post) {
  return post.location?['name']?.toString() ?? post.community?.name ?? '';
}

String _cleanContent(String content) {
  String clean = content.trim();
  final categories = [
    'Discussion',
    'Suggestion',
    'Complaint',
    'Information',
    'General Update',
    'Community Post',
  ];
  
  for (final category in categories) {
    if (clean.startsWith('**$category**')) {
      clean = clean.substring(category.length + 4).trim();
      break;
    } else if (clean.startsWith(category)) {
      clean = clean.substring(category.length).trim();
      break;
    }
  }
  
  // Additional safety to remove leading empty lines if any
  return clean.trim();
}

String _categoryFromContent(String content) {
  final first = content.split('\n\n').first.trim();
  if (['Discussion', 'Suggestion', 'Complaint', 'Information'].contains(first))
    return first;
  final lower = content.toLowerCase();
  if (lower.contains('not working') || lower.contains('complaint'))
    return 'Complaint';
  if (lower.contains('suggest')) return 'Suggestion';
  return 'Information';
}

DateTime _parseDateTime(String value) {
  return DateHelper.parseUtcToLocal(value);
}

String _timeAgo(String? value) {
  if (value == null || value.isEmpty) return 'Just now';
  try {
    final date = _parseDateTime(value);
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  } catch (_) {
    return 'Just now';
  }
}

String _remainingTime(String? value) {
  if (value == null || value.isEmpty) return '2 Days';
  try {
    final diff = DateHelper.parseUtcToLocal(value).difference(DateTime.now());
    if (diff.isNegative) return 'Closed';
    if (diff.inDays > 0) return '${diff.inDays} Days';
    if (diff.inHours > 0) return '${diff.inHours} Hours';
    return '${diff.inMinutes} Min';
  } catch (_) {
    return '2 Days';
  }
}

final _sampleCommunities = [
  CommunityModel(
    id: 1,
    name: 'Doctors - Nagapattinam',
    description: 'Medical support community',
    memberCount: 325,
    createdAt: '',
  ),
  CommunityModel(
    id: 2,
    name: 'Farmers - Nagapattinam',
    description: 'Agriculture updates',
    memberCount: 412,
    createdAt: '',
  ),
  CommunityModel(
    id: 3,
    name: 'Teachers - Nagapattinam',
    description: 'Education coordination',
    memberCount: 276,
    createdAt: '',
  ),
  CommunityModel(
    id: 4,
    name: 'Lawyers - Nagapattinam',
    description: 'Legal support',
    memberCount: 189,
    createdAt: '',
  ),
  CommunityModel(
    id: 5,
    name: 'Youth Wing - Nagapattinam',
    description: 'Volunteer team',
    memberCount: 358,
    createdAt: '',
  ),
  CommunityModel(
    id: 6,
    name: 'Business Owners - Nagapattinam',
    description: 'Local business group',
    memberCount: 156,
    createdAt: '',
  ),
  CommunityModel(
    id: 7,
    name: "Women's Forum - Nagapattinam",
    description: 'Community forum',
    memberCount: 198,
    createdAt: '',
  ),
  CommunityModel(
    id: 8,
    name: 'Police Support - Nagapattinam',
    description: 'Safety updates',
    memberCount: 221,
    createdAt: '',
  ),
];

final _samplePosts = [
  PostModel(
    id: -1,
    title: 'Street light issue',
    content:
        'Street light not working near Pushpavanam Bus Stop for 3 days. Please fix it.',
    category: 'Complaint',
    images: const ['sample-light', 'sample-pole'],
    likes: 28,
    authorName: 'Kumar M',
    authorRole: 'Member',
    commentCount: 6,
    createdAt: DateTime.now()
        .subtract(const Duration(minutes: 20))
        .toIso8601String(),
    location: const {'name': 'Pushpavanam Street'},
  ),
  PostModel(
    id: -2,
    title: 'Water supply update',
    content:
        'Water supply will be closed tomorrow from 10 AM to 4 PM for maintenance.',
    category: 'Information',
    images: const [],
    likes: 54,
    authorName: 'Selvam R',
    authorRole: 'Ward Coordinator',
    commentCount: 11,
    createdAt: DateTime.now()
        .subtract(const Duration(hours: 1))
        .toIso8601String(),
    location: const {'name': 'Vedaranyam'},
  ),
];

final _sampleComments = [
  CommentModel(
    id: -1,
    content: "Yes, it is not working. I also noticed.",
    authorName: 'Ravi S',
    authorRole: 'Member',
    createdAt: DateTime.now()
        .subtract(const Duration(minutes: 15))
        .toIso8601String(),
  ),
  CommentModel(
    id: -2,
    content: 'I have informed EB office. They will check and update.',
    authorName: 'Selvi P',
    authorRole: 'Area Coordinator',
    createdAt: DateTime.now()
        .subtract(const Duration(minutes: 10))
        .toIso8601String(),
  ),
];

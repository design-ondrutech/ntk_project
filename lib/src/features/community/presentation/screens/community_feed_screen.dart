import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/core/widgets/ntk_snackbar.dart';
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
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, initialIndex: 1, vsync: this);
    _tabController.addListener(() => setState(() {}));
    context.read<CommunityBloc>().add(const FetchCommunities());
    _fetchFeed();
    _fetchPolls();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    return globalLoc?.name ?? auth?.locationName ?? 'Nagapattinam';
  }

  void _fetchFeed() {
    if (_selectedCommunity != null) {
      context.read<CommunityBloc>().add(
        FetchCommunityPosts(_selectedCommunity!.id),
      );
      return;
    }
    context.read<CommunityBloc>().add(FetchCommunityFeed(locationId: _locationId));
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
      MaterialPageRoute(builder: (_) => CommunityChatScreen(community: community)),
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
              NTKSnackbar.showError(context, message: state.error!);
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
      ],
      child: Scaffold(
        backgroundColor: _bg,
        appBar: NTKAppBar(
          title: _selectedCommunity?.name ?? 'Community',
          subtitle: _locationName,
          actions: [
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
                  _fetchFeed();
                  _fetchPolls();
                },
              ),
              ...communities.take(8).map(
                    (community) => _CommunityOption(
                      icon: _groupIcon(community.name),
                      title: community.name,
                      subtitle: '${community.memberCount} members',
                      selected: _selectedCommunity?.id == community.id,
                      onTap: () {
                        setState(() => _selectedCommunity = community);
                        Navigator.pop(context);
                        _fetchFeed();
                        _fetchPolls();
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
        builder: (context, state) {
          final source = _selectedCommunity == null ? state.feedPosts : state.posts;
          final posts = source.isEmpty ? _samplePosts : source;
          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            children: [
              _CreatePostCard(
                onPhoto: () => _openCreatePost('Information'),
                onVideo: () => _openCreatePost('Information'),
                onPoll: _openCreatePoll,
                onPost: () => _openCreatePost('Discussion'),
              ),
              const SizedBox(height: 14),
              if (state.isFeedLoading || state.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CupertinoActivityIndicator()),
                ),
              ...posts.map(
                (post) => _PostCard(
                  post: post,
                  onLike: () => context.read<CommunityBloc>().add(LikePost(post.id)),
                  onComment: () => _openPostDetails(post),
                  onOpen: () => _openPostDetails(post),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGroupsTab() {
    return BlocBuilder<CommunityBloc, CommunityState>(
      builder: (context, state) {
        if (state.isLoading && state.communities.isEmpty) {
          return const Center(child: CupertinoActivityIndicator());
        }

        final communities = state.communities.isEmpty
            ? _sampleCommunities
            : state.communities;

        if (communities.isEmpty) {
          return const Center(child: Text('No groups found.', style: TextStyle(color: _muted)));
        }

        final yourGroups = communities.take(3).toList();
        final moreGroups = communities.skip(3).take(8).toList();

        return RefreshIndicator(
          color: _primary,
          onRefresh: () async => context.read<CommunityBloc>().add(const FetchCommunities()),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            children: [
              _SearchField(hint: 'Search groups'),
              const SizedBox(height: 18),
              if (yourGroups.isNotEmpty) ...[
                _SectionHeader(title: 'Your Groups', action: 'View All'),
                const SizedBox(height: 10),
                ...yourGroups.map(
                  (community) => _GroupRow(
                    community: community,
                    joined: true,
                    onTap: () => _openChat(community),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              if (moreGroups.isNotEmpty) ...[
                const _SectionHeader(title: 'More Groups'),
                const SizedBox(height: 10),
                ...moreGroups.map(
                  (community) => _GroupRow(
                    community: community,
                    joined: false,
                    onTap: () => _openChat(community),
                    onJoin: () {
                      final user = context.read<AuthBloc>().state.loginData;
                      if (user != null) {
                        context.read<CommunityBloc>().add(
                          JoinCommunity(communityId: community.id, memberId: user.id),
                        );
                      }
                    },
                  ),
                ),
              ],
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
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            children: [
              _CreatePollPrompt(onTap: _openCreatePoll),
              const SizedBox(height: 14),
              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CupertinoActivityIndicator()),
                )
              else if (state.polls.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.poll_outlined, size: 56, color: Color(0xFFCBD5E1)),
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
                          'Be the first to create a poll for your community',
                          style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...state.polls.map(
                  (poll) => _PollCard(
                    poll: poll,
                    onTap: () => _openPollDetails(poll),
                    onVote: (optionId) => context.read<CommunityPollsBloc>().add(
                      VoteInPollEvent(pollId: poll.id, optionId: optionId),
                    ),
                  ),
                ),
            ],
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

  void _openPostDetails(PostModel post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _PostDetailsScreen(post: post)),
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
  late String _category = widget.initialCategory;
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
    final authState = context.read<AuthBloc>().state;
    final role = authState.loginData?.role ?? '';
    final locationId = authState.loginData?.locationId;

    if (role == 'SUB_ADMIN' && locationId != null) {
      _loadStreetsForSubAdmin(locationId);
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
      final finalLocation =
          _selectedStreet ??
          _selectedArea ??
          _selectedConstituency ??
          _selectedDistrict;
      if (finalLocation == null) {
        NTKSnackbar.showError(
          context,
          message: 'Please select a target location',
        );
        return;
      }
      eventLocationId = finalLocation.id;
    }

    final auth = authState.loginData;
    final images = <String>[];
    for (final image in _images) {
      images.add(base64Encode(await image.readAsBytes()));
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
    required ValueChanged<T?> onChanged,
    required String Function(T) itemLabel,
    required String hintText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            CupertinoIcons.chevron_down,
            size: 16,
            color: Color(0xFF6B7280),
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
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
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
    final remaining = 500 - _content.text.length;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF004D2A), // Dark Green
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Create Post',
          style: TextStyle(
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
                  const _FormLabel('Select Category'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _CategoryChip(label: 'Discussion', icon: Icons.forum_outlined, active: _category == 'Discussion', onTap: () => setState(() => _category = 'Discussion')),
                      _CategoryChip(label: 'Suggestion', icon: Icons.lightbulb_outline, active: _category == 'Suggestion', onTap: () => setState(() => _category = 'Suggestion')),
                      _CategoryChip(label: 'Complaint', icon: Icons.warning_amber_rounded, active: _category == 'Complaint', onTap: () => setState(() => _category = 'Complaint')),
                      _CategoryChip(label: 'Information', icon: Icons.info_outline_rounded, active: _category == 'Information', onTap: () => setState(() => _category = 'Information')),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const _FormLabel('What is happening?'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _content,
                    maxLength: 500,
                    minLines: 6,
                    maxLines: 10,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Write your post...',
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
                  const _FormLabel('Add Photos / Videos'),
                  const SizedBox(height: 10),
                  _ImagePreviewGrid(images: _images, onAdd: _pickImages, onRemove: (index) => setState(() => _images.removeAt(index))),
                  const SizedBox(height: 20),
                  const _FormLabel('Location'),
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
                            const _FormLabel('Street'),
                            const SizedBox(height: 6),
                            _loadingStreets
                                ? _buildLoadingField('Street')
                                : _buildDropdownField<LocationModel>(
                                    items: _streets,
                                    value: _selectedStreet,
                                    onChanged: (val) =>
                                        setState(() => _selectedStreet = val),
                                    itemLabel: (item) => item.name,
                                    hintText: 'Select Street (Optional)',
                                  ),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. State
                          const _FormLabel('State'),
                          const SizedBox(height: 6),
                          _buildDropdownField<String>(
                            items: _states,
                            value: _selectedState,
                            onChanged: (val) =>
                                setState(() => _selectedState = val),
                            itemLabel: (item) => item,
                            hintText: 'Select State',
                          ),
                          const SizedBox(height: 16),

                          // 2. District
                          const _FormLabel('District *'),
                          const SizedBox(height: 6),
                          _loadingDistricts
                              ? _buildLoadingField('District')
                              : _buildDropdownField<LocationModel>(
                                  items: _districts,
                                  value: _selectedDistrict,
                                  onChanged: _onDistrictChanged,
                                  itemLabel: (item) => item.name,
                                  hintText: 'Select District',
                                ),
                          const SizedBox(height: 16),

                          // 3. Constituency (Taluk)
                          const _FormLabel('Constituency (Taluk)'),
                          const SizedBox(height: 6),
                          _loadingConstituencies
                              ? _buildLoadingField('Constituency')
                              : _selectedDistrict == null
                              ? _buildDisabledField('Select District first')
                              : _buildDropdownField<LocationModel>(
                                  items: _constituencies,
                                  value: _selectedConstituency,
                                  onChanged: _onConstituencyChanged,
                                  itemLabel: (item) => item.name,
                                  hintText: 'Select Constituency',
                                ),
                          const SizedBox(height: 16),

                          // 4. Area (Town)
                          const _FormLabel('Area (Town)'),
                          const SizedBox(height: 6),
                          _loadingAreas
                              ? _buildLoadingField('Area')
                              : _selectedConstituency == null
                              ? _buildDisabledField('Select Constituency first')
                              : _buildDropdownField<LocationModel>(
                                  items: _areas,
                                  value: _selectedArea,
                                  onChanged: _onAreaChanged,
                                  itemLabel: (item) => item.name,
                                  hintText: 'Select Area',
                                ),
                          const SizedBox(height: 16),

                          // 5. Street
                          const _FormLabel('Street'),
                          const SizedBox(height: 6),
                          _loadingStreets
                              ? _buildLoadingField('Street')
                              : _selectedArea == null
                              ? _buildDisabledField('Select Area first')
                              : _buildDropdownField<LocationModel>(
                                  items: _streets,
                                  value: _selectedStreet,
                                  onChanged: (val) =>
                                      setState(() => _selectedStreet = val),
                                  itemLabel: (item) => item.name,
                                  hintText: 'Select Street',
                                ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            _BottomAction(label: 'Post', onTap: _publish),
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
    final authState = context.read<AuthBloc>().state;
    final role = authState.loginData?.role ?? '';
    final locationId = authState.loginData?.locationId;

    if (role == 'SUB_ADMIN' && locationId != null) {
      _loadStreetsForSubAdmin(locationId);
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

  void _createPoll() {
    final question = _question.text.trim();
    final options = _options.map((x) => x.text.trim()).where((x) => x.isNotEmpty).toList();
    if (question.isEmpty || options.length < 2) {
      NTKSnackbar.showError(context, message: 'Add a question and at least two options');
      return;
    }

    final authState = context.read<AuthBloc>().state;
    final userRole = authState.loginData?.role ?? '';

    int eventLocationId;
    if (userRole == 'SUB_ADMIN') {
      eventLocationId = _selectedStreet?.id ?? widget.locationId;
    } else {
      final finalLocation =
          _selectedStreet ??
          _selectedArea ??
          _selectedConstituency ??
          _selectedDistrict;
      if (finalLocation == null) {
        NTKSnackbar.showError(
          context,
          message: 'Please select a target location',
        );
        return;
      }
      eventLocationId = finalLocation.id;
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
    required ValueChanged<T?> onChanged,
    required String Function(T) itemLabel,
    required String hintText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            CupertinoIcons.chevron_down,
            size: 16,
            color: Color(0xFF6B7280),
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
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
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
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF004D2A), // Dark Green
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Create Poll',
          style: TextStyle(
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
                  const _FormLabel('Poll Question'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _question,
                    maxLength: 100,
                    minLines: 3,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Enter your question...',
                      counterText: '0/100',
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _FormLabel('Options'),
                  const SizedBox(height: 10),
                  ...List.generate(_options.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _options[index],
                              decoration: InputDecoration(hintText: 'Option ${index + 1}'),
                            ),
                          ),
                          if (_options.length > 2)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded),
                              onPressed: () => setState(() => _options.removeAt(index)),
                            ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: _options.length >= 6
                        ? null
                        : () => setState(() => _options.add(TextEditingController())),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Option'),
                  ),
                  const SizedBox(height: 18),
                  const _FormLabel('Poll Duration'),
                  const SizedBox(height: 8),
                  _DurationRadios(value: _duration, onChanged: (value) => setState(() => _duration = value)),
                  const SizedBox(height: 18),
                  const _FormLabel('Target Location'),
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
                            const _FormLabel('Street'),
                            const SizedBox(height: 6),
                            _loadingStreets
                                ? _buildLoadingField('Street')
                                : _buildDropdownField<LocationModel>(
                                    items: _streets,
                                    value: _selectedStreet,
                                    onChanged: (val) =>
                                        setState(() => _selectedStreet = val),
                                    itemLabel: (item) => item.name,
                                    hintText: 'Select Street (Optional)',
                                  ),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. State
                          const _FormLabel('State'),
                          const SizedBox(height: 6),
                          _buildDropdownField<String>(
                            items: _states,
                            value: _selectedState,
                            onChanged: (val) =>
                                setState(() => _selectedState = val),
                            itemLabel: (item) => item,
                            hintText: 'Select State',
                          ),
                          const SizedBox(height: 16),

                          // 2. District
                          const _FormLabel('District *'),
                          const SizedBox(height: 6),
                          _loadingDistricts
                              ? _buildLoadingField('District')
                              : _buildDropdownField<LocationModel>(
                                  items: _districts,
                                  value: _selectedDistrict,
                                  onChanged: _onDistrictChanged,
                                  itemLabel: (item) => item.name,
                                  hintText: 'Select District',
                                ),
                          const SizedBox(height: 16),

                          // 3. Constituency (Taluk)
                          const _FormLabel('Constituency (Taluk)'),
                          const SizedBox(height: 6),
                          _loadingConstituencies
                              ? _buildLoadingField('Constituency')
                              : _selectedDistrict == null
                              ? _buildDisabledField('Select District first')
                              : _buildDropdownField<LocationModel>(
                                  items: _constituencies,
                                  value: _selectedConstituency,
                                  onChanged: _onConstituencyChanged,
                                  itemLabel: (item) => item.name,
                                  hintText: 'Select Constituency',
                                ),
                          const SizedBox(height: 16),

                          // 4. Area (Town)
                          const _FormLabel('Area (Town)'),
                          const SizedBox(height: 6),
                          _loadingAreas
                              ? _buildLoadingField('Area')
                              : _selectedConstituency == null
                              ? _buildDisabledField('Select Constituency first')
                              : _buildDropdownField<LocationModel>(
                                  items: _areas,
                                  value: _selectedArea,
                                  onChanged: _onAreaChanged,
                                  itemLabel: (item) => item.name,
                                  hintText: 'Select Area',
                                ),
                          const SizedBox(height: 16),

                          // 5. Street
                          const _FormLabel('Street'),
                          const SizedBox(height: 6),
                          _loadingStreets
                              ? _buildLoadingField('Street')
                              : _selectedArea == null
                              ? _buildDisabledField('Select Area first')
                              : _buildDropdownField<LocationModel>(
                                  items: _streets,
                                  value: _selectedStreet,
                                  onChanged: (val) =>
                                      setState(() => _selectedStreet = val),
                                  itemLabel: (item) => item.name,
                                  hintText: 'Select Street',
                                ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            _BottomAction(label: 'Create Poll', onTap: _createPoll),
          ],
        ),
      ),
    );
  }
}

class _PollDetailsScreen extends StatelessWidget {
  const _PollDetailsScreen({required this.poll});

  final PollModel poll;

  @override
  Widget build(BuildContext context) {
    final total = poll.votesCount == 0
        ? poll.options.fold<int>(0, (sum, option) => sum + option.votesCount)
        : poll.votesCount;
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          Container(
            color: _primary,
            child: const SafeArea(
              bottom: false,
              child: SizedBox.shrink(),
            ),
          ),
          const _PageHeader(title: 'Poll Details'),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  _AuthorLine(
                    name: poll.createdBy?['name']?.toString() ?? 'Kumar M',
                    location: poll.location?['name']?.toString() ?? 'Pushpavanam Street',
                    time: _timeAgo(poll.createdAt),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    poll.question,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _text),
                  ),
                  const SizedBox(height: 18),
                  ...poll.options.map((option) {
                    final pct = total == 0 ? 0.0 : option.votesCount / total;
                    return _ResultBar(label: option.text, percent: pct, votes: option.votesCount);
                  }),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: _MetricCard(title: 'Total Votes', value: '$total')),
                      const SizedBox(width: 10),
                      Expanded(child: _MetricCard(title: 'Ends in', value: _remainingTime(poll.expiresAt))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SocialActions(likes: 12, comments: 5, onLike: () {}, onComment: () {}, onShare: () {}),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostDetailsScreen extends StatefulWidget {
  const _PostDetailsScreen({required this.post});

  final PostModel post;

  @override
  State<_PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<_PostDetailsScreen> {
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _addComment() {
    final text = _comment.text.trim();
    if (text.isEmpty) return;
    final auth = context.read<AuthBloc>().state.loginData;
    context.read<CommunityBloc>().add(
      AddComment(
        postId: widget.post.id,
        content: text,
        authorName: auth?.name ?? 'Community Member',
        authorRole: auth?.role ?? 'MEMBER',
      ),
    );
    _comment.clear();
  }

  @override
  Widget build(BuildContext context) {
    final comments = widget.post.comments.isEmpty ? _sampleComments : widget.post.comments;
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
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  _PostCard(post: widget.post, onLike: () => context.read<CommunityBloc>().add(LikePost(widget.post.id)), onComment: () {}, onOpen: () {}),
                  const SizedBox(height: 12),
                  const _SectionHeader(title: 'Comments'),
                  const SizedBox(height: 8),
                  ...comments.map((comment) => _CommentTile(comment: comment)),
                ],
              ),
            ),
            _CommentComposer(controller: _comment, onSend: _addComment),
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
        tabs: const [
          Tab(text: 'Groups'),
          Tab(text: 'Feed'),
          Tab(text: 'Polls'),
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
                    child: Icon(item.$2, color: selected ? Colors.white : item.$3, size: 22),
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
              const CircleAvatar(radius: 16, backgroundColor: Color(0xFFEAF6EF), child: Icon(Icons.person_rounded, color: _primary, size: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: onPost,
                  child: const Text('What is happening in your area?', style: TextStyle(color: _muted, fontSize: 14)),
                ),
              ),
            ],
          ),
          const Divider(height: 22, color: _line),
          Row(
            children: [
              Expanded(child: _InlineAction(icon: Icons.image_outlined, label: 'Photo', onTap: onPhoto)),
              Expanded(child: _InlineAction(icon: Icons.video_library_outlined, label: 'Video', onTap: onVideo)),
              Expanded(child: _InlineAction(icon: Icons.poll_outlined, label: 'Poll', onTap: onPoll)),
              SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: onPost,
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Post'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _secondary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(80, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onOpen,
  });

  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(16),
      child: _Card(
        margin: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AuthorLine(name: post.authorName, location: _postLocation(post), time: _timeAgo(post.createdAt)),
            if (post.category != null && post.category!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _CategoryBadge(category: post.category!),
            ],
            const SizedBox(height: 10),
            Text(
              _cleanContent(post.content),
              style: const TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 15, height: 1.45),
            ),
            const SizedBox(height: 12),
            _PostImageGrid(images: post.images.isNotEmpty ? post.images : (post.image == null ? const [] : [post.image!])),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, color: _secondary, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(_postLocation(post), style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const Divider(height: 22, color: _line),
            _SocialActions(likes: post.likes, comments: post.commentCount, onLike: onLike, onComment: onComment, onShare: () {}),
          ],
        ),
      ),
    );
  }
}

class _PollCard extends StatelessWidget {
  const _PollCard({required this.poll, required this.onTap, required this.onVote});

  final PollModel poll;
  final VoidCallback onTap;
  final ValueChanged<int> onVote;

  @override
  Widget build(BuildContext context) {
    final total = poll.votesCount == 0
        ? poll.options.fold<int>(0, (sum, option) => sum + option.votesCount)
        : poll.votesCount;
    final hasVoted = poll.userVoteOptionId != null;
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
              location: poll.location?['name']?.toString() ?? 'Nagapattinam',
              time: _timeAgo(poll.createdAt),
              category: hasVoted ? 'Voted' : 'Active',
            ),
            const SizedBox(height: 14),
            Text(poll.question, style: const TextStyle(color: _text, fontSize: 17, fontWeight: FontWeight.w900, height: 1.35)),
            const SizedBox(height: 14),
            ...poll.options.map((option) {
              final pct = total == 0 ? 0.0 : option.votesCount / total;
              if (hasVoted || total > 0) {
                return _ResultBar(label: option.text, percent: pct, votes: option.votesCount);
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: OutlinedButton(
                  onPressed: () => onVote(option.id),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    minimumSize: const Size(double.infinity, 44),
                    side: const BorderSide(color: _line),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(option.text),
                ),
              );
            }),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('$total votes', style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(_remainingTime(poll.expiresAt), style: const TextStyle(color: _secondary, fontSize: 12, fontWeight: FontWeight.w800)),
              ],
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
  });

  final String name;
  final String location;
  final String time;
  final String? category;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: const Color(0xFFEAF6EF),
          child: Text(name.isEmpty ? 'C' : name.characters.first.toUpperCase(), style: const TextStyle(color: _primary, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 14)),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: _secondary, size: 13),
                  const SizedBox(width: 2),
                  Expanded(child: Text(location, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 11))),
                  if (time.isNotEmpty) Text('  -  $time', style: const TextStyle(color: _muted, fontSize: 11)),
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
    required this.likes,
    required this.comments,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });

  final int likes;
  final int comments;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _InlineAction(icon: Icons.thumb_up_outlined, label: '$likes', onTap: onLike),
        const SizedBox(width: 18),
        _InlineAction(icon: Icons.chat_bubble_outline_rounded, label: '$comments', onTap: onComment),
        const Spacer(),
        _InlineAction(icon: Icons.share_outlined, label: 'Share', onTap: onShare),
      ],
    );
  }
}

class _InlineAction extends StatelessWidget {
  const _InlineAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _muted, size: 18),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: _muted, fontWeight: FontWeight.w700, fontSize: 12)),
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
    final shown = images.isEmpty ? ['sample-light', 'sample-pole'] : images.take(4).toList();
    if (shown.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(height: 190, width: double.infinity, child: _ImageSource(value: shown.first)),
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
        childAspectRatio: 1.35,
      ),
      itemBuilder: (_, index) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _ImageSource(value: shown[index]),
      ),
    );
  }
}

class _ImageSource extends StatelessWidget {
  const _ImageSource({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Image.network(value, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _SampleImage(seed: value));
    }
    if (value.startsWith('sample')) return _SampleImage(seed: value);
    try {
      final clean = value.contains('base64,') ? value.substring(value.indexOf('base64,') + 7) : value;
      return Image.memory(base64Decode(clean), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _SampleImage(seed: value));
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

class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.community, required this.joined, required this.onTap, this.onJoin});

  final CommunityModel community;
  final bool joined;
  final VoidCallback onTap;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    return _Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: _avatarTint(community.name),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(_groupIcon(community.name), color: _primary, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(community.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: _text, fontSize: 14)),
                  const SizedBox(height: 3),
                  Text('${community.memberCount} Members', style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            joined ? const _TinyBadge(label: 'Joined') : _JoinButton(onTap: onJoin ?? onTap),
          ],
        ),
      ),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _line)),
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
        Expanded(child: Text(title, style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w900))),
        if (action != null) Text(action!, style: const TextStyle(color: _secondary, fontWeight: FontWeight.w800, fontSize: 12)),
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
          const CircleAvatar(backgroundColor: Color(0xFFEAF6EF), child: Icon(Icons.poll_outlined, color: _primary)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ask your community', style: TextStyle(color: _text, fontWeight: FontWeight.w900)),
                Text('Create a poll for local decisions', style: TextStyle(color: _muted, fontSize: 12)),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: onTap,
            icon: const Icon(Icons.add_rounded),
            style: IconButton.styleFrom(backgroundColor: _secondary, foregroundColor: Colors.white),
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
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded, color: Colors.white)),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
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
    return Text(text, style: const TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 13));
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.icon, required this.active, required this.onTap});

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
          border: Border.all(color: active ? color : _line, width: active ? 1.4 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ImagePreviewGrid extends StatelessWidget {
  const _ImagePreviewGrid({required this.images, required this.onAdd, required this.onRemove});

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
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _line)),
              child: const Icon(Icons.add_rounded, color: _primary, size: 30),
            ),
          );
        }
        return Stack(
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(images[index], width: double.infinity, height: double.infinity, fit: BoxFit.cover)),
            Positioned(
              top: 4,
              right: 4,
              child: InkWell(
                onTap: () => onRemove(index),
                child: const CircleAvatar(radius: 11, backgroundColor: Colors.black54, child: Icon(Icons.close_rounded, color: Colors.white, size: 14)),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _line)),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: _secondary, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(location, style: const TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 13))),
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
          title: Text('$days Day${days == 1 ? '' : 's'}', style: const TextStyle(fontWeight: FontWeight.w700)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class _ResultBar extends StatelessWidget {
  const _ResultBar({required this.label, required this.percent, required this.votes});

  final String label;
  final double percent;
  final int votes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w700))),
              Text('${(percent * 100).round()}% ($votes votes)', style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: percent.clamp(0, 1),
              minHeight: 7,
              color: _secondary,
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 16)),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final CommentModel comment;

  @override
  Widget build(BuildContext context) {
    return _Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AuthorLine(name: comment.authorName, location: comment.authorRole ?? 'Member', time: _timeAgo(comment.createdAt)),
          const SizedBox(height: 8),
          Text(comment.content, style: const TextStyle(color: _text, fontWeight: FontWeight.w600, height: 1.4)),
          const SizedBox(height: 8),
          Row(
            children: [
              const _InlineAction(icon: Icons.thumb_up_outlined, label: '3', onTap: _noop),
              const SizedBox(width: 12),
              TextButton(onPressed: () {}, child: const Text('Reply')),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text('Thanks, we will update the ward team.', style: TextStyle(color: _muted.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

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
                decoration: const InputDecoration(hintText: 'Write a comment...'),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: onSend,
              icon: const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(backgroundColor: _secondary, foregroundColor: Colors.white),
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
    final isComplaint = category == 'Complaint';
    final color = isComplaint ? const Color(0xFFE53935) : category == 'Information' ? const Color(0xFF2F6DE0) : _secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isComplaint ? Icons.warning_amber_rounded : Icons.info_outline_rounded, color: color, size: 14),
          const SizedBox(width: 5),
          Text(category, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11)),
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
      decoration: BoxDecoration(color: const Color(0xFFEAF6EF), borderRadius: BorderRadius.circular(99)),
      child: Text(label, style: const TextStyle(color: _secondary, fontSize: 11, fontWeight: FontWeight.w900)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Join', style: TextStyle(fontWeight: FontWeight.w900)),
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
      leading: CircleAvatar(backgroundColor: const Color(0xFFEAF6EF), child: Icon(icon, color: _primary)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle),
      trailing: selected ? const Icon(Icons.check_circle_rounded, color: _secondary) : null,
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
  return post.location?['name']?.toString() ?? post.community?.name ?? 'Pushpavanam, Nagapattinam';
}

String _cleanContent(String content) {
  final parts = content.split('\n\n');
  if (parts.length > 1 && ['Discussion', 'Suggestion', 'Complaint', 'Information', 'General Update', 'Community Post'].contains(parts.first.trim())) {
    return parts.skip(1).join('\n\n').trim();
  }
  return content.trim();
}

String _categoryFromContent(String content) {
  final first = content.split('\n\n').first.trim();
  if (['Discussion', 'Suggestion', 'Complaint', 'Information'].contains(first)) return first;
  final lower = content.toLowerCase();
  if (lower.contains('not working') || lower.contains('complaint')) return 'Complaint';
  if (lower.contains('suggest')) return 'Suggestion';
  return 'Information';
}

DateTime _parseDateTime(String value) {
  final parsedInt = int.tryParse(value);
  if (parsedInt != null) {
    return DateTime.fromMillisecondsSinceEpoch(
      parsedInt > 9999999999 ? parsedInt : parsedInt * 1000,
    ).toLocal();
  }
  String normalized = value;
  if (!normalized.endsWith('Z') && !normalized.contains('+') && !normalized.contains(RegExp(r'-\d{2}:?\d{2}$'))) {
    normalized = normalized.replaceAll(' ', 'T');
    if (!normalized.endsWith('Z')) {
      normalized = '${normalized}Z';
    }
  }
  return DateTime.parse(normalized).toLocal();
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
    final diff = DateTime.parse(value).difference(DateTime.now());
    if (diff.isNegative) return 'Closed';
    if (diff.inDays > 0) return '${diff.inDays} Days';
    if (diff.inHours > 0) return '${diff.inHours} Hours';
    return '${diff.inMinutes} Min';
  } catch (_) {
    return '2 Days';
  }
}

final _sampleCommunities = [
  CommunityModel(id: 1, name: 'Doctors - Nagapattinam', description: 'Medical support community', memberCount: 325, createdAt: ''),
  CommunityModel(id: 2, name: 'Farmers - Nagapattinam', description: 'Agriculture updates', memberCount: 412, createdAt: ''),
  CommunityModel(id: 3, name: 'Teachers - Nagapattinam', description: 'Education coordination', memberCount: 276, createdAt: ''),
  CommunityModel(id: 4, name: 'Lawyers - Nagapattinam', description: 'Legal support', memberCount: 189, createdAt: ''),
  CommunityModel(id: 5, name: 'Youth Wing - Nagapattinam', description: 'Volunteer team', memberCount: 358, createdAt: ''),
  CommunityModel(id: 6, name: 'Business Owners - Nagapattinam', description: 'Local business group', memberCount: 156, createdAt: ''),
  CommunityModel(id: 7, name: "Women's Forum - Nagapattinam", description: 'Community forum', memberCount: 198, createdAt: ''),
  CommunityModel(id: 8, name: 'Police Support - Nagapattinam', description: 'Safety updates', memberCount: 221, createdAt: ''),
];

final _samplePosts = [
  PostModel(
    id: -1,
    title: 'Street light issue',
    content: 'Street light not working near Pushpavanam Bus Stop for 3 days. Please fix it.',
    category: 'Complaint',
    images: const ['sample-light', 'sample-pole'],
    likes: 28,
    authorName: 'Kumar M',
    authorRole: 'Member',
    commentCount: 6,
    createdAt: DateTime.now().subtract(const Duration(minutes: 20)).toIso8601String(),
    location: const {'name': 'Pushpavanam Street'},
  ),
  PostModel(
    id: -2,
    title: 'Water supply update',
    content: 'Water supply will be closed tomorrow from 10 AM to 4 PM for maintenance.',
    category: 'Information',
    images: const [],
    likes: 54,
    authorName: 'Selvam R',
    authorRole: 'Ward Coordinator',
    commentCount: 11,
    createdAt: DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
    location: const {'name': 'Vedaranyam'},
  ),
];



final _sampleComments = [
  CommentModel(id: -1, content: "Yes, it is not working. I also noticed.", authorName: 'Ravi S', authorRole: 'Member', createdAt: DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String()),
  CommentModel(id: -2, content: 'I have informed EB office. They will check and update.', authorName: 'Selvi P', authorRole: 'Area Coordinator', createdAt: DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String()),
];

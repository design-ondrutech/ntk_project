import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/links/community_links_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/links/community_links_event.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/links/community_links_state.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunityLinksScreen extends StatefulWidget {
  final int communityId;
  final bool isAdmin;

  const CommunityLinksScreen({Key? key, required this.communityId, this.isAdmin = false}) : super(key: key);

  @override
  State<CommunityLinksScreen> createState() => _CommunityLinksScreenState();
}

class _CommunityLinksScreenState extends State<CommunityLinksScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CommunityLinksBloc>().add(FetchCommunityMediaGalleryEvent(widget.communityId));
  }

  Future<void> _launchURL(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: const NTKAppBar(
        title: 'Media, Links & Docs',
        subtitle: 'Recent activity gallery',
      ),
      body: BlocConsumer<CommunityLinksBloc, CommunityLinksState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.media.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0A3D28)));
          }
          
          if (state.media.isEmpty) {
            return const Center(child: Text('No media or documents available.', style: TextStyle(color: Colors.grey)));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: state.media.length,
            itemBuilder: (context, index) {
              final media = state.media[index];
              return GestureDetector(
                onTap: () => _launchURL(media.mediaUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: media.mediaType == 'IMAGE' 
                    ? Image.network(media.mediaUrl, fit: BoxFit.cover)
                    : Container(
                        color: const Color(0xFFEAF6EF),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              media.mediaType == 'DOCUMENT' ? Icons.description : Icons.link, 
                              color: const Color(0xFF0F8A4B)
                            ),
                            if (media.fileName != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Text(
                                  media.fileName!, 
                                  maxLines: 1, 
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                          ],
                        ),
                      ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

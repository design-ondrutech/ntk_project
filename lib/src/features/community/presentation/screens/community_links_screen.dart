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
    context.read<CommunityLinksBloc>().add(FetchCommunityLinksEvent(widget.communityId));
  }

  Future<void> _launchURL(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _showAddLinkDialog() {
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Link/Document', style: TextStyle(color: Color(0xFF0A3D28), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: 'URL', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F8A4B)),
            onPressed: () {
              if (titleController.text.trim().isEmpty || urlController.text.trim().isEmpty) return;
              context.read<CommunityLinksBloc>().add(UploadCommunityLinkEvent(
                communityId: widget.communityId,
                title: titleController.text.trim(),
                url: urlController.text.trim(),
                type: 'LINK',
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: const NTKAppBar(
        title: 'Community Links',
        subtitle: 'Important documents & links',
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF0F8A4B),
              onPressed: _showAddLinkDialog,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: BlocConsumer<CommunityLinksBloc, CommunityLinksState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.successMessage!)));
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.links.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0A3D28)));
          }
          
          if (state.links.isEmpty) {
            return const Center(child: Text('No links or documents available.', style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.links.length,
            itemBuilder: (context, index) {
              final link = state.links[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEAF6EF),
                    child: Icon(Icons.link, color: Color(0xFF0F8A4B)),
                  ),
                  title: Text(link.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text(link.url, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.blue)),
                  trailing: widget.isAdmin
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            context.read<CommunityLinksBloc>().add(DeleteCommunityLinkEvent(
                              link.id,
                            ));
                          },
                        )
                      : null,
                  onTap: () => _launchURL(link.url),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

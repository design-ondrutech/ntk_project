import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_posts_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_posts_event.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_posts_state.dart';
import 'package:ntk_project/src/core/widgets/ntk_snackbar.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';

class CreateCommunityPostScreen extends StatefulWidget {
  final int communityId;

  const CreateCommunityPostScreen({Key? key, required this.communityId}) : super(key: key);

  @override
  State<CreateCommunityPostScreen> createState() => _CreateCommunityPostScreenState();
}

class _CreateCommunityPostScreenState extends State<CreateCommunityPostScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _picker = ImagePicker();

  final List<File> _pickedImages = [];
  final List<String> _attachedDocuments = [];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final List<XFile> files = await _picker.pickMultiImage(imageQuality: 80);
      if (files.isEmpty) return;
      setState(() {
        _pickedImages.addAll(files.map((f) => File(f.path)));
      });
    } catch (e) {
      if (mounted) {
        NTKSnackbar.showError(context, message: 'Could not open gallery. Please try again.');
      }
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (file == null) return;
      setState(() {
        _pickedImages.add(File(file.path));
      });
    } catch (e) {
      if (mounted) {
        NTKSnackbar.showError(context, message: 'Could not open camera. Please try again.');
      }
    }
  }



  void _removeImage(int index) {
    setState(() {
      _pickedImages.removeAt(index);
    });
  }

  void _submitPost() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      NTKSnackbar.showError(context, message: 'Title and Content are required');
      return;
    }

    final user = context.read<AuthBloc>().state.loginData;
    if (user == null) return;

    // Convert picked image files to Base64 strings
    final List<String> imageBase64List = [];
    for (var file in _pickedImages) {
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      imageBase64List.add('data:image/jpeg;base64,$base64String');
    }

    context.read<CommunityPostsBloc>().add(
      CreateCommunityPostEvent(
        communityId: widget.communityId,
        title: title,
        content: content,
        category: null,
        images: imageBase64List.isNotEmpty ? imageBase64List : null,
        documents: _attachedDocuments.isNotEmpty ? _attachedDocuments : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CommunityPostsBloc, CommunityPostsState>(
      listenWhen: (previous, current) => previous.isLoading && !current.isLoading,
      listener: (context, state) {
        if (state.successMessage != null) {
          NTKSnackbar.showSuccess(context, message: state.successMessage!);
          Navigator.pop(context);
        } else if (state.error != null) {
          NTKSnackbar.showError(context, message: state.error!);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Post', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF005C3B),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              RichText(
                text: const TextSpan(
                  text: 'Title ',
                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(text: '*', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter post title',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF005C3B)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Description Field
              RichText(
                text: const TextSpan(
                  text: 'Description ',
                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(text: '*', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contentController,
                maxLines: 8,
                minLines: 5,
                decoration: InputDecoration(
                  hintText: 'Describe your question or issue in detail...',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF005C3B)),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Add Photos Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Photos',
                    style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: _pickFromCamera,
                    icon: const Icon(CupertinoIcons.camera_fill, color: Color(0xFF004D2A)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Image button only (Gallery)
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Center(
                    child: Icon(Icons.add, color: Color(0xFF004D2A), size: 32),
                  ),
                ),
              ),

              // Image Previews
              if (_pickedImages.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Selected Images',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pickedImages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _pickedImages[index],
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(3),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: BlocBuilder<CommunityPostsBloc, CommunityPostsState>(
              builder: (context, state) {
                return ElevatedButton(
                  onPressed: state.isLoading ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005C3B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Post',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/home_provider.dart';

class AddStorySheet extends ConsumerStatefulWidget {
  const AddStorySheet({super.key});

  @override
  ConsumerState<AddStorySheet> createState() => _AddStorySheetState();
}

class _AddStorySheetState extends ConsumerState<AddStorySheet> {
  final _captionController = TextEditingController();
  bool _isPosting = false;
  XFile? _pickedFile;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Share Creative Process',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Image Picker Card Trigger
          InkWell(
            onTap: () async {
              final picker = ImagePicker();
              final file = await picker.pickImage(
                source: ImageSource.gallery, 
                imageQuality: 70,
              );
              if (file != null) {
                setState(() => _pickedFile = file);
              }
            },
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                // FIX: Removed 'style: BorderStyle.dashed' which caused the crash
                border: Border.all(color: Colors.grey.shade300, width: 1),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: _pickedFile == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_outlined, size: 32, color: Color(0xFF8C2D19)),
                        SizedBox(height: 8),
                        Text(
                          'Tap to Select Photo from Gallery',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Image Selected Successfully!',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Caption Inputs
          TextField(
            controller: _captionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Story Caption / Legend',
              hintText: 'Describe what you are working on today...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          
          // Submission Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8C2D19),
                foregroundColor: Colors.white,
              ),
              onPressed: _isPosting ? null : _handlePublish,
              child: _isPosting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Publish Story', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePublish() async {
    if (_pickedFile == null) return;
    setState(() => _isPosting = true);

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final supabase = Supabase.instance.client;
        final fileBytes = await _pickedFile!.readAsBytes();
        final fileExtension = _pickedFile!.name.split('.').last;
        final String storagePath = '${user.id}/story_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

        // 1. Upload to storage bucket container layout
        await supabase.storage.from('stories').uploadBinary(
              storagePath,
              fileBytes,
              fileOptions: FileOptions(contentType: 'image/$fileExtension'),
            );

        // 2. Fetch public link URL
        final String publicUrl = supabase.storage.from('stories').getPublicUrl(storagePath);

        // 3. Update database table data records
        await supabase.from('artisans').update({
          'latest_story_url': publicUrl,
          'story_caption': _captionController.text.trim(),
          'story_created_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);

        ref.invalidate(homeFeedProvider);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        setState(() => _isPosting = false);
      }
    }
  }
}
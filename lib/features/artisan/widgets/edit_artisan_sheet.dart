import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/artisan_provider.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class EditArtisanSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> artisan;
  const EditArtisanSheet({super.key, required this.artisan});

  @override
  ConsumerState<EditArtisanSheet> createState() => _EditArtisanSheetState();
}

class _EditArtisanSheetState extends ConsumerState<EditArtisanSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _regionController;
  late TextEditingController _storyController;
  bool _isSaving = false;
  XFile? _profileImage;
  Uint8List? _profileBytes;

  XFile? _coverImage;
  Uint8List? _coverBytes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
        text: widget.artisan['name'] ?? widget.artisan['shop_name']);
    _regionController = TextEditingController(text: widget.artisan['region']);
    _storyController = TextEditingController(
        text: widget.artisan['story'] ?? widget.artisan['heritage_story']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regionController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isCover) async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        if (isCover) {
          _coverImage = file;
          _coverBytes = bytes;
        } else {
          _profileImage = file;
          _profileBytes = bytes;
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final artisanId =
          (widget.artisan['id'] ?? supabase.auth.currentUser?.id).toString();

      final Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'region': _regionController.text.trim(),
        'heritage_story': _storyController.text.trim(),
      };

      if (_profileImage != null && _profileBytes != null) {
        final ext = _profileImage!.name.split('.').last;
        final path =
            '$artisanId/profile_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await supabase.storage.from('artisan-assets').uploadBinary(
            path, _profileBytes!,
            fileOptions: FileOptions(contentType: 'image/$ext'));
        updateData['profile_photo_url'] =
            supabase.storage.from('artisan-assets').getPublicUrl(path);
      }

      if (_coverImage != null && _coverBytes != null) {
        final ext = _coverImage!.name.split('.').last;
        final path =
            '$artisanId/cover_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await supabase.storage.from('artisan-assets').uploadBinary(
            path, _coverBytes!,
            fileOptions: FileOptions(contentType: 'image/$ext'));
        updateData['cover_photo_url'] =
            supabase.storage.from('artisan-assets').getPublicUrl(path);
      }

      await supabase.from('artisans').update(updateData).eq('id', artisanId);

      ref.invalidate(artisanProfileProvider(artisanId));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error updating: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);

    // Existing image fallbacks from the UI data mapping
    final existingCover = widget.artisan['cover_photo_url'] ??
        widget.artisan['cover'] ??
        'https://via.placeholder.com/400x200';
    final existingAvatar = widget.artisan['profile_photo_url'] ??
        widget.artisan['avatar'] ??
        'https://via.placeholder.com/150';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Edit Profile & Story',
                    style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),

          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // --- IMAGE PICKERS ---
                  const Text('Cover Photo',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickImage(true),
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: _coverBytes != null
                              ? MemoryImage(_coverBytes!) as ImageProvider
                              : NetworkImage(existingCover),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('Profile Avatar',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickImage(false),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _profileBytes != null
                                ? MemoryImage(_profileBytes!) as ImageProvider
                                : NetworkImage(existingAvatar),
                          ),
                          Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- TEXT FIELDS ---
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                        labelText: 'Artisan / Workshop Name',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required field' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _regionController,
                    decoration: InputDecoration(
                        labelText: 'Cultural Region (e.g., Siem Reap)',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _storyController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Your Heritage Story',
                      hintText:
                          'Describe the cultural motif legend or hand-carving history...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Submit Button
          Container(
            padding: EdgeInsets.fromLTRB(
                24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5))
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8C2D19),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Profile & Images',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

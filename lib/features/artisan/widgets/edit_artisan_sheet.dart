import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/artisan_provider.dart';

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

  // Image Picking States (Web-safe)
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
        text: widget.artisan['heritage_story'] ?? widget.artisan['story']);
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

      // 1. Prepare base update data
      final Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'region': _regionController.text.trim(),
        'heritage_story': _storyController.text.trim(),
      };

      // 2. Upload Profile Photo if changed
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

      // 3. Upload Cover Photo if changed
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

      // 4. Push updates to public.artisans schema
      await supabase.from('artisans').update(updateData).eq('id', artisanId);

      // Refresh UI state
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
    final existingCover = widget.artisan['cover_photo_url'] ??
        widget.artisan['cover'] ??
        'https://via.placeholder.com/400x200';
    final existingAvatar = widget.artisan['profile_photo_url'] ??
        widget.artisan['avatar'] ??
        'https://via.placeholder.com/150';

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header (Aligned with UploadProductSheet)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Profile & Story',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'serif',
                      color: AppTheme.deepEarth),
                ),
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
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // --- COVER PHOTO PICKER ---
                  const Text('Cover Photo',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.gold)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _pickImage(true),
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppTheme.gold.withOpacity(0.5), width: 1),
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
                            borderRadius: BorderRadius.circular(16)),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt,
                                color: Colors.white, size: 32),
                            SizedBox(height: 8),
                            Text('Tap to change cover',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- AVATAR PHOTO PICKER ---
                  const Text('Profile Avatar',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.gold)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _pickImage(false),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppTheme.gold.withOpacity(0.5),
                                  width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.grey.shade100,
                              backgroundImage: _profileBytes != null
                                  ? MemoryImage(_profileBytes!) as ImageProvider
                                  : NetworkImage(existingAvatar),
                            ),
                          ),
                          Container(
                            height: 90,
                            width: 90,
                            decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
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
                  const Text('Workshop Details',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.gold)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration('Artisan / Workshop Name'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required field' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _regionController,
                    decoration:
                        _inputDecoration('Cultural Region (e.g., Siem Reap)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _storyController,
                    maxLines: 4,
                    decoration: _inputDecoration('Your Heritage Story'),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Submit Button (Aligned with UploadProductSheet)
          Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20,
                MediaQuery.of(context).viewInsets.bottom > 0 ? 20 : 32),
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
                  backgroundColor: AppTheme.gold,
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

  // Unified input styling matching UploadProductSheet
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.gold)),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}

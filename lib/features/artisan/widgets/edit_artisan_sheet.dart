import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final artisanId =
          (widget.artisan['id'] ?? supabase.auth.currentUser?.id).toString();

      await supabase.from('artisans').update({
        'name': _nameController.text.trim(),
        'region': _regionController.text.trim(),
        'heritage_story': _storyController.text.trim(),
        'story_created_at': DateTime.now().toIso8601String(),
      }).eq('id', artisanId);

      ref.invalidate(artisanProfileProvider(artisanId));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Heritage Story & Profile saved successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error updating: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Profile & Story',
                style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: 'Artisan / Workshop Name',
                  border: OutlineInputBorder()),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required field' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regionController,
              decoration: const InputDecoration(
                  labelText: 'Cultural Region (e.g., Siem Reap)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _storyController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Your Heritage Story',
                hintText:
                    'Describe the cultural motif legend or hand-carving history...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8C2D19),
                    foregroundColor: Colors.white),
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Changes',
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

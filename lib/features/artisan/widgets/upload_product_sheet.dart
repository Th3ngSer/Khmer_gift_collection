import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/artisan_provider.dart';

class UploadProductSheet extends ConsumerStatefulWidget {
  final String artisanId;
  const UploadProductSheet({super.key, required this.artisanId});

  @override
  ConsumerState<UploadProductSheet> createState() => _UploadProductSheetState();
}

class _UploadProductSheetState extends ConsumerState<UploadProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _imgController = TextEditingController();
  String _selectedCategory = 'Textile';
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _imgController.dispose();
    super.dispose();
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isUploading = true);

    try {
      final supabase = Supabase.instance.client;

      final productRes = await supabase.from('products').insert({
        'artisan_id': widget.artisanId,
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'category': _selectedCategory,
        'price': double.parse(_priceController.text.trim()),
      }).select().single();

      final imageUrl = _imgController.text.trim().isNotEmpty 
          ? _imgController.text.trim() 
          : 'https://images.unsplash.com/photo-1618220179428-22790b461013';

      await supabase.from('product_images').insert({
        'product_id': productRes['id'],
        'image_url': imageUrl,
        'is_primary': true,
      });

      ref.invalidate(artisanProfileProvider(widget.artisanId));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masterpiece successfully listed for sale!')));
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('List a New Masterpiece', style: TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: ['Textile', 'Silver', 'Wood', 'Edible', 'Jewelry', 'Carving', 'Weaving'].map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (\$)', border: OutlineInputBorder()),
                validator: (v) => v == null || double.tryParse(v) == null ? 'Enter valid price' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imgController,
                decoration: const InputDecoration(labelText: 'Product Image URL', hintText: 'https://...', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description & Cultural Motif', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8C2D19), foregroundColor: Colors.white),
                  onPressed: _isUploading ? null : _submitProduct,
                  child: _isUploading ? const CircularProgressIndicator(color: Colors.white) : const Text('Publish Product', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
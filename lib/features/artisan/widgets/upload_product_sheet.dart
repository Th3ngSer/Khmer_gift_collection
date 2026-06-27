import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/artisan_provider.dart';

class UploadProductSheet extends ConsumerStatefulWidget {
  final String artisanId;

  const UploadProductSheet({super.key, required this.artisanId});

  @override
  ConsumerState<UploadProductSheet> createState() => _UploadProductSheetState();
}

class _UploadProductSheetState extends ConsumerState<UploadProductSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _isUploading = false;
  XFile? _pickedImage;
  Uint8List? _imageBytes;

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '1');
  final _descController = TextEditingController();

  // Detail Controllers
  final _dimensionsController = TextEditingController();
  final _motifController = TextEditingController();

  // Dropdown Selections
  String _selectedCategory = 'Textile';
  String _selectedBudget = 'Medium';
  String _selectedMaterial = 'Silk';
  String _selectedRecipient = 'For Her';
  String _selectedVibe = 'Traditional';
  bool _isMadeToOrder = false;

  final List<String> categories = [
    'Textile',
    'Silver',
    'Wood',
    'Edible',
    'Jewelry',
    'Ceramic',
    'Other'
  ];
  final List<String> budgetBrackets = ['Low', 'Medium', 'Premium', 'Luxury'];
  final List<String> materialFocus = [
    'Silk',
    'Cotton',
    'Silver',
    'Wood',
    'Rattan',
    'Clay',
    'Mixed'
  ];
  final List<String> targetRecipients = [
    'For Her',
    'For Him',
    'For Couples',
    'Tourist',
    'Wedding',
    'Corporate'
  ];
  final List<String> stylisticVibes = [
    'Traditional',
    'Modern Khmer',
    'Minimalist',
    'Rustic',
    'Festive'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descController.dispose();
    _dimensionsController.dispose();
    _motifController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) {
      // Safely read bytes cross-platform (Web + Mobile)
      final bytes = await file.readAsBytes();
      setState(() {
        _pickedImage = file;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _handlePublish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a product image first.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final supabase = Supabase.instance.client;

      // 1. Upload Image to Supabase Storage ('product-media' bucket)
      final fileBytes = await _pickedImage!.readAsBytes();
      final fileExt = _pickedImage!.name.split('.').last;
      final fileName =
          '${widget.artisanId}/prod_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await supabase.storage.from('product-media').uploadBinary(
            fileName,
            fileBytes,
            fileOptions: FileOptions(contentType: 'image/$fileExt'),
          );
      final imageUrl =
          supabase.storage.from('product-media').getPublicUrl(fileName);

      // 2. Insert Product Record
      final productResponse = await supabase
          .from('products')
          .insert({
            'artisan_id': widget.artisanId,
            'name': _nameController.text.trim(),
            'description': _descController.text.trim(),
            'category': _selectedCategory,
            'price': double.tryParse(_priceController.text) ?? 0.0,
            'stock_quantity': int.tryParse(_stockController.text) ?? 0,
            'is_made_to_order': _isMadeToOrder,
            'dimensions': _dimensionsController.text.trim(),
            'motif_legend': _motifController.text.trim(),
            // Gift Finder Quiz Tags
            'budget_bracket': _selectedBudget,
            'material_focus': _selectedMaterial,
            'target_recipient': _selectedRecipient,
            'stylistic_vibe': _selectedVibe,
          })
          .select('id')
          .single();

      final productId = productResponse['id'];

      // 3. Insert Image Record
      await supabase.from('product_images').insert({
        'product_id': productId,
        'image_url': imageUrl,
        'is_primary': true,
      });

      // 4. Refresh State & Close
      ref.invalidate(artisanProfileProvider(widget.artisanId));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Product published successfully!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error publishing product: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'List New Creation',
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
                  // Image Picker
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppTheme.gold.withOpacity(0.5), width: 1),
                        image: _pickedImage != null
                            ? DecorationImage(
                                image: MemoryImage(_imageBytes!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _pickedImage == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo,
                                    size: 40, color: AppTheme.gold),
                                SizedBox(height: 10),
                                Text('Tap to upload primary image',
                                    style:
                                        TextStyle(color: AppTheme.deepEarth)),
                              ],
                            )
                          : const SizedBox(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Basic Info
                  const Text('Core Details',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.gold)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration:
                        _inputDecoration('Product Name (e.g., Silk Krama)'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: _inputDecoration('Price (\$)'),
                          validator: (val) =>
                              val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: _inputDecoration('Stock Qty'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown('Category', _selectedCategory, categories,
                      (val) => setState(() => _selectedCategory = val!)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: _inputDecoration('General Description'),
                  ),

                  const SizedBox(height: 24),

                  // Cultural & Physical Details
                  const Text('Cultural Context & Specs',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.gold)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _motifController,
                    maxLines: 2,
                    decoration: _inputDecoration(
                        'Motif Legend (e.g., Symbolizes prosperity...)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dimensionsController,
                    decoration:
                        _inputDecoration('Dimensions (e.g., 40cm x 180cm)'),
                  ),
                  SwitchListTile(
                    title: const Text('Is Made to Order?'),
                    activeColor: AppTheme.gold,
                    contentPadding: EdgeInsets.zero,
                    value: _isMadeToOrder,
                    onChanged: (val) => setState(() => _isMadeToOrder = val),
                  ),

                  const SizedBox(height: 24),

                  // Gift Finder Tags
                  const Text('Gift Finder Quiz Tags',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.gold)),
                  const SizedBox(height: 8),
                  const Text('These tags power the recommendation algorithm.',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _buildDropdown(
                              'Budget',
                              _selectedBudget,
                              budgetBrackets,
                              (val) => setState(() => _selectedBudget = val!))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildDropdown(
                              'Material',
                              _selectedMaterial,
                              materialFocus,
                              (val) =>
                                  setState(() => _selectedMaterial = val!))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _buildDropdown(
                              'Recipient',
                              _selectedRecipient,
                              targetRecipients,
                              (val) =>
                                  setState(() => _selectedRecipient = val!))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildDropdown(
                              'Vibe',
                              _selectedVibe,
                              stylisticVibes,
                              (val) => setState(() => _selectedVibe = val!))),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Submit Button
          Container(
            padding: const EdgeInsets.all(20),
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
                onPressed: _isUploading ? null : _handlePublish,
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Publish Masterpiece',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildDropdown(String label, String value, List<String> items,
      Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: _inputDecoration(label),
      items: items
          .map((item) => DropdownMenuItem(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 14))))
          .toList(),
      onChanged: onChanged,
    );
  }
}

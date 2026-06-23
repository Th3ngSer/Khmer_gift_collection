import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/product_detail_provider.dart';

class WriteReviewSheet extends ConsumerStatefulWidget {
  final String productId;

  const WriteReviewSheet({super.key, required this.productId});

  @override
  ConsumerState<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends ConsumerState<WriteReviewSheet> {
  final _textController = TextEditingController();
  int _selectedRating = 5;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to write a review.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final supabase = Supabase.instance.client;
      
      // Insert review record directly into your backend database table
      await supabase.from('reviews').insert({
        'product_id': widget.productId,
        'user_id': user.id,
        'rating': _selectedRating,
        'review_text': _textController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      // Invalidate the detail provider to force an automatic layout update
      ref.invalidate(productDetailProvider(widget.productId));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you! Your review has been published.')),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post review: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);
    const terracottaColor = Color(0xFF8C2D19);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Write a Review',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Tap to Select Interactive Star Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              return IconButton(
                icon: Icon(
                  _selectedRating >= starValue ? Icons.star : Icons.star_border,
                  color: goldColor,
                  size: 36,
                ),
                onPressed: () => setState(() => _selectedRating = starValue),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Review Content Input Field
          TextField(
            controller: _textController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Your Experience',
              hintText: 'Share details about the cultural motif, craft quality...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: goldColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submission Action Trigger Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: terracottaColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: _isSubmitting ? null : _submitReview,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
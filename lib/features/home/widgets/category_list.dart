import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/home_provider.dart';

class CategoryList extends ConsumerWidget {
  final List<String> categories;

  const CategoryList({super.key, required this.categories});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    const terracottaColor = Color(0xFFC05E3D);
    return SizedBox(
      height: 40,
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = selectedCategory == category;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  category,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                selected: isSelected,
                onSelected: (bool selected) {
                  if (isSelected) {
                    ref
                        .read(selectedCategoryProvider.notifier)
                        .selectCategory(null);
                  } else {
                    ref
                        .read(selectedCategoryProvider.notifier)
                        .selectCategory(category);
                  }
                },
                selectedColor: terracottaColor,
                backgroundColor: Theme.of(context).cardColor,
                side: BorderSide(
                  color: isSelected
                      ? terracottaColor
                      : Theme.of(context).dividerColor,
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                showCheckmark: false,
              ),
            );
          }),
    );
  }
}

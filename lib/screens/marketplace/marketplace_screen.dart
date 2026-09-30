import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/app_models.dart';
import '../../services/marketplace_service.dart';
import '../../services/marketplace_search.dart';
import '../../widgets/marketplace_preview_art.dart';
import '../../widgets/app_back_button.dart';
import 'package:firebase_core/firebase_core.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key, this.productStream});
  final Stream<List<ProductItem>>? productStream;

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String selectedCategory = 'All';
  late final Stream<List<ProductItem>> products =
      widget.productStream ?? MarketplaceService.watchProducts();
  String search = '';
  final Set<String> favoriteProducts = <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Market place'),
        leading: const AppBackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.handshake_outlined),
            tooltip: 'Rent equipment',
            onPressed: () => Navigator.pushNamed(context, '/rental-flow'),
          ),
          IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        // Search bar
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                onChanged: (value) => setState(() {
                                  search = value.trim().toLowerCase();
                                  selectedCategory = 'All';
                                }),
                                decoration: InputDecoration(
                                  hintText: 'Search items',
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: AppColors.textLight,
                                  ),
                                  fillColor: Colors.white,
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(
                                Icons.tune,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Category Pill selector (All, Books, Electronics, Other)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ['All', 'Books', 'Electronics', 'Other']
                                .map((cat) {
                                  bool isSelected = selectedCategory == cat;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ChoiceChip(
                                      label: Text(cat),
                                      selected: isSelected,
                                      selectedColor: AppColors.primary,
                                      backgroundColor: Colors.white,
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      onSelected: (val) {
                                        setState(() => selectedCategory = cat);
                                      },
                                    ),
                                  );
                                })
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Grid matching Market place screen in Figma
                        StreamBuilder<List<ProductItem>>(
                          stream: products,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData && !snapshot.hasError) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final preview =
                                snapshot.hasError || snapshot.data!.isEmpty;
                            final available = preview
                                ? marketplacePreview()
                                : snapshot.data!;
                            final visibleProducts = available
                                .where(
                                  (product) =>
                                      (selectedCategory == 'All' ||
                                          product.category ==
                                              selectedCategory) &&
                                      matchesMarketplaceSearch(product, search),
                                )
                                .toList();
                            if (visibleProducts.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'No items found. Add an item to get started.',
                                ),
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (preview)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      snapshot.error is FirebaseException &&
                                              (snapshot.error
                                                          as FirebaseException)
                                                      .code ==
                                                  'permission-denied'
                                          ? 'Preview items — live listings require access. Sign in or check marketplace permissions.'
                                          : 'Preview items — no live listings available.',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        // 210 was 14px short once a title
                                        // wrapped to two lines, clipping the
                                        // price off the bottom of the card.
                                        mainAxisExtent: 232,
                                        crossAxisSpacing: 14,
                                        mainAxisSpacing: 14,
                                      ),
                                  itemCount: visibleProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = visibleProducts[index];
                                    return _buildProductCard(product);
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // + Add Items sticky button at bottom matching Figma
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/add_product'),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add items'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductItem product) {
    return GestureDetector(
      onTap: () {
        if (product.id.startsWith('preview-')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This is a preview item, not a live listing.'),
            ),
          );
          return;
        }
        Navigator.pushNamed(context, '/product_detail', arguments: product);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAlignment.start,
          children: [
            // Image area with heart icon
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: product.imageUrl.startsWith('art:')
                        ? MarketplacePreviewArt(
                            kind: product.imageUrl.substring(4),
                          )
                        // No photo, or one that fails to load, falls back to
                        // drawn artwork chosen from the title and category
                        // rather than a bare grey icon.
                        : product.imageUrl.isEmpty
                        ? MarketplacePreviewArt(
                            kind: MarketplacePreviewArt.kindFor(
                              product.title,
                              product.category,
                            ),
                          )
                        : product.id.startsWith('preview-')
                        ? Image.asset(product.imageUrl, fit: BoxFit.contain)
                        : Image.network(
                            product.imageUrl,
                            width: double.infinity,
                            height: 104,
                            fit: BoxFit.contain,
                            errorBuilder: (_, error, stackTrace) =>
                                MarketplacePreviewArt(
                                  kind: MarketplacePreviewArt.kindFor(
                                    product.title,
                                    product.category,
                                  ),
                                ),
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => setState(() {
                        if (favoriteProducts.contains(product.id)) {
                          favoriteProducts.remove(product.id);
                        } else {
                          favoriteProducts.add(product.id);
                        }
                      }),
                      child: Icon(
                        favoriteProducts.contains(product.id)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 18,
                        color: favoriteProducts.contains(product.id)
                            ? Colors.red
                            : AppColors.textLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Expanded so the text block is bounded by the tile height
            // rather than pushing past it when a title wraps.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs. ${product.price.toInt()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

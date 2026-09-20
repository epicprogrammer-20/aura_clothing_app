import 'package:flutter/material.dart';
import 'category_model.dart';
import 'category_card.dart';
import 'category_products_screen.dart';
import 'search_screen.dart';
import 'product_model.dart';
import 'cart_service.dart';
import 'product_detail_screen.dart';
import 'currency_service.dart';

const List<String> kShopProductFilters = [
  'All',
  'New Arrivals',
  'Outerwear',
  'Suits',
  'Knitwear',
];

const List<String> kSortOptions = [
  'Featured',
  'Newest',
  'Price: Low to High',
  'Price: High to Low',
];

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _selectedFilter = 'All';
  String _selectedSort = 'Featured';

  RangeValues _priceRange = const RangeValues(0, 3000);
  final Set<String> _filterSizes = {};
  final Set<Color> _filterColors = {};
  bool _onlyInStock = false;

  List<ProductModel> get _filteredProducts {
    var list = mockProducts.where((p) {
      if (_selectedFilter == 'New Arrivals' && p.badge != 'NEW') return false;
      if (_selectedFilter != 'All' &&
          _selectedFilter != 'New Arrivals' &&
          p.category != _selectedFilter) {
        return false;
      }
      if (p.priceValue < _priceRange.start || p.priceValue > _priceRange.end) return false;
      if (_filterSizes.isNotEmpty && !p.sizes.any(_filterSizes.contains)) return false;
      if (_filterColors.isNotEmpty &&
          !p.colors.any((c) => _filterColors.any((fc) => fc.value == c.value))) {
        return false;
      }
      if (_onlyInStock && !p.inStock) return false;
      return true;
    }).toList();

    switch (_selectedSort) {
      case 'Newest':
        list = list.reversed.toList();
        break;
      case 'Price: Low to High':
        list.sort((a, b) => a.priceValue.compareTo(b.priceValue));
        break;
      case 'Price: High to Low':
        list.sort((a, b) => b.priceValue.compareTo(a.priceValue));
        break;
      default:
        break;
    }
    return list;
  }

  void _openSortMenu() async {
    final selected = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 220, 16, 0),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      items: kSortOptions
          .map((s) => PopupMenuItem<String>(
        value: s,
        child: Text(
          s,
          style: TextStyle(
            fontWeight: s == _selectedSort ? FontWeight.w600 : FontWeight.w400,
            color: Colors.black,
          ),
        ),
      ))
          .toList(),
    );
    if (selected != null) setState(() => _selectedSort = selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Shop',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
      endDrawer: _FilterDrawer(
        priceRange: _priceRange,
        selectedSizes: _filterSizes,
        selectedColors: _filterColors,
        onlyInStock: _onlyInStock,
        onApply: (priceRange, sizes, colors, inStock) {
          setState(() {
            _priceRange = priceRange;
            _filterSizes
              ..clear()
              ..addAll(sizes);
            _filterColors
              ..clear()
              ..addAll(colors);
            _onlyInStock = inStock;
          });
          Navigator.pop(context);
        },
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Defined by simplicity.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              sliver: SliverToBoxAdapter(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: mockCategories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                  ),
                  itemBuilder: (context, index) {
                    final category = mockCategories[index];
                    return CategoryCard(
                      category: category,
                      height: double.infinity,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CategoryProductsScreen(category: category),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'All Products',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildFilterChips()),
            SliverToBoxAdapter(child: _buildFilterSortBar()),
            _buildProductGrid(),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: kShopProductFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = kShopProductFilters[index];
          final isSelected = filter == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.grey.shade300,
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterSortBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BarButton(
              icon: Icons.tune_rounded,
              label: 'Filter',
              onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          ),
          Container(width: 1, height: 20, color: Colors.grey.shade200),
          Expanded(
            child: _BarButton(
              icon: Icons.swap_vert_rounded,
              label: 'Sort By',
              onTap: _openSortMenu,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    final products = _filteredProducts;

    if (products.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 48),
          child: Center(
            child: Text(
              'No products match your filters.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _crossAxisCount(context),
          mainAxisSpacing: 20,
          crossAxisSpacing: 14,
          childAspectRatio: 0.62,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final product = products[index];
            return _ProductCard(
              product: product,
              onWishlistToggle: () {
                setState(() => product.isWishlisted = !product.isWishlisted);
              },
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(product: product),
                  ),
                );
              },
            );
          },
          childCount: products.length,
        ),
      ),
    );
  }

  int _crossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) return 4;
    if (width >= 600) return 3;
    return 2;
  }
}

class _BarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BarButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.black),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback onWishlistToggle;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.onWishlistToggle,
    required this.onTap,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _hovering = false;

  void _quickAdd(BuildContext context) {
    final product = widget.product;
    String? selectedSize;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedBuilder(
                      animation: CurrencyService.instance,
                      builder: (context, _) => Text(
                        CurrencyService.instance.formatFromPriceString(product.price),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select Size',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.sizes.map((size) {
                        final isSelected = size == selectedSize;
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedSize = size),
                          child: Container(
                            width: 48,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.black : Colors.white,
                              border: Border.all(
                                color: isSelected ? Colors.black : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              size,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          elevation: 0,
                        ),
                        onPressed: selectedSize == null
                            ? null
                            : () {
                          CartService.instance.addItem(
                            product,
                            selectedSize!,
                            product.colors.first,
                          );
                          Navigator.pop(sheetContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.black,
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(milliseconds: 1400),
                              content: Text(
                                'Added to bag',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        },
                        child: const Text('Add to Bag'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: AnimatedScale(
                      scale: _hovering ? 1.04 : 1.0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      child: Container(
                        color: Colors.grey.shade100,
                        child: Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_outlined, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (product.badge != null)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.badge == 'NEW' ? Colors.black : Colors.white,
                          border: product.badge == 'LIMITED'
                              ? Border.all(color: Colors.black)
                              : null,
                        ),
                        child: Text(
                          product.badge!,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: product.badge == 'NEW' ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: widget.onWishlistToggle,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          product.isWishlisted ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: product.isWishlisted ? Colors.pinkAccent : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  if (!product.inStock)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.white.withOpacity(0.9),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        alignment: Alignment.center,
                        child: const Text(
                          'SOLD OUT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  AnimatedOpacity(
                    opacity: _hovering ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _QuickAddButton(
                          enabled: product.inStock,
                          onTap: () => _quickAdd(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedBuilder(
              animation: CurrencyService.instance,
              builder: (context, _) => Text(
                CurrencyService.instance.formatFromPriceString(product.price),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: product.colors.take(4).map((color) {
                return Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _QuickAddButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? Colors.black : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          enabled ? 'Quick Add' : 'Sold Out',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _FilterDrawer extends StatefulWidget {
  final RangeValues priceRange;
  final Set<String> selectedSizes;
  final Set<Color> selectedColors;
  final bool onlyInStock;
  final void Function(RangeValues, Set<String>, Set<Color>, bool) onApply;

  const _FilterDrawer({
    required this.priceRange,
    required this.selectedSizes,
    required this.selectedColors,
    required this.onlyInStock,
    required this.onApply,
  });

  @override
  State<_FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<_FilterDrawer> {
  static const _allSizes = ['S', 'M', 'L', 'XL', 'One Size'];
  static const _allColors = [Colors.black, Colors.white, Colors.grey];

  late RangeValues _priceRange = widget.priceRange;
  late Set<String> _sizes = {...widget.selectedSizes};
  late Set<Color> _colors = {...widget.selectedColors};
  late bool _inStock = widget.onlyInStock;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      width: MediaQuery.of(context).size.width * 0.85,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _sectionTitle('Price'),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 3000,
                    divisions: 30,
                    activeColor: Colors.black,
                    inactiveColor: Colors.grey.shade300,
                    labels: RangeLabels(
                      '\$${_priceRange.start.round()}',
                      '\$${_priceRange.end.round()}',
                    ),
                    onChanged: (v) => setState(() => _priceRange = v),
                  ),
                  const SizedBox(height: 12),
                  _sectionTitle('Size'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allSizes.map((size) {
                      final selected = _sizes.contains(size);
                      return GestureDetector(
                        onTap: () => setState(
                              () => selected ? _sizes.remove(size) : _sizes.add(size),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? Colors.black : Colors.white,
                            border: Border.all(
                              color: selected ? Colors.black : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            size,
                            style: TextStyle(
                              fontSize: 12,
                              color: selected ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Color'),
                  Wrap(
                    spacing: 10,
                    children: _allColors.map((color) {
                      final selected = _colors.any((c) => c.value == color.value);
                      return GestureDetector(
                        onTap: () => setState(() {
                          selected
                              ? _colors.removeWhere((c) => c.value == color.value)
                              : _colors.add(color);
                        }),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected ? Colors.black : Colors.grey.shade300,
                              width: selected ? 2 : 1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Availability'),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: Colors.black,
                    title: const Text(
                      'In Stock Only',
                      style: TextStyle(fontSize: 13, color: Colors.black),
                    ),
                    value: _inStock,
                    onChanged: (v) => setState(() => _inStock = v),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      onPressed: () => setState(() {
                        _priceRange = const RangeValues(0, 3000);
                        _sizes.clear();
                        _colors.clear();
                        _inStock = false;
                      }),
                      child: const Text('Clear', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () =>
                          widget.onApply(_priceRange, _sizes, _colors, _inStock),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: Colors.black,
      ),
    ),
  );
}
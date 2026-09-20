import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'product_model.dart';
import 'product_detail_screen.dart';
import 'currency_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  final Map<String, String> _chipToCategory = {
    'Women': 'Suits',
    'Men': 'Outerwear',
    'Sport': 'Knitwear',
    'Casual': 'Outerwear',
  };
  final Set<String> _activeCategoryFilters = {};

  final List<String> _bodyTypeOptions = [
    'Petite',
    'Tall',
    'Plus size',
    'Athletic',
    'Curvy',
  ];
  final Set<String> _selectedBodyTypes = {};

  late double _priceFloor;
  late double _priceCeiling;
  late RangeValues _selectedPriceRange;
  bool _priceFilterActive = false;

  @override
  void initState() {
    super.initState();
    final prices = mockProducts.map((p) => _parsePrice(p.price)).toList();
    _priceFloor = prices.reduce((a, b) => a < b ? a : b);
    _priceCeiling = prices.reduce((a, b) => a > b ? a : b);
    _selectedPriceRange = RangeValues(_priceFloor, _priceCeiling);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Raw USD numeric value — used for filtering/comparison only.
  // Display labels are formatted separately via CurrencyService so the
  // person sees their selected currency, while filtering logic stays
  // consistent against the underlying USD mock data.
  double _parsePrice(String price) {
    final numeric = price.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(numeric) ?? 0;
  }

  List<ProductModel> get _filteredProducts {
    return mockProducts.where((product) {
      final matchesQuery = _searchQuery.isEmpty ||
          product.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.category.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _activeCategoryFilters.isEmpty ||
          _activeCategoryFilters
              .map((chip) => _chipToCategory[chip])
              .contains(product.category);

      final productPrice = _parsePrice(product.price);
      final matchesPrice = !_priceFilterActive ||
          (productPrice >= _selectedPriceRange.start &&
              productPrice <= _selectedPriceRange.end);

      return matchesQuery && matchesCategory && matchesPrice;
    }).toList();
  }

  void _toggleCategoryChip(String label) {
    setState(() {
      if (_activeCategoryFilters.contains(label)) {
        _activeCategoryFilters.remove(label);
      } else {
        _activeCategoryFilters.add(label);
      }
    });
  }

  bool get _hasActiveFilters =>
      _selectedBodyTypes.isNotEmpty || _priceFilterActive;

  @override
  Widget build(BuildContext context) {
    final results = _filteredProducts;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: _buildFilterDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey[500], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                hintText: 'Search styles, brands, items',
                              ),
                              style: const TextStyle(fontSize: 14),
                              onChanged: (value) {
                                setState(() => _searchQuery = value);
                              },
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: Icon(Icons.close,
                                  size: 18, color: Colors.grey[500]),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      Icons.tune,
                      color: _hasActiveFilters ? Colors.black : Colors.black54,
                    ),
                    onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  ..._chipToCategory.keys.map((label) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(label),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 12),

            if (_searchQuery.isNotEmpty ||
                _activeCategoryFilters.isNotEmpty ||
                _priceFilterActive)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${results.length} result${results.length == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            Expanded(
              child: results.isEmpty
                  ? _buildEmptyState()
                  : MasonryGridView.count(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                itemCount: results.length,
                itemBuilder: (context, index) {
                  return _ProductCard(product: results[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      width: MediaQuery.of(context).size.width * 0.8,
      child: StatefulBuilder(
        builder: (context, setDrawerState) {
          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
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
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Body types',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ..._bodyTypeOptions.map((option) {
                          final isChecked = _selectedBodyTypes.contains(option);
                          return CheckboxListTile(
                            value: isChecked,
                            title: Text(option),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            activeColor: Colors.black,
                            onChanged: (checked) {
                              setDrawerState(() {
                                if (checked == true) {
                                  _selectedBodyTypes.add(option);
                                } else {
                                  _selectedBodyTypes.remove(option);
                                }
                              });
                              setState(() {});
                            },
                          );
                        }),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text(
                          'Price range',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedBuilder(
                          animation: CurrencyService.instance,
                          builder: (context, _) => Text(
                            '${CurrencyService.instance.format(_selectedPriceRange.start)} - '
                                '${CurrencyService.instance.format(_selectedPriceRange.end)}',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ),
                        RangeSlider(
                          values: _selectedPriceRange,
                          min: _priceFloor,
                          max: _priceCeiling,
                          divisions: 20,
                          activeColor: Colors.black,
                          inactiveColor: Colors.grey[300],
                          labels: RangeLabels(
                            CurrencyService.instance.format(_selectedPriceRange.start),
                            CurrencyService.instance.format(_selectedPriceRange.end),
                          ),
                          onChanged: (values) {
                            setDrawerState(() {
                              _selectedPriceRange = values;
                              _priceFilterActive = true;
                            });
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setDrawerState(() {
                              _selectedBodyTypes.clear();
                              _selectedPriceRange =
                                  RangeValues(_priceFloor, _priceCeiling);
                              _priceFilterActive = false;
                            });
                            setState(() {});
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            side: BorderSide(color: Colors.grey[400]!),
                          ),
                          child: const Text(
                            'Reset',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isActive = _activeCategoryFilters.contains(label);

    return GestureDetector(
      onTap: () => _toggleCategoryChip(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
          border: isActive ? Border.all(color: Colors.white, width: 1.5) : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              const Icon(Icons.close, size: 14, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'No results found',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different search or clear your filters',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Hero(
          tag: 'product_${product.id}',
          child: Image.network(
            product.imageUrl,
            height: product.imageHeight,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                height: product.imageHeight,
                color: Colors.grey[200],
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              height: product.imageHeight,
              color: Colors.grey[200],
              child: Icon(Icons.image_outlined, color: Colors.grey[400]),
            ),
          ),
        ),
      ),
    );
  }
}
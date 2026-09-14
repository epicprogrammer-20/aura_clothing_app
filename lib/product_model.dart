class ProductModel {
  final String id;
  final String title;
  final String price;
  final String imageUrl;
  final double imageHeight;
  final String category;
  bool isWishlisted;

  // Who posted/is wearing this look.
  final String? postedByName;
  final String? postedByAvatarUrl;
  final String? instagramHandle;
  final String? facebookUrl;

  // NEW: true only when the photo actually shows a person wearing the
  // item (not a flat-lay or product-only shot). This is what controls
  // whether the "worn by" tag overlay appears on the search grid —
  // separate from postedByName, since a product can have a linked poster
  // without a visible person in this specific image.
  final bool personVisible;

  ProductModel({
    required this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.imageHeight,
    required this.category,
    this.isWishlisted = false,
    this.postedByName,
    this.postedByAvatarUrl,
    this.instagramHandle,
    this.facebookUrl,
    this.personVisible = false,
  });
}

// ─────────────────────────────────────────────────────────
// MOCK DATA — replace with results from your real search/
// product API once the backend is wired up.
// ─────────────────────────────────────────────────────────
final List<ProductModel> mockProducts = [
  ProductModel(
    id: '1',
    title: 'Classic Burgundy Leather Jacket',
    price: '\$189',
    imageUrl:
    'https://images.unsplash.com/photo-1551028719-00167b16eac5?q=80&w=800',
    imageHeight: 220,
    category: 'Outerwear',
    postedByName: 'Jordan K.',
    instagramHandle: 'jordan.k',
    personVisible: true, // photo shows a person wearing the jacket
  ),
  ProductModel(
    id: '2',
    title: 'Fashion Week Teal Coat',
    price: '\$265',
    imageUrl:
    'https://images.unsplash.com/photo-1520975954732-35dd22299614?q=80&w=800',
    imageHeight: 300,
    category: 'Outerwear',
    postedByName: 'Mia Santos',
    instagramHandle: 'miasantos',
    facebookUrl: 'https://facebook.com/miasantos',
    personVisible: true,
  ),
  ProductModel(
    id: '3',
    title: 'Everyday Layer Pink Suit',
    price: '\$210',
    imageUrl:
    'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?q=80&w=800',
    imageHeight: 260,
    category: 'Suits',
    personVisible: true,
    // No postedByName — simulates a visible person with no linked social
    // account yet (tag will still show since it only checks personVisible).
  ),
  ProductModel(
    id: '4',
    title: 'Cream Knit Sweater',
    price: '\$78',
    imageUrl:
    'https://images.unsplash.com/photo-1576871337622-98d48d1cf531?q=80&w=800',
    imageHeight: 240,
    category: 'Knitwear',
    postedByName: 'Theo Brandt',
    instagramHandle: 'theobrandt',
    personVisible: false, // flat-lay style shot, no person in frame
  ),
  ProductModel(
    id: '5',
    title: 'Relaxed Denim Jacket',
    price: '\$130',
    imageUrl:
    'https://images.unsplash.com/photo-1544022613-e87ca75a784a?q=80&w=800',
    imageHeight: 280,
    category: 'Outerwear',
    personVisible: true,
  ),
  ProductModel(
    id: '6',
    title: 'Minimal Black Trench',
    price: '\$195',
    imageUrl:
    'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?q=80&w=800',
    imageHeight: 320,
    category: 'Outerwear',
    postedByName: 'Aura Studio',
    instagramHandle: 'aura.studio',
    facebookUrl: 'https://facebook.com/aurastudio',
    personVisible: false, // product/studio shot, no model
  ),
];
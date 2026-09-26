class ReviewModel {
  final String reviewerName;
  final double rating; // 1–5
  final String comment;
  final String date;

  const ReviewModel({
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.date,
  });
}

// Mock reviews keyed by product id — matches the ids in product_model.dart's
// mockProducts ('1' through '6'). Products without an entry show no reviews.
final Map<String, List<ReviewModel>> mockReviewsByProductId = {
  '1': [
    ReviewModel(
      reviewerName: 'Alex M.',
      rating: 5,
      comment: 'Fits perfectly and the leather feels genuinely premium.',
      date: '2 weeks ago',
    ),
    ReviewModel(
      reviewerName: 'Priya S.',
      rating: 4,
      comment: 'Great jacket — runs slightly large, size down.',
      date: '1 month ago',
    ),
  ],
  '2': [
    ReviewModel(
      reviewerName: 'Jordan K.',
      rating: 5,
      comment: 'Obsessed with this coat, so warm for winter.',
      date: '3 days ago',
    ),
  ],
  '4': [
    ReviewModel(
      reviewerName: 'Sam R.',
      rating: 4,
      comment: 'Cozy and well made, true to size.',
      date: '5 days ago',
    ),
  ],
};

List<ReviewModel> reviewsFor(String productId) =>
    mockReviewsByProductId[productId] ?? [];

double averageRating(List<ReviewModel> reviews) {
  if (reviews.isEmpty) return 0;
  return reviews.fold(0.0, (sum, r) => sum + r.rating) / reviews.length;
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/review.dart';

class VendorReviewsScreen extends StatefulWidget {
  const VendorReviewsScreen({super.key});

  @override
  State<VendorReviewsScreen> createState() => _VendorReviewsScreenState();
}

class _VendorReviewsScreenState extends State<VendorReviewsScreen> {
  double _averageRating = 0.0;
  int _totalReviews = 0;
  List<int> _ratingDistribution = [0, 0, 0, 0, 0]; // 5-star to 1-star counts

  @override
  void initState() {
    super.initState();
    _loadReviewStats();
  }

  Future<void> _loadReviewStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Get all reviews for this vendor
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('vendorId', isEqualTo: user.uid)
          .get();

      // Calculate average rating and distribution
      double totalRating = 0;
      final ratingDist = [0, 0, 0, 0, 0];

      for (var doc in reviewsSnapshot.docs) {
        final review = Review.fromFirestore(doc);
        totalRating += review.rating;
        
        // Rating distribution (1-5 stars -> index 0-4)
        if (review.rating >= 1 && review.rating <= 5) {
          ratingDist[5 - review.rating]++; // 5 stars -> index 0, 1 star -> index 4
        }
      }

      setState(() {
        _totalReviews = reviewsSnapshot.docs.length;
        _averageRating = _totalReviews > 0 ? totalRating / _totalReviews : 0;
        _ratingDistribution = ratingDist;
      });
    } catch (e) {
      print('Error loading review stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view reviews'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reviews'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating Summary Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    _averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return Icon(
                        index < _averageRating.round()
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 24,
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text('$_totalReviews reviews'),
                ],
              ),
            ),
          ),
          
          // Rating Distribution
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rating Distribution',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(5, (index) {
                    final starCount = 5 - index;
                    final count = _ratingDistribution[index];
                    final percentage = _totalReviews > 0
                        ? (count / _totalReviews) * 100
                        : 0;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 30,
                            child: Text('$starCount'),
                          ),
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.amber,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 40,
                            child: Text(
                              '$count',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Reviews List
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Recent Reviews',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .where('vendorId', isEqualTo: user.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final reviews = snapshot.data?.docs ?? [];

                if (reviews.isEmpty) {
                  return const Center(
                    child: Text('No reviews yet'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = Review.fromFirestore(reviews[index] as DocumentSnapshot<Map<String, dynamic>>);
                    final formattedDate = DateFormat('MMM d, yyyy').format(review.createdAt);
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  child: Text(review.customerName[0].toUpperCase()),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        review.customerName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: List.generate(5, (starIndex) {
                                    return Icon(
                                      starIndex < review.rating
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 16,
                                    );
                                  }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              review.serviceName,
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(review.comment),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
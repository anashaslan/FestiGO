import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class RecommendationService {
  static final RecommendationService _instance = RecommendationService._internal();
  factory RecommendationService() => _instance;
  RecommendationService._internal();

  /// Gets personalized service recommendations for a customer
  Future<List<Map<String, dynamic>>> getRecommendations({int limit = 10}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      // Get customer's booking history
      final bookingHistory = await _getCustomerBookingHistory(user.uid);
      
      // Get customer's wishlist
      final wishlist = await _getCustomerWishlist(user.uid);
      
      // Get all services
      final allServices = await _getAllServices();
      
      // Calculate recommendation scores
      final scoredServices = await _calculateRecommendationScores(
        allServices: allServices,
        bookingHistory: bookingHistory,
        wishlist: wishlist,
        customerId: user.uid,
      );
      
      // Sort by score and take top recommendations
      scoredServices.sort((a, b) => b['score'].compareTo(a['score']));
      
      // Remove services the customer has already booked
      final bookedServiceIds = bookingHistory.map((b) => b['serviceId']).toSet();
      final filteredServices = scoredServices
          .where((service) => !bookedServiceIds.contains(service['id']))
          .take(limit)
          .toList();
          
      return filteredServices;
    } catch (e) {
      debugPrint('Error getting recommendations: $e');
      return [];
    }
  }

  /// Gets customer's booking history
  Future<List<Map<String, dynamic>>> _getCustomerBookingHistory(String customerId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('customerId', isEqualTo: customerId)
          .where('status', whereIn: ['confirmed', 'completed'])
          .get();
          
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'serviceId': data['serviceId'],
          'serviceName': data['serviceName'],
          'category': data['category'],
          'price': data['price'],
          'createdAt': data['createdAt'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting booking history: $e');
      return [];
    }
  }

  /// Gets customer's wishlist
  Future<List<Map<String, dynamic>>> _getCustomerWishlist(String customerId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(customerId)
          .collection('wishlist')
          .get();
          
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'serviceId': data['serviceId'],
          'addedAt': data['addedAt'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting wishlist: $e');
      return [];
    }
  }

  /// Gets all services
  Future<List<Map<String, dynamic>>> _getAllServices() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('services')
          .get();
          
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'vendorId': data['vendorId'],
          'serviceName': data['serviceName'],
          'description': data['description'],
          'price': data['price'],
          'category': data['category'],
          'imageUrl': data['imageUrl'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting all services: $e');
      return [];
    }
  }

  /// Calculates recommendation scores for all services
  Future<List<Map<String, dynamic>>> _calculateRecommendationScores({
    required List<Map<String, dynamic>> allServices,
    required List<Map<String, dynamic>> bookingHistory,
    required List<Map<String, dynamic>> wishlist,
    required String customerId,
  }) async {
    // Calculate category preferences based on booking history
    final categoryPreferences = _calculateCategoryPreferences(bookingHistory);
    
    // Calculate service popularity scores
    final popularityScores = await _calculatePopularityScores();
    
    // Calculate recency boost for recently booked categories
    final recencyBoost = _calculateRecencyBoost(bookingHistory);
    
    // Score each service
    final scoredServices = <Map<String, dynamic>>[];
    
    for (final service in allServices) {
      double score = 0.0;
      
      // 1. Category preference score (40% weight)
      final categoryScore = categoryPreferences[service['category']] ?? 0.0;
      score += categoryScore * 0.4;
      
      // 2. Popularity score (30% weight)
      final popularityScore = popularityScores[service['id']] ?? 0.0;
      score += popularityScore * 0.3;
      
      // 3. Recency boost (20% weight)
      final recencyScore = recencyBoost[service['category']] ?? 0.0;
      score += recencyScore * 0.2;
      
      // 4. Wishlist boost (10% weight)
      final isInWishlist = wishlist.any((item) => item['serviceId'] == service['id']);
      if (isInWishlist) {
        score += 0.1;
      }
      
      scoredServices.add({
        ...service,
        'score': score,
        'recommendationReason': _getRecommendationReason(
          categoryScore: categoryScore,
          popularityScore: popularityScore,
          recencyScore: recencyScore,
          isInWishlist: isInWishlist,
        ),
      });
    }
    
    return scoredServices;
  }

  /// Calculates category preferences based on booking history
  Map<String, double> _calculateCategoryPreferences(List<Map<String, dynamic>> bookingHistory) {
    if (bookingHistory.isEmpty) {
      // Return equal preference for all categories if no booking history
      return {
        'COMMUNITY AND PUBLIC': 1.0,
        'CORPORATE & BUSINESS': 1.0,
        'EDUCATION & SCHOOL': 1.0,
        'ENTERTAINMENT & STAGES': 1.0,
        'PERSONAL & FAMILY': 1.0,
        'OTHERS & CUSTOM': 1.0,
      };
    }
    
    // Count bookings per category
    final categoryCount = <String, int>{};
    for (final booking in bookingHistory) {
      final category = booking['category'] as String? ?? 'OTHERS & CUSTOM';
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }
    
    // Convert to normalized preferences (0.0 to 1.0)
    final totalBookings = bookingHistory.length;
    final preferences = <String, double>{};
    
    for (final entry in categoryCount.entries) {
      preferences[entry.key] = entry.value / totalBookings;
    }
    
    return preferences;
  }

  /// Calculates service popularity based on total bookings
  Future<Map<String, double>> _calculatePopularityScores() async {
    // Get all bookings
    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('status', whereIn: ['confirmed', 'completed'])
        .get();
    
    // Count bookings per service
    final serviceBookingCount = <String, int>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final serviceId = data['serviceId'] as String?;
      if (serviceId != null) {
        serviceBookingCount[serviceId] = (serviceBookingCount[serviceId] ?? 0) + 1;
      }
    }
    
    // Find max booking count for normalization
    final maxBookings = serviceBookingCount.values.isEmpty 
        ? 1 
        : serviceBookingCount.values.reduce((a, b) => a > b ? a : b);
    
    // Convert to normalized popularity scores (0.0 to 1.0)
    final popularityScores = <String, double>{};
    for (final entry in serviceBookingCount.entries) {
      popularityScores[entry.key] = entry.value / maxBookings;
    }
    
    return popularityScores;
  }

  /// Calculates recency boost for recently booked categories
  Map<String, double> _calculateRecencyBoost(List<Map<String, dynamic>> bookingHistory) {
    if (bookingHistory.isEmpty) return {};
    
    // Sort by creation date (newest first)
    final sortedBookings = [...bookingHistory];
    sortedBookings.sort((a, b) {
      final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
      final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
      return bTime.compareTo(aTime);
    });
    
    // Give higher boost to recently booked categories
    final recencyBoost = <String, double>{};
    final now = DateTime.now();
    
    for (int i = 0; i < sortedBookings.length && i < 5; i++) {
      final booking = sortedBookings[i];
      final category = booking['category'] as String? ?? 'OTHERS & CUSTOM';
      final createdAt = (booking['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
      
      // Calculate days since booking (0-30 days = 1.0 boost, 30-60 days = 0.5 boost, etc.)
      final daysSince = now.difference(createdAt).inDays;
      final boost = (30 - (daysSince / 2)).clamp(0.0, 1.0) / 30.0;
      
      // Accumulate boost for category (most recent gets highest boost)
      if (!recencyBoost.containsKey(category) || recencyBoost[category]! < boost) {
        recencyBoost[category] = boost;
      }
    }
    
    return recencyBoost;
  }

  /// Generates a reason for why a service was recommended
  String _getRecommendationReason({
    required double categoryScore,
    required double popularityScore,
    required double recencyScore,
    required bool isInWishlist,
  }) {
    if (isInWishlist) {
      return 'Based on your wishlist';
    }
    
    if (categoryScore >= 0.5) {
      return 'Matches your preferred categories';
    }
    
    if (popularityScore >= 0.7) {
      return 'Popular with other customers';
    }
    
    if (recencyScore >= 0.5) {
      return 'Recently trending';
    }
    
    return 'You might like this';
  }
}
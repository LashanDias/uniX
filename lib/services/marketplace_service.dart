import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_models.dart';
import 'app_access_service.dart';
import 'auth_service.dart';

class MarketplaceService {
  static Stream<List<ProductItem>> watchProducts() => FirebaseFirestore.instance
      .collection('products')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return ProductItem(
            id: doc.id,
            title: data['title'] as String,
            category: data['category'] as String,
            price: (data['price'] as num).toDouble(),
            imageUrl: data['imageUrl'] as String? ?? '',
            sellerName: data['sellerName'] as String? ?? '',
            sellerId: data['sellerId'] as String? ?? '',
            rating: 0,
            reviewsCount: 0,
            description: data['description'] as String? ?? '',
          );
        }).toList(),
      );

  static Future<void> post({
    required String title,
    required String category,
    required double price,
    required String description,
    required String imageUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Please sign in to post an item.');
    await FirebaseFirestore.instance.collection('products').add({
      'title': title,
      'category': category,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'sellerId': user.uid,
      'sellerName': user.displayName ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteProduct(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Please sign in to remove this item.');
    }

    final doc = await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .get();
    final sellerId = doc.data()?['sellerId'] as String? ?? '';
    final isAdmin = AuthService.isCurrentUserAdmin();
    if (!AppAccessService.canManageOwnedResource(user.uid, sellerId, isAdmin: isAdmin)) {
      throw StateError('Only the item owner or an admin can remove this listing.');
    }

    await FirebaseFirestore.instance.collection('products').doc(productId).delete();
  }
}

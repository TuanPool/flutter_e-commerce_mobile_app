import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProposeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Ghi lại lịch sử xem sản phẩm của người dùng
  Future<void> logUserInteraction(String userId, String productId) async {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('viewed_products')
          .doc(productId)
          .set({
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Lỗi lưu lịch sử xem sản phẩm: $e");
    }
  }

  // Lấy danh sách 5 sản phẩm gần nhất mà user đã xem
  Future<List<Product>> getLastViewedProducts(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('viewed_products')
          .orderBy('timestamp', descending: true)
          .limit(5) // Lấy 5 sản phẩm gần nhất
          .get();

      // Chạy song song để giảm thời gian truy vấn Firestore
      List<Future<Product?>> futures = snapshot.docs.map((doc) async {
        var productDoc = await _firestore.collection('products').doc(doc.id).get();
        if (productDoc.exists) {
          return Product.fromMap(productDoc.data() as Map<String, dynamic>, productDoc.id);
        }
        return null;
      }).toList();

      List<Product> viewedProducts = (await Future.wait(futures)).whereType<Product>().toList();
      return viewedProducts;
    } catch (e) {
      print("Lỗi lấy sản phẩm gần đây: $e");
      return [];
    }
  }

  // Lấy danh sách sản phẩm đề xuất
  Future<List<Product>> getRecommendedProducts(String userId) async {
    try {
      List<Product> lastViewedProducts = await getLastViewedProducts(userId);
      if (lastViewedProducts.isEmpty) return [];

      // Lọc danh mục và hãng
      Set<String> categories = {};
      Set<String> stores = {};
      for (var product in lastViewedProducts) {
        categories.add(product.category);
        stores.add(product.store);
      }

      // Giới hạn danh sách tránh lỗi Firestore (max 10 phần tử trong whereIn)
      List<String> categoryList = categories.take(10).toList();
      List<String> storeList = stores.take(10).toList();

      // Lấy sản phẩm theo category
      Future<QuerySnapshot> categoryQuery = _firestore
          .collection('products')
          .where('category', whereIn: categoryList)
          .limit(10)
          .get();

      // Lấy sản phẩm theo store
      Future<QuerySnapshot> storeQuery = _firestore
          .collection('products')
          .where('store', whereIn: storeList)
          .limit(10)
          .get();

      // Chạy song song để tối ưu hiệu suất
      List<QuerySnapshot> results = await Future.wait([categoryQuery, storeQuery]);

      // Hợp nhất kết quả, loại bỏ trùng lặp và sản phẩm đã xem
      Set<String> viewedIds = lastViewedProducts.map((p) => p.id).toSet();
      Set<String> addedIds = {};

      List<Product> recommendedProducts = [];
      for (var result in results) {
        for (var doc in result.docs) {
          if (!viewedIds.contains(doc.id) && !addedIds.contains(doc.id)) {
            recommendedProducts.add(Product.fromMap(doc.data() as Map<String, dynamic>, doc.id));
            addedIds.add(doc.id);
          }
        }
      }

      return recommendedProducts;
    } catch (e) {
      print("Lỗi lấy sản phẩm đề xuất: $e");
      return [];
    }
  }
}

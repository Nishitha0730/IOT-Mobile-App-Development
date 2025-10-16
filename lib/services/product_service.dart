import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  static final ProductService instance = ProductService._();
  ProductService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add a new product
  Future<String> addProduct(Product product) async {
    final docRef = await _db.collection('products').add(product.toMap());
    return docRef.id;
  }

  // Update a product
  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    await _db.collection('products').doc(productId).update(data);
  }

  // Delete a product
  Future<void> deleteProduct(String productId) async {
    await _db.collection('products').doc(productId).delete();
  }

  // Get all products
  Future<List<Product>> getAllProducts() async {
    final snapshot = await _db.collection('products').get();
    return snapshot.docs
        .map((doc) => Product.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    final snapshot = await _db
        .collection('products')
        .where('category', isEqualTo: category)
        .get();
    return snapshot.docs
        .map((doc) => Product.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Stream all products (real-time)
  Stream<List<Product>> streamProducts() {
    return _db.collection('products').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Product.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Stream products by category (real-time)
  Stream<List<Product>> streamProductsByCategory(String category) {
    return _db
        .collection('products')
        .where('category', isEqualTo: category)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Product.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Search products by name
  Future<List<Product>> searchProducts(String query) async {
    final snapshot = await _db.collection('products').get();
    return snapshot.docs
        .map((doc) => Product.fromMap(doc.data(), doc.id))
        .where((product) =>
            product.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/link_item.dart';
import '../models/category.dart';

/// Service for Firestore database operations
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ====== Links ======

  /// Get user's links collection reference
  CollectionReference _userLinksCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('links');
  }

  /// Stream of user's links (ordered by most recent)
  Stream<List<LinkItem>> getUserLinks(String userId) {
    return _userLinksCollection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LinkItem.fromFirestore(doc))
            .toList());
  }

  /// Stream of user's favorite links
  Stream<List<LinkItem>> getFavoriteLinks(String userId) {
    return _userLinksCollection(userId)
        .where('favorite', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LinkItem.fromFirestore(doc))
            .toList());
  }

  /// Stream of links by category
  Stream<List<LinkItem>> getLinksByCategory(String userId, String categoryId) {
    return _userLinksCollection(userId)
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LinkItem.fromFirestore(doc))
            .toList());
  }

  /// Add a new link
  Future<void> addLink(String userId, LinkItem link) async {
    await _userLinksCollection(userId).add(link.toFirestore());
  }

  /// Update an existing link
  Future<void> updateLink(String userId, LinkItem link) async {
    await _userLinksCollection(userId).doc(link.id).update(link.toFirestore());
  }

  /// Delete a link
  Future<void> deleteLink(String userId, String linkId) async {
    await _userLinksCollection(userId).doc(linkId).delete();
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String userId, String linkId, bool favorite) async {
    await _userLinksCollection(userId).doc(linkId).update({'favorite': favorite});
  }

  // ====== Categories ======

  /// Get user's categories collection reference
  CollectionReference _userCategoriesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('categories');
  }

  /// Stream of user's categories
  Stream<List<Category>> getUserCategories(String userId) {
    return _userCategoriesCollection(userId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Category.fromFirestore(doc))
            .toList());
  }

  /// Add a new category
  Future<String> addCategory(String userId, String name) async {
    final docRef = await _userCategoriesCollection(userId).add({
      'name': name,
      'createdAt': Timestamp.now(),
    });
    return docRef.id;
  }

  /// Update category name
  Future<void> updateCategory(String userId, String categoryId, String name) async {
    await _userCategoriesCollection(userId).doc(categoryId).update({'name': name});
  }

  /// Delete a category
  Future<void> deleteCategory(String userId, String categoryId) async {
    // Remove category from links first
    final linksSnapshot = await _userLinksCollection(userId)
        .where('categoryId', isEqualTo: categoryId)
        .get();
    
    for (var doc in linksSnapshot.docs) {
      await doc.reference.update({'categoryId': null});
    }
    
    // Delete category
    await _userCategoriesCollection(userId).doc(categoryId).delete();
  }

  // ====== Notepad ======

  /// Get notepad content
  Future<String> getNotepad(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data()?['notepad'] ?? '';
  }

  /// Update notepad content
  Future<void> updateNotepad(String userId, String content) async {
    await _firestore.collection('users').doc(userId).set(
      {'notepad': content},
      SetOptions(merge: true),
    );
  }

  /// Stream of notepad content
  Stream<String> getNotepadStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data()?['notepad'] ?? '');
  }
}

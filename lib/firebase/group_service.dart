import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:split_wise/models/group.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new group
  Future<void> createGroup({
    required String name,
    required GroupType type,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('groups').add({
      'name': name,
      'type': groupTypeToString(type), // Convert enum to string
      'createdBy': user.uid,
      'members': [user.uid],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  String groupTypeToString(GroupType type) {
    return type.toString().split('.').last;
  }

  // Get all groups for current user
  Stream<List<Group>> getGroups() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return _firestore
        .collection('groups')
        .where('members', arrayContains: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Group.fromMap(doc.data(), doc.id))
        .toList());
  }

  // Add user to group
  Future<void> addUserToGroup(String groupId, String userId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([userId]),
    });
  }
}
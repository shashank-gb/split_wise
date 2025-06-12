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
      'members': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateGroup({
    required String groupId,
    required String name,
    required GroupType type,
    required List<String> members,
  }) async {
    await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
      'name': name,
      'type': type.toString().split('.').last,
      'members': members,
    });
  }

  Future<void> deleteGroup(String groupId) async {
    // Delete group and related expenses
    final batch = FirebaseFirestore.instance.batch();

    // Delete group
    batch.delete(FirebaseFirestore.instance.collection('groups').doc(groupId));

    // Delete related expenses
    final expenses = await FirebaseFirestore.instance
        .collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .get();

    for (var doc in expenses.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
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
        .where('createdBy', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Group.fromMap(doc.data(), doc.id))
        .toList());
  }

  // Fetch groups for the current user
  Stream<List<Map<String, dynamic>>> getUserGroups() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('groups')
        .where('members', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {
      'id': doc.id,
      'name': doc.data()['name'],
      ...doc.data(),
    })
        .toList());
  }

  // Add user to group
  Future<void> addUsersToGroup(String groupId, List<String> userIds) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Verify the current user has permission to add to this group
    final groupDoc = await _firestore.collection('groups').doc(groupId).get();
    if (!groupDoc.exists) throw Exception('Group does not exist');

    if ((groupDoc.data()?['createdBy'] as String) != user.uid) {
      throw Exception('You are not a member of this group');
    }

    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion(userIds),
    });
  }

  Future<String> getGroupShareCode(String groupId) async {
    final doc = await _firestore.collection('groups').doc(groupId).get();
    return doc.data()?['shareCode'] ?? groupId; // Fallback to groupId if no shareCode
  }

  // Get stream of members for a specific group by groupName
  Stream<List<String>> getGroupMembersByGroupName(String groupName) {
    return _firestore
        .collection('groups')
        .where('name', isEqualTo: groupName)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Group.fromMap(doc.data(), doc.id))
        .expand((group) => group.members)
        .toList());
  }

  // Get all members from all groups of current user (as friends)
  Future<List<String>> getAllMembersFromAllGroupsAsFriends() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final String currentUserId = currentUser.uid;
      final List<String> friends = [];

      // 1. Get all groups where current user is a member
      // todo: check the logic for point 1
      final groupsQuery = await _firestore
          .collection('groups')
          .where('createdBy', isEqualTo: currentUserId)
          .get();

      // 2. For each group, get all members
      for (final groupDoc in groupsQuery.docs) {
        final groupData = groupDoc.data();
        final List<dynamic> members = groupData['members'] ?? [];

        // 3. Add each member to friends list (if not current user and not already added)
        for (final memberId in members) {
          if (memberId != currentUserId && !friends.contains(memberId)) {
            friends.add(memberId as String);
          }
        }
      }

      return friends;
    } catch (e) {
      print('Error getting friends from groups: $e');
      return [];
    }
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:split_wise/models/expense.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Future<void> addExpense({
  //   required String description,
  //   required double amount,
  //   required DateTime date,
  //   required String paidBy,
  //   required bool splitEqually,
  //   required List<String> selectedFriends,
  //   required String? groupId,
  //   required String? groupName,
  // }) async {
  //   try {
  //     final user = _auth.currentUser;
  //     if (user == null) throw Exception('User not authenticated');
  //
  //     final expenseData = {
  //       'description': description,
  //       'amount': amount,
  //       'date': Timestamp.fromDate(date),
  //       'paidBy': paidBy,
  //       'splitEqually': splitEqually,
  //       'participants': splitEqually ? [] : selectedFriends,
  //       'createdBy': user.uid,
  //       'createdAt': FieldValue.serverTimestamp(),
  //       'groupId': groupId,
  //       'groupName': groupName,
  //       'settled': false,
  //     };
  //
  //     // Add to expenses collection
  //     final expenseRef = await _firestore.collection('expenses').add(expenseData);
  //
  //     // Update the group's last activity if it's a group expense
  //     if (groupId != null) {
  //       await _firestore.collection('groups').doc(groupId).update({
  //         'lastActivity': FieldValue.serverTimestamp(),
  //         'totalExpenses': FieldValue.increment(amount),
  //       });
  //     }
  //
  //     // Create settlement records for each participant
  //     await _createSettlementRecords(
  //       expenseId: expenseRef.id,
  //       paidBy: paidBy,
  //       amount: amount,
  //       participants: splitEqually ? await _getGroupMembers(groupId) : selectedFriends,
  //       totalParticipants: splitEqually
  //           ? (await _getGroupMembers(groupId)).length + 1 // +1 for payer
  //           : selectedFriends.length + 1,
  //     );
  //   } catch (e) {
  //     throw Exception('Failed to add expense: ${e.toString()}');
  //   }
  // }

  Future<List<String>> _getGroupMembers(String? groupId) async {
    if (groupId == null) return [];
    final groupDoc = await _firestore.collection('groups').doc(groupId).get();
    return List<String>.from(groupDoc.data()?['members'] ?? []);
  }

  Future<void> _createSettlementRecords({
    required String expenseId,
    required String paidBy,
    required double amount,
    required List<String> participants,
    required int totalParticipants,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();
    final splitAmount = amount / totalParticipants;

    for (final participant in participants) {
      if (participant == paidBy) continue;

      final settlementRef = _firestore
          .collection('users')
          .doc(participant)
          .collection('settlements')
          .doc(expenseId);

      batch.set(settlementRef, {
        'expenseId': expenseId,
        'amount': splitAmount,
        'paidBy': paidBy,
        'createdAt': FieldValue.serverTimestamp(),
        'settled': false,
      });
    }

    await batch.commit();
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

  // Fetch friends for the current user
  Stream<List<String>> getUserFriends() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) => List<String>.from(snapshot.data()?['friends'] ?? []));
  }
}
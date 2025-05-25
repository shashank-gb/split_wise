import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:split_wise/models/expense.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Expense>> getExpensesByGroup(String groupName) {
    return _firestore
        .collection('expenses')
        .where('groupName', isEqualTo: groupName)
        .orderBy('date', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Expense.fromMap(doc.data(), doc.id))
        .toList());
  }

  Future<void> addExpense({
    required String description,
    required double amount,
    required DateTime date,
    required String paidBy,
    required bool splitEqually,
    required List<String> selectedFriends,
    required String? groupId,
    required String? groupName,
  }) async {
    try {
      await _firestore.collection('expenses').add({
        'description': description,
        'amount': amount,
        'date': date.millisecondsSinceEpoch,
        'paidBy': paidBy,
        'splitEqually': splitEqually,
        'selectedFriends': selectedFriends,
        'groupId': groupId,
        'groupName': groupName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add expense: $e');
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    await _firestore.collection('expenses').doc(expenseId).delete();
  }
}
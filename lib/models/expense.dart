class Expense {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String paidBy;
  final bool splitEqually;
  final List<String> selectedFriends;
  final String? groupId;
  final String? groupName;

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.paidBy,
    required this.splitEqually,
    required this.selectedFriends,
    this.groupId,
    this.groupName,
  });

  factory Expense.fromMap(Map<String, dynamic> data, String id) {
    return Expense(
      id: id,
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(data['date']),
      paidBy: data['paidBy'] ?? '',
      splitEqually: data['splitEqually'] ?? false,
      selectedFriends: List<String>.from(data['selectedFriends'] ?? []),
      groupId: data['groupId'],
      groupName: data['groupName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'paidBy': paidBy,
      'splitEqually': splitEqually,
      'selectedFriends': selectedFriends,
      'groupId': groupId,
      'groupName': groupName,
    };
  }
}
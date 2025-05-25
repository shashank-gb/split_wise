import 'package:flutter/material.dart';
import 'package:split_wise/models/friend.dart';

class FriendExpensesScreen extends StatelessWidget {
  final Friend friend;

  const FriendExpensesScreen({super.key, required this.friend});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(friend.name),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(friend.imageUrl as String),
            ),
            const SizedBox(height: 20),
            Text(
              friend.amountOwed == 0
                  ? 'Settled up'
                  : '${friend.owesYou ? 'You owe' : 'Owes you'} \$${friend.amountOwed.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24,
                color: friend.amountOwed == 0
                    ? Colors.grey
                    : friend.owesYou
                    ? Colors.red
                    : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Expense history would appear here'),
          ],
        ),
      ),
    );
  }
}
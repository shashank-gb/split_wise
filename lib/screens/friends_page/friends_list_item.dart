import 'package:flutter/material.dart';
import 'package:split_wise/models/friend.dart';

class FriendListItem extends StatelessWidget {
  final Friend friend;
  final VoidCallback onTap;

  const FriendListItem({
    super.key,
    required this.friend,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: friend.imageUrl != null
          ? CircleAvatar(
        backgroundImage: MemoryImage(friend.imageUrl!),
      )
          : CircleAvatar(
        child: Text(friend.name.isNotEmpty
            ? friend.name[0].toUpperCase()
            : '?'),
      ),
      title: Text(friend.name),
      subtitle: Text(friend.email),
      trailing: Text(
        friend.amountOwed == 0
            ? 'Settled up'
            : '${friend.owesYou ? 'You owe' : 'Owes you'} \$${friend.amountOwed.toStringAsFixed(2)}',
        style: TextStyle(
          color: friend.amountOwed == 0
              ? Colors.grey
              : friend.owesYou
              ? Colors.red
              : Colors.green,
        ),
      ),
      onTap: onTap,
    );
  }
}
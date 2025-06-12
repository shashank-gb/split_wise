import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:split_wise/models/friend.dart';
import 'package:split_wise/screens/groups_page/add_expense_screen.dart';
import 'package:split_wise/screens/friends_page/contacts_screen.dart';
import 'package:split_wise/screens/friends_page/friends_expenses_screen.dart';
import 'package:split_wise/screens/friends_page/friends_list_item.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  // Sample list of friends
  final List<Friend> friends = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
      ),
      body: ListView.builder(
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friend = friends[index];
          return FriendListItem(
            friend: friend,
            onTap: () => _navigateToFriendExpenses(friend),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFriendFromContacts,
        tooltip: 'Add expense',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addFriendFromContacts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactsScreen(
          onContactSelected: _addSelectedContact,
        ),
      ),
    );
  }

  Future<void> _addSelectedContact(Contact contact) async {
    try {
      // Load full contact details only when selected
      final fullContact = await FlutterContacts.getContact(contact.id,
        withProperties: true,
        withPhoto: true,
      );

      if (fullContact == null || !mounted) return;

      setState(() {
        friends.add(Friend(
          name: fullContact.displayName,
          email: fullContact.emails.isNotEmpty
              ? fullContact.emails.first.address
              : 'No email',
          amountOwed: 0.0,
          owesYou: true,
          imageUrl: fullContact.photoOrThumbnail,
        ));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${fullContact.displayName} as friend')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding contact: $e')),
      );
    }
  }
  void _navigateToFriendExpenses(Friend friend) {
    // Implement navigation to friend's expenses
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendExpensesScreen(friend: friend),
      ),
    );
  }
}

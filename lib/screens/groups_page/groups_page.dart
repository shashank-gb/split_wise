import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:split_wise/firebase/group_service.dart';
import 'package:split_wise/models/group.dart';
import 'package:split_wise/screens/groups_page/create_group_screen.dart';
import 'package:split_wise/screens/groups_page/group_details_screen.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {

  @override
  Widget build(BuildContext context) {
    final groupService = Provider.of<GroupService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
        actions: [
          /*IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
            ),
          ),*/
        ],
      ),
      body: StreamBuilder<List<Group>>(
        stream: groupService.getGroups(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final groups = snapshot.data ?? [];

          if (groups.isEmpty) {
            return const Center(child: Text('No groups yet'));
          }

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return _buildGroupTile(group);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
          );
        },
        tooltip: 'Add expense',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGroupTile(Group group) {
    return Dismissible(
      key: Key(group.id),
      direction: DismissDirection.endToStart, // Only allow swipe from right to left
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        // Show confirmation dialog
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Confirm"),
              content: const Text("Are you sure you want to delete this group?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("CANCEL"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("DELETE", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        try {
          final groupService = Provider.of<GroupService>(context, listen: false);
          await groupService.deleteGroup(group.id); // Call your delete function
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${group.name} deleted')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: ${e.toString()}')),
          );
        }
      },
      child: ListTile(
        leading: _getGroupIcon(group.type),
        title: Text(group.name),
        subtitle: Text(
          '${group.members.length + 1} members • ${_formatDate(group.createdAt)}',
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupDetailsScreen(group: group),
          ),
        ),
      ),
    );
  }

  Icon _getGroupIcon(GroupType type) {
    switch (type) {
      case GroupType.trip:
        return const Icon(Icons.flight, color: Colors.blue);
      case GroupType.home:
        return const Icon(Icons.home, color: Colors.green);
      case GroupType.couple:
        return const Icon(Icons.favorite, color: Colors.pink);
      default:
        return const Icon(Icons.group, color: Colors.grey);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
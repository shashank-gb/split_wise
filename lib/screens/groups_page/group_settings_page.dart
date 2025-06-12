import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:split_wise/firebase/group_service.dart';
import 'package:split_wise/screens/groups_page/add_friends_to_group.dart';

import 'package:split_wise/models/group.dart';

class GroupSettingsPage extends StatefulWidget {
  final Group group;

  const GroupSettingsPage({super.key, required this.group});

  @override
  State<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends State<GroupSettingsPage> {
  late TextEditingController _nameController;
  late GroupType _selectedType;
  late List<String> _members;
  final TextEditingController _newMemberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _selectedType = widget.group.type;
    _members = List.from(widget.group.members);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newMemberController.dispose();
    super.dispose();
  }

  Future<void> _updateGroup() async {
    try {
      final groupService = Provider.of<GroupService>(context, listen: false);
      await groupService.updateGroup(
        groupId: widget.group.id,
        name: _nameController.text,
        type: _selectedType,
        members: _members,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group updated successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating group: $e')));
      }
    }
  }

  Future<void> _deleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text('Are you sure you want to delete this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final groupService = Provider.of<GroupService>(context, listen: false);
        await groupService.deleteGroup(widget.group.id);
        if (mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting group: $e')));
        }
      }
    }
  }

  Future<void> _removeMember(String userId) async {
    setState(() {
      _members.remove(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Settings'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _updateGroup),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Name Field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Group Type Selection
            const Text(
              'Group Type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8,
              children: [
                _buildTypeChip(GroupType.trip, 'Trip', Icons.flight),
                _buildTypeChip(GroupType.home, 'Home', Icons.home),
                _buildTypeChip(GroupType.couple, 'Couple', Icons.favorite),
                _buildTypeChip(GroupType.other, 'Other', Icons.group),
              ],
            ),
            const SizedBox(height: 20),

            // Members Section
            const Text(
              'Members',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Add Member
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddFriendsToGroupScreen(groupId: widget.group.id),
                  ),
                );
              },
              child: Row(
                children: [
                  Expanded(child: ListTile(title: const Text('Add members'))),
                  Icon(Icons.add),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Members List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final memberId = _members[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(_members[index][0])),
                  title: Text(_members[index]),
                  trailing:
                      memberId != FirebaseAuth.instance.currentUser?.displayName
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _removeMember(memberId),
                        )
                      : null,
                );
              },
            ),
            const SizedBox(height: 20),

            // Delete Group Button
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: _deleteGroup,
                child: const Text('Delete Group'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(GroupType value, String label, IconData icon) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 18), const SizedBox(width: 5), Text(label)],
      ),
      selected: _selectedType == value,
      onSelected: (selected) {
        setState(() => _selectedType = selected ? value : GroupType.other);
      },
    );
  }
}

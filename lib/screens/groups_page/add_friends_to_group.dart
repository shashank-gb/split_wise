import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:split_wise/auth_services.dart';
import 'package:split_wise/firebase/group_service.dart';
import 'package:split_wise/screens/groups_page/groups_page.dart';

class AddFriendsToGroupScreen extends StatefulWidget {
  final String groupId;
  final List<String>? friends;

  const AddFriendsToGroupScreen({
    super.key,
    required this.groupId,
    this.friends,
  });

  @override
  State<AddFriendsToGroupScreen> createState() =>
      _AddFriendsToGroupScreenState();
}

class _AddFriendsToGroupScreenState extends State<AddFriendsToGroupScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _selectedFriends = [];
  List<String> _allFriends = [];
  List<String> _filteredFriends = [];
  String _currentUserName = '';

  final GroupService _groupService = GroupService();

  @override
  void initState() {
    super.initState();
    _currentUserName = FirebaseAuth.instance.currentUser?.displayName ?? '';
    _selectedFriends.add(_currentUserName); // Add current user by default
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final friends = await _groupService.getAllMembersFromAllGroupsAsFriends();
      setState(() {
        _allFriends = friends;
        _filteredFriends = _allFriends;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load friends: $e')));
    }
  }

  Future<void> _saveFriendsToGroup() async {
    try {
      // Remove current user from the list to add (since they're already in the group)
      // final friendsToAdd =

      if (_selectedFriends.isNotEmpty) {
        await _groupService.addUsersToGroup(widget.groupId, _selectedFriends);
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GroupsPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add friends: $e')));
    }
  }

  void _searchFriends(String query) {
    setState(() {
      _filteredFriends = _allFriends.where((friend) {
        return friend.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Friends'),
        actions: [
          TextButton(
            onPressed: _saveFriendsToGroup,
            child: const Text(
              'Done',
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search friends...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onChanged: _searchFriends,
            ),
          ),

          // Selected Friends Horizontal List
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedFriends.length,
              itemBuilder: (context, index) {
                final friendName = _selectedFriends[index];
                final isCurrentUser = friendName == _currentUserName;
                final displayName = isCurrentUser
                    ? AuthService().currentUser?.displayName ?? 'You'
                    : friendName; // In a real app, you'd fetch the user's name

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        child: Text(displayName[0].toUpperCase()),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 60,
                        child: Text(
                          displayName,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Friends List
          Expanded(
            child: _searchController.text.isEmpty
                ? ListView.builder(
              itemCount: _filteredFriends.length,
              itemBuilder: (context, index) {
                final friend = _filteredFriends[index];
                final isSelected = _selectedFriends.contains(friend);

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(friend[0]),
                  ),
                  title: Text(friend),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedFriends.remove(friend);
                      } else {
                        _selectedFriends.add(friend);
                      }
                    });
                  },
                );
              },
            )
                : _filteredFriends.isEmpty
                ? ListTile(
              leading: const Icon(Icons.person_add),
              title: Text('Add "${_searchController.text}" to this group'),
              onTap: () {
                // Add the searched text as a new friend
                setState(() {
                  _selectedFriends.add(_searchController.text);
                  _searchController.clear();
                  _searchFriends('');
                });
              },
            )
                : ListView.builder(
              itemCount: _filteredFriends.length,
              itemBuilder: (context, index) {
                final friend = _filteredFriends[index];
                final isSelected = _selectedFriends.contains(friend);

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(friend[0]),
                  ),
                  title: Text(friend),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedFriends.remove(friend);
                      } else {
                        _selectedFriends.add(friend);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

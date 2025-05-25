import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:split_wise/firebase/group_service.dart';
import 'package:split_wise/models/group.dart';
import 'package:split_wise/screens/groups_page/group_type_button.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  GroupType _selectedType = GroupType.other;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Group Name'),
                validator: (value) =>
                value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              const Text('Group Type'),
              Wrap(
                spacing: 8,
                children: [
                  _buildTypeChip(GroupType.trip, 'Trip', Icons.flight),
                  _buildTypeChip(GroupType.home, 'Home', Icons.home),
                  _buildTypeChip(GroupType.couple, 'Couple', Icons.favorite),
                  _buildTypeChip(GroupType.other, 'Other', Icons.group),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _createGroup,
                child: const Text('Create Group'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createGroup() async {
    if (_formKey.currentState!.validate()) {
      try {
        final groupService = Provider.of<GroupService>(context, listen: false);
        await groupService.createGroup(
          name: _nameController.text,
          type: _selectedType,
        );
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating group: $e')),
          );
        }
      }
    }
  }

  Widget _buildTypeChip(GroupType value, String label, IconData icon) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 5),
          Text(label),
        ],
      ),
      selected: _selectedType == value,
      onSelected: (selected) {
        setState(() => _selectedType = selected ? value : GroupType.other);
      },
    );
  }
}


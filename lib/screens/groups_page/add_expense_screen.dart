import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:split_wise/auth_services.dart';
import 'package:split_wise/firebase/expense_service.dart';
import 'package:split_wise/firebase/group_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const AddExpenseScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _paidByController = TextEditingController();
  final List<String> _friendsInThisGroup = List.empty(growable: true);
  late Stream<List<String>> _groupFriendsStream = Stream.empty(broadcast: true);

  bool _splitEqually = true;
  List<String> _selectedFriends = [];
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('MMM dd, yyyy').format(_selectedDate);
    _paidByController.text = 'You';
  }

  @override
  Widget build(BuildContext context) {
    final groupService = Provider.of<GroupService>(context);
    setState(() {
      _groupFriendsStream = groupService.getGroupMembersByGroupName(widget.groupName);
      _groupFriendsStream.listen((friends) {
        _friendsInThisGroup.addAll(friends);
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add expense'),
        actions: [
          _isSubmitting
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.check),
            onPressed: _createExpense,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'With you and ${widget.groupName}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                hintText: 'What was this for?',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                hintText: '0.00',
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<String>>(
              // stream: friendService.getUserFriends(),
              stream: _groupFriendsStream,
              builder: (context, snapshot) {
                final friends = snapshot.data ?? [];
                return TextFormField(
                  controller: _paidByController,
                  decoration: const InputDecoration(
                    labelText: 'Paid by',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final selected = await showModalBottomSheet<String>(
                      context: context,
                      builder: (context) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Who paid?',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ListTile(
                              title: const Text('You'),
                              onTap: () => Navigator.pop(context, 'You'),
                            ),
                            ...friends.map((friend) {
                              return ListTile(
                                title: Text(friend),
                                onTap: () => Navigator.pop(context, friend),
                              );
                            }),
                          ],
                        );
                      },
                    );
                    if (selected != null) {
                      setState(() {
                        _paidByController.text = selected;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select who paid';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Split equally',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: _splitEqually,
                  onChanged: (value) {
                    setState(() {
                      _splitEqually = value;
                      if (value) {
                        _selectedFriends.clear();
                      }
                    });
                  },
                ),
              ],
            ),
            if (!_splitEqually)
              StreamBuilder<List<String>>(
                stream: _groupFriendsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }

                  final friends = snapshot.data ?? [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'Select friends to split with:',
                        style: TextStyle(fontSize: 14),
                      ),
                      ...friends.map((friend) {
                        return CheckboxListTile(
                          title: Text(friend),
                          value: _selectedFriends.contains(friend),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedFriends.add(friend);
                              } else {
                                _selectedFriends.remove(friend);
                              }
                            });
                          },
                        );
                      }),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('MMM dd, yyyy').format(picked);
      });
    }
  }

  Future<void> _createExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    print(_friendsInThisGroup.toString() + "-----------------------");

    try {
      final expenseService = Provider.of<ExpenseService>(context, listen: false);

      await expenseService.addExpense(
        description: _descriptionController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        paidBy: _paidByController.text == "You" ? AuthService().currentUser!.displayName! : _paidByController.text,
        splitEqually: _splitEqually,
        selectedFriends: _splitEqually ? _friendsInThisGroup.toSet().toList() : _selectedFriends,
        groupId: widget.groupId,
        groupName: widget.groupName,
      );

      Navigator.pop(context, true); // Return success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add expense: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

}
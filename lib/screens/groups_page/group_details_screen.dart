import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:split_wise/firebase/expense_service.dart';
import 'package:split_wise/models/expense.dart';
import 'package:split_wise/models/group.dart';
import 'package:split_wise/screens/add_expense_screen.dart';
import 'package:split_wise/screens/home_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  final Group group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final expenseService = Provider.of<ExpenseService>(context, listen: false);

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (!didPop) {
          // Handle the back action manually
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.group.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // Navigate to settings page
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Horizontal scrollable buttons
            _buildActionButtons(),
            // Expenses list
            Expanded(child: _buildExpensesList(expenseService)),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddExpenseScreen(
                  isFromGroup: true,
                  groupName: widget.group.name,
                ),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildActionButton("Settle Up", 0, Color(0xFF2196F3)),
          _buildActionButton("Balances", 1, Color(0xFF424242)),
          _buildActionButton("Export", 3, Color(0xFF424242)),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, int index, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpensesList(ExpenseService expenseService) {
    return StreamBuilder<List<Expense>>(
      stream: expenseService.getExpensesByGroup(widget.group.name),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading expenses'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final expenses = snapshot.data ?? [];

        if (expenses.isEmpty) {
          return Center(child: const Text('No Expenses'));
        }

        return ListView.builder(
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            return _buildExpenseItem(expense, expenseService);
          },
        );
      },
    );
  }

  Widget _buildExpenseItem(Expense expense, ExpenseService expenseService) {
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Expense'),
            content: const Text(
              'Are you sure you want to delete this expense?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => expenseService.deleteExpense(expense.id),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: const Icon(Icons.receipt, color: Colors.green),
          title: Text(expense.description),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Paid by ${expense.paidBy}'),
              Text(
                DateFormat('MMM dd, yyyy').format(expense.date),
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          trailing: Text(
            '\$${expense.amount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          onTap: () => _showExpenseDetails(context, expense),
        ),
      ),
    );
  }

  Future<void> _showAddExpenseDialog(
    BuildContext context,
    ExpenseService expenseService,
  ) async {
    final formKey = GlobalKey<FormState>();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool splitEqually = true;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Expense'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Required';
                    if (double.tryParse(value!) == null)
                      return 'Invalid amount';
                    return null;
                  },
                ),
                ListTile(
                  title: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      selectedDate = date;
                    }
                  },
                ),
                SwitchListTile(
                  title: const Text('Split equally'),
                  value: splitEqually,
                  onChanged: (value) => splitEqually = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                try {
                  await expenseService.addExpense(
                    description: descriptionController.text,
                    amount: double.parse(amountController.text),
                    date: selectedDate,
                    paidBy: 'You',
                    // Replace with actual user
                    splitEqually: splitEqually,
                    selectedFriends: [],
                    // Add friend selection logic
                    groupId: widget.group.name,
                    groupName: widget.group.name,
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showExpenseDetails(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(expense.description),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: \$${expense.amount.toStringAsFixed(2)}'),
            Text('Paid by: ${expense.paidBy}'),
            Text('Date: ${DateFormat('MMM dd, yyyy').format(expense.date)}'),
            Text('Split equally: ${expense.splitEqually ? 'Yes' : 'No'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

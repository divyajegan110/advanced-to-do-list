import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: unused_import
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(TodoApp());
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TodoListModel()..loadItems(),
      child: MaterialApp(
        title: 'D-List',
        theme: ThemeData(
          primarySwatch: Colors.yellow,
          scaffoldBackgroundColor: Colors.yellow[50], // Set the background color here
        ),
        debugShowCheckedModeBanner: false,
        home: TodoListScreen(),
      ),
    );

  }
}

class TodoListModel extends ChangeNotifier {
  List<TodoItem> _items = [];

  List<TodoItem> get items => _items;

  TodoListModel() {
    _startTimer();
  }

  void _startTimer() {
  }

  void addItem(String title, String category, DateTime? dueDate, TimeOfDay? dueTime) {
    _items.add(TodoItem(title: title, category: category, dueDate: dueDate, dueTime: dueTime));
    saveItems();
    notifyListeners();
  }

  void removeItem(TodoItem item) {
    _items.remove(item);
    saveItems();
    notifyListeners();
  }

  void toggleItemCompletion(TodoItem item) {
    item.isCompleted = !item.isCompleted;
    saveItems();
    notifyListeners();
  }

  void toggleItemImportance(TodoItem item) {
    item.isImportant = !item.isImportant;
    saveItems();
    notifyListeners();
  }

  void editItem(TodoItem item, String newTitle, String newCategory, DateTime? newDueDate, TimeOfDay? newDueTime) {
    item.title = newTitle;
    item.category = newCategory;
    item.dueDate = newDueDate;
    item.dueTime = newDueTime;
    saveItems();
    notifyListeners();
  }

  void sortItems() {
    _items.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    notifyListeners();
  }

  void clearItems() {
    _items.clear();
    saveItems();
    notifyListeners();
  }

  void loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final savedItems = prefs.getStringList('todoItems') ?? [];
    _items = savedItems.map((item) => TodoItem.fromJson(item)).toList();
    notifyListeners();
  }

  void saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    final savedItems = _items.map((item) => item.toJson()).toList();
    prefs.setStringList('todoItems', savedItems);
  }
}

class TodoItem {
  String title;
  bool isCompleted;
  bool isImportant;
  String category;
  DateTime? dueDate;
  TimeOfDay? dueTime;

  TodoItem({
    required this.title,
    this.isCompleted = false,
    this.isImportant = false,
    this.category = 'General',
    this.dueDate,
    this.dueTime,
  });

  String toJson() {
    return '$title|$isCompleted|$isImportant|$category|${dueDate?.toIso8601String() ?? ''}|${dueTime?.format(const Duration() as BuildContext) ?? ''}';
  }

  static TodoItem fromJson(String json) {
    final parts = json.split('|');
    return TodoItem(
      title: parts[0],
      isCompleted: parts[1] == 'true',
      isImportant: parts[2] == 'true',
      category: parts[3],
      dueDate: parts[4].isEmpty ? null : DateTime.parse(parts[4]),
      dueTime: parts[5].isEmpty ? null : TimeOfDay.fromDateTime(DateTime.parse(parts[4] + 'T' + parts[5])),
    );
  }

  bool isPastDue() {
    if (dueDate == null || dueTime == null) return false;
    final now = DateTime.now();
    final dueDateTime = DateTime(
      dueDate!.year,
      dueDate!.month,
      dueDate!.day,
      dueTime!.hour,
      dueTime!.minute,
    );
    return now.isAfter(dueDateTime);
  }
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _category = 'General';
  DateTime? _dueDate;
  TimeOfDay? _dueTime;

  @override
  Widget build(BuildContext context) {
    final todoList = Provider.of<TodoListModel>(context);
    final filteredItems = todoList.items
        .where((item) => item.title.toLowerCase().contains(_searchController.text.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to D-List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_by_alpha),
            onPressed: () {
              todoList.sortItems();
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              todoList.clearItems();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Enter new task',
                    ),
                  ),
                ),
                DropdownButton<String>(
                  value: _category,
                  items: <String>['General', 'Work', 'Personal'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _category = newValue!;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    _dueDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () async {
                    _dueTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      todoList.addItem(_controller.text, _category, _dueDate, _dueTime);
                      _controller.clear();
                      setState(() {
                        _category = 'General';
                        _dueDate = null;
                        _dueTime = null;
                      });
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search tasks',
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return ListTile(
                  title: Text(
                    item.title,
                    style: TextStyle(
                      decoration: item.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: item.isPastDue() ? Colors.red : item.isImportant ? Colors.red : Colors.black,
                    ),
                  ),
                  subtitle: Text('${item.category} - Due: ${item.dueDate?.toLocal().toShortDateString() ?? 'None'} ${item.dueTime != null ? '- ${item.dueTime!.format(context)}' : ''}'),
                  leading: Checkbox(
                    value: item.isCompleted,
                    onChanged: (bool? value) {
                      todoList.toggleItemCompletion(item);
                    },
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          item.isImportant ? Icons.star : Icons.star_border,
                          color: item.isImportant ? Colors.yellow[700] : null,
                        ),
                        onPressed: () {
                          todoList.toggleItemImportance(item);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showEditDialog(context, todoList, item);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          todoList.removeItem(item);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, TodoListModel todoList, TodoItem item) {
    final TextEditingController editController = TextEditingController(text: item.title);
    String editCategory = item.category;
    DateTime? editDueDate = item.dueDate;
    TimeOfDay? editDueTime = item.dueTime;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Alter Task Detail'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editController,
                decoration: const InputDecoration(
                  hintText: 'Edit task title...',
                ),
              ),
              DropdownButton<String>(
                value: editCategory,
                items: <String>['General', 'Work', 'Personal'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  editCategory = newValue!;
                },
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  editDueDate = await showDatePicker(
                    context: context,
                    initialDate: editDueDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: () async {
                  editDueTime = await showTimePicker(
                    context: context,
                    initialTime: editDueTime ?? TimeOfDay.now(),
                  );
                },
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (editController.text.isNotEmpty) {
                  todoList.editItem(item, editController.text, editCategory, editDueDate, editDueTime);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Done!'),
            ),
          ],
        );
      },
    );
  }
}

extension DateTimeExtension on DateTime {
  String toShortDateString() {
    return "$day/$month/$year";
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// DATA_MODEL
/// Represents a single task item.
class Task {
  final String id;
  final String title;
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  /// Creates a copy of this Task but with the given fields replaced with the new values.
  Task copyWith({
    String? id,
    String? title,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// TaskProvider manages the state of the tasks list using ChangeNotifier.
class TaskProvider extends ChangeNotifier {
  final List<Task> _tasks;

  /// Initializes the task list with some sample data.
  TaskProvider()
      : _tasks = [
          Task(id: '1', title: 'Buy groceries', isCompleted: false),
          Task(id: '2', title: 'Finish Flutter project', isCompleted: true),
          Task(id: '3', title: 'Call mom', isCompleted: false),
          Task(id: '4', title: 'Go for a run', isCompleted: false),
        ];

  /// Returns an unmodifiable view of the tasks list.
  List<Task> get tasks => List.unmodifiable(_tasks);

  /// Adds a new task to the list.
  void addTask(String title) {
    if (title.trim().isEmpty) return;
    _tasks.add(Task(id: DateTime.now().toIso8601String(), title: title.trim()));
    notifyListeners();
  }

  /// Toggles the completion status of a task by its ID.
  void toggleTaskCompletion(String taskId) {
    final int index = _tasks.indexWhere((Task task) => task.id == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(isCompleted: !_tasks[index].isCompleted);
      notifyListeners();
    }
  }

  /// Deletes a task by its ID.
  void deleteTask(String taskId) {
    _tasks.removeWhere((Task task) => task.id == taskId);
    notifyListeners();
  }
}

void main() {
  runApp(const TaskApp());
}

class TaskApp extends StatelessWidget {
  const TaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TaskProvider>(
      create: (BuildContext context) => TaskProvider(),
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Task Manager',
          theme: ThemeData(
            primarySwatch: Colors.blueGrey,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}

/// HomeScreen manages the overall layout with a sidebar (Drawer), header (AppBar),
/// main content, and navigational footer (BottomNavigationBar).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // State for the selected tab in BottomNavigationBar

  // List of widgets to display in the main content area
  static final List<Widget> _widgetOptions = <Widget>[
    const TaskListContent(), // Content for the Tasks tab
    const SettingsScreen(), // Placeholder content for the Settings tab
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'), // Header title
      ),
      drawer: Drawer(
        // Sidebar content
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Text(
                'Navigation',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.task),
              title: const Text('Tasks'),
              selected: _selectedIndex == 0,
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context); // Close the drawer after selection
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              selected: _selectedIndex == 1,
              onTap: () {
                _onItemTapped(1);
                Navigator.pop(context); // Close the drawer after selection
              },
            ),
          ],
        ),
      ),
      body: _widgetOptions.elementAt(_selectedIndex), // Main content area
      bottomNavigationBar: BottomNavigationBar(
        // Navigational footer
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.task),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 0 // Show FAB only on the Tasks screen
          ? FloatingActionButton(
              onPressed: () => _showAddTaskDialog(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  /// Displays a dialog to add a new task.
  Future<void> _showAddTaskDialog(BuildContext context) async {
    final TextEditingController taskController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add New Task'),
          content: TextField(
            controller: taskController,
            decoration: const InputDecoration(hintText: 'Enter task title'),
            autofocus: true,
            onSubmitted: (String value) {
              if (value.trim().isNotEmpty) {
                Provider.of<TaskProvider>(dialogContext, listen: false).addTask(value);
                Navigator.of(dialogContext).pop();
              }
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (taskController.text.trim().isNotEmpty) {
                  Provider.of<TaskProvider>(dialogContext, listen: false).addTask(taskController.text);
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    taskController.dispose();
  }
}

/// TaskListContent displays the list of tasks. It is designed to be a component
/// within a larger screen structure, without its own Scaffold.
class TaskListContent extends StatelessWidget {
  const TaskListContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (BuildContext context, TaskProvider taskProvider, Widget? child) {
        if (taskProvider.tasks.isEmpty) {
          return const Center(
            child: Text(
              'No tasks yet! Add one using the + button.',
              style: TextStyle(fontSize: 16.0, color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          itemCount: taskProvider.tasks.length,
          itemBuilder: (BuildContext context, int index) {
            final Task task = taskProvider.tasks[index];
            return Dismissible(
              key: ValueKey<String>(task.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (DismissDirection direction) {
                taskProvider.deleteTask(task.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Task "${task.title}" deleted')),
                );
              },
              child: Card(
                elevation: 2.0,
                margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                child: ListTile(
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                      color: task.isCompleted ? Colors.grey : Colors.black,
                    ),
                  ),
                  leading: Checkbox(
                    value: task.isCompleted,
                    onChanged: (bool? newValue) {
                      if (newValue != null) {
                        taskProvider.toggleTaskCompletion(task.id);
                      }
                    },
                  ),
                  trailing: task.isCompleted ? const Icon(Icons.check_circle, color: Colors.green) : null,
                  onTap: () {
                    taskProvider.toggleTaskCompletion(task.id);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// SettingsScreen is a placeholder widget for the settings content.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.settings, size: 80.0, color: Colors.grey),
          SizedBox(height: 16.0),
          Text(
            'Settings Content Goes Here',
            style: TextStyle(fontSize: 20.0, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
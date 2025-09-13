import 'package:flutter/material.dart';
import 'dart:convert'; //for jsonEncoded/jsonDecode
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool("isDarkMode") ?? false;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _toggleTheme() async{
    final prefs = await SharedPreferences.getInstance();
    final isDark = _themeMode == ThemeMode.dark;
    await prefs.setBool("isDarkMode", !isDark);
    setState(() {
      _themeMode = !isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'To-do App',
      themeMode: _themeMode,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.light,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 18),
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.dark,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 18),
        ),
      ),
      home: TodoPage(onToggleTheme: _toggleTheme, themeMode: _themeMode),
    );
  }
}

// A Task model (hold text + done state)
class Task{
  String title;
  bool isDone;
  Task({required this.title, this.isDone = false});

  //convert Task -> Map (for JSON)
  Map<String, dynamic> toMap(){
    return {'title': title, 'isDone': isDone};
  }

  //convert Map -> Task
  factory Task.fromMap(Map<String, dynamic> map){
    return Task(
      title: map['title'],
      isDone : map['isDone'],
    );
  }
}

class TodoPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;

  const TodoPage({
   super.key,
   required this.onToggleTheme,
   required this.themeMode
  });

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final List<Task> _todos = []; // our task list
  final TextEditingController _controller = TextEditingController();
  int _selectedIndex = 0; //for bottom navigation
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
      ConfettiController(duration: const Duration(seconds: 1));
    _loadTodos(); // load tasks on startup
  }
  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }
  // check if all tasks are complete
  void _checkAllComplete() {
    if (_todos.isNotEmpty && _todos.every((task) => task.isDone)) {
      _confettiController.play();
    }
  }

  // save tasks locally
  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> taskList =
        _todos.map((task) => jsonEncode(task.toMap())).toList();
    await prefs.setStringList('todos', taskList);
  }

  // load tasks locally
  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? taskList = prefs.getStringList('todos');

    if(taskList != null){
      setState(() {
        _todos.clear();
        _todos.addAll(
          taskList.map((item) => Task.fromMap(jsonDecode(item))),
        );
      });
    }
  }

  //add a task
  void _addTodo(){
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _todos.add(Task(title: _controller.text.trim()));
      _controller.clear();
    });
    _saveTodos();
    _checkAllComplete();
  }

  //remove a task
  void _removeTodoAt(int index) {
    setState(() {
      _todos.removeAt(index);
    });
    _saveTodos();
    _checkAllComplete();
  }

  // toggle "done" state
  void _toggleTask(int index){
    setState(() {
      _todos[index].isDone = !_todos[index].isDone;
    });
    _saveTodos();
    _checkAllComplete();
  }

  // Clear completed tasks
  void _clearCompleted() {
    setState(() {
      _todos.removeWhere((task) => task.isDone);
    });
    _saveTodos();
  }

  //filtering based on bottom nav
  List<Task> get _filteredTodos {
    if(_selectedIndex == 1) {
      return _todos.where((t) => !t.isDone).toList(); //Active
    } else if(_selectedIndex == 2) {
      return _todos.where((t) => t.isDone).toList(); // completed
    }
    return _todos;
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Stack(
      children:[ Scaffold(
        appBar: AppBar(
            title: const Text("My To-Do List"),
            actions: [
              IconButton(
                  icon: Icon(widget.themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode),
                tooltip: "Toggle Theme",
                onPressed: widget.onToggleTheme,
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: "Clear Completed",
                onPressed: _clearCompleted,
              ),
            ],
        ),

       // Task List
        body: _filteredTodos.isEmpty
          ? const Center(
            child: Text(
              "No tasks yet ✨",
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _filteredTodos.length,
            itemBuilder: (context, index) {
              final task = _filteredTodos[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Checkbox(
                      value: task.isDone,
                      onChanged: (_) => _toggleTask(_todos.indexOf(task)),
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration: task.isDone
                          ? TextDecoration.lineThrough
                          :TextDecoration.none,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () =>
                        _removeTodoAt(_todos.indexOf(task)),
                  ),
                ),
              );
            }
        ),
         // Floating action button
        floatingActionButton: FloatingActionButton(
            onPressed: ()=> _showAddTaskDialog(context),
            child: const Icon(Icons.add),
        ),

        //bottom navigation
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(()  => _selectedIndex = index ),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.list), label: "All"),
            BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: "Active"),
            BottomNavigationBarItem(icon: Icon(Icons.check_circle),label: "Completed"),
          ],
        ),
      ),
        Align(
          alignment: Alignment.center,
          child: ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive, // full circle
          emissionFrequency: 0.05,
          numberOfParticles: 30,
          gravity: 0.2,
          ),
        ),
      ]
    );
  }

  // add task dialog
  void _showAddTaskDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("New Task"),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: "Enter task"),
            autofocus: true,
            onSubmitted: (_) {
              _addTodo();
              Navigator.pop(context);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _controller.clear();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(onPressed: () {
              _addTodo();
              Navigator.pop(context);
            },
              child: const Text("Add"),
            ),
          ],
        ),
    );
  }
}
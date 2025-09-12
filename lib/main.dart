import 'package:flutter/material.dart';
import 'dart:convert'; //for jsonEncoded/jsonDecode
import 'package:shared_preferences/shared_preferences.dart';
void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget{
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'To-do App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TodoPage(),
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


class TodoPage extends StatefulWidget{
  const TodoPage({super.key});

  @override
  State<StatefulWidget> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final List<Task> _todos = []; // our task list
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTodos(); // load tasks on startup
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
  }

  //remove a task
  void _removeTodoAt(int index) {
    setState(() {
      _todos.removeAt(index);
    });
    _saveTodos();
  }

  // toggle "done" state
  void _toggleTask(int index){
    setState(() {
      _todos[index].isDone = !_todos[index].isDone;
    });
    _saveTodos();
  }

  // Clear completed tasks
  void _clearCompleted() {
    setState(() {
      _todos.removeWhere((task) => task.isDone);
    });
    _saveTodos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("My To-Do List"),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: "Clear Completed",
              onPressed: _clearCompleted,
            ),
          ],
      ),
      body: Column(
        children: [
          // input row
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Enter a task",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addTodo,
                  child: const Text("Add"),
                )
              ],
            ),
          ),
          // task list
          Expanded(
            child: ListView.builder(
              itemCount: _todos.length,
              itemBuilder: (context,index) {
                final task = _todos[index];
                return ListTile(
                  leading: Checkbox(
                    value: task.isDone,
                    onChanged: (_) => _toggleTask(index),
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration: task.isDone
                      ? TextDecoration.lineThrough : TextDecoration.none,
                      color: task.isDone ? Colors.grey : Colors.black,
                    ),
                  ),
                  trailing: IconButton(
                      onPressed: ()=>_removeTodoAt(index),
                      icon: const Icon(Icons.delete, color: Colors.red)
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}
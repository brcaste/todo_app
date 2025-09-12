import 'package:flutter/material.dart';

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
}

class TodoPage extends StatefulWidget{
  const TodoPage({super.key});

  @override
  State<StatefulWidget> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final List<Task> _todos = []; // our task list
  final TextEditingController _controller = TextEditingController();

  //add a task
  void _addTodo(){
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _todos.add(Task(title: _controller.text.trim()));
      _controller.clear();
    });
  }

  //remove a task
  void _removeTodoAt(int index) {
    setState(() {
      _todos.removeAt(index);
    });
  }

  // toggle "done" state
  void _toggleTask(int index){
    setState(() {
      _todos[index].isDone = !_todos[index].isDone;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Task App")),
      body: Column(
        children: [
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
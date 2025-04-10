// Importing required packages

import 'package:flutter/material.dart'; // Flutter UI library
import 'package:firebase_core/firebase_core.dart'; //For initializing Firebase
import 'package:cloud_firestore/cloud_firestore.dart'; //  To connect with Firestore database
import 'package:table_calendar/table_calendar.dart'; // To show calendar in app

// This is the main screen of the app
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState(); // Creates the state for HomePage
}

// State class contains logic and data of HomePage
class _HomePageState extends State<HomePage> {
  // Firestore instance to interact with database
  final FirebaseFirestore db =
      FirebaseFirestore.instance; //new firestore instance
  final TextEditingController nameController =
      TextEditingController(); //captures textform input
  // List to store tasks (each task is a map with id, name, and status)
  final List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    fetchTasks(); // Load tasks from database when screen opens
  }

  //Fetches tasks from the firestore and update local task list
  Future<void> fetchTasks() async {
    final snapshot = await db.collection('tasks').orderBy('timestamp').get();

    setState(() {
      tasks.clear(); // Clear old tasks
      // Add each document from database to the task list
      tasks.addAll(
        snapshot.docs.map(
          (doc) => {
            'id': doc.id, // Firestore document ID
            'name': doc.get('name'), // Task name
            'completed':
                doc.get('completed') ??
                false, // Completion status (default false)
          },
        ),
      );
    });
  }

  //Function that adds new tasks to local state & firestore database
  Future<void> addTask() async {
    final taskName = nameController.text.trim(); // Get text from input field

    // Check if task name is not empty
    if (taskName.isNotEmpty) {
      final newTask = {
        'name': taskName,
        'completed': false, // Default status is incomplete
        'timestamp': FieldValue.serverTimestamp(), // Add timestamp
      };

      //docRef gives us the insertion id of the task from the database
      final docRef = await db.collection('tasks').add(newTask);

      //Adding tasks locally
      setState(() {
        tasks.add({'id': docRef.id, ...newTask});
      });
      nameController.clear(); // Clear input after adding
    }
  }

  //Updates the completion status of the task in Firestore & locally
  Future<void> updateTask(int index, bool completed) async {
    final task = tasks[index]; // Get the task at given index
    await db.collection('tasks').doc(task['id']).update({
      'completed': completed,
    });

    setState(() {
      tasks[index]['completed'] = completed;
    });
  }

  //Delete the task locally & in the Firestore
  Future<void> removeTasks(int index) async {
    final task = tasks[index];
    // Delete from Firestore
    await db.collection('tasks').doc(task['id']).delete();
    // Remove from local task list
    setState(() {
      tasks.removeAt(index);
    });
  }

  // Main UI of the screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue, // Blue app bar color
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Show app logo
            Expanded(child: Image.asset('assets/rdplogo.png', height: 80)),
            const Text(
              'Daily Planner', // App title
              style: TextStyle(
                fontFamily: 'Caveat',
                fontSize: 32,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Show calendar (doesn’t affect tasks yet)
                  TableCalendar(
                    calendarFormat: CalendarFormat.month,
                    focusedDay: DateTime.now(), // Current date is focused
                    firstDay: DateTime(2025), // Start of calendar
                    lastDay: DateTime(2026), // End of calendar
                  ),
                  buildTaskList(tasks, removeTasks, updateTask),
                ],
              ),
            ),
          ),
          // Section to add a new task
          buildAddTaskSection(nameController, addTask),
        ],
      ),
      drawer: Drawer(), // Side menu (currently empty)
    );
  }
}

//Build the section for adding tasks
Widget buildAddTaskSection(nameController, addTask) {
  return Container(
    decoration: const BoxDecoration(color: Colors.white),
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          // Input box for typing task name
          Expanded(
            child: Container(
              child: TextField(
                maxLength: 32, // Max characters allowed
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Add Task',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          // Button to add task
          ElevatedButton(
            onPressed: addTask, //Adds tasks when pressed
            child: Text('Add Task'),
          ),
        ],
      ),
    ),
  );
}

//Widget that displays the task item on the UI
Widget buildTaskList(tasks, removeTasks, updateTask) {
  return ListView.builder(
    shrinkWrap: true, // Allow list inside scroll view
    physics:
        const NeverScrollableScrollPhysics(), // List doesn’t scroll on its own
    itemCount: tasks.length, // Number of tasks
    itemBuilder: (context, index) {
      final task = tasks[index];
      final isEven = index % 2 == 0; // Used to alternate background colors

      return Padding(
        padding: EdgeInsets.all(1.0),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          tileColor: isEven ? Colors.blue : Colors.green, // Alternate row color
          leading: Icon(
            task['completed']
                ? Icons.check_circle
                : Icons.circle_outlined, // Show tick if task is completed
          ),
          title: Text(
            task['name'], // Task name
            style: TextStyle(
              decoration:
                  task['completed']
                      ? TextDecoration.lineThrough
                      : null, // Line through if completed
              fontSize: 22,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Checkbox to mark complete/incomplete
              Checkbox(
                value: task['completed'],
                onChanged:
                    (value) =>
                        updateTask(index, value!), // Update task on change
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => removeTasks(index), // Remove task
              ),
            ],
          ),
        ),
      );
    },
  );
}

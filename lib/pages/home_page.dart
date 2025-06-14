import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final client = Supabase.instance.client;
  List<Map<String, dynamic>> todos = [];
  List<Map<String, dynamic>> incompleteTodos = [];
  List<Map<String, dynamic>> completedTodos = [];

  @override
  void initState() {
    super.initState();
    fetchTodos();
  }

  Future<void> fetchTodos() async {
    final user = client.auth.currentUser;
    if (user == null) return;

    final response = await client
        .from('todos')
        .select()
        .eq('user_id', user.id)
        .order('deadline', ascending: true);

    final allTodos = List<Map<String, dynamic>>.from(response);
    final notDone = allTodos.where((todo) => todo['is_done'] == false).toList();
    final done = allTodos.where((todo) => todo['is_done'] == true).toList();

    setState(() {
      todos = allTodos;
      incompleteTodos = notDone;
      completedTodos = done;
    });
  }

  void openTodoDialog({Map<String, dynamic>? existingTodo}) {
    final titleController =
        TextEditingController(text: existingTodo?['title'] ?? '');
    DateTime? selectedDateTime;

    if (existingTodo != null && existingTodo['deadline'] != null) {
      selectedDateTime =
          DateTime.parse(existingTodo['deadline'] as String).toLocal();
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(existingTodo != null ? 'Edit Tugas' : 'Tambah Tugas'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Judul Tugas'),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    selectedDateTime == null
                        ? 'Pilih Deadline'
                        : DateFormat('dd MMM yyyy • HH:mm')
                            .format(selectedDateTime!),
                  ),
                  onPressed: () async {
                    final now = DateTime.now();

                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDateTime ?? now,
                      firstDate: now,
                      lastDate: DateTime(now.year + 5),
                    );

                    if (pickedDate != null) {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedDateTime != null
                            ? TimeOfDay.fromDateTime(selectedDateTime!)
                            : TimeOfDay.now(),
                      );

                      if (pickedTime != null) {
                        final newDateTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                        setStateDialog(() {
                          selectedDateTime = newDateTime;
                        });
                      }
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final title = titleController.text.trim();
                  final user = client.auth.currentUser;

                  if (title.isEmpty ||
                      selectedDateTime == null ||
                      user == null) return;

                  final data = {
                    'title': title,
                    'deadline': selectedDateTime!.toUtc().toIso8601String(),
                  };

                  if (existingTodo != null) {
                    await client
                        .from('todos')
                        .update(data)
                        .eq('id', existingTodo['id']);
                  } else {
                    await client.from('todos').insert({
                      ...data,
                      'is_done': false,
                      'user_id': user.id,
                    });
                  }

                  Navigator.pop(context);
                  fetchTodos();
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildTodoItem(Map<String, dynamic> todo) {
    final deadline = todo['deadline'] != null
        ? DateFormat('dd MMM yyyy – HH:mm')
            .format(DateTime.parse(todo['deadline']).toLocal())
        : 'Tidak ada deadline';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      child: ListTile(
        title: Text(
          todo['title'],
          style: TextStyle(
            decoration: todo['is_done'] ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text('Deadline: $deadline'),
        leading: Checkbox(
          value: todo['is_done'],
          onChanged: (value) async {
            await client
                .from('todos')
                .update({'is_done': value})
                .eq('id', todo['id']);
            fetchTodos();
          },
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => openTodoDialog(existingTodo: todo),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              color: Colors.red,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Konfirmasi'),
                    content: const Text('Apakah kamu yakin ingin menghapus tugas ini?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () async {
                          Navigator.pop(context);
                          await client
                              .from('todos')
                              .delete()
                              .eq('id', todo['id']);
                          fetchTodos();
                        },
                        child: const Text('Hapus'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: todos.isEmpty
          ? const Center(child: Text('Belum ada tugas.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tugas Belum Selesai',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (incompleteTodos.isEmpty)
                    const Text('Tidak ada tugas yang belum selesai.')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: incompleteTodos.length,
                      itemBuilder: (context, index) =>
                          buildTodoItem(incompleteTodos[index]),
                    ),

                  const SizedBox(height: 24),
                  const Divider(thickness: 2),
                  const SizedBox(height: 24),

                  Text(
                    'Tugas Selesai',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (completedTodos.isEmpty)
                    const Text('Belum ada tugas yang diselesaikan.')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: completedTodos.length,
                      itemBuilder: (context, index) =>
                          buildTodoItem(completedTodos[index]),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openTodoDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Tugas'),
      ),
    );
  }
}

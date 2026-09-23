import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';

class TaskService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _tasks(String userId) =>
      _firestore.collection('users').doc(userId).collection('tasks');

  Future<List<TaskItem>> getTasks(String userId) async {
    final snapshot =
        await _tasks(userId).orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => TaskItem.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<void> saveTask(String userId, TaskItem task) async {
    await _tasks(userId).doc(task.id).set(task.toJson());
  }

  Future<void> deleteTask(String userId, String taskId) async {
    await _tasks(userId).doc(taskId).delete();
  }

  Future<void> setCompleted(
      String userId, TaskItem task, bool completed) async {
    await _tasks(userId).doc(task.id).update({
      'completed': completed,
      'completedAt': completed ? DateTime.now().toIso8601String() : null,
    });
  }

  Future<void> updateTask(String userId, TaskItem task) async {
    await _tasks(userId)
        .doc(task.id)
        .set(task.toJson(), SetOptions(merge: true));
  }

  Future<void> recordCompletion(
      String userId, TaskItem task, bool completed) async {
    await _tasks(userId).doc(task.id).collection('completionHistory').add({
      'completed': completed,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}

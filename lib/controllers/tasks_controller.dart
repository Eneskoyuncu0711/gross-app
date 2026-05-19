// lib/controllers/tasks_controller.dart
import 'package:flutter/material.dart';
import 'package:gross/models/note_model.dart';
import 'package:gross/services/note_service.dart';

class TasksController extends ChangeNotifier {
  final NoteService _noteService = NoteService();
  String selectedType = 'eksik';

  // Ham Veri Akışı
  Stream<List<Note>> get notesStream => _noteService.getNotes(selectedType);

  //YAPAY ZEKA SADECE BURAYA BAKACAK
  Stream<List<Note>> get invoicesStream => _noteService.getNotes('fatura');

  void changeType(String type) {
    selectedType = type;
    notifyListeners();
  }

  // 🔥 4. DÜZELTME: SIRALAMA VE MATEMATİK UI'DAN SÖKÜLDÜ
  List<Note> getProcessedActiveNotes(List<Note> allNotes) {
    final activeNotes = allNotes.where((n) => !n.isDone).toList();
    activeNotes.sort((a, b) {
      if (a.isUrgent && !b.isUrgent) return -1;
      if (!a.isUrgent && b.isUrgent) return 1;
      return b.date.compareTo(a.date);
    });
    return activeNotes;
  }

  List<Note> getProcessedDoneNotes(List<Note> allNotes) {
    return allNotes.where((n) => n.isDone).toList();
  }

  double calculateTotalBudget(List<Note> activeNotes) {
    return activeNotes.fold(0, (sum, note) => sum + note.budget);
  }

  Future<void> addNote(Note note) async {
    await _noteService.addNote(note);
  }

  Future<void> markNoteAsDone(String id) async {
    await _noteService.markNoteAsDone(id);
  }

  Future<void> deleteNote(String id) async {
    await _noteService.deleteNote(id);
  }
}

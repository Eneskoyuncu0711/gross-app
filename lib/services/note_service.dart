// lib/services/note_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gross/models/note_model.dart';
import 'package:gross/services/auth_service.dart';

class NoteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _companyId =>
      AuthService().currentUser?.companyId ?? 'default_company';
  String get _shopId => AuthService().currentUser?.shopId ?? 'default_shop';

  Future<void> addNote(Note note) async {
    String id = _db.collection('notes').doc().id;
    Map<String, dynamic> data = note.toMap();
    data['companyId'] = _companyId;
    data['shopId'] = _shopId;
    await _db.collection('notes').doc(id).set(data);
  }

  Stream<List<Note>> getNotes(String type) {
    return _db
        .collection('notes')
        .where('companyId', isEqualTo: _companyId)
        .where('shopId', isEqualTo: _shopId)
        .where('type', isEqualTo: type)
        .snapshots()
        .map((snapshot) {
          var list = snapshot.docs
              .map((doc) => Note.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  Future<void> markNoteAsDone(String id) async {
    await _db.collection('notes').doc(id).update({'isDone': true});
  }

  Future<void> deleteNote(String id) async {
    await _db.collection('notes').doc(id).delete();
  }
}

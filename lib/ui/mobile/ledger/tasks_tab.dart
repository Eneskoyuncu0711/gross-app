// lib/ui/mobile/ledger/tasks_tab.dart
import 'package:flutter/material.dart';
import 'package:gross/controllers/auth_controller.dart';
import 'package:provider/provider.dart';
import 'package:gross/models/note_model.dart';
import 'package:gross/controllers/tasks_controller.dart';

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _showAddNoteDialog(String type) {
    final controller = context.read<TasksController>();
    final TextEditingController titleController = TextEditingController();
    final TextEditingController detailController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    bool isUrgent = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                _getDialogTitle(type),
                style: const TextStyle(
                  color: Color(0xFF1C1C1E),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: "Başlık / İsim",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: detailController,
                      decoration: InputDecoration(
                        labelText: "Detay Açıklama (Opsiyonel)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    if (type == 'fatura') ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Tutar (₺)",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(
                            Icons.currency_lira,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          "Acil / Önemli",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        value: isUrgent,
                        activeColor: Colors.red,
                        onChanged: (val) =>
                            setDialogState(() => isUrgent = val),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    "İptal",
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E3192),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (titleController.text.trim().isNotEmpty) {
                      double parsedBudget =
                          double.tryParse(amountController.text) ?? 0.0;
                      Note newNote = Note(
                        id: '',
                        title: titleController.text.trim(),
                        detail: detailController.text.trim(),
                        type: type,
                        isDone: false,
                        date: DateTime.now(),
                        budget: parsedBudget,
                        isUrgent: isUrgent,
                      );
                      controller.addNote(newNote);
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text(
                    "Kaydet",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getDialogTitle(String type) {
    if (type == 'eksik') return "Stok İsteği Ekle";
    if (type == 'fatura') return "Fatura / Toptancı Ekle";
    return "Genel Görev Ekle";
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final authController = context.read<AuthController>();
    bool isPatron = authController.isPatron;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Consumer<TasksController>(
              builder: (context, controller, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCategoryChip(
                      controller,
                      'eksik',
                      'Eksikler',
                      Icons.shopping_basket,
                    ),
                    if (isPatron)
                      _buildCategoryChip(
                        controller,
                        'fatura',
                        'Faturalar',
                        Icons.receipt_long,
                      ),
                    _buildCategoryChip(
                      controller,
                      'gorev',
                      'Görevler',
                      Icons.assignment,
                    ),
                  ],
                );
              },
            ),
          ),

          Expanded(
            child: Consumer<TasksController>(
              builder: (context, controller, child) {
                return StreamBuilder<List<Note>>(
                  stream: controller.notesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final notes = snapshot.data ?? [];
                    if (notes.isEmpty) {
                      return Center(
                        child: Text(
                          "Bu kategoride kayıt bulunmuyor.",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }

                    // 🔥 6. DÜZELTME: MATEMATİK BEYNE (CONTROLLER) GİTTİ!
                    final activeNotes = controller.getProcessedActiveNotes(
                      notes,
                    );
                    final doneNotes = controller.getProcessedDoneNotes(notes);
                    double totalBudget = controller.calculateTotalBudget(
                      activeNotes,
                    );

                    return ListView(
                      padding: const EdgeInsets.only(bottom: 100, top: 10),
                      children: [
                        if (controller.selectedType == 'fatura' &&
                            activeNotes.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange.shade700,
                                  Colors.orange.shade500,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.account_balance_wallet,
                                  color: Colors.white,
                                  size: 40,
                                ),
                                const SizedBox(width: 15),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Bekleyen Ödemeler",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      "₺${totalBudget.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ...activeNotes.map(
                          (note) => _buildNoteCard(
                            context,
                            controller,
                            note,
                            isPatron,
                          ),
                        ),
                        if (doneNotes.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Row(
                              children: [
                                Expanded(child: Divider(thickness: 1)),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    "Tamamlananlar",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(thickness: 1)),
                              ],
                            ),
                          ),
                          ...doneNotes.map(
                            (note) => _buildNoteCard(
                              context,
                              controller,
                              note,
                              isPatron,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: Consumer<TasksController>(
          builder: (context, controller, child) {
            return FloatingActionButton.extended(
              heroTag: "btn_add_task",
              backgroundColor: const Color(0xFF2E3192),
              onPressed: () => _showAddNoteDialog(controller.selectedType),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                _getDialogTitle(
                  controller.selectedType,
                ).replaceAll(" Ekle", ""),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    TasksController controller,
    String type,
    String label,
    IconData icon,
  ) {
    bool isSelected = controller.selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeType(type),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2E3192) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteCard(
    BuildContext context,
    TasksController controller,
    Note note,
    bool isPatron,
  ) {
    return Dismissible(
      key: Key(note.id),
      direction: isPatron ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => controller.deleteNote(note.id),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: note.isDone ? Colors.grey[200] : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: note.isUrgent && !note.isDone
              ? const BorderSide(color: Colors.red, width: 2)
              : BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: InkWell(
            onTap: note.isDone
                ? null
                : () {
                    controller.markNoteAsDone(note.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("İşlem tamamlandı olarak işaretlendi!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: note.isDone ? Colors.green : Colors.grey,
                  width: 2,
                ),
                color: note.isDone ? Colors.green : Colors.transparent,
              ),
              child: Icon(
                Icons.check,
                size: 20,
                color: note.isDone ? Colors.white : Colors.transparent,
              ),
            ),
          ),
          title: Row(
            children: [
              if (note.isUrgent && !note.isDone)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.warning_rounded,
                    color: Colors.red,
                    size: 18,
                  ),
                ),
              Expanded(
                child: Text(
                  note.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: note.isDone ? Colors.grey : const Color(0xFF1C1C1E),
                    decoration: note.isDone
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.detail.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    note.detail,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      decoration: note.isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ),
              if (note.isDone)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    "✓ Tamamlandı",
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          trailing: note.budget > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: note.isDone
                        ? Colors.grey.shade300
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "₺${note.budget.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: note.isDone ? Colors.grey : Colors.green.shade800,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

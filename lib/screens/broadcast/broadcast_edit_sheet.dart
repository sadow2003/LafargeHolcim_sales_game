import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../main.dart';

class EditBroadcastSheet extends StatefulWidget {
  final String docId;
  final String initialContent;
  final String initialType;
//Constructor
  const EditBroadcastSheet({
    super.key,
    required this.docId,
    required this.initialContent,
    required this.initialType,
  });

  // create State
  @override
  State<EditBroadcastSheet> createState() => _EditBroadcastSheetState();
}


class _EditBroadcastSheetState extends State<EditBroadcastSheet> {
  late TextEditingController _contentCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _contentCtrl = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

//Method save the updates
  Future<void> _save() async {
    final text = _contentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    await FirebaseFirestore.instance
        .collection('broadcasts')
        .doc(widget.docId)
        .update({
      'content': text,
      'editedAt': FieldValue.serverTimestamp(),
    });
    if (mounted) Navigator.pop(context);
  }

// ____UI BUILDING___
  @override
  Widget build(BuildContext context) {

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;// to move the sheet up when keyboard appears
    
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF1A3A6B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 18),
          // title
          const Text(
            'Edit Broadcast',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),

          // content input
          TextField(
            controller: _contentCtrl,
            maxLines: 4,
            maxLength: 280,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Update your broadcast...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kSecondaryColor),
              ),
              counterStyle: const TextStyle(color: Colors.white38),
            ),
          ),

          const SizedBox(height: 16),

          // save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: kSecondaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text(
                      'Save Changes',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../main.dart';

class PostBroadcastSheet extends StatefulWidget {
  final User? currentUser;
  final Map<String, dynamic>? userData;
  final int currentRank;

  // Constructor
  const PostBroadcastSheet({
    super.key,
    required this.currentUser,
    required this.userData,
    required this.currentRank,
  });


  @override
  State<PostBroadcastSheet> createState() => _PostBroadcastSheetState();
}

class _PostBroadcastSheetState extends State<PostBroadcastSheet> {
  final _contentCtrl = TextEditingController();
  bool _posting = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

// Method to post the broadcast
  Future<void> _post() async {
    final text = _contentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _posting = true);

    // Prepare author info for the broadcast document
    final userData = widget.userData;
    final firstName = userData?['firstName'] ?? '';
    final lastName = userData?['lastName'] ?? '';
    final authorName = '$firstName $lastName'.trim();

    // Add a new document to the broadcasts collection with all relevant info
    await FirebaseFirestore.instance.collection('broadcasts').add({
      'authorId': widget.currentUser?.uid,
      'authorName': authorName,
      'authorRole': userData?['role'] ?? 'salesperson',
      'authorPhotoUrl': userData?['photoUrl'],
      'type': 'general',
      'content': text,
      'pointsAtTime': userData?['totalPoints'] ?? 0,
      'rankAtTime': widget.currentRank > 0 ? widget.currentRank : null,
      'reactions': {},
      'createdAt': FieldValue.serverTimestamp(),
      'expireAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 48))),
    });
    // After posting, close the sheet
    if (mounted) Navigator.pop(context);
  }

  // ____UI BUILDING___
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;// to move the sheet up when keyboard appears
    
    // Main container for the sheet with padding and background
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF1A3A6B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Column to layout the content vertically
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

          // title and user info
          const Text(
            'New Broadcast',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 4),

          // show current rank and points if available
          if (widget.currentRank > 0)
            Text(
              'Posting as Rank #${widget.currentRank} · ${widget.userData?['totalPoints'] ?? 0} pts',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),


          const SizedBox(height: 18),

          // text input
          TextField(
            controller: _contentCtrl,
            maxLines: 4,
            maxLength: 280,

            style: const TextStyle(color: Colors.white),

            decoration: InputDecoration(
              hintText: 'Share something with your team...',
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

          // post button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _posting ? null : _post,
              style: ElevatedButton.styleFrom(
                backgroundColor: kSecondaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              // Show loading indicator when posting, otherwise show "Post Broadcast" text
              child: _posting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text(
                      'Post Broadcast',
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

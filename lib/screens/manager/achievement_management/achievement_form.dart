import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../main.dart';


// This file defines the AchievementForm widget, which is used for creating and editing achievements in the manager's achievement management section. It includes form fields for title, description, icon selection, and points reward, along with validation and Firestore integration for saving the achievement data.
class AchievementForm extends StatefulWidget {
  final String? id;
  final Map<String, dynamic>? existing;

  const AchievementForm({super.key, this.id, this.existing});

  @override
  State<AchievementForm> createState() => _AchievementFormState();
}


class _AchievementFormState extends State<AchievementForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _ptsCtrl;
  String _iconName = 'trophy';
  bool   _saving   = false;

// Tuple: (iconName, iconData, displayName)
  static const _iconOptions = [
    ('trophy',  Icons.emoji_events,          'Trophy'),
    ('star',    Icons.star,                  'Star'),
    ('medal',   Icons.military_tech,         'Medal'),
    ('fire',    Icons.local_fire_department, 'Fire'),
    ('rocket',  Icons.rocket_launch,         'Rocket'),
    ('target',  Icons.gps_fixed,             'Target'),
    ('diamond', Icons.diamond,               'Diamond'),
    ('login',   Icons.login,                 'Login'),
  ];

  @override
  void initState() {
    super.initState();
    final e    = widget.existing;
    _titleCtrl = TextEditingController(text: e?['title']       ?? '');
    _descCtrl  = TextEditingController(text: e?['description'] ?? '');
    _ptsCtrl   = TextEditingController(
        text: '${(e?['pointsReward'] as num?)?.toInt() ?? 0}');
    _iconName  = e?['iconName'] ?? 'trophy';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _ptsCtrl.dispose();
    super.dispose();
  }

// Validates input and saves to Firestore (add or update based on presence of id)
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    // Prepare data payload for Firestore
    final payload = <String, dynamic>{
      'title':        _titleCtrl.text.trim(),
      'description':  _descCtrl.text.trim(),
      'iconName':     _iconName,
      'pointsReward': int.tryParse(_ptsCtrl.text) ?? 0,
    };

    // Reference to 'achievements' collection in Firestore
    final col = FirebaseFirestore.instance.collection('achievements');
    if (widget.id != null) {
      await col.doc(widget.id).update(payload);
    } else {
      payload['createdAt'] = FieldValue.serverTimestamp();
      await col.add(payload);
    }

    if (mounted) Navigator.pop(context);
  }

//_________ui____________
  @override
  Widget build(BuildContext context) {
    final isEdit = widget.id != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      
      // Main container with rounded top corners and white background
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),

        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                // Title text indicating whether it's an edit or new achievement
                Text(
                  isEdit ? 'Edit Achievement' : 'New Achievement',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
                
                const SizedBox(height: 16),
                // Title input field with validation
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                
                const SizedBox(height: 12),
                // Description input field (optional)
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                  maxLines: 2,
                ),
                
                const SizedBox(height: 16),
                // Section label for icon selection
                const Text('Icon', style: TextStyle(fontWeight: FontWeight.w600)),
                
                const SizedBox(height: 8),
                
                // Icon selection grid with tooltips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _iconOptions.map((ic) {
                    final selected = _iconName == ic.$1;
                    return GestureDetector(
                      onTap: () => setState(() => _iconName = ic.$1),
                      child: Tooltip(
                        message: ic.$3,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? kSecondaryColor.withValues(alpha: 0.15)
                                : Colors.grey.shade100,
                            border: selected
                                ? Border.all(color: kSecondaryColor, width: 2)
                                : null,
                          ),
                          child: Icon(
                            ic.$2,
                            color: selected ? kSecondaryColor : Colors.grey.shade500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 16),
                // Points reward input field with validation for non-negative integers
                TextFormField(
                  controller: _ptsCtrl,
                  decoration: const InputDecoration(labelText: 'Points reward'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 0) return 'Enter a number ≥ 0';
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                // Save button that shows a loading indicator when saving
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(isEdit ? 'Save Changes' : 'Create Achievement'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

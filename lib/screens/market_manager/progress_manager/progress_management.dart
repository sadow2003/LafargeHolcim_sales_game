import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../main.dart';
import '../../../widgets/_buildDrawer.dart';
import '../../../widgets/gradient_app_bar.dart';
import 'progress_management_service.dart';

// ── Page ──────────────────────────────────────────────────────────────────────

class ProgressManagementPage extends StatelessWidget {
  const ProgressManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Progress Challenges',
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: StreamBuilder<DocumentSnapshot>(
        stream: ProgressChallengeService.stream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data?.data() as Map<String, dynamic>?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Current challenge ───────────────────────────────────
                const Text(
                  'Current Progress Challenge',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                _ActiveChallengeCard(data: data),
                const SizedBox(height: 32),

                // ── Create / edit form ──────────────────────────────────
                const Text(
                  'Set New Challenge',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Enter a title and point target. Saving will activate the '
                  'challenge immediately and replace any existing one.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 16),

                // ValueKey forces the form to rebuild (and pre-fill) when the
                // Firestore doc changes — e.g. after an external edit or delete.
                _ChallengeFormCard(
                  key: ValueKey(
                      '${data?['title']}_${data?['targetPoints']}'),
                  initialTitle:
                      data?['title'] as String? ?? '',
                  initialTarget:
                      (data?['targetPoints'] as num?)?.toInt() ?? 0,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Active challenge card ──────────────────────────────────────────────────────

class _ActiveChallengeCard extends StatefulWidget {
  const _ActiveChallengeCard({this.data});
  final Map<String, dynamic>? data;

  @override
  State<_ActiveChallengeCard> createState() => _ActiveChallengeCardState();
}

class _ActiveChallengeCardState extends State<_ActiveChallengeCard> {
  bool _isLoading = false;

  Future<void> _toggleActive() async {
    final nowActive = widget.data?['isActive'] == true;
    setState(() => _isLoading = true);
    try {
      await ProgressChallengeService.setActive(!nowActive);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              nowActive ? 'Challenge deactivated.' : 'Challenge activated.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Challenge'),
        content: const Text(
          'This will permanently delete the progress challenge.\n\n'
          'Salespersons will no longer see a progress target.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ProgressChallengeService.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Challenge deleted.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    // ── No challenge ──────────────────────────────────────────────────────
    if (data == null) {
      return Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: const ListTile(
          leading: Icon(Icons.flag_outlined, color: Colors.grey),
          title:    Text('No progress challenge set'),
          subtitle: Text('Use the form below to create one.'),
        ),
      );
    }

    // ── Existing challenge ────────────────────────────────────────────────
    final isActive    = data['isActive'] == true;
    final title       = (data['title'] as String?) ?? 'Untitled';
    final target      = (data['targetPoints'] as num?)?.toInt() ?? 0;
    final statusColor = isActive ? Colors.green : Colors.orange;
    final statusLabel = isActive ? 'ACTIVE' : 'INACTIVE';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:        statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color:      statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize:   12,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Title row
            Row(
              children: [
                const Icon(Icons.title_outlined,
                    size: 16, color: kPrimaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Target row
            Row(
              children: [
                const Icon(Icons.flag_outlined,
                    size: 16, color: Color(0xFFFFD700)),
                const SizedBox(width: 8),
                Text(
                  'Target: $target pts',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          isActive ? Colors.orange : Colors.green,
                      side: BorderSide(
                          color: isActive ? Colors.orange : Colors.green),
                    ),
                    onPressed: _isLoading ? null : _toggleActive,
                    icon: Icon(isActive
                        ? Icons.pause_outlined
                        : Icons.play_arrow_outlined),
                    label:
                        Text(isActive ? 'Deactivate' : 'Activate'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side:            const BorderSide(color: Colors.red),
                    ),
                    onPressed: _isLoading ? null : _delete,
                    icon: _isLoading
                        ? const SizedBox(
                            width:  16,
                            height: 16,
                            child:  CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.red),
                          )
                        : const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Create / edit form card ───────────────────────────────────────────────────

class _ChallengeFormCard extends StatefulWidget {
  const _ChallengeFormCard({
    super.key,
    required this.initialTitle,
    required this.initialTarget,
  });

  final String initialTitle;
  final int    initialTarget;

  @override
  State<_ChallengeFormCard> createState() => _ChallengeFormCardState();
}

class _ChallengeFormCardState extends State<_ChallengeFormCard> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _targetCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl  = TextEditingController(text: widget.initialTitle);
    _targetCtrl = TextEditingController(
      text: widget.initialTarget > 0 ? '${widget.initialTarget}' : '',
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  bool get _canSave {
    if (_titleCtrl.text.trim().isEmpty) return false;
    final pts = int.tryParse(_targetCtrl.text.trim());
    return pts != null && pts > 0;
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _isSaving = true);
    try {
      await ProgressChallengeService.save(
        title:        _titleCtrl.text.trim(),
        targetPoints: int.parse(_targetCtrl.text.trim()),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('Progress challenge saved and activated.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error saving: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Title field ─────────────────────────────────────────────
            TextField(
              controller:         _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText:   'Challenge Title',
                hintText:    'e.g. Q2 Sprint Challenge',
                prefixIcon:  Icon(Icons.title_outlined),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // ── Target points field ─────────────────────────────────────
            TextField(
              controller:   _targetCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText:   'Target Points',
                hintText:    'e.g. 500',
                prefixIcon:  Icon(Icons.flag_outlined),
                suffixText:  'pts',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // ── Save button ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (_canSave && !_isSaving) ? _save : null,
                icon: _isSaving
                    ? const SizedBox(
                        width:  16,
                        height: 16,
                        child:  CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Save Challenge'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

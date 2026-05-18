import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lafargeholcim_sales_game/widgets/_buildDrawer.dart';
import '../../main.dart';
import '../../widgets/gradient_app_bar.dart';
import 'manager_services.dart';


class ManagerSalesManagment extends StatefulWidget {
  const ManagerSalesManagment({super.key});

  @override
  State<ManagerSalesManagment> createState() => _ManagerSalesManagmentState();
}


class _ManagerSalesManagmentState extends State<ManagerSalesManagment> {
  String _filter = 'pending';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: 'Approve Sales'),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // ── Status Filter Tabs ───────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _filterChip('Pending',  'pending'),
                const SizedBox(width: 8),
                _filterChip('Approved', 'approved'),
                const SizedBox(width: 8),
                _filterChip('Rejected', 'rejected'),
                const SizedBox(width: 8),
                _filterChip('All',      'all'),
              ],
            ),
          ),

          // ── Sales List ───────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _filter == 'all'
                  ? FirebaseFirestore.instance
                      .collection('sales')
                      .orderBy('createdAt', descending: true)
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('sales')
                      .where('status', isEqualTo: _filter)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'No $_filter sales claims.',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc  = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _SaleCard(
                      saleId:    doc.id,
                      data:      data,
                      onApprove: _filter == 'pending'
                          ? () => _approveSale(doc.id, data)
                          : null,
                      onReject:  _filter == 'pending'
                          ? () => _rejectSale(doc.id, data)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter Chip ──────────────────────────────────────────────────────────
  Widget _filterChip(String label, String value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: kPrimaryColor,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _filter = value),
    );
  }

  // ── Approve Sale ─────────────────────────────────────────────────────────
  Future<void> _approveSale(String saleId, Map<String, dynamic> data) async {
    try {
      final pointsAwarded = await ManagerService.approveSale(saleId, data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sale approved! +$pointsAwarded points awarded.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving sale: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Reject Sale ──────────────────────────────────────────────────────────
  Future<void> _rejectSale(String saleId, Map<String, dynamic> data) async {
    try {
      await ManagerService.rejectSale(saleId, data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sale claim rejected.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting sale: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}


// ── Sale Card Widget ──────────────────────────────────────────────────────────
class _SaleCard extends StatelessWidget {
  final String               saleId;
  final Map<String, dynamic> data;
  final VoidCallback?        onApprove;
  final VoidCallback?        onReject;

  const _SaleCard({
    required this.saleId,
    required this.data,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final productName   = data['productName']   ?? 'Unknown';
    final quantity      = data['quantity']      ?? 0;
    final status        = data['status']        ?? 'pending';
    final userName      = data['userName']      ?? 'Unknown User';
    final proofImageUrl = data['proofImageUrl'] as String?;
    final pointsAwarded = data['pointsAwarded'] ?? 0;
    final createdAt     = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Card Header ────────────────────────────────────────────────
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE8EEF7),
              child: Icon(Icons.receipt_long, color: kPrimaryColor),
            ),
            title: Text(
              productName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('By: $userName'),
            trailing: _statusBadge(status),
          ),

          // ── Sale Details ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _detail('Quantity', '$quantity units'),
                const SizedBox(width: 20),
                if (createdAt != null)
                  _detail(
                    'Date',
                    '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                  ),
                if (status == 'approved') ...[
                  const SizedBox(width: 20),
                  _detail('Points', '+$pointsAwarded pts', color: Colors.green),
                ],
              ],
            ),
          ),

          // ── Proof Photo ────────────────────────────────────────────────
          if (proofImageUrl != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () => _viewImage(context, proofImageUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    proofImageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : Container(
                            height: 140,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                    errorBuilder: (_, _, _) => Container(
                      height: 80,
                      color: Colors.grey.shade100,
                      child: const Center(child: Text('Could not load image')),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
              child: Text(
                'Tap image to view full size',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          ],

          // ── Approve / Reject Buttons ───────────────────────────────────
          if (onApprove != null || onReject != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  if (onReject != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text(
                          'Reject',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  if (onApprove != null && onReject != null)
                    const SizedBox(width: 10),
                  if (onApprove != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _detail(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color bg, fg;
    switch (status) {
      case 'approved':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        break;
      case 'rejected':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        break;
      default:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.4)),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _viewImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

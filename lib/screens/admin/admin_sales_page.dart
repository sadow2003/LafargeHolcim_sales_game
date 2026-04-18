import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lafargeholcim_sales_game/screens/admin/_buildDrawer_Admin.dart';
import '../../main.dart';
import '../../widgets/gradient_app_bar.dart';



class AdminSalesPage extends StatefulWidget {
  const AdminSalesPage({super.key});

  @override
  State<AdminSalesPage> createState() => _AdminSalesPageState();
}


class _AdminSalesPageState extends State<AdminSalesPage> {
  // Filter: show 'pending', 'approved', 'rejected', or 'all'.
  String _filter = 'pending'; // Default to pending so admin sees what needs action

  @override
  Widget build(BuildContext context) {
    return Scaffold(



      //the app bar gradiant
      appBar: GradientAppBar(
        title: 'Approve Sales',
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),




      //Drawer of admin
      drawer: const AppDrawer(),



      body: Column(
        children: [
          // ── Status Filter Tabs ─────────────────────────────────────────
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




          // ── Sales List ─────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(


              stream: _filter == 'all'

                  // 'All' tab: no status filter, order by newest first.
                  ? FirebaseFirestore.instance
                      .collection('sales')
                      .orderBy('createdAt', descending: true)
                      .snapshots()

                  // Other tabs: filter by the selected status.
                  : FirebaseFirestore.instance
                      .collection('sales')
                      .where('status', isEqualTo: _filter)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),

              builder: (context, snapshot) {
                //shows the loading circle 
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                //show a message error
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
                      saleId:   doc.id,
                      data:     data,
                      onApprove: _filter == 'pending'
                          ? () => _approveSale(doc.id, data)
                          : null, // Hide approve button for non-pending
                      onReject: _filter == 'pending'
                          ? () => _rejectSale(doc.id)
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

  // ── Filter Chip helper ────────────────────────────────────────────────────
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

  // ── Approve Sale ──────────────────────────────────────────────────────────
  Future<void> _approveSale(String saleId, Map<String, dynamic> data) async {

    final userId    = data['userId']        as String?;
    final productId = data['productId']     as String?;
    final quantity  = (data['quantity']     ?? 0) as int;

    if (userId == null || productId == null) return;

    try {

      // Step 1: Fetch the product to get its current point value.
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();

      final productPoints =
          (productDoc.data()?['productPoints'] ?? 0) as int;

      // Step 2: Calculate points earned for this sale.
      // Formula from spec: Points = productPoints × quantity
      final pointsAwarded = productPoints * quantity;

      // Step 3: Update the sale document.
      await FirebaseFirestore.instance
          .collection('sales')
          .doc(saleId)
          .update({
        'status':        'approved',
        'pointsAwarded': pointsAwarded,
      });

      // Step 4: Add points to the salesperson's totalPoints.
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'totalPoints': FieldValue.increment(pointsAwarded),
      });


      // Step 5: Recalculate ALL salesperson ranks.
      await _recalculateRanks();


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

  // ── Reject Sale ───────────────────────────────────────────────────────────
  Future<void> _rejectSale(String saleId) async {
    
    try {
      await FirebaseFirestore.instance
          .collection('sales')
          .doc(saleId)
          .update({'status': 'rejected'});

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






  // ── Recalculate Ranks ─────────────────────────────────────────────────────

  Future<void> _recalculateRanks() async {
    final usersSnap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'salesperson')
        .orderBy('totalPoints', descending: true)
        .get();

    // WriteBatch lets us update many documents in a single network request.
    final batch = FirebaseFirestore.instance.batch();

    for (int i = 0; i < usersSnap.docs.length; i++) {
      final userRef = usersSnap.docs[i].reference;
      // rank 1 = highest points (i=0), rank 2 = second (i=1), etc.
      batch.update(userRef, {'rank': i + 1});
    }

    await batch.commit(); // Send all rank updates to Firestore at once
  }
}








// ── Sale Card Widget ──────────────────────────────────────────────────────────
// Displays one sale claim with details and (optionally) Approve/Reject buttons.
class _SaleCard extends StatelessWidget {
  final String                saleId;
  final Map<String, dynamic>  data;
  final VoidCallback?         onApprove; // null = hide the button
  final VoidCallback?         onReject;


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



          // ── Card Header ─────────────────────────────────────────────
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
            // Status badge on the right.
            trailing: _statusBadge(status),
          ),



          // ── Sale Details ─────────────────────────────────────────────
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
                  _detail('Points', '+$pointsAwarded pts',
                      color: Colors.green),
                ],
              ],
            ),
          ),



          // ── Proof Photo ──────────────────────────────────────────────
          if (proofImageUrl != null) ...[
            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                // Tapping the thumbnail opens it full-screen.

                onTap: () => _viewImage(context, proofImageUrl),
                
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    proofImageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,

                    // Show a grey box while the image loads.
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child: Container(
                            height: 140,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                    errorBuilder: (_, _, _) => Container(
                      height: 80,
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: Text('Could not load image'),
                      ),
                    ),


                  ),
                ),
              ),
            ),


            Padding(
              padding:
                  const EdgeInsets.only(left: 16, top: 4, bottom: 4),
              child: Text(
                'Tap image to view full size',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          ],



          // ── Approve / Reject Buttons ─────────────────────────────────
          // Only shown for pending claims (onApprove/onReject are non-null).
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


  // Small label + value column used in the details section.
  Widget _detail(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),


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



  // Status colored pill badge.
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



  // Opens the proof image full-screen in a dialog.
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

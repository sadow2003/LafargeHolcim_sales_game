// admin/admin_products_page.dart — Lets the admin manage the product catalog.
//
// Features:
//   • Lists all products from Firestore in real time.
//   • A FAB (+) opens a form to add a new product.
//   • Tapping the edit icon on a product lets the admin update it.
//   • Tapping the delete icon removes the product after a confirmation.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart'; // kPrimaryColor, kAccentColor

class AdminProductsPage extends StatelessWidget {
  const AdminProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Products')),

      // ── Product List ────────────────────────────────────────────────────
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('name')
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
                  Icon(Icons.inventory_2_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text('No products yet. Tap + to add one.'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc  = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  // Leading icon varies by category.
                  leading: CircleAvatar(
                    backgroundColor:
                        kPrimaryColor.withValues(alpha: 0.1),
                    child: const Icon(Icons.inventory_2_outlined,
                        color: kPrimaryColor),
                  ),
                  title: Text(
                    data['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${data['category'] ?? ''} — ${data['productPoints'] ?? 0} pts/unit',
                    style: const TextStyle(fontSize: 12),
                  ),
                  // Edit and Delete buttons on the right side.
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit button — opens the product form pre-filled.
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: kPrimaryColor),
                        tooltip: 'Edit',
                        onPressed: () =>
                            _showProductForm(context, doc.id, data),
                      ),
                      // Delete button — shows a confirmation dialog first.
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        tooltip: 'Delete',
                        onPressed: () =>
                            _confirmDelete(context, doc.id, data['name']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),

      // ── Add Product FAB ─────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductForm(context, null, null),
        tooltip: 'Add Product',
        child: const Icon(Icons.add), // 'child' must be last argument
      ),
    );
  }

  // ── Product Form (Add or Edit) ────────────────────────────────────────────
  // Opens a bottom sheet with fields for name, category, points, description.
  // If docId is null → we are ADDING a new product.
  // If docId is not null → we are EDITING an existing product.
  void _showProductForm(
    BuildContext context,
    String? docId,
    Map<String, dynamic>? existing,
  ) {
    // Pre-fill the controllers with existing data when editing.
    final nameCtrl   = TextEditingController(text: existing?['name'] ?? '');
    final pointsCtrl = TextEditingController(
        text: existing?['productPoints']?.toString() ?? '');
    final descCtrl   = TextEditingController(
        text: existing?['description'] ?? '');

    // The four allowed categories.
    final categories = ['Cement', 'Concrete', 'Mortar', 'Aggregates'];
    String selectedCategory = existing?['category'] ?? categories[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to grow when keyboard opens
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        // StatefulBuilder allows the dropdown inside the bottom sheet to rebuild.
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              // viewInsets.bottom adds extra padding so the keyboard doesn't
              // cover the form fields.
              padding: EdgeInsets.only(
                left:   20,
                right:  20,
                top:    24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    docId == null ? 'Add Product' : 'Edit Product',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Product Name
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Product Name'),
                  ),
                  const SizedBox(height: 12),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setModalState(() => selectedCategory = v);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Points per unit
                  TextField(
                    controller: pointsCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Points per Unit'),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextField(
                    controller: descCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Description (optional)'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  // Save Button
                  ElevatedButton(
                    onPressed: () async {
                      final name   = nameCtrl.text.trim();
                      final points = int.tryParse(pointsCtrl.text.trim()) ?? 0;
                      final desc   = descCtrl.text.trim();

                      if (name.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Product name cannot be empty.'),
                          ),
                        );
                        return;
                      }

                      // Build the Firestore data map.
                      final productData = {
                        'name':          name,
                        'category':      selectedCategory,
                        'productPoints': points,
                        'description':   desc,
                      };

                      if (docId == null) {
                        // ADD: create a new document.
                        await FirebaseFirestore.instance
                            .collection('products')
                            .add(productData);
                      } else {
                        // EDIT: update the existing document.
                        await FirebaseFirestore.instance
                            .collection('products')
                            .doc(docId)
                            .update(productData);
                      }

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx); // Close the bottom sheet
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(docId == null
                              ? 'Product added successfully!'
                              : 'Product updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: const Text('Save Product'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Delete Confirmation ───────────────────────────────────────────────────
  void _confirmDelete(BuildContext context, String docId, String? name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('products')
                  .doc(docId)
                  .delete();
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Product deleted.'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

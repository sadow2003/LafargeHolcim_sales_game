import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lafargeholcim_sales_game/screens/admin/_buildDrawer_Admin.dart';
import '../../main.dart'; 
import '../../widgets/gradient_app_bar.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  // Search and filter state
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Cement',
    'Concrete',
    'Mortar',
    'Aggregates',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(


      appBar: GradientAppBar(
        title: 'Manage Products',
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

          // ── Search Bar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),



          // ── Category Filter Chips ─────────────────────────────────────────
          SizedBox(
            height: 52,

            //Scrollable list of items
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              separatorBuilder: (_, i) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat      = _categories[index];
                final selected = cat == _selectedCategory;

                //creates a chip that acts like a checkbox
                return FilterChip(
                  label: Text(cat),
                  selected: selected,
                  selectedColor: kPrimaryColor,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  checkmarkColor: Colors.white,
                  onSelected: (_) =>
                      setState(() => _selectedCategory = cat),
                );
              },
            ),
          ),

          // ── Product List ──────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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


                final allDocs = snapshot.data?.docs ?? [];

                // Apply search and category filters
                final filtered = allDocs.where((doc) {
                  final data     = doc.data() as Map<String, dynamic>;
                  final name     = (data['name'] ?? '').toString().toLowerCase();
                  final category = (data['category'] ?? '').toString();

                  final matchesSearch = _searchQuery.isEmpty ||
                      name.contains(_searchQuery.toLowerCase());
                  final matchesCategory = _selectedCategory == 'All' ||
                      category == _selectedCategory;

                  return matchesSearch && matchesCategory;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          allDocs.isEmpty
                              ? 'No products yet. Tap + to add one.'
                              : 'No products match your search.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc  = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        // Leading icon varies by category.
                        leading: CircleAvatar(
                          backgroundColor: _colorForCategory(
                              data['category'] ?? ''),
                          child: Icon(
                            _iconForCategory(data['category'] ?? ''),
                            color: kPrimaryColor,
                          ),
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
          ),
        ],
      ),





      // ── Add Product FAB ───────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductForm(context, null, null),
        tooltip: 'Add Product',
        child: const Icon(Icons.add),
      ),
    );
  }





  // ── Category helpers ────────────────────────────────────────────────────────
  IconData _iconForCategory(String cat) {
    switch (cat) {
      case 'Cement':     return Icons.foundation;
      case 'Concrete':   return Icons.construction;
      case 'Mortar':     return Icons.handyman;
      case 'Aggregates': return Icons.terrain;
      default:           return Icons.inventory_2_outlined;
    }
  }




  //___Colors for every category_______________________________________
  Color _colorForCategory(String cat) {
    switch (cat) {
      case 'Cement':     return Colors.grey.shade200;
      case 'Concrete':   return Colors.brown.shade100;
      case 'Mortar':     return Colors.orange.shade100;
      case 'Aggregates': return Colors.green.shade100;
      default:           return Colors.blue.shade50;
    }
  }






  // ── Product Form (Add or Edit) ──────────────────────────────────────────────
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

    //shows a windows for adding or editing a product
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


                  //text of the product
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
                        //create a new document.
                        await FirebaseFirestore.instance
                            .collection('products')
                            .add(productData);
                      } else {
                        //update the existing document.
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




  // ── Delete Confirmation ─────────────────────────────────────────────────────
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

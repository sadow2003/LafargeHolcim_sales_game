import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '_buildDrawer.dart';
import '../widgets/gradient_app_bar.dart';


class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}



class _ProductsPageState extends State<ProductsPage> {
  //variable of the search bar 
  String _searchQuery = '';

  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Cement',
    'Concrete',
    'Mortar',
    'Aggregates',
  ];

//________UI______________________________
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: 'Product Catalog'),
      drawer: const AppDrawer(),

      body: Column(
        children: [


          // ── Search Bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products…',
                prefixIcon: const Icon(Icons.search),
                // the button x TO CLEAR OUT THE SEARCH BAR
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                  //fill the text field with the color
                filled: true,
                fillColor: Colors.grey.shade100,
                //manipulates the border
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),

              // every time the user types a lettre the screen changes to show the results
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),





          // ── Category Filter Chips ───────────────────────────────────────
          SizedBox(
            height: 52,//52px
            //horisantal scrolling list with seperators
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              //number of item on the list ,each item with it own sizebox
              itemCount: _categories.length,
              separatorBuilder: (_, i) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat      = _categories[index];
                final selected = cat == _selectedCategory;
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


          // ── Product List ─────────────────────────────────────────────────
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
                //the doument of produts we got from firestore
                final allDocs = snapshot.data?.docs ?? [];

                // Apply search and category
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



// If no products match the filters, show a message to the user
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
                              ? 'No products yet.\nAsk an admin to add products.'
                              : 'No products match your search.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }



// Build a scrollable list of product cards for the filtered products.
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final data =
                        filtered[index].data() as Map<String, dynamic>;
                    return _ProductCard(
                      name:          data['name']          ?? '',
                      category:      data['category']      ?? '',
                      description:   data['description']   ?? '',
                      productPoints: (data['productPoints'] ?? 0) as int,
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
}





// ── Product Card Widget ───────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final String name;
  final String category;
  final String description;
  final int    productPoints;

  const _ProductCard({
    required this.name,
    required this.category,
    required this.description,
    required this.productPoints,
  });




  IconData _iconForCategory(String cat) {
    switch (cat) {
      case 'Cement':     return Icons.foundation;
      case 'Concrete':   return Icons.construction;
      case 'Mortar':     return Icons.handyman;
      case 'Aggregates': return Icons.terrain;
      default:           return Icons.inventory_2_outlined;
    }
  }





  Color _colorForCategory(String cat) {
    switch (cat) {
      case 'Cement':     return Colors.grey.shade200;
      case 'Concrete':   return Colors.brown.shade100;
      case 'Mortar':     return Colors.orange.shade100;
      case 'Aggregates': return Colors.green.shade100;
      default:           return Colors.blue.shade50;
    }
  }




  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category icon circle.
            CircleAvatar(
              radius: 24,
              backgroundColor: _colorForCategory(category),
              child: Icon(_iconForCategory(category),
                  color: kPrimaryColor, size: 24),
            ),
            const SizedBox(width: 14),




            // Name, category label, description.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                  Text(
                    category,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),





            // Points badge.
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: kSecondaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kSecondaryColor),
              ),
              child: Column(
                children: [
                  Text(
                    '$productPoints',
                    style: const TextStyle(
                      color: kSecondaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Text(
                    'pts/unit',
                    style: TextStyle(color: kSecondaryColor, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

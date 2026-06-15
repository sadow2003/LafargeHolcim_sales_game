import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';
import '../../widgets/_buildDrawer.dart';
import '../../widgets/gradient_app_bar.dart';


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
    'Concrete',
    'Mortar',
    'Aggregates',
    'Road Activity',
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
                      onTap: () => _showProductDetail(
                        context,
                        name:          data['name']          ?? '',
                        category:      data['category']      ?? '',
                        description:   data['description']   ?? '',
                        productPoints: (data['productPoints'] ?? 0) as int,
                      ),
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

  void _showProductDetail(
    BuildContext context, {
    required String name,
    required String category,
    required String description,
    required int productPoints,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        final icon  = _iconForCategory(category);
        final color = _colorForCategory(category);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (_, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: color,
                      child: Icon(icon, color: kPrimaryColor, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryColor)),
                          const SizedBox(height: 4),
                          Text(category,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: kSecondaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kSecondaryColor),
                  ),
                  child: Column(
                    children: [
                      Text('$productPoints',
                          style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: kSecondaryColor)),
                      Text('points per ${_unitForCategory(category)}',
                          style: const TextStyle(fontSize: 13, color: kSecondaryColor)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Description',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor)),
                const SizedBox(height: 8),
                Text(
                  description.isNotEmpty ? description : 'No description available.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _unitForCategory(String cat) =>
      cat == 'Concrete' ? 'm³' : 'TON';

  IconData _iconForCategory(String cat) {
    switch (cat) {
      case 'Concrete':      return Icons.construction;
      case 'Mortar':        return Icons.handyman;
      case 'Aggregates':    return Icons.terrain;
      case 'Road Activity': return Icons.add_road;
      default:              return Icons.inventory_2_outlined;
    }
  }

  Color _colorForCategory(String cat) {
    switch (cat) {
      case 'Concrete':      return Colors.brown.shade100;
      case 'Mortar':        return Colors.orange.shade100;
      case 'Aggregates':    return Colors.green.shade100;
      case 'Road Activity': return Colors.yellow.shade100;
      default:              return Colors.blue.shade50;
    }
  }
}





// ── Product Card Widget ───────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final String name;
  final String category;
  final String description;
  final int    productPoints;
  final VoidCallback onTap;

  const _ProductCard({
    required this.name,
    required this.category,
    required this.description,
    required this.productPoints,
    required this.onTap,
  });



//unit of the product
  String _unitForCategory(String cat) =>
      cat == 'Concrete' ? 'm³' : 'tonnes';

  IconData _iconForCategory(String cat) {
    switch (cat) {
      case 'Concrete':   return Icons.construction;
      case 'Mortar':     return Icons.handyman;
      case 'Aggregates':    return Icons.terrain;
      case 'Road Activity': return Icons.add_road;
      default:              return Icons.inventory_2_outlined;
    }
  }





  Color _colorForCategory(String cat) {
    switch (cat) {
      case 'Concrete':   return Colors.brown.shade100;
      case 'Mortar':     return Colors.orange.shade100;
      case 'Aggregates':    return Colors.green.shade100;
      case 'Road Activity': return Colors.yellow.shade100;
      default:              return Colors.blue.shade50;
    }
  }




  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
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
                  Text(
                    'pts/${_unitForCategory(category)}',
                    style: const TextStyle(color: kSecondaryColor, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

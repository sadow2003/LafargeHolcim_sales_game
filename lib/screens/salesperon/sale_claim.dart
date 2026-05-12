import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart'; // Camera / gallery picker
import 'package:lafargeholcim_sales_game/widgets/_buildDrawer.dart';
import '../../main.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../services/notification_service.dart';



//start the screen sales claim
class SaleClaimPage extends StatefulWidget {
  const SaleClaimPage({super.key});

  @override
  State<SaleClaimPage> createState() => _SaleClaimPageState();
}





class _SaleClaimPageState extends State<SaleClaimPage> {
//this create a unique key that links to the form widget allowing us to manipulate it
  final _formKey        = GlobalKey<FormState>();

  final _quantityCtrl   = TextEditingController();

  final _imagePicker    = ImagePicker(); //image and camera 

  final User? _currentUser = FirebaseAuth.instance.currentUser;

//I'll store a future Firestore query here, assigned before the widget first builds.
  late Future<QuerySnapshot> _productsFuture;



  // Start variables.
  bool    _isLoading       = false;
  Uint8List? _proofImage;     // The image bytes picked by the user, uint8list(Unit int 8 bytes List)
  String? _selectedProductId; // Firestore document ID of the chosen product
  String? _selectedProductName;
  String? _selectedProductCategory;
  int     _productPoints   = 0; // Points per unit for the selected product
  int     _estimatedPoints = 0; // Live preview: productPoints × quantity


//it collects the documents of products and checks whether the sales window is open
  late Future<DocumentSnapshot> _salesEventFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = FirebaseFirestore.instance
      .collection('products')
      .orderBy('name')
      .get();
    _salesEventFuture = FirebaseFirestore.instance
      .collection('settings')
      .doc('salesEvent')
      .get();
  }


//delete the memory contained in the input text 
  @override
  void dispose() {
    _quantityCtrl.dispose();
    super.dispose();
  }



  // ── Recalculate estimated points ─────────────────────────────────────────
  // this is called every time user changes the quatity of the product
  void _updateEstimatedPoints() {
    final qty = int.tryParse(_quantityCtrl.text) ?? 0;
    setState(() {
      _estimatedPoints = _productPoints * qty;
    });
  }



  
  // ── Pick Image ────────────────────────────────────────────────────────────
  // Show a bottom sheet for galery and camera
  Future<void> _pickImage(ImageSource source) async {
    // pickImage() returns null if the user cancels.
    final XFile? picked = await _imagePicker.pickImage(
      source:     source,
      imageQuality: 70, // compress image to 70% quality for a small file size 5mb
      maxWidth:   1280, //the maximum width of the image 1280 pixels
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();//it transfomes the file image into byte code for Uint8list
      setState(() {
        _proofImage = bytes;
      });
    }
  }



  void _showImageSourceSheet() {
    //it creates a window at the bottom of the screen 
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),

      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            const SizedBox(height: 8),

            //the camera option
            ListTile(
              leading: const Icon(Icons.camera_alt, color: kPrimaryColor),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);//specify the camera option
              },
            ),


            //the galery option
            ListTile(
              leading: const Icon(Icons.photo_library, color: kPrimaryColor),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);//specify the galery option
              },
            ),




            const SizedBox(height: 8),


          ],
        ),
      ),
    );
  }

  // ── Submit Sale ───────────────────────────────────────────────────────────
  Future<void> _submitSale() async {

    // Validate all text fields first.
    if (!_formKey.currentState!.validate()) return;


    // Check that a product was selected.
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product.'),
          backgroundColor: Colors.orange,
        ),
      );
      //return to original sale page
      return;
    }




    // Check that a proof photo was attached.
    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please attach a proof photo (receipt or contract).'),
          backgroundColor: Colors.orange,
        ),
      );
       //return to original sale page
      return;
    }

    //set the state of the widjet into the loading state
    setState(() => _isLoading = true);




    try {
      final uid      = _currentUser!.uid;
      final quantity = int.parse(_quantityCtrl.text.trim());


      // ── Step 1: Upload the proof photo to Firebase Storage ──────────────
      final fileName   = '${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()//start from the root of the storage '/'
          .child('sales_proofs') // A folder called 'sales_proofs'
          .child(fileName);



      // putFile() uploads the file; IT WAITS UNTIL THE file is uploaded
      await storageRef.putData(
        _proofImage!,
        SettableMetadata(contentType: 'image/jpeg'),
      );




      // getDownloadURL() gives us the url of the image to better store it 
      final proofImageUrl = await storageRef.getDownloadURL();





      // ── Step 2: Get the salesperson's name to store with the sale 
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final userData  = userDoc.data() ?? {};
      final userName  ='${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();






      // ── Step 3: Write the sale document to Firestore
      final saleRef = await FirebaseFirestore.instance.collection('sales').add({
        'userId':        uid,
        'userName':      userName,
        'productId':     _selectedProductId,
        'productName':   _selectedProductName,
        'quantity':      quantity,
        'status':        'pending',
        'pointsAwarded': 0,
        'proofImageUrl': proofImageUrl,
        'createdAt':     FieldValue.serverTimestamp(),
      });

      // ── Step 4: Notify all managers about the new sale claim ───────────
      await NotificationService.sendNewSaleClaimNotification(
        userName:    userName,
        productName: _selectedProductName ?? '',
        quantity:    quantity,
        saleId:      saleRef.id,
      );


      //if the widget is destoryed , return to original page withou changing anything, so that it doesnt crash tha application
      if (!mounted) return;


      //message of confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sale submitted! Waiting for manager approval.'),
          backgroundColor: Colors.green,
        ),
      );





      // Go back to the original sales page 
      Navigator.pushNamed(context, '/saleclaim');


    } catch (e) {
      if (!mounted) return;
      //gives an error message if it fails at any pint in the application
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submission failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
      //no matter what happens before, this code will always run
    } finally {
      //if the widget id not destroyed we can change the state from dowloading
      if (mounted) setState(() => _isLoading = false);
    }
  }






  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: GradientAppBar(title: 'Submit Sale Claim'),
      drawer: const AppDrawer(),

      body: FutureBuilder<DocumentSnapshot>(
        future: _salesEventFuture,
        builder: (context, eventSnap) {
          // While checking the event, show a loader.
          if (eventSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Determine whether the sales window is currently open.
          final eventData = eventSnap.data?.data() as Map<String, dynamic>?;
          bool isWindowOpen = false;
          if (eventData != null) {
            final start  = (eventData['startDate'] as Timestamp).toDate();
            final end    = (eventData['endDate']   as Timestamp).toDate();
            final now    = DateTime.now();
            isWindowOpen = now.isAfter(start) && now.isBefore(end);
          }

          // If the window is closed, show a locked screen instead of the form.
          if (!isWindowOpen) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_clock,
                        size: 72, color: Colors.grey.shade400),
                    const SizedBox(height: 20),
                    Text(
                      'Sales window is closed',
                      style: TextStyle(
                        fontSize:   20,
                        fontWeight: FontWeight.bold,
                        color:      Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      eventData == null
                          ? 'No sales event has been scheduled yet.\nPlease check back later.'
                          : 'The current sales period has ended.\nPlease check back when the next event opens.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            );
          }

          // Sales window is open — show the submission form.
          return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Product Selector ─────────────────────────────────────────


              const Text(
                'Select Product',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),

              // FutureBuilder loads the product list once when the page opens.
              FutureBuilder<QuerySnapshot>(
                future: _productsFuture,
                builder: (context, snapshot) {
                  // while it loading it shows the spinning circle
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }

                  
                  final docs = snapshot.data?.docs ?? [];




                  // Build the list of dropdown items from Firestore products.
                  final items = docs.map((doc) {
                    final data   = doc.data() as Map<String, dynamic>;
                    final name   = data['name']          ?? '';
                    final pts    = data['productPoints'] ?? 0;
                    final cat    = data['category']      ?? '';
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(
                        '$name  ($cat — $pts pts/unit)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList();



                  return DropdownButtonFormField<String>(
                    //forces it to fill the available width instead of sizing to its content
                    isExpanded: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                      hintText:   'Choose a product…',
                    ),
                    items: items,
                    onChanged: (docId) {
                      if (docId == null) return;
                      // Find the selected product's data to update points.
                      final doc  = docs.firstWhere((d) => d.id == docId);
                      final data = doc.data() as Map<String, dynamic>;
                      setState(() {
                        _selectedProductId       = docId;
                        _selectedProductName     = data['name']     ?? '';
                        _selectedProductCategory = data['category'] ?? '';
                        _productPoints           = (data['productPoints'] ?? 0) as int;
                      });
                      _updateEstimatedPoints();
                    },
                    validator: (v) =>
                        v == null ? 'Please select a product' : null,
                  );
                },
              ),
              const SizedBox(height: 20),




              // ── Quantity Field ───────────────────────────────────────────
              const Text(
                'Quantity Sold',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),

              




              const SizedBox(height: 8),



              TextFormField(
                controller: _quantityCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.numbers),
                  hintText:   'e.g. 10',
                  suffixText: (_selectedProductCategory ?? '').toLowerCase().contains('concrete')
                      ? 'm³'
                      : 'tonnes',
                ),



                onChanged: (_) => _updateEstimatedPoints(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the quantity';
                  }
                  final qty = int.tryParse(value);
                  if (qty == null || qty <= 0) {
                    return 'Quantity must be a positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),


              // ── Live Points Preview ──────────────────────────────────────
              // Updates automatically as the user types the quantity of the product
              if (_selectedProductId != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kSecondaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kSecondaryColor.withValues(alpha: 0.4)),
                  ),



                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: kSecondaryColor),
                      const SizedBox(width: 8),



                      Text(
                        'Estimated points: $_estimatedPoints',
                        style: const TextStyle(
                          color: kSecondaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),



                    ],
                  ),
                ),




              const SizedBox(height: 24),



              // ── Proof Photo Section ──────────────────────────────────────
              const Text(
                'Proof Photo (receipt or contract)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),



              const SizedBox(height: 8),




              // If a photo has been picked, show a preview. 
              GestureDetector(
                onTap: _showImageSourceSheet,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color:        Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _proofImage != null
                          ? kPrimaryColor
                          : Colors.grey.shade400,
                          //if the image has been picked then the width of the border is 2 otherwise it normal
                      width: _proofImage != null ? 2 : 1,
                    ),
                  ),



                  child: _proofImage != null
                      // Show the picked image as a preview if the image id not null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.memory(
                            _proofImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )




                      // Placeholder when no photo is chosen yet if otherwise
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to take or upload a photo',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                ),
              ),




              // If a photo is already chosen, show a button to change it.
              if (_proofImage != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _showImageSourceSheet,
                  icon: const Icon(Icons.edit),
                  label: const Text('Change Photo'),
                ),
              ],





              const SizedBox(height: 32),







              // ── Submit Button ────────────────────────────────────────────
              ElevatedButton(
                onPressed: _isLoading ? null : _submitSale,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading


                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )



                    : const Text(
                        'Submit Sale Claim',
                        style: TextStyle(fontSize: 16),
                      ),
              ),



              // Reminder below the button.
              const SizedBox(height: 12),



              const Text(
                'Your sale is going to be reviewed by an manager after submitting, please wait until then',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
        // closes FutureBuilder builder
        },
      ),
    );
  }
}

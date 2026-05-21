import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lafargeholcim_sales_game/utils/app_emojis.dart';
import '../../../main.dart';
import 'event_management_service.dart';
import 'event_reward.dart';
import 'reward_fields_input.dart';

class EventDatePickerCard extends StatefulWidget {
  const EventDatePickerCard({super.key});

  @override
  State<EventDatePickerCard> createState() => _EventDatePickerCardState();
}

class _EventDatePickerCardState extends State<EventDatePickerCard> {
  DateTimeRange? _pickedRange;
  bool           _isSaving = false;

  final _rewardAmounts = List.generate(3, (_) => TextEditingController());

  static const _categories = ['Concrete', 'Mortar','Aggregates','Road Activivty'];
  
  String? _selectedCategory;
  String? _selectedProductId;
  String? _selectedProductName;
  final _targetQtyCtrl = TextEditingController();

  List<QueryDocumentSnapshot> _categoryProducts =[];
  bool _loadingProducts =false;

  @override
  void dispose(){
    for(final c in _rewardAmounts){c.dispose();}
    _targetQtyCtrl.dispose();
    super.dispose();
  }
  String _fmtDateTime(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/'
    '${d.year}  '
    '${d.hour.toString().padLeft(2, '0')}:'
    '${d.minute.toString().padLeft(2, '0')}';

    String _unitLabel(){
      if(_selectedCategory == 'Concrete') return 'm³';
      if (_selectedCategory !=null) return 'toones';
      return 'units';
    }

  Future<void>_loadProductsForCategory(String category)async{
    setState((){_loadingProducts=true;_categoryProducts = [];});
    try{
      final snap =await FirebaseFirestore.instance
          .collection('products')
          .where('category',isEqualTo: category)
          .get();
      if(mounted){
        final sorted = snap.docs.toList()
            ..sort((a,b){
              final nameA = (a.data()['name'] as String?) ?? '';
              final nameB = (b.data()['name'] as String?) ?? '';
              return nameA.compareTo(nameB);
            });
            setState((){
              _categoryProducts =sorted;
              _loadingProducts = false;
            });
      }

    }catch(e){
      debugPrint('Failed to load products: $e');
      if (mounted) setState(()=>_loadingProducts = false);
    }

  }

   Future<void> _pickDateRange() async {
    final now = DateTime.now();

    final dates = await showDateRangePicker(
      context:          context,
      firstDate:        DateTime(now.year, now.month, now.day),
      lastDate:         DateTime(now.year + 3),
      initialDateRange: _pickedRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary:   kPrimaryColor,
            onPrimary: Colors.white,
            surface:   Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (dates == null || !mounted) return;

    final startTime = await showTimePicker(
      context:     context,
      initialTime: TimeOfDay.fromDateTime(_pickedRange?.start ?? now),
      helpText:    'Start Time',
    );
    if (startTime == null || !mounted) return;

    final endTime = await showTimePicker(
      context:     context,
      initialTime: TimeOfDay.fromDateTime(_pickedRange?.end ?? now),
      helpText: 'End Time',
    );
    if (endTime == null || !mounted) return;

    setState(() => _pickedRange = DateTimeRange(
      start: DateTime(dates.start.year, dates.start.month, dates.start.day,
                      startTime.hour, startTime.minute),
      end:   DateTime(dates.end.year,   dates.end.month,   dates.end.day,
                      endTime.hour,   endTime.minute),
    ));
  }

  bool get _canSave{
    if (_pickedRange == null) return false;
    if(_selectedCategory == null) return false;
    final qty = int.tryParse(_targetQtyCtrl.text.trim());
    if(qty == null || qty <= 0) return false;
    return _rewardAmounts.every((c){
      final v =double.tryParse(c.text.trim());
      return v != null && v>0;
    }); 
  }


  Future<void> _saveEvent()async{
    if(!_canSave) return;
    setState(() => _isSaving=true);
    try{
      final rewards = _rewardAmounts
          .map((c) => MoneyReward(amount: double.parse(c.text.trim())))
          .toList();
      await EventManagementService.saveEvent(
        _pickedRange!,
        rewards,
        productCategory: _selectedCategory!,
        productId: _selectedProductId,
        productName: _selectedProductName,
        targetQuantity:  int.parse(_targetQtyCtrl.text.trim()),
        );
        if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('Sales event saved successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      setState((){
        _pickedRange = null;
        _selectedCategory = null ;
        _selectedProductId = null ;
        _selectedProductName = null;
        _categoryProducts = [];
        for (final c in _rewardAmounts){c.clear();}
        _targetQtyCtrl.clear();
      });
    }catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving event: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Event Rewards ─────────────────────────────────────────────
            const Text(
              'Event Rewards',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            const Text(
              'Set the cash prize (MAD) for each of the top 3 salespersons.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 14),
            RewardFieldsInput(
              rankLabel:  '${AppEmojis.gold} 1st Place',
              rankColor:  const Color(0xFFFFD700),
              amountCtrl: _rewardAmounts[0],
            ),
            const SizedBox(height: 12),
            RewardFieldsInput(
              rankLabel:  '${AppEmojis.silver} 2nd Place',
              rankColor:  const Color(0xFFC0C0C0),
              amountCtrl: _rewardAmounts[1],
            ),
            const SizedBox(height: 12),
            RewardFieldsInput(
              rankLabel:  '${AppEmojis.bronze} 3rd Place',
              rankColor:  const Color(0xFFCD7F32),
              amountCtrl: _rewardAmounts[2],
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Progress',
              style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15),
            ),
            const SizedBox(height:4),
            const Text(
              'Choose which product type (and optionally a specific product) '
              'counts toward the progress leaderboard.',
              style: TextStyle(fontSize: 12,color: Colors.black54),
            ),
            const SizedBox(height: 14),

            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Product Category',
                prefixIcon: Icon(Icons.category_outlined),
                border: OutlineInputBorder(),
              ),
              child : DropdownButton<String>(
                value:  _selectedCategory,
                isExpanded: true,
                underline: const SizedBox(),
                hint: const Text('Selecte a product category'),
                items: _categories  
                    .map((c)=> DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val){
                  setState((){
                    _selectedCategory = val;
                    _selectedProductId = null;
                    _selectedProductName = null;
                    _categoryProducts = [];
                  });
                  if(val != null) _loadProductsForCategory(val);
                },
                ),
              ),
              const SizedBox(height: 14),

              if(_selectedCategory != null)...[
                if(_loadingProducts)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: LinearProgressIndicator(),
                  )
                  else
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Specific Product (optional)',
                      prefixIcon: const Icon(Icons.inventory_2_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    child: DropdownButton<String?>(
                      value: _selectedProductId,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Any $_selectedCategory product'),
                          ),
                          ..._categoryProducts.map((doc){
                            final name =(doc.data() as Map<String,dynamic>)['name']
                                as String? ??
                              doc.id;
                            return DropdownMenuItem<String?>(
                              value:doc.id,
                              child: Text(name),
                            );
                          }),
                      ], 
                      onChanged: (val){
                        if (val == null){
                          setState((){
                            _selectedProductId = null;
                            _selectedProductName = null;
                          });
                        } else {
                          final doc = _categoryProducts.firstWhere((d) => d.id ==val);
                          final name = (doc.data() as Map<String,dynamic>)['name']
                              as String ? ??
                            val;
                          setState(() {
                            _selectedProductId =val;
                            _selectedProductName = name;
                          });
                        }
                      }
                      ),
                  ),
                  const SizedBox(height:14),
              ],

              TextField(
                controller: _targetQtyCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Target Quantity',
                  hintText: 'e.g. 100',
                  prefixIcon: const Icon(Icons.flag_outlined),
                  suffixText: _unitLabel(),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height:20),
              const Divider(),
              const SizedBox(height: 8),
              _DateRangeField(
                pickedRange: _pickedRange,
                fmtDateTime : _fmtDateTime,
                onTap: _pickDateRange,
              ),
               const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (_canSave && !_isSaving) ? _saveEvent : null,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Save Sales Window'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRangeField extends StatelessWidget {
  const _DateRangeField({
    required this.pickedRange,
    required this.fmtDateTime,
    required this.onTap,
  });

  final DateTimeRange?            pickedRange;
  final String Function(DateTime) fmtDateTime;
  final VoidCallback              onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:        onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width:   double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border:       Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.date_range_outlined, color: kPrimaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                pickedRange == null
                    ? 'Tap to pick a date range'
                    : '${fmtDateTime(pickedRange!.start)}  →  ${fmtDateTime(pickedRange!.end)}',
                style: TextStyle(
                  fontSize: 15,
                  color:    pickedRange == null ? Colors.black38 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

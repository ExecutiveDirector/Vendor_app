import 'package:flutter/material.dart';
import '../data/product_model.dart';
import '../data/products_api.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;
  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _brand;
  late final TextEditingController _description;
  late final TextEditingController _size;
  late final TextEditingController _price;
  late final TextEditingController _stock;

  List<Category> _categories = [];
  List<dynamic> _outlets = [];
  int? _selectedCategory;
  String? _selectedOutlet;
  bool _isActive = true;
  bool _isFeatured = false;
  bool _saving = false;
  bool _loading = true;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.productName ?? '');
    _code = TextEditingController(text: p?.productCode ?? '');
    _brand = TextEditingController(text: p?.brand ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _size = TextEditingController(text: p?.sizeSpecification ?? '');
    _price = TextEditingController(text: p?.basePrice.toString() ?? '');
    _stock = TextEditingController(text: p?.currentStock?.toString() ?? '0');
    _selectedCategory = p?.categoryId;
    _isActive = p?.isActive ?? true;
    _isFeatured = p?.isFeatured ?? false;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final cats = await ProductsApi.categories();
      final outlets = await ProductsApi.outlets();
      if (mounted) {
        setState(() {
          _categories = cats;
          _outlets = outlets;
          if (outlets.isNotEmpty) {
            _selectedOutlet = outlets.first['outlet_id']?.toString();
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _brand.dispose();
    _description.dispose();
    _size.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final payload = {
        'product_name': _name.text.trim(),
        'product_code': _code.text.trim(),
        'brand': _brand.text.trim(),
        'description': _description.text.trim(),
        'size_specification': _size.text.trim(),
        'base_price': double.parse(_price.text),
        'category_id': _selectedCategory,
        'is_active': _isActive,
        'is_featured': _isFeatured,
        'stock_quantity': int.tryParse(_stock.text) ?? 0,
        'outlet_id': _selectedOutlet,
      };
      if (_isEdit) {
        await ProductsApi.update(widget.product!.productId, payload);
      } else {
        await ProductsApi.create(payload);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Product updated!' : 'Product created!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Product' : 'Add Product'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Save'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _section('Basic Info', [
                    _field('Product Name *', _name, required: true),
                    const SizedBox(height: 12),
                    _field('Product Code / SKU *', _code, required: true),
                    const SizedBox(height: 12),
                    _field('Brand', _brand),
                    const SizedBox(height: 12),
                    _field('Description', _description, maxLines: 3),
                    const SizedBox(height: 12),
                    _field('Size / Specification', _size,
                        hint: 'e.g. 6kg, 13kg, 35kg'),
                  ]),
                  const SizedBox(height: 16),
                  _section('Pricing & Stock', [
                    _field('Base Price (KES) *', _price,
                        required: true,
                        keyboardType: TextInputType.number, validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null)
                        return 'Enter a valid number';
                      return null;
                    }),
                    const SizedBox(height: 12),
                    _field('Initial Stock Quantity', _stock,
                        keyboardType: TextInputType.number),
                  ]),
                  const SizedBox(height: 16),
                  _section('Category & Outlet', [
                    if (_categories.isNotEmpty)
                      DropdownButtonFormField<int>(
                        value: _selectedCategory,
                        decoration:
                            const InputDecoration(labelText: 'Category'),
                        items: _categories
                            .map((c) => DropdownMenuItem(
                                value: c.categoryId,
                                child: Text(c.categoryName)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedCategory = v),
                      ),
                    const SizedBox(height: 12),
                    if (_outlets.isNotEmpty && !_isEdit)
                      DropdownButtonFormField<String>(
                        value: _selectedOutlet,
                        decoration: const InputDecoration(labelText: 'Outlet'),
                        items: _outlets
                            .map((o) => DropdownMenuItem<String>(
                                value: o['outlet_id']?.toString(),
                                child: Text(o['outlet_name'] ?? '')))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedOutlet = v),
                      ),
                  ]),
                  const SizedBox(height: 16),
                  _section('Settings', [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active'),
                      subtitle: const Text('Product visible to customers'),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Featured'),
                      subtitle: const Text('Show in featured section'),
                      value: _isFeatured,
                      onChanged: (v) => setState(() => _isFeatured = v),
                    ),
                  ]),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: Text(
                      _saving
                          ? 'Saving...'
                          : (_isEdit ? 'Update Product' : 'Create Product'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    ]);
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      validator: validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null),
    );
  }
}

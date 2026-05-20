import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/dio_client.dart';
import './image_picker.dart';

class AddProductDialog extends StatefulWidget {
  final List<dynamic> categories;
  final Map<String, dynamic>? product;
  final VoidCallback onSave;

  const AddProductDialog({
    super.key,
    required this.categories,
    required this.onSave,
    this.product,
  });

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final formKey = GlobalKey<FormState>();
  final imageService = ImagePickerService();

  late TextEditingController nameController;
  late TextEditingController codeController;
  late TextEditingController brandController;
  late TextEditingController priceController;
  late TextEditingController minPriceController;
  late TextEditingController maxPriceController;
  late TextEditingController stockController;
  late TextEditingController sizeController;
  late TextEditingController weightController;
  late TextEditingController carbonFootprintController;
  late TextEditingController descriptionController;

  int? selectedCategory;
  String selectedUnit = 'kg';
  bool isActive = true;
  bool isFeatured = false;

  List<XFile> selectedImages = [];
  bool isSaving = false;
  bool isUploadingImages = false;
  int uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    codeController = TextEditingController();
    brandController = TextEditingController();
    priceController = TextEditingController();
    minPriceController = TextEditingController();
    maxPriceController = TextEditingController();
    stockController = TextEditingController(text: '0');
    sizeController = TextEditingController();
    weightController = TextEditingController();
    carbonFootprintController = TextEditingController();
    descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    codeController.dispose();
    brandController.dispose();
    priceController.dispose();
    minPriceController.dispose();
    maxPriceController.dispose();
    stockController.dispose();
    sizeController.dispose();
    weightController.dispose();
    carbonFootprintController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _showImagePickerOptions() async {
    final result = await imageService.showImageSourceBottomSheet(
      context,
      allowMultiple: true,
    );

    if (result != null) {
      if (result is List<XFile>) {
        await _handleMultipleImages(result);
      } else if (result is XFile) {
        await _handleSingleImage(result);
      }
    }
  }

  Future<void> _handleSingleImage(XFile image) async {
    final validation = await imageService.validateImage(image);

    if (!validation.isValid) {
      _showSnackBar(validation.errorMessage ?? 'Invalid image', isError: true);
      return;
    }

    setState(() {
      selectedImages.add(image);
    });
  }

  Future<void> _handleMultipleImages(List<XFile> images) async {
    int addedCount = 0;
    int failedCount = 0;

    for (var image in images) {
      final validation = await imageService.validateImage(image);

      if (validation.isValid) {
        setState(() {
          selectedImages.add(image);
        });
        addedCount++;
      } else {
        failedCount++;
      }
    }

    if (failedCount > 0) {
      _showSnackBar(
        '$addedCount image(s) added, $failedCount failed validation',
        isError: failedCount > addedCount,
      );
    } else {
      _showSnackBar('$addedCount image(s) added successfully');
    }
  }

  void _removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  bool _validatePrices() {
    final basePrice = double.tryParse(priceController.text);
    final minPrice = minPriceController.text.isEmpty
        ? null
        : double.tryParse(minPriceController.text);
    final maxPrice = maxPriceController.text.isEmpty
        ? null
        : double.tryParse(maxPriceController.text);

    if (basePrice == null || basePrice <= 0) {
      _showSnackBar('Base price must be greater than 0', isError: true);
      return false;
    }

    if (minPrice != null && maxPrice != null && minPrice > maxPrice) {
      _showSnackBar('Min price cannot be greater than max price',
          isError: true);
      return false;
    }

    if (minPrice != null && basePrice < minPrice) {
      _showSnackBar('Base price cannot be less than min price', isError: true);
      return false;
    }

    if (maxPrice != null && basePrice > maxPrice) {
      _showSnackBar('Base price cannot be greater than max price',
          isError: true);
      return false;
    }

    return true;
  }

  Future<void> _saveProduct() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedCategory == null) {
      _showSnackBar('Please select a category', isError: true);
      return;
    }
    if (!_validatePrices()) return;

    setState(() => isSaving = true);

    try {
      List<String> imageUrls = [];

      // Upload images if any
      if (selectedImages.isNotEmpty) {
        setState(() => isUploadingImages = true);

        imageUrls = await imageService.uploadMultipleImages(
          images: selectedImages,
          uploadUrl: '/vendor/upload-image',
          dio: ApiClient.dio,
          onBatchProgress: (current, total) {
            setState(() => uploadProgress = current);
          },
        );

        setState(() => isUploadingImages = false);
      }

      // Prepare product payload
      final payload = {
        'product_name': nameController.text.trim(),
        'product_code': codeController.text.trim(),
        'category_id': selectedCategory,
        'brand': brandController.text.trim().isEmpty
            ? null
            : brandController.text.trim(),
        'base_price': double.parse(priceController.text),
        'min_price': minPriceController.text.isEmpty
            ? null
            : double.parse(minPriceController.text),
        'max_price': maxPriceController.text.isEmpty
            ? null
            : double.parse(maxPriceController.text),
        'stock_quantity': int.parse(stockController.text),
        'size_specification': sizeController.text.trim().isEmpty
            ? null
            : sizeController.text.trim(),
        'unit_of_measure': selectedUnit,
        'weight_kg': weightController.text.isEmpty
            ? null
            : double.parse(weightController.text),
        'carbon_footprint_kg': carbonFootprintController.text.isEmpty
            ? null
            : double.parse(carbonFootprintController.text),
        'description': descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        'is_active': isActive,
        'is_featured': isFeatured,
        'product_images': imageUrls.isEmpty ? null : jsonEncode(imageUrls),
      };

      // Create product
      await ApiClient.dio.post('/vendor/products', data: payload);

      if (mounted) {
        Navigator.pop(context);
        widget.onSave();
        _showSnackBar('Product added successfully');
      }
    } catch (e) {
      _showSnackBar('Error adding product: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
          isUploadingImages = false;
          uploadProgress = 0;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.add_box, color: Colors.green),
          const SizedBox(width: 8),
          const Expanded(child: Text('Add New Product')),
          if (isUploadingImages)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
      content: SizedBox(
        width: isWideScreen ? screenWidth * 0.7 : screenWidth * 0.9,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Images Section
                _buildSectionHeader(
                    'Product Images (${selectedImages.length})'),
                _buildImageSection(),

                if (isUploadingImages)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          value: uploadProgress / selectedImages.length,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Uploading image $uploadProgress of ${selectedImages.length}...',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Basic Information
                _buildSectionHeader('Basic Information'),
                _buildTextField(
                  controller: nameController,
                  label: 'Product Name',
                  required: true,
                  icon: Icons.shopping_bag,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: codeController,
                  label: 'Product Code',
                  required: true,
                  icon: Icons.qr_code,
                  hint: 'Unique identifier',
                ),
                const SizedBox(height: 16),
                _buildCategoryDropdown(),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: brandController,
                  label: 'Brand',
                  icon: Icons.business,
                ),
                const SizedBox(height: 24),

                // Pricing
                _buildSectionHeader('Pricing'),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: priceController,
                        label: 'Base Price',
                        required: true,
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        prefix: 'KES ',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: stockController,
                        label: 'Stock Quantity',
                        required: true,
                        icon: Icons.inventory,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: minPriceController,
                        label: 'Min Price',
                        icon: Icons.arrow_downward,
                        keyboardType: TextInputType.number,
                        prefix: 'KES ',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: maxPriceController,
                        label: 'Max Price',
                        icon: Icons.arrow_upward,
                        keyboardType: TextInputType.number,
                        prefix: 'KES ',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Specifications
                _buildSectionHeader('Specifications'),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: sizeController,
                        label: 'Size Specification',
                        icon: Icons.straighten,
                        hint: 'e.g., 13kg, 6kg',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _buildUnitDropdown()),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: weightController,
                        label: 'Weight (kg)',
                        icon: Icons.scale,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: carbonFootprintController,
                        label: 'Carbon Footprint (kg)',
                        icon: Icons.eco,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: descriptionController,
                  label: 'Description',
                  icon: Icons.description,
                  maxLines: 4,
                ),
                const SizedBox(height: 24),

                // Status Switches
                _buildSectionHeader('Product Status'),
                Row(
                  children: [
                    Expanded(
                      child: SwitchListTile(
                        title: const Text('Active'),
                        subtitle: const Text('Product is visible'),
                        value: isActive,
                        onChanged: (value) => setState(() => isActive = value),
                        activeColor: Colors.green,
                      ),
                    ),
                    Expanded(
                      child: SwitchListTile(
                        title: const Text('Featured'),
                        subtitle: const Text('Show in featured'),
                        value: isFeatured,
                        onChanged: (value) =>
                            setState(() => isFeatured = value),
                        activeColor: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: isSaving ? null : _saveProduct,
          icon: isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.add),
          label: Text(isSaving ? 'Adding...' : 'Add Product'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedImages.isNotEmpty)
          Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedImages.length,
              itemBuilder: (context, index) {
                return _buildImagePreview(
                  imageFile: File(selectedImages[index].path),
                  onRemove: () => _removeImage(index),
                );
              },
            ),
          ),
        OutlinedButton.icon(
          onPressed: isUploadingImages ? null : _showImagePickerOptions,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Add Images'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.green,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tip: You can select multiple images at once',
          style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildImagePreview({
    required File imageFile,
    required VoidCallback onRemove,
  }) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              imageFile,
              fit: BoxFit.cover,
              width: 100,
              height: 100,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? prefix,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: Colors.green) : null,
        prefixText: prefix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return 'This field is required';
        }
        if (keyboardType == TextInputType.number &&
            value != null &&
            value.isNotEmpty) {
          if (double.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
        }
        return null;
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<int>(
      value: selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category *',
        prefixIcon: const Icon(Icons.category, color: Colors.green),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: widget.categories.isEmpty
          ? [
              const DropdownMenuItem<int>(
                  value: null,
                  enabled: false,
                  child: Text('No categories available'))
            ]
          : widget.categories.map<DropdownMenuItem<int>>((cat) {
              return DropdownMenuItem<int>(
                value: cat['category_id'],
                child: Text(cat['category_name'] ?? 'N/A'),
              );
            }).toList(),
      onChanged: widget.categories.isEmpty
          ? null
          : (value) => setState(() => selectedCategory = value),
      validator: (value) => value == null && widget.categories.isNotEmpty
          ? 'Please select a category'
          : null,
    );
  }

  Widget _buildUnitDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedUnit,
      decoration: InputDecoration(
        labelText: 'Unit *',
        prefixIcon: const Icon(Icons.straighten, color: Colors.green),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: const [
        DropdownMenuItem(value: 'kg', child: Text('Kilograms')),
        DropdownMenuItem(value: 'liters', child: Text('Liters')),
        DropdownMenuItem(value: 'pieces', child: Text('Pieces')),
        DropdownMenuItem(value: 'meters', child: Text('Meters')),
      ],
      onChanged: (value) => setState(() => selectedUnit = value!),
      validator: (value) => value == null ? 'Please select a unit' : null,
    );
  }
}

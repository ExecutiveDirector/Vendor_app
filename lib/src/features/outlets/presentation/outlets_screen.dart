import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
//import '../../../core/config.dart'; // Contains AppConfig.apiBaseUrl
//import '../../../core/services/local_storage.dart'; // Contains LocalStorage.getToken
//import 'api_client.dart'; // Dio client with configured base URL and interceptor
import '../../../core/api/dio_client.dart';
import 'dart:convert';

class OutletsScreen extends StatefulWidget {
  const OutletsScreen({super.key});

  @override
  State<OutletsScreen> createState() => _OutletsScreenState();
}

class _OutletsScreenState extends State<OutletsScreen> {
  // State management
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  List<VendorOutlet> _outlets = [];

  @override
  void initState() {
    super.initState();
    _loadOutlets();
  }

  /// Loads outlets from the API
  Future<void> _loadOutlets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiClient.dio.get('/vendor/outlets');
      if (response.statusCode == 200) {
        setState(() {
          _outlets = (response.data['outlets'] as List)
              .map((outlet) => VendorOutlet.fromJson(outlet))
              .toList();
        });
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to load outlets: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      setState(() => _error = _formatDioError(e));
    } catch (e) {
      setState(() => _error = 'Unexpected error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Creates a new outlet
  Future<void> _createOutlet(VendorOutletCreate outlet) async {
    try {
      final response = await ApiClient.dio.post(
        '/vendor/outlets',
        data: outlet.toJson(),
      );

      if (response.statusCode == 201) {
        await _loadOutlets();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Outlet created successfully')),
          );
        }
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to create outlet: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${_formatDioError(e)}')),
        );
      }
    }
  }

  /// Updates an existing outlet
  Future<void> _updateOutlet(VendorOutlet outlet) async {
    try {
      final response = await ApiClient.dio.put(
        '/vendor/outlets/${outlet.outletId}',
        data: outlet.toJson(),
      );

      if (response.statusCode == 200) {
        await _loadOutlets();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Outlet updated successfully')),
          );
        }
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to update outlet: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${_formatDioError(e)}')),
        );
      }
    }
  }

  /// Deletes an outlet by ID
  Future<void> _deleteOutlet(int outletId) async {
    try {
      final response = await ApiClient.dio.delete('/vendor/outlets/$outletId');

      if (response.statusCode == 200) {
        setState(() {
          _outlets.removeWhere((o) => o.outletId == outletId);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Outlet deleted successfully')),
          );
        }
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to delete outlet: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${_formatDioError(e)}')),
        );
      }
    }
  }

  /// Formats Dio errors for user-friendly display
  String _formatDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please check your internet connection.';
    } else if (e.response != null) {
      return 'Failed with status ${e.response!.statusCode}: ${e.message ?? 'Unknown error'}';
    } else {
      return 'Network error: ${e.message ?? 'Unknown error'}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && !_isRefreshing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Error: $_error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadOutlets,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Outlet Management'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOutlets,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _isRefreshing = true);
          await _loadOutlets();
          setState(() => _isRefreshing = false);
        },
        child: _buildOutletsList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOutletDialog,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Add Outlet'),
      ),
    );
  }

  Widget _buildOutletsList() {
    if (_outlets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No outlets found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first outlet to get started',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddOutletDialog,
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Add Outlet'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _outlets.length,
      itemBuilder: (context, index) => _buildOutletCard(_outlets[index]),
    );
  }

  Widget _buildOutletCard(VendorOutlet outlet) {
    final operatingHours = outlet.operatingHours != null
        ? _parseOperatingHours(outlet.operatingHours!)
        : null;

    final isOpen =
        operatingHours != null ? _isOutletOpen(operatingHours) : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Icon(
                    Icons.store,
                    color: Colors.blue[600],
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              outlet.outletName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          if (isOpen != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isOpen ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isOpen ? 'Open' : 'Closed',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Code: ${outlet.outletCode}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _formatAddress(outlet),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleOutletAction(value, outlet),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'view_map',
                      child: Row(
                        children: [
                          Icon(Icons.map, size: 18),
                          SizedBox(width: 8),
                          Text('View on Map'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'inventory',
                      child: Row(
                        children: [
                          Icon(Icons.inventory, size: 18),
                          SizedBox(width: 8),
                          Text('View Inventory'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (outlet.contactPhone != null) ...[
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    outlet.contactPhone!,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (outlet.managerName != null) ...[
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Manager: ${outlet.managerName}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (operatingHours != null) ...[
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    _getCurrentDayHours(operatingHours),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (outlet.facilities != null && outlet.facilities!.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _parseFacilities(outlet.facilities!)
                    .map((facility) => _buildFacilityChip(facility))
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showOutletDetails(outlet),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _editOutlet(outlet),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityChip(String facility) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Text(
        facility,
        style: TextStyle(
          color: Colors.blue[700],
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatAddress(VendorOutlet outlet) {
    final parts = <String>[
      outlet.addressLine1,
      if (outlet.addressLine2 != null && outlet.addressLine2!.isNotEmpty)
        outlet.addressLine2!,
      outlet.city,
      outlet.county,
    ];
    return parts.join(', ');
  }

  Map<String, dynamic>? _parseOperatingHours(String operatingHours) {
    try {
      return jsonDecode(operatingHours);
    } catch (e) {
      return null;
    }
  }

  List<String> _parseFacilities(String facilities) {
    try {
      final parsed = jsonDecode(facilities);
      if (parsed is List) {
        return parsed.cast<String>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  bool _isOutletOpen(Map<String, dynamic> operatingHours) {
    final now = DateTime.now();
    final today = _getDayName(now.weekday);
    final todayHours = operatingHours[today.toLowerCase()];

    if (todayHours == null) return false;

    try {
      final openTime = _parseTimeString(todayHours['open']);
      final closeTime = _parseTimeString(todayHours['close']);

      if (openTime == null || closeTime == null) return false;

      final currentTime = TimeOfDay.now();
      final currentMinutes = currentTime.hour * 60 + currentTime.minute;
      final openMinutes = openTime.hour * 60 + openTime.minute;
      final closeMinutes = closeTime.hour * 60 + closeTime.minute;

      if (closeMinutes < openMinutes) {
        // Crosses midnight
        return currentMinutes >= openMinutes || currentMinutes <= closeMinutes;
      } else {
        return currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
      }
    } catch (e) {
      return false;
    }
  }

  String _getCurrentDayHours(Map<String, dynamic> operatingHours) {
    final now = DateTime.now();
    final today = _getDayName(now.weekday);
    final todayHours = operatingHours[today.toLowerCase()];

    if (todayHours == null) {
      return 'Closed today';
    }

    return '${todayHours['open']} - ${todayHours['close']}';
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  TimeOfDay? _parseTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      // Handle parsing errors
    }
    return null;
  }

  void _handleOutletAction(String action, VendorOutlet outlet) {
    switch (action) {
      case 'edit':
        _editOutlet(outlet);
        break;
      case 'view_map':
        _viewOnMap(outlet);
        break;
      case 'inventory':
        _viewInventory(outlet);
        break;
      case 'delete':
        _showDeleteConfirmation(outlet);
        break;
    }
  }

  void _showAddOutletDialog() {
    showDialog(
      context: context,
      builder: (context) => OutletFormDialog(
        onSave: (outlet) => _createOutlet(outlet),
      ),
    );
  }

  void _editOutlet(VendorOutlet outlet) {
    showDialog(
      context: context,
      builder: (context) => OutletFormDialog(
        outlet: outlet,
        onSave: (updatedOutlet) => _updateOutlet(updatedOutlet),
      ),
    );
  }

  void _showOutletDetails(VendorOutlet outlet) {
    showDialog(
      context: context,
      builder: (context) => OutletDetailsDialog(outlet: outlet),
    );
  }

  void _viewOnMap(VendorOutlet outlet) {
    Navigator.pushNamed(
      context,
      '/map',
      arguments: {
        'latitude': outlet.latitude,
        'longitude': outlet.longitude,
        'title': outlet.outletName,
      },
    );
  }

  void _viewInventory(VendorOutlet outlet) {
    Navigator.pushNamed(
      context,
      '/inventory',
      arguments: {'outlet_id': outlet.outletId},
    );
  }

  void _showDeleteConfirmation(VendorOutlet outlet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Outlet'),
        content: Text(
          'Are you sure you want to delete "${outlet.outletName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteOutlet(outlet.outletId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Data models
class VendorOutlet {
  final int outletId;
  final int vendorId;
  final String outletName;
  final String outletCode;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String county;
  final String? postalCode;
  final double latitude;
  final double longitude;
  final String? contactPhone;
  final String? managerName;
  final String? operatingHours;
  final String? facilities;

  VendorOutlet({
    required this.outletId,
    required this.vendorId,
    required this.outletName,
    required this.outletCode,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.county,
    this.postalCode,
    required this.latitude,
    required this.longitude,
    this.contactPhone,
    this.managerName,
    this.operatingHours,
    this.facilities,
  });

  factory VendorOutlet.fromJson(Map<String, dynamic> json) {
    return VendorOutlet(
      outletId: json['outlet_id'],
      vendorId: json['vendor_id'],
      outletName: json['outlet_name'],
      outletCode: json['outlet_code'],
      addressLine1: json['address_line_1'],
      addressLine2: json['address_line_2'],
      city: json['city'],
      county: json['county'],
      postalCode: json['postal_code'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      contactPhone: json['contact_phone'],
      managerName: json['manager_name'],
      operatingHours: json['operating_hours'],
      facilities: json['facilities'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'outlet_id': outletId,
      'vendor_id': vendorId,
      'outlet_name': outletName,
      'outlet_code': outletCode,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'county': county,
      'postal_code': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'contact_phone': contactPhone,
      'manager_name': managerName,
      'operating_hours': operatingHours,
      'facilities': facilities,
    };
  }
}

class VendorOutletCreate {
  final String outletName;
  final String outletCode;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String county;
  final String? postalCode;
  final double latitude;
  final double longitude;
  final String? contactPhone;
  final String? managerName;
  final String? operatingHours;
  final String? facilities;

  VendorOutletCreate({
    required this.outletName,
    required this.outletCode,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.county,
    this.postalCode,
    required this.latitude,
    required this.longitude,
    this.contactPhone,
    this.managerName,
    this.operatingHours,
    this.facilities,
  });

  Map<String, dynamic> toJson() {
    return {
      'outlet_name': outletName,
      'outlet_code': outletCode,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'county': county,
      'postal_code': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'contact_phone': contactPhone,
      'manager_name': managerName,
      'operating_hours': operatingHours,
      'facilities': facilities,
    };
  }
}

// Form dialog for creating/editing outlets
class OutletFormDialog extends StatefulWidget {
  final VendorOutlet? outlet;
  final Function(dynamic) onSave;

  const OutletFormDialog({
    super.key,
    this.outlet,
    required this.onSave,
  });

  @override
  State<OutletFormDialog> createState() => _OutletFormDialogState();
}

class _OutletFormDialogState extends State<OutletFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _countyController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _managerController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.outlet != null) {
      _nameController.text = widget.outlet!.outletName;
      _codeController.text = widget.outlet!.outletCode;
      _addressLine1Controller.text = widget.outlet!.addressLine1;
      _addressLine2Controller.text = widget.outlet!.addressLine2 ?? '';
      _cityController.text = widget.outlet!.city;
      _countyController.text = widget.outlet!.county;
      _postalCodeController.text = widget.outlet!.postalCode ?? '';
      _phoneController.text = widget.outlet!.contactPhone ?? '';
      _managerController.text = widget.outlet!.managerName ?? '';
      _latitudeController.text = widget.outlet!.latitude.toString();
      _longitudeController.text = widget.outlet!.longitude.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _countyController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    _managerController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.outlet == null ? 'Add Outlet' : 'Edit Outlet'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Outlet Name *'),
                validator: (value) =>
                    value?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Outlet Code *'),
                validator: (value) =>
                    value?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressLine1Controller,
                decoration:
                    const InputDecoration(labelText: 'Address Line 1 *'),
                validator: (value) =>
                    value?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressLine2Controller,
                decoration: const InputDecoration(labelText: 'Address Line 2'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'City *'),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _countyController,
                      decoration: const InputDecoration(labelText: 'County *'),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _postalCodeController,
                decoration: const InputDecoration(labelText: 'Postal Code'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Contact Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _managerController,
                decoration: const InputDecoration(labelText: 'Manager Name'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      decoration:
                          const InputDecoration(labelText: 'Latitude *'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty == true) return 'Required';
                        if (double.tryParse(value!) == null)
                          return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      decoration:
                          const InputDecoration(labelText: 'Longitude *'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty == true) return 'Required';
                        if (double.tryParse(value!) == null)
                          return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveOutlet,
          child: Text(widget.outlet == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }

  void _saveOutlet() {
    if (_formKey.currentState!.validate()) {
      final outletData = widget.outlet == null
          ? VendorOutletCreate(
              outletName: _nameController.text.trim(),
              outletCode: _codeController.text.trim(),
              addressLine1: _addressLine1Controller.text.trim(),
              addressLine2: _addressLine2Controller.text.trim().isEmpty
                  ? null
                  : _addressLine2Controller.text.trim(),
              city: _cityController.text.trim(),
              county: _countyController.text.trim(),
              postalCode: _postalCodeController.text.trim().isEmpty
                  ? null
                  : _postalCodeController.text.trim(),
              contactPhone: _phoneController.text.trim().isEmpty
                  ? null
                  : _phoneController.text.trim(),
              managerName: _managerController.text.trim().isEmpty
                  ? null
                  : _managerController.text.trim(),
              latitude: double.parse(_latitudeController.text),
              longitude: double.parse(_longitudeController.text),
            )
          : VendorOutlet(
              outletId: widget.outlet!.outletId,
              vendorId: widget.outlet!.vendorId,
              outletName: _nameController.text.trim(),
              outletCode: _codeController.text.trim(),
              addressLine1: _addressLine1Controller.text.trim(),
              addressLine2: _addressLine2Controller.text.trim().isEmpty
                  ? null
                  : _addressLine2Controller.text.trim(),
              city: _cityController.text.trim(),
              county: _countyController.text.trim(),
              postalCode: _postalCodeController.text.trim().isEmpty
                  ? null
                  : _postalCodeController.text.trim(),
              contactPhone: _phoneController.text.trim().isEmpty
                  ? null
                  : _phoneController.text.trim(),
              managerName: _managerController.text.trim().isEmpty
                  ? null
                  : _managerController.text.trim(),
              latitude: double.parse(_latitudeController.text),
              longitude: double.parse(_longitudeController.text),
              operatingHours: widget.outlet!.operatingHours,
              facilities: widget.outlet!.facilities,
            );

      widget.onSave(outletData);
      Navigator.pop(context);
    }
  }
}

// Details dialog for viewing outlet information
class OutletDetailsDialog extends StatelessWidget {
  final VendorOutlet outlet;

  const OutletDetailsDialog({super.key, required this.outlet});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(outlet.outletName),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Code', outlet.outletCode),
            _buildDetailRow('Address',
                '${outlet.addressLine1}${outlet.addressLine2?.isNotEmpty == true ? '\n${outlet.addressLine2}' : ''}'),
            _buildDetailRow('City', outlet.city),
            _buildDetailRow('County', outlet.county),
            if (outlet.postalCode != null)
              _buildDetailRow('Postal Code', outlet.postalCode!),
            if (outlet.contactPhone != null)
              _buildDetailRow('Phone', outlet.contactPhone!),
            if (outlet.managerName != null)
              _buildDetailRow('Manager', outlet.managerName!),
            _buildDetailRow(
                'Coordinates', '${outlet.latitude}, ${outlet.longitude}'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

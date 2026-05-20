import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:dio/dio.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // State management
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  // Filter states
  String _selectedType = 'all';
  String _selectedPriority = 'all';
  bool _showUnreadOnly = false;

  // Data
  List<NotificationItem> _notifications = [];
  Map<String, int> _unreadCounts = {};

  final List<String> _notificationTypes = [
    'all',
    'order_update',
    'delivery_update',
    'payment_update',
    'promotional',
    'system_alert',
    'reminder'
  ];

  final List<String> _priorities = ['all', 'low', 'normal', 'high'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = Dio();
      final response = await dio.get(
        '/api/vendor/notifications',
        options: Options(
            headers: {'Authorization': 'Bearer ${await _getAuthToken()}'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _notifications = (response.data['notifications'] as List)
              .map((item) => NotificationItem.fromJson(item))
              .toList();
          _unreadCounts =
              Map<String, int>.from(response.data['unread_counts'] ?? {});
        });
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _getAuthToken() async {
    // Implement your auth token retrieval logic
    return 'your_auth_token_here';
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      final dio = Dio();
      final response = await dio.put(
        '/api/vendor/notifications/$notificationId/read',
        options: Options(
            headers: {'Authorization': 'Bearer ${await _getAuthToken()}'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          final index = _notifications
              .indexWhere((n) => n.notificationId == notificationId);
          if (index != -1) {
            _notifications[index] = _notifications[index].copyWith(
              isRead: true,
              readAt: DateTime.now(),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final dio = Dio();
      final response = await dio.put(
        '/api/vendor/notifications/mark-all-read',
        options: Options(
            headers: {'Authorization': 'Bearer ${await _getAuthToken()}'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _notifications = _notifications
              .map((n) => n.copyWith(
                    isRead: true,
                    readAt: DateTime.now(),
                  ))
              .toList();
          _unreadCounts.clear();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All notifications marked as read')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteNotification(int notificationId) async {
    try {
      final dio = Dio();
      final response = await dio.delete(
        '/api/vendor/notifications/$notificationId',
        options: Options(
            headers: {'Authorization': 'Bearer ${await _getAuthToken()}'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _notifications.removeWhere((n) => n.notificationId == notificationId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification deleted')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  List<NotificationItem> get _filteredNotifications {
    var notifications = List<NotificationItem>.from(_notifications);

    // Filter by type
    if (_selectedType != 'all') {
      notifications = notifications
          .where((n) => n.notificationType == _selectedType)
          .toList();
    }

    // Filter by priority
    if (_selectedPriority != 'all') {
      notifications =
          notifications.where((n) => n.priority == _selectedPriority).toList();
    }

    // Filter unread only
    if (_showUnreadOnly) {
      notifications = notifications.where((n) => !n.isRead).toList();
    }

    return notifications;
  }

  List<NotificationItem> get _unreadNotifications {
    return _filteredNotifications.where((n) => !n.isRead).toList();
  }

  List<NotificationItem> get _readNotifications {
    return _filteredNotifications.where((n) => n.isRead).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
                onPressed: _loadNotifications,
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
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read),
                    SizedBox(width: 8),
                    Text('Mark All Read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(text: 'All (${_filteredNotifications.length})'),
            Tab(text: 'Unread (${_unreadNotifications.length})'),
            Tab(text: 'Read (${_readNotifications.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationsList(_filteredNotifications),
                _buildNotificationsList(_unreadNotifications),
                _buildNotificationsList(_readNotifications),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              _getTypeDisplayName(_selectedType),
              Icons.category,
              () => _showTypeSelector(),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Priority: ${_selectedPriority.toUpperCase()}',
              Icons.priority_high,
              () => _showPrioritySelector(),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Unread Only'),
              selected: _showUnreadOnly,
              onSelected: (selected) {
                setState(() => _showUnreadOnly = selected);
              },
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(List<NotificationItem> notifications) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No notifications found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for updates',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _isRefreshing = true);
        await _loadNotifications();
        setState(() => _isRefreshing = false);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) =>
            _buildNotificationCard(notifications[index]),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    final isUnread = !notification.isRead;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isUnread ? 3 : 1,
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isUnread
                ? Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _getNotificationIcon(notification.notificationType),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontWeight: isUnread
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (isUnread)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleNotificationAction(value, notification),
                    itemBuilder: (context) => [
                      if (!notification.isRead)
                        const PopupMenuItem(
                          value: 'mark_read',
                          child: Row(
                            children: [
                              Icon(Icons.mark_email_read, size: 18),
                              SizedBox(width: 8),
                              Text('Mark Read'),
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
                    child: Icon(Icons.more_vert, color: Colors.grey[400]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    _getTypeDisplayName(notification.notificationType),
                    _getTypeColor(notification.notificationType),
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    notification.priority.toUpperCase(),
                    _getPriorityColor(notification.priority),
                  ),
                  const Spacer(),
                  Text(
                    _formatDateTime(notification.createdAt),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    IconData iconData;
    Color color;

    switch (type) {
      case 'order_update':
        iconData = Icons.shopping_cart;
        color = Colors.blue;
        break;
      case 'delivery_update':
        iconData = Icons.local_shipping;
        color = Colors.green;
        break;
      case 'payment_update':
        iconData = Icons.payment;
        color = Colors.purple;
        break;
      case 'promotional':
        iconData = Icons.local_offer;
        color = Colors.orange;
        break;
      case 'system_alert':
        iconData = Icons.warning;
        color = Colors.red;
        break;
      case 'reminder':
        iconData = Icons.access_time;
        color = Colors.amber;
        break;
      default:
        iconData = Icons.notifications;
        color = Colors.grey;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(iconData, color: color, size: 20),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'order_update':
        return Colors.blue;
      case 'delivery_update':
        return Colors.green;
      case 'payment_update':
        return Colors.purple;
      case 'promotional':
        return Colors.orange;
      case 'system_alert':
        return Colors.red;
      case 'reminder':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'normal':
        return Colors.blue;
      case 'low':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'all':
        return 'All Types';
      case 'order_update':
        return 'Orders';
      case 'delivery_update':
        return 'Delivery';
      case 'payment_update':
        return 'Payments';
      case 'promotional':
        return 'Promotions';
      case 'system_alert':
        return 'System';
      case 'reminder':
        return 'Reminders';
      default:
        return type;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleNotificationTap(NotificationItem notification) {
    if (!notification.isRead) {
      _markAsRead(notification.notificationId);
    }

    // Navigate based on notification type and action URL
    if (notification.actionUrl != null) {
      // Implement navigation logic based on actionUrl
      _navigateToNotificationTarget(notification);
    }
  }

  void _handleNotificationAction(String action, NotificationItem notification) {
    switch (action) {
      case 'mark_read':
        _markAsRead(notification.notificationId);
        break;
      case 'delete':
        _showDeleteConfirmation(notification);
        break;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'mark_all_read':
        _markAllAsRead();
        break;
      case 'refresh':
        _loadNotifications();
        break;
      case 'settings':
        _showNotificationSettings();
        break;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: _notificationTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getTypeDisplayName(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedType = value!);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: _priorities.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(priority.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedPriority = value!);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedType = 'all';
                _selectedPriority = 'all';
                _showUnreadOnly = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showTypeSelector() {
    // Implement type selector bottom sheet
  }

  void _showPrioritySelector() {
    // Implement priority selector bottom sheet
  }

  void _showDeleteConfirmation(NotificationItem notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content:
            const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteNotification(notification.notificationId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToNotificationTarget(NotificationItem notification) {
    // Implement navigation based on notification type and actionUrl
    switch (notification.notificationType) {
      case 'order_update':
        // Navigate to order details
        break;
      case 'delivery_update':
        // Navigate to delivery tracking
        break;
      case 'payment_update':
        // Navigate to payment details
        break;
      // Add more cases as needed
    }
  }

  void _showNotificationSettings() {
    // Navigate to notification settings screen
  }
}

// Data model based on your backend notifications schema
class NotificationItem {
  final int notificationId;
  final String notificationType;
  final String title;
  final String message;
  final String? actionUrl;
  final String priority;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? relatedEntityType;
  final int? relatedEntityId;

  NotificationItem({
    required this.notificationId,
    required this.notificationType,
    required this.title,
    required this.message,
    this.actionUrl,
    required this.priority,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.relatedEntityType,
    this.relatedEntityId,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      notificationId: json['notification_id'],
      notificationType: json['notification_type'],
      title: json['title'],
      message: json['message'],
      actionUrl: json['action_url'],
      priority: json['priority'],
      isRead: json['is_read'] == 1,
      createdAt: DateTime.parse(json['created_at']),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      relatedEntityType: json['related_entity_type'],
      relatedEntityId: json['related_entity_id'],
    );
  }

  NotificationItem copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return NotificationItem(
      notificationId: notificationId,
      notificationType: notificationType,
      title: title,
      message: message,
      actionUrl: actionUrl,
      priority: priority,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
      relatedEntityType: relatedEntityType,
      relatedEntityId: relatedEntityId,
    );
  }
}

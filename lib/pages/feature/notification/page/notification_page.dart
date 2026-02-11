import 'package:ASSOU/data/models/notification_model.dart';
import 'package:ASSOU/data/services/notification_service.dart' as api;
import 'package:ASSOU/data/services/user_service.dart';
import 'package:ASSOU/pages/feature/notification/service/notification_service.dart';
import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<AppNotification> notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // Fonction pour charger les notifications depuis l'API
  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    final token = await UserService.getToken();
    if (token != null) {
      final loadedNotifications =
          await api.NotificationService.getNotifications(
        token: token,
      );

      setState(() {
        notifications = loadedNotifications;
        _isLoading = false;
      });

      _updateBadgeCount();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateBadgeCount() async {
    final token = await UserService.getToken();
    if (token != null) {
      final unreadCount =
          await api.NotificationService.getUnreadCount(token: token);
      NotificationService.notificationCount.value = unreadCount;
    }
  }

  void _markAsRead(String slug) async {
    final token = await UserService.getToken();
    if (token != null) {
      // Direct local update of the list for immediate UI feedback
      setState(() {
        final index = notifications.indexWhere((notif) => notif.slug == slug);
        if (index != -1 && !notifications[index].isRead) {
          notifications[index] = notifications[index].copyWith(isRead: true);
          // Decrement global count immediately for snappy feel
          if (NotificationService.notificationCount.value > 0) {
            NotificationService.notificationCount.value--;
          }
        }
      });

      // API call to persist the change
      await api.NotificationService.markAsRead(
        token: token,
        notificationSlug: slug,
      );

      // Refresh from API to ensure sync (handles cases where other apps/devices changed state)
      _updateBadgeCount();
    }
  }

  void _markAllAsRead() async {
    final token = await UserService.getToken();
    if (token != null) {
      // Instant local update
      setState(() {
        notifications =
            notifications.map((n) => n.copyWith(isRead: true)).toList();
        NotificationService.notificationCount.value = 0;
      });

      await api.NotificationService.markAllAsRead(token: token);

      _updateBadgeCount();
    }
  }

  void _deleteNotification(String slug) async {
    // Note: API deletion might not be available in backend yet
    setState(() {
      notifications.removeWhere((notif) => notif.slug == slug);
    });
    // Locally save deletion is tricky with sync, but since we refresh from API,
    // deletions should ideally be handled on backend.
  }

  // Helper methods for date formatting
  String _getDay(DateTime date) {
    return date.day.toString().padLeft(2, '0');
  }

  String _getMonth(DateTime date) {
    const months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];
    return months[date.month - 1];
  }

  // Future<void> _saveNotifications({bool? isReadAll, bool? isRead}) async {
  //   // Removed as we use API now
  // }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((notif) => !notif.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade400,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Tout marquer lu',
                style: TextStyle(
                    color: Colors.yellow[800],
                    fontWeight: FontWeight.w800,
                    fontSize: 15),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: notifications.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: [
                        ValueListenableBuilder<int>(
                          valueListenable:
                              NotificationService.notificationCount,
                          builder: (context, count, _) {
                            if (count <= 0) return const SizedBox.shrink();
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              color: Colors.yellow[800],
                              child: Text(
                                '$count notification${count > 1 ? 's' : ''} non lue${count > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            );
                          },
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: notifications.length,
                            itemBuilder: (context, index) {
                              final notification = notifications[index];
                              return _buildNotificationItem(notification);
                            },
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune notification',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous êtes à jour !',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification notification) {
    return Dismissible(
      key: Key(notification.slug),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 24,
        ),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification.slug);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification supprimée'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          // Blue background for unread notifications, white for read ones
          color: notification.isRead ? Colors.white : Colors.blue.shade50,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date section on the left
              Container(
                width: 70,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: notification.isRead
                      ? Colors.grey.shade100
                      : Colors.blue.shade100,
                  border: Border(
                    right: BorderSide(
                      color: notification.isRead
                          ? Colors.grey.shade300
                          : Colors.blue.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getDay(notification.createdAt),
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: notification.isRead
                            ? Colors.grey.shade700
                            : Colors.blue.shade700,
                      ),
                    ),
                    Text(
                      _getMonth(notification.createdAt),
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: notification.isRead
                            ? Colors.grey.shade600
                            : Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Main content
              Expanded(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    notification.displayTitle,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: notification.isRead
                          ? FontWeight.w600
                          : FontWeight.bold,
                      fontSize: 16,
                      color: notification.isRead
                          ? Colors.grey.shade800
                          : Colors.blue.shade900,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        notification.displayMessage,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: notification.isRead
                              ? Colors.grey.shade600
                              : Colors.grey.shade700,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.formattedDate,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: notification.isRead
                      ? null
                      : Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            shape: BoxShape.circle,
                          ),
                        ),
                  onTap: () {
                    if (!notification.isRead) {
                      _markAsRead(notification.slug);
                    }
                    // Ici vous pouvez naviguer vers une page de détail si nécessaire
                    _showNotificationDetail(notification);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationDetail(AppNotification notification) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        // Icon and color based on type
        IconData iconData = Icons.notifications_rounded;
        Color primaryColor = const Color(0xFF3B82F6);
        List<Color> gradientColors = [
          const Color(0xFF3B82F6),
          const Color(0xFF1D4ED8)
        ];

        if (notification.type == 'payment') {
          iconData = Icons.account_balance_wallet_rounded;
          primaryColor = const Color(0xFF10B981);
          gradientColors = [const Color(0xFF10B981), const Color(0xFF047857)];
        } else if (notification.type == 'voucher' ||
            notification.titre.contains('🎁')) {
          iconData = Icons.card_giftcard_rounded;
          primaryColor = const Color(0xFFF59E0B);
          gradientColors = [const Color(0xFFF59E0B), const Color(0xFFD97706)];
        } else if (notification.type == 'promotion') {
          iconData = Icons.campaign_rounded;
          primaryColor = const Color(0xFFEC4899);
          gradientColors = [const Color(0xFFEC4899), const Color(0xFFBE185D)];
        }

        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                margin: const EdgeInsets.only(top: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.displayTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.blueGrey[900],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Text(
                          notification.displayMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.blueGrey[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 6),
                          Text(
                            notification.fullFormattedDate,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                          shadowColor: primaryColor.withOpacity(0.4),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Compris',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      iconData,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class NotificationItem {
  final String ref;
  final String title;
  final String body;
  final DateTime time;
  bool isRead;

  NotificationItem({
    required this.ref,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      ref: json['ref'],
      title: json['title'],
      body: json['body'],
      time: DateTime.parse(json['time']),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'ref': ref,
    'title': title,
    'body': body,
    'time': time.toIso8601String(),
    'isRead': isRead,
  };
}

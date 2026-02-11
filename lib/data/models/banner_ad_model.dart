class BannerAd {
  final int id;
  final String image;
  final String? title;
  final String? subtitle;
  final String? link;
  final bool status;
  final DateTime? startDate;
  final DateTime? endDate;

  BannerAd({
    required this.id,
    required this.image,
    this.title,
    this.subtitle,
    this.link,
    required this.status,
    this.startDate,
    this.endDate,
  });

  factory BannerAd.fromJson(Map<String, dynamic> json) {
    return BannerAd(
      id: json['id'] ?? 0,
      image: json['image'] ?? '',
      title: json['title'],
      subtitle: json['subtitle'],
      link: json['link'],
      status: json['status'] == true || json['status'] == 1,
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'])
          : null,
      endDate:
          json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'title': title,
      'subtitle': subtitle,
      'link': link,
      'status': status,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }
}

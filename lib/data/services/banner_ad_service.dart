import 'package:ASSOU/data/services/api_service.dart';
import 'package:ASSOU/config/api_endpoints.dart';
import 'package:ASSOU/utils/logger.dart';
import '../models/banner_ad_model.dart';

class BannerAdService {
  /// Fetch all active banners from the server
  static Future<List<BannerAd>> getActiveBanners({int limit = 10}) async {
    final url = '${ApiEndpoints.bannerAdsActive}?limit=$limit';
    AppLogger.info('Fetching banners from: $url', 'BANNER_SERVICE');
    try {
      final response = await ApiService.get<List<dynamic>>(url);

      AppLogger.info('Banner API Response status: ${response.statusCode}',
          'BANNER_SERVICE');

      if (response.isSuccess && response.data != null) {
        final List<dynamic> data = response.data!;
        AppLogger.info('Loaded ${data.length} banners', 'BANNER_SERVICE');
        return data.map((json) => BannerAd.fromJson(json)).toList();
      } else {
        AppLogger.error(
            'Failed to load active banners: ${response.message} (Status: ${response.statusCode})',
            'BANNER_SERVICE');
        return [];
      }
    } catch (e) {
      AppLogger.error(
          'Exception while loading active banners', 'BANNER_SERVICE', e);
      return [];
    }
  }

  /// Track impression for a banner
  static Future<void> trackImpression(int bannerId) async {
    try {
      await ApiService.post(
        ApiEndpoints.getFullUrl('/v2/banner-ads/$bannerId/impression'),
        {},
      );
    } catch (e) {
      // Slient fail for tracking
    }
  }

  /// Track click for a banner
  static Future<void> trackClick(int bannerId) async {
    try {
      await ApiService.post(
        ApiEndpoints.getFullUrl('/v2/banner-ads/$bannerId/click'),
        {},
      );
    } catch (e) {
      // Slient fail for tracking
    }
  }
}

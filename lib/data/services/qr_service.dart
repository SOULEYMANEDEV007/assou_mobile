import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/environment.dart';
import '../models/qr_code_model.dart';

class QRCodeService {
  /// Scan QR code (Public endpoint - No authentication required)
  static Future<QRScanResult?> scanQrCode(String qrCode) async {
    try {
      // Use the QR scan endpoint from ApiEndpoints
      final qrEndpoint = '${Environment.apiBaseUrl}/qr/$qrCode';

      final response = await http.get(
        Uri.parse(qrEndpoint),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return QRScanResult.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      print('Error scanning QR code: $e');
      return null;
    }
  }

  /// Extract QR code from URL if scanned URL contains the endpoint
  static String extractQrCodeFromUrl(String scannedData) {
    // Check for the API version pattern
    if (scannedData.contains('/api/v1/qr/')) {
      return scannedData.split('/api/v1/qr/').last;
    }
    // Fallback for just /qr/ pattern
    if (scannedData.contains('/qr/')) {
      return scannedData.split('/qr/').last;
    }
    return scannedData;
  }

  /// Validate QR code format
  static bool isValidQrCode(String qrCode) {
    // Basic validation - you can enhance this based on your QR code format
    return qrCode.isNotEmpty && qrCode.length >= 6;
  }

  /// Get QR code type from scan result
  static QRCodeType getQrCodeType(QRScanResult result) {
    switch (result.type) {
      case 'payment':
        return QRCodeType.payment;
      case 'contact':
        return QRCodeType.contact;
      case 'promotion':
        return QRCodeType.promotion;
      case 'general':
        return QRCodeType.general;
      default:
        return QRCodeType.unknown;
    }
  }

  /// Generate QR code data for voucher
  static String generateVoucherQRData({
    required String voucherCode,
    required String boutiqueCode,
    String? additionalData,
  }) {
    final qrData = <String, String>{
      'type': 'voucher',
      'voucher_code': voucherCode,
      'boutique_code': boutiqueCode,
    };

    if (additionalData != null) {
      qrData['data'] = additionalData;
    }

    return jsonEncode(qrData);
  }

  /// Parse voucher QR code data
  static Map<String, dynamic>? parseVoucherQRData(String qrData) {
    try {
      final data = jsonDecode(qrData);
      if (data['type'] == 'voucher') {
        return data;
      }
      return null;
    } catch (e) {
      print('Error parsing voucher QR data: $e');
      return null;
    }
  }
}

enum QRCodeType {
  payment,
  contact,
  promotion,
  general,
  unknown,
}

// Méthode de récupération des données d'un QR_code

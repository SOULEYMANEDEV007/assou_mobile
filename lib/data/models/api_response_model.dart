import 'dart:convert';
import 'package:http/http.dart' as http;

class ResponseUpdateProfil {
  final bool success;
  final String message;

  ResponseUpdateProfil({
    required this.success,
    required this.message,
  });

  /// Factory pour parser depuis un JSON (ex: réponse API)
  factory ResponseUpdateProfil.fromJson(Map<String, dynamic> json) {
    return ResponseUpdateProfil(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }

  /// Optionnel : pour convertir en JSON (utile pour debug ou renvoi)
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
    };
  }
}

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int? statusCode;
  final Map<String, dynamic>? errors;
  final Map<String, dynamic>? meta;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
    this.errors,
    this.meta,
  });

  factory ApiResponse.fromResponse(http.Response response) {
    try {
      final body = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : <String, dynamic>{};

      final bool isSuccess =
          response.statusCode >= 200 && response.statusCode < 300;

      final Map<String, dynamic> bodyMap =
          (body is Map) ? Map<String, dynamic>.from(body) : {};

      return ApiResponse<T>(
        success: bodyMap['success'] ?? isSuccess,
        message: bodyMap['message'] ?? _getDefaultMessage(response.statusCode),
        data: (body is Map) ? body['data'] : (body as T?),
        statusCode: response.statusCode,
        errors: bodyMap['errors'],
        meta: bodyMap['meta'],
      );
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        message: 'Failed to parse response: ${e.toString()}',
        statusCode: response.statusCode,
      );
    }
  }

  factory ApiResponse.success({
    required T? data,
    String message = 'Success',
    int? statusCode,
    Map<String, dynamic>? meta,
  }) {
    return ApiResponse<T>(
      success: true,
      message: message,
      data: data,
      statusCode: statusCode,
      meta: meta,
    );
  }

  factory ApiResponse.error(
    String message, {
    T? data,
    int? statusCode,
    Map<String, dynamic>? errors,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      data: data,
      statusCode: statusCode,
      errors: errors,
    );
  }

  static String _getDefaultMessage(int statusCode) {
    switch (statusCode) {
      case 200:
        return 'Success';
      case 201:
        return 'Created successfully';
      case 204:
        return 'No content';
      case 400:
        return 'Bad request';
      case 401:
        return 'Non authentifié';
      case 403:
        return 'Accès interdit';
      case 404:
        return 'Ressource non trouvée';
      case 422:
        return 'Données invalides';
      case 500:
        return 'Erreur serveur';
      case 503:
        return 'Service indisponible';
      default:
        return 'Une erreur est survenue';
    }
  }

  bool get isSuccess => success;
  bool get isError => !success;
  bool get hasData => data != null;
  bool get hasErrors => errors != null && errors!.isNotEmpty;
  bool get hasMeta => meta != null && meta!.isNotEmpty;

  // Pagination helpers (if meta contains pagination info)
  int? get currentPage => meta?['current_page'];
  int? get lastPage => meta?['last_page'];
  int? get total => meta?['total'];
  int? get perPage => meta?['per_page'];
  bool get hasNextPage =>
      currentPage != null && lastPage != null && currentPage! < lastPage!;
  bool get hasPreviousPage => currentPage != null && currentPage! > 1;

  // Error handling helpers
  String? getFieldError(String fieldName) {
    if (!hasErrors) return null;
    final fieldErrors = errors![fieldName];
    if (fieldErrors is List && fieldErrors.isNotEmpty) {
      return fieldErrors.first.toString();
    }
    return fieldErrors?.toString();
  }

  List<String> getAllErrorMessages() {
    if (!hasErrors) return [];

    final List<String> messages = [];
    errors!.forEach((key, value) {
      if (value is List) {
        messages.addAll(value.map((e) => e.toString()));
      } else {
        messages.add(value.toString());
      }
    });
    return messages;
  }

  @override
  String toString() {
    return 'ApiResponse{success: $success, message: $message, statusCode: $statusCode}';
  }
}

class ApiResponseRelance<T> {
  final bool success;
  final String? message;
  final T? data;

  ApiResponseRelance({
    required this.success,
    this.message,
    this.data,
  });

  factory ApiResponseRelance.fromResponse(
    http.Response response, {
    T Function(Map<String, dynamic>)? fromJson,
  }) {
    final Map<String, dynamic> json = jsonDecode(response.body);

    return ApiResponseRelance<T>(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null && fromJson != null
          ? fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  factory ApiResponseRelance.error(String message) {
    return ApiResponseRelance<T>(
      success: false,
      message: message,
      data: null,
    );
  }
}

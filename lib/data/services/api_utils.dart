// Place this file at: lib/data/services/api_utils.dart

/// Get authenticated headers with Bearer token
Map<String, String> getAuthHeaders(String token) {
  return {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
}

/// Get basic headers without authentication
Map<String, String> getBasicHeaders() {
  return {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
}

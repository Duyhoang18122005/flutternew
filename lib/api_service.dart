import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8080/api';
  static const Duration timeout = Duration(seconds: 10);
  static final storage = FlutterSecureStorage();
  static Map<String, dynamic>? _currentUser;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  static Future<Map<String, String>> get _headersWithToken async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<String?> login(String username, String password) async {
    try {
      final url = Uri.parse('$baseUrl/auth/login');
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await storage.write(key: 'jwt', value: data['token']);

        // Gọi API lấy thông tin user sau khi đăng nhập thành công
        final userInfo = await getUserInfo();
        if (userInfo != null) {
          _currentUser = userInfo;
          await storage.write(key: 'user', value: jsonEncode(_currentUser));
        }

        return null;
      } else {
        final error = jsonDecode(response.body);
        return error['message'] ?? 'Sai tài khoản hoặc mật khẩu';
      }
    } catch (e) {
      if (e is http.ClientException) {
        return 'Không thể kết nối đến máy chủ';
      }
      return 'Đã xảy ra lỗi: ${e.toString()}';
    }
  }

  static Future<String?> register(String username, String password, String email, String fullName) async {
    try {
      final url = Uri.parse('$baseUrl/auth/register');
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'username': username,
          'password': password,
          'email': email,
          'fullName': fullName,
        }),
      ).timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null;
      } else {
        final error = jsonDecode(response.body);
        return error['message'] ?? 'Đăng ký thất bại';
      }
    } catch (e) {
      if (e is http.ClientException) {
        return 'Không thể kết nối đến máy chủ';
      }
      return 'Đã xảy ra lỗi: ${e.toString()}';
    }
  }

  static Future<void> logout() async {
    try {
      await storage.delete(key: 'jwt');
      await storage.delete(key: 'user');
      _currentUser = null;
    } catch (e) {
      print('Lỗi khi đăng xuất: ${e.toString()}');
    }
  }

  static Future<String?> getToken() async {
    try {
      return await storage.read(key: 'jwt');
    } catch (e) {
      print('Lỗi khi đọc token: ${e.toString()}');
      return null;
    }
  }

  // Thêm method kiểm tra token còn hạn không
  static Future<bool> isTokenValid() async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final url = Uri.parse('$baseUrl/validate');
      final response = await http.get(
        url,
        headers: await _headersWithToken,
      ).timeout(timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<dynamic>> fetchGames() async {
    try {
      final url = Uri.parse('$baseUrl/games');
      final response = await http.get(url).timeout(timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<String?> registerPlayer(Map<String, dynamic> data) async {
    try {
      final token = await getToken();
      final url = Uri.parse('$baseUrl/game-players');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          return null;
        } else {
          return result['message'] ?? 'Đăng ký player thất bại';
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          return error['message'] ?? 'Đăng ký player thất bại';
        } catch (e) {
          return response.body.isNotEmpty ? response.body : 'Đăng ký player thất bại';
        }
      }
    } catch (e) {
      return 'Đã xảy ra lỗi: ${e.toString()}';
    }
  }

  static Future<List<dynamic>> fetchAllPlayers() async {
    try {
      final url = Uri.parse('$baseUrl/game-players');
      final response = await http.get(url).timeout(timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] as List;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> fetchPlayerById(int id) async {
    try {
      final url = Uri.parse('$baseUrl/game-players/$id');
      final response = await http.get(url).timeout(timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    try {
      final userJson = await storage.read(key: 'user');
      if (userJson != null) {
        _currentUser = jsonDecode(userJson) as Map<String, dynamic>;
        return _currentUser;
      }
      return null;
    } catch (e) {
      print('Lỗi khi đọc thông tin người dùng: ${e.toString()}');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final url = Uri.parse('$baseUrl/auth/me');
      final response = await http.get(
        url,
        headers: await _headersWithToken,
      ).timeout(timeout);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data != null && data is Map<String, dynamic>) {
          return data;
        }
      }
      return null;
    } catch (e) {
      print('Lỗi khi đọc thông tin người dùng: [31m${e.toString()}[0m');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> sendMessage({
    required int receiverId,
    required String content,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/messages/send/$receiverId');
      final response = await http.post(
        url,
        headers: await _headersWithToken,
        body: jsonEncode({'content': content}),
      ).timeout(timeout);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data != null && data is Map<String, dynamic>) {
          return data;
        }
      }
      return null;
    } catch (e) {
      print('Lỗi gửi tin nhắn: $e');
      return null;
    }
  }

  static Future<List<dynamic>> getConversation(int userId) async {
    try {
      final url = Uri.parse('$baseUrl/messages/conversation/$userId');
      final response = await http.get(
        url,
        headers: await _headersWithToken,
      ).timeout(timeout);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data != null && data is List) {
          return data;
        }
      }
      return [];
    } catch (e) {
      print('Lỗi lấy hội thoại: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getConversations() async {
    try {
      final url = Uri.parse('$baseUrl/messages/conversations');
      final response = await http.get(
        url,
        headers: await _headersWithToken,
      ).timeout(timeout);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data != null && data is List) {
          return data;
        }
      }
      return [];
    } catch (e) {
      print('Lỗi lấy danh sách hội thoại: $e');
      return [];
    }
  }

  static Future<double?> fetchWalletBalance() async {
    try {
      final url = Uri.parse('$baseUrl/payments/wallet-balance');
      final response = await http.get(
        url,
        headers: await _headersWithToken,
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return double.tryParse(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> deposit(double amount, String method) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/payments/deposit');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'amount': amount,
        'method': method,
      }),
    ).timeout(timeout);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Nạp tiền thất bại');
    }
  }

  static Future<Map<String, dynamic>?> processPayment(String transactionId) async {
    try {
      final token = await getToken();
      final url = Uri.parse('$baseUrl/payments/process');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'transactionId': transactionId,
        }),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Xử lý thanh toán thất bại');
      }
    } catch (e) {
      print('Lỗi khi xử lý thanh toán: ${e.toString()}');
      return null;
    }
  }

  static Future<String?> topUp(double amount) async {
    try {
      final token = await getToken();
      final url = Uri.parse('$baseUrl/payments/topup');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount,
        }),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return null; // Thành công
      } else {
        final error = jsonDecode(response.body);
        return error['message'] ?? 'Nạp tiền thất bại';
      }
    } catch (e) {
      print('Lỗi khi nạp tiền: ${e.toString()}');
      return 'Đã xảy ra lỗi: ${e.toString()}';
    }
  }

  static Future<int> fetchFollowerCount(int playerId) async {
    final url = Uri.parse('$baseUrl/players/$playerId/followers/count');
    final response = await http.get(url).timeout(timeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['followerCount'] ?? 0;
    }
    return 0;
  }

  static Future<int> fetchHireHours(int playerId) async {
    final url = Uri.parse('$baseUrl/players/$playerId/hire-hours');
    final response = await http.get(url).timeout(timeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['totalHireHours'] ?? 0;
    }
    return 0;
  }

  static Future<bool> followPlayer(int playerId) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/players/$playerId/follow');
    print('[LOG] Gửi POST follow tới $url với token: ${token != null}');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(timeout);
    print('[LOG] Response followPlayer: statusCode=${response.statusCode}, body=${response.body}');
    return response.statusCode == 200;
  }

  static Future<bool> checkFollowing(int playerId) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/players/$playerId/is-following');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(timeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['isFollowing'] == true;
    }
    return false;
  }

  static Future<bool> unfollowPlayer(int playerId) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/players/$playerId/unfollow');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(timeout);
    return response.statusCode == 200;
  }
}
// DIAGNOSTIC: Agregar logging detallado al login
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final baseUrl = 'https://fastapi-backend-o7ks.onrender.com';
  
  // Exactamente como lo hace la app
  final requestBody = {
    'username': 'DireccionInnovaSalud',
    'password': 'Admin2025',
    'campus': 'cres-llano-largo',
  };
  
  print('═══════════════════════════════════════');
  print('DIAGNOSTICO DE LOGIN DESDE DART');
  print('═══════════════════════════════════════');
  print('');
  print('URL: $baseUrl/auth/login');
  print('');
  print('Body JSON:');
  print(jsonEncode(requestBody));
  print('');
  print('Body bytes:');
  final bodyBytes = utf8.encode(jsonEncode(requestBody));
  print('Length: ${bodyBytes.length}');
  print('Hex: ${bodyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
  print('');
  
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    ).timeout(Duration(seconds: 15));
    
    print('Response Status: ${response.statusCode}');
    print('Response Headers: ${response.headers}');
    print('');
    print('Response Body:');
    print(response.body);
    
    if (response.statusCode == 200) {
      print('');
      print('✅ LOGIN EXITOSO');
      final data = jsonDecode(response.body);
      print('Usuario: ${data['user']['username']}');
    } else {
      print('');
      print('❌ LOGIN FALLIDO');
    }
  } catch (e) {
    print('');
    print('❌ ERROR: $e');
  }
  
  print('');
  print('═══════════════════════════════════════');
}

import 'dart:convert';
import 'dart:io';

void main() async {
  print('🧪 Testing API Connection...');
  
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:8000/api/v1/articles'));
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final data = json.decode(responseBody);
      
      print('✅ API Connection Successful!');
      print('📊 Status: ${data['status']}');
      print('📰 Articles: ${data['count']} found');
      print('🎯 First article: ${data['articles'][0]['rewritten_headline']}');
    } else {
      print('❌ API returned status: ${response.statusCode}');
    }
    
    client.close();
  } catch (e) {
    print('❌ Connection failed: $e');
  }
}
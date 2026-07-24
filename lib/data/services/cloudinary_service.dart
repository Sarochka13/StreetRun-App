import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Загрузка аватарок в Cloudinary через unsigned upload preset —
/// так не нужно прятать API secret в мобильном приложении.
///
/// ВАЖНО: замените cloudName и uploadPreset на свои значения из
/// консоли Cloudinary (Settings -> Upload -> Upload presets, режим Unsigned).
class CloudinaryService {
  static const String cloudName = 'YOUR_CLOUD_NAME';
  static const String uploadPreset = 'streetrun_avatars';

  Uri get _uploadUri =>
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

  /// Загружает файл и возвращает secure_url загруженного изображения.
  Future<String> uploadAvatar(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', _uploadUri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception('Cloudinary вернул код ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['secure_url'] as String;
    } catch (e) {
      throw Exception('Не удалось загрузить аватарку: $e');
    }
  }
}

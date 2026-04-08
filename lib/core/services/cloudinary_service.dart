import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // TODO: set these after you create the unsigned preset.
  static const String cloudName = 'djjbn95fw';
  static const String uploadPreset = 'upload_preset';

  static Uri _endpoint({required bool isVideo}) => Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/${isVideo ? 'video' : 'image'}/upload',
      );

  static Future<String> uploadFile({
    required String filePath,
    required bool isVideo,
    String? folder,
  }) async {
    if (cloudName == 'YOUR_CLOUD_NAME' || uploadPreset == 'YOUR_UPLOAD_PRESET') {
      throw Exception('Set CloudinaryService.cloudName and uploadPreset');
    }

    final request = http.MultipartRequest('POST', _endpoint(isVideo: isVideo));
    request.fields['upload_preset'] = uploadPreset;
    if (folder != null && folder.trim().isNotEmpty) {
      request.fields['folder'] = folder.trim();
    }
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Cloudinary upload failed (${response.statusCode}): $body');
    }

    final jsonData = json.decode(body) as Map<String, dynamic>;
    final secureUrl = jsonData['secure_url'];
    if (secureUrl is! String || secureUrl.isEmpty) {
      throw Exception('Cloudinary response missing secure_url');
    }
    return secureUrl;
  }
}


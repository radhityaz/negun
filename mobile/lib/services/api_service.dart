import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/exam_package.dart';

class ApiService {
  // Ganti IP ini dengan IP laptop kamu (bukan localhost kalau run di emulator/HP fisik)
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1'; 

  static Future<List<ExamHeader>> fetchAvailableExams() async {
    final response = await http.get(Uri.parse('$baseUrl/exams/available'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      // Backend return struct custom, tapi kita bisa map ke ExamHeader
      // Note: Backend return struct ExamResponse yang mirip Header tapi ada download_url
      return body.map((dynamic item) => ExamHeader(
        examId: item['id'],
        title: item['title'],
        version: item['version'],
        encryptionIV: "", // Belum ada di list response, nanti ada di file .exam
        validFrom: DateTime.now(), // Placeholder
        validUntil: DateTime.now().add(const Duration(days: 7)), // Placeholder
        durationMins: item['duration_mins'],
      )).toList();
    } else {
      throw Exception('Failed to load exams');
    }
  }

  static Future<String> getDownloadUrl(String examId) async {
    // Di backend MVP, list exams sudah include download_url
    // Tapi kalau mau fetch spesifik lagi bisa buat endpoint baru
    // Untuk sekarang kita ambil dari list saja di UI
    return '$baseUrl/files/$examId-v1.exam'; // Simplifikasi MVP
  }

  // Upload file .ans ke server
  static Future<String> uploadAnswerFile(String examId, File file) async {
    // 1. Get Upload URL & Attempt ID
    final initResp = await http.post(Uri.parse('$baseUrl/exams/$examId/upload-url'));
    if (initResp.statusCode != 200) throw Exception('Failed to init upload');
    
    final initData = jsonDecode(initResp.body);
    final uploadUrl = initData['upload_url'];
    final attemptId = initData['attempt_id'];

    // 2. Upload File (Mock: Kirim ke endpoint dummy backend)
    // Di produksi: PUT binary ke Presigned URL
    // Di MVP: POST multipart ke backend handler
    var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    var uploadResp = await request.send();

    if (uploadResp.statusCode != 200) throw Exception('Upload failed');

    // 3. Confirm & Get Receipt
    // Kita butuh hash file & signature dari file .ans untuk konfirmasi
    // (Simplifikasi: di MVP kita skip hash check di client, langsung minta receipt)
    
    final confirmResp = await http.post(
      Uri.parse('$baseUrl/attempts/confirm'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'attempt_id': attemptId,
        'file_hash': "dummy-hash", // TODO: Calculate SHA256 of file
        'client_signature': "dummy-sig"
      }),
    );

    if (confirmResp.statusCode != 200) throw Exception('Confirmation failed');
    
    final confirmData = jsonDecode(confirmResp.body);
    return confirmData['receipt_code']; // RCPT-12345
  }
}

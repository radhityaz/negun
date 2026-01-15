import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import '../models/exam_package.dart';
import 'crypto_service.dart';

class ExamService {
  // Key harus sama dengan backend
  // TODO: Move this to Flutter Secure Storage or Build Config/Env
  static const String masterKey = "01234567890123456789012345678901"; 

  // Helper: List Downloaded Exams
  static Future<List<File>> getDownloadedExams() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.listSync().whereType<File>().where((f) => f.path.endsWith('.exam')).toList();
  }

  // Helper: List Pending Answers
  static Future<List<File>> getPendingAnswers() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.listSync().whereType<File>().where((f) => f.path.endsWith('.ans')).toList();
  }

  // Download file .exam dari URL dan simpan ke local storage
  static Future<File> downloadExam(String url, String examId, int version) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) throw Exception('Download failed');

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$examId-v$version.exam');
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  // Load file lokal, verifikasi signature, lalu decrypt payload
  static Future<ExamPayload> loadAndDecryptExam(String examId, int version) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$examId-v$version.exam');
    
    if (!await file.exists()) throw Exception('Exam file not found');

    String content = await file.readAsString();
    Map<String, dynamic> jsonMap = jsonDecode(content);
    ExamPackage pkg = ExamPackage.fromJson(jsonMap);

    // 1. Verifikasi Signature (HMAC)
    // Format sign data harus sama persis dengan backend: "examID.version.ciphertext"
    String signData = "${pkg.header.examId}.${pkg.header.version}.${pkg.payload}";
    String computedSig = CryptoService.computeHMAC(signData, masterKey);

    if (computedSig != pkg.signature) {
      throw Exception('Security Warning: File corrupted or tampered!');
    }

    // 2. Decrypt Payload
    String decryptedJson = CryptoService.decryptAES(pkg.payload, pkg.header.encryptionIV, masterKey);
    
    // 3. Parse ke Object
    return ExamPayload.fromJson(jsonDecode(decryptedJson));
  }

  // Finalisasi Ujian: Bungkus jawaban jadi file .ans terenkripsi
  static Future<File> sealExamAttempt(String examId, String studentId, Map<String, dynamic> answers, List<dynamic> logs) async {
    final attemptId = "att-${DateTime.now().millisecondsSinceEpoch}";
    
    // 1. Encrypt Payload FIRST to get IV
    final payloadData = AnswerPayload(
      answers: answers.entries.map((e) => AnswerItem(
        questionId: e.key, 
        answer: e.value, 
        timeSpent: 0
      )).toList(),
      logs: logs.map((e) => AuditLog(event: e['event'], timestamp: e['ts'])).toList(),
    );

    final payloadJson = jsonEncode(payloadData.toJson());
    final encrypted = CryptoService.encryptAES(payloadJson, masterKey);
    final ciphertext = encrypted['ciphertext']!;
    final ivHex = encrypted['iv']!;

    // 2. Siapkan Header
    final header = AnswerHeader(
      examId: examId,
      studentId: studentId,
      attemptId: attemptId,
      deviceId: "device-uuid-123", // TODO: Get Real Device ID
      submitTime: DateTime.now(),
      iv: ivHex,
    );

    // 3. Sign Package
    final signData = "$attemptId.$ciphertext";
    final signature = CryptoService.computeHMAC(signData, masterKey);

    // 4. Create Package
    final pkg = AnswerPackage(
      header: header,
      payload: ciphertext,
      signature: signature,
    );

    // 5. Write to File
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$attemptId.ans');
    await file.writeAsString(jsonEncode(pkg.toJson()));
    
    return file;
  }
}

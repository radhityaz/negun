import 'dart:async';
import 'package:flutter/material.dart';
import '../models/exam_package.dart';
import '../models/answer_package.dart';
import '../services/exam_service.dart';

class ExamPage extends StatefulWidget {
  final String examId;
  final int version;

  const ExamPage({super.key, required this.examId, required this.version});

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> with WidgetsBindingObserver {
  ExamPayload? _payload;
  bool _isLoading = true;
  String? _error;
  bool _isOffline = true; // Mock status koneksi

  // State Ujian
  int _currentIndex = 0;
  Map<String, dynamic> _answers = {}; // q_id -> answer
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadExam();
    _startAutoSave();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  // Detect App Focus (Anti-Cheat Sederhana)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      print("User keluar aplikasi! Catat pelanggaran.");
      // TODO: Add to Audit Log
    }
  }

  Future<void> _loadExam() async {
    try {
      // 1. Cek Koneksi (Mock: Anggap offline)
      // if (await Connectivity().checkConnectivity() != ConnectivityResult.none) {
      //   throw Exception("Matikan internet untuk memulai ujian!");
      // }

      // 2. Load & Decrypt
      final payload = await ExamService.loadAndDecryptExam(widget.examId, widget.version);
      
      setState(() {
        _payload = payload;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      // TODO: Save _answers to Encrypted Local File
      print("Autosaving answers...");
    });
  }

import 'package:exam_app_offline/services/api_service.dart'; // Add import

// ... (kode lain tetap sama)

  Future<void> _submitExam() async {
    // 1. Finalize Attempt -> Create .ans file
    try {
      final file = await ExamService.sealExamAttempt(
        widget.examId, 
        "student-123", // Mock Student ID
        _answers, 
        [] // Mock Logs
      );
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jawaban dikunci. Menghubungkan ke server...")));
      
      // 2. Upload Logic
      // Asumsi: Di real app, ini akan menampilkan dialog "Nyalakan Internet" dulu
      // dan punya retry logic yang lebih robust.
      
      try {
        String receipt = await ApiService.uploadAnswerFile(widget.examId, file);
        
        // 3. Show Success & Receipt
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text("Berhasil Dikirim!"),
            content: Text("Kode Bukti (Receipt):\n$receipt\n\nSimpan kode ini/screenshot."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close Dialog
                  Navigator.pop(context); // Close Exam Page -> Back to Dashboard
                },
                child: const Text("Tutup"),
              )
            ],
          ),
        );
      } catch (uploadError) {
        // Upload gagal, tapi file aman tersimpan di HP
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Gagal Upload"),
            content: Text("Koneksi gagal: $uploadError\n\nJawaban SUDAH TERSIMPAN di HP. Cari sinyal yang lebih baik lalu coba upload lagi dari menu Dashboard."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
            ],
          ),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal submit: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: Center(child: Text("Error: $_error")));

    final question = _payload!.questions[_currentIndex];
    final totalQ = _payload!.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text("Soal ${_currentIndex + 1} / $totalQ"),
        automaticallyImplyLeading: false, // Disable Back Button
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Konten Soal
            Text(question.content, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            
            // Opsi Jawaban
            ...question.options.map((opt) => RadioListTile(
              title: Text(opt.content),
              value: opt.id,
              groupValue: _answers[question.id],
              onChanged: (val) {
                setState(() {
                  _answers[question.id] = val;
                });
              },
            )),

            const Spacer(),
            
            // Navigasi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _currentIndex > 0 
                    ? () => setState(() => _currentIndex--) 
                    : null,
                  child: const Text("Sebelumnya"),
                ),
                ElevatedButton(
                  onPressed: _currentIndex < totalQ - 1
                    ? () => setState(() => _currentIndex++)
                    : _submitExam,
                  child: Text(_currentIndex < totalQ - 1 ? "Selanjutnya" : "Selesai"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

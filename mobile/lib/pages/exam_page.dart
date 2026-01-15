import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/exam_package.dart';
import '../models/answer_package.dart';
import '../services/exam_service.dart';
import 'package:exam_app_offline/services/api_service.dart';

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
  
  // Connectivity
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _connectivitySubscription;
  
  bool _isLocked = false;

  // Storage
  final _storage = const FlutterSecureStorage();

  // State Ujian
  int _currentIndex = 0;
  Map<String, dynamic> _answers = {}; // q_id -> answer
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showGuidedAccessPrompt());
    }

    _loadExam();
    _startAutoSave();
    _initConnectivityMonitor();
  }

  void _initConnectivityMonitor() {
    // Check initial state
    _checkConnectivity();

    // Listen to changes
    // Using Stream.periodic as a fallback/robust checker + listener
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((_) {
      _checkConnectivity();
    });
  }

  Future<void> _checkConnectivity() async {
    // Bypass for Web/Emulator if needed (optional)
    // if (kDebugMode) return; 

    final result = await _connectivity.checkConnectivity();
    // ConnectivityResult.none means offline.
    // result might be ConnectivityResult (enum)
    
    bool isOnline = result != ConnectivityResult.none;
    
    if (isOnline) {
      if (!_isLocked) {
        setState(() {
          _isLocked = true;
        });
        _showLockDialog();
      }
    } else {
      if (_isLocked) {
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        setState(() {
          _isLocked = false;
        });
      }
    }
  }

  void _showLockDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text("UJIAN DIHENTIKAN"),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off, size: 50, color: Colors.red),
              SizedBox(height: 10),
              Text("Koneksi Internet Terdeteksi!"),
              Text("Matikan Data Seluler & WiFi untuk melanjutkan."),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                _checkConnectivity(); // Re-check manually
              },
              child: const Text("Saya Sudah Offline"),
            )
          ],
        ),
      ),
    );
  }

  void _showGuidedAccessPrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Mode Aman Wajib (iOS)"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Untuk mencegah kecurangan, Anda WAJIB mengaktifkan Guided Access."),
            SizedBox(height: 10),
            Text("Cara Aktifkan:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("1. Buka Settings -> Accessibility -> Guided Access (On)."),
            Text("2. Kembali ke browser ini."),
            Text("3. Tekan Tombol Power 3x dengan cepat."),
            Text("4. Klik 'Start' di pojok kanan atas."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Saya Sudah Mengaktifkan"),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSaveTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      print("User keluar aplikasi! Catat pelanggaran.");
      // TODO: Add to Audit Log
    }
  }

  Future<void> _loadExam() async {
    try {
      // Initial Check
      await _checkConnectivity();
      if (_isLocked) return;

      final payload = await ExamService.loadAndDecryptExam(widget.examId, widget.version);
      
      // Load saved answers if any
      String? savedAnswers = await _storage.read(key: "ans_${widget.examId}");
      if (savedAnswers != null) {
        _answers = jsonDecode(savedAnswers);
      }

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
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _storage.write(
        key: "ans_${widget.examId}", 
        value: jsonEncode(_answers)
      );
      print("Autosaved to SecureStorage");
    });
  }

  Future<void> _submitExam() async {
    try {
      final file = await ExamService.sealExamAttempt(
        widget.examId, 
        "student-123", 
        _answers, 
        [] 
      );
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jawaban dikunci. Silakan nyalakan internet.")));
      
      // Allow user to go online now
      // Note: In real app, we might need to disable the lock listener here
      _connectivitySubscription?.cancel(); // Stop listening
      
      bool success = false;
      String message = "";
      
      // Retry loop or manual trigger
      try {
        String receipt = await ApiService.uploadAnswerFile(widget.examId, file);
        success = true;
        message = "Kode Bukti (Receipt):\n$receipt";
        // Clear local storage on success? Or keep as backup? Keep as backup.
      } catch (e) {
        message = "Gagal Upload: $e\n\nFile aman tersimpan di HP.";
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(success ? "Berhasil!" : "Info Upload"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text("Tutup"),
            )
          ],
        ),
      );

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
        automaticallyImplyLeading: false, 
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question.content, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            
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

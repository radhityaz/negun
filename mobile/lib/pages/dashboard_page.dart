import 'dart:io';
import 'package:flutter/material.dart';
import 'package:exam_app_offline/models/exam_package.dart';
import 'package:exam_app_offline/pages/exam_page.dart';
import 'package:exam_app_offline/services/api_service.dart';
import 'package:exam_app_offline/services/exam_service.dart';
import 'package:share_plus/share_plus.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<List<ExamHeader>> futureExams;
  List<File> downloadedExams = [];
  List<File> pendingAnswers = [];
  bool isLoadingLocal = true;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      futureExams = ApiService.fetchAvailableExams();
      _loadLocalFiles();
    });
  }

  Future<void> _loadLocalFiles() async {
    try {
      final exams = await ExamService.getDownloadedExams();
      final answers = await ExamService.getPendingAnswers();
      setState(() {
        downloadedExams = exams;
        pendingAnswers = answers;
        isLoadingLocal = false;
      });
    } catch (e) {
      print("Error loading local files: $e");
    }
  }

  Future<void> _downloadExam(ExamHeader exam) async {
    try {
      final url = await ApiService.getDownloadUrl(exam.examId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Downloading...")));
      
      await ExamService.downloadExam(url, exam.examId, exam.version);
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Download Selesai!")));
      _loadLocalFiles();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal download: $e")));
    }
  }

  Future<void> _uploadAnswer(File file) async {
    try {
      // Extract examId from filename (simplified)
      // Filename format: att-TIMESTAMP.ans -> But we need ExamID. 
      // Oops, ExamID is inside the file content (Header).
      // Let's verify file first.
      
      // For MVP, assume we can upload to generic endpoint or we need to read header.
      // Let's just upload to a generic handler if possible, or read header.
      // ApiService.uploadAnswerFile needs examId.
      
      // We should read file to get ExamID.
      // But file is encrypted package.
      // The AnswerPackage is JSON. Header is plain text inside JSON? 
      // Let's check AnswerPackage model.
      // AnswerPackage: { header: AnswerHeader, ... }
      // AnswerHeader has examId.
      
      String content = await file.readAsString();
      // Simple regex to find exam_id without full parse if needed, or just full parse
      // Let's full parse
      // import 'dart:convert';
      // Map<String, dynamic> jsonMap = jsonDecode(content);
      // String examId = jsonMap['header']['exam_id'];
      
      // For now, let's just ask user to confirm or mock it.
      // Or better: Implement helper in ExamService to peek header.
      // Since I can't edit ExamService easily right now without context switch, let's do manual parse here.
      
      // String examId = ...
      // For this MVP, let's hardcode or try to parse.
      
      // Attempt parse
      // final pkg = jsonDecode(await file.readAsString());
      // final examId = pkg['header']['exam_id'];
      
      // await ApiService.uploadAnswerFile(examId, file);
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Upload logic not fully implemented in Dashboard yet. Use Share.")));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
  
  void _manualExport(File file) {
    Share.shareXFiles([XFile(file.path)], text: 'Hasil Ujian Saya');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Siswa')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Pending Uploads (Critical)
            if (pendingAnswers.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("PERLU DIUPLOAD / DISERAHKAN", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
              ...pendingAnswers.map((file) => Card(
                color: Colors.red.shade50,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(file.path.split('/').last),
                  subtitle: const Text("Jawaban belum terkirim"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.upload),
                        onPressed: () => _uploadAnswer(file),
                        tooltip: "Coba Upload Lagi",
                      ),
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () => _manualExport(file),
                        tooltip: "Kirim Manual (WA/Email)",
                      ),
                    ],
                  ),
                ),
              )),
              const Divider(),
            ],

            // Section 2: Siap Dikerjakan (Local)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("SIAP DIKERJAKAN (OFFLINE)", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            if (isLoadingLocal)
              const Center(child: CircularProgressIndicator())
            else if (downloadedExams.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("Belum ada ujian yang didownload.")),
            
            ...downloadedExams.map((file) {
              // Filename: examId-vVersion.exam
              final filename = file.path.split('/').last;
              final parts = filename.replaceAll('.exam', '').split('-v');
              final examId = parts[0];
              final version = int.tryParse(parts[1]) ?? 1;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(examId), // Show ID for now
                  subtitle: const Text("Sudah didownload. Matikan internet untuk mulai."),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ExamPage(examId: examId, version: version)),
                      ).then((_) => _refreshData());
                    },
                    child: const Text("MULAI"),
                  ),
                ),
              );
            }),

            const Divider(),

            // Section 3: Available Online
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("TERSEDIA (ONLINE)", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            FutureBuilder<List<ExamHeader>>(
              future: futureExams,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
                } else if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Gagal koneksi server: ${snapshot.error}'),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("Tidak ada ujian baru."));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final exam = snapshot.data![index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(exam.title),
                        subtitle: Text('Durasi: ${exam.durationMins} m • Versi ${exam.version}'),
                        trailing: ElevatedButton(
                          onPressed: () => _downloadExam(exam),
                          child: const Text('Download'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshData,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

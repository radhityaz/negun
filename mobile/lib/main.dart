import 'package:flutter/material.dart';
import 'models/exam_package.dart';
import 'services/api_service.dart';

void main() {
  runApp(const ExamApp());
}

class ExamApp extends StatelessWidget {
  const ExamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exam Browser Offline',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Siswa')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const TextField(decoration: InputDecoration(labelText: 'Username')),
              const SizedBox(height: 16),
              const TextField(decoration: InputDecoration(labelText: 'Password'), obscureText: true),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement Real Login
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardPage()));
                },
                child: const Text('Masuk'),
              ),
              const SizedBox(height: 16),
              const Text("Pastikan internet aktif untuk login awal", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<List<ExamHeader>> futureExams;

  @override
  void initState() {
    super.initState();
    futureExams = ApiService.fetchAvailableExams();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Ujian')),
      body: FutureBuilder<List<ExamHeader>>(
        future: futureExams,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}\nPastikan backend jalan & koneksi aman.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada ujian tersedia.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final exam = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(exam.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Durasi: ${exam.durationMins} Menit • Versi ${exam.version}'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // TODO: Download Action
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Download dimulai... (Mock)')),
                      );
                    },
                    child: const Text('Download'),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            futureExams = ApiService.fetchAvailableExams();
          });
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

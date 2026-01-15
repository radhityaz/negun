import 'package:flutter/material.dart';

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
                  // TODO: Implement Login Logic
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

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Ujian')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Ujian Matematika Akhir'),
            subtitle: const Text('60 Menit • Wajib Offline'),
            trailing: ElevatedButton(
              onPressed: () {
                // TODO: Download & Start Exam
              },
              child: const Text('Download'),
            ),
          ),
        ],
      ),
    );
  }
}

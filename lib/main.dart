import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://liqraghkzfjsgcyfgpdd.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxpcXJhZ2hremZqc2djeWZncGRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAwNTAwMjgsImV4cCI6MjA5NTYyNjAyOH0.sJJW-x5mOC0OII90gClR7zkzBvMnFp8GesTWr867QSE', // Replace with your anon public key
  );

  runApp(const KhmerGiftApp());
}

class KhmerGiftApp extends StatelessWidget {
  const KhmerGiftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Khmer Gift Collection',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4AF37), 
          brightness: Brightness.light,
        ),
      ),
      routerConfig: goRouter,
    );
  }
}

class TestConnectionScreen extends StatefulWidget {
  const TestConnectionScreen({super.key});

  @override
  State<TestConnectionScreen> createState() => _TestConnectionScreenState();
}

class _TestConnectionScreenState extends State<TestConnectionScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchMockData();
  }

  Future<void> _fetchMockData() async {
    final data = await _supabase.from('products').select();
    setState(() {
      _products = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Connection Test'),
      ),
      body: _products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return ListTile(
                  title: Text(product['name']),
                  subtitle: Text('${product['category']} - \$${product['price']}'),
                  leading: const Icon(Icons.card_giftcard),
                );
              },
            ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/admin/admin_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const WeddingAdminApp());
}

class WeddingAdminApp extends StatelessWidget {
  const WeddingAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wedding Essentials Admin',
      debugShowCheckedModeBanner: false,
      home: const AdminGuard(),
    );
  }
}

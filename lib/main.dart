import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_shell.dart';
import 'state/customers_controller.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const TessyApp());
}

class TessyApp extends StatelessWidget {
  /// [customersController] lets tests inject a controller backed by a fake
  /// repository instead of the real on-device database.
  const TessyApp({super.key, this.customersController});

  final CustomersController? customersController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => customersController ?? (CustomersController()..load()),
        ),
      ],
      child: MaterialApp(
        title: 'Tessy Creations',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const HomeShell(),
      ),
    );
  }
}

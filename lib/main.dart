import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_shell.dart';
import 'state/customers_controller.dart';
import 'state/orders_controller.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const TessyApp());
}

class TessyApp extends StatelessWidget {
  /// [customersController] / [ordersController] let tests inject controllers
  /// backed by fake repositories instead of the real on-device database.
  const TessyApp({super.key, this.customersController, this.ordersController});

  final CustomersController? customersController;
  final OrdersController? ordersController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => customersController ?? (CustomersController()..load()),
        ),
        ChangeNotifierProvider(
          create: (_) => ordersController ?? (OrdersController()..load()),
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

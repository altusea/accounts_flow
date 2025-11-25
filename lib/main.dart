import 'package:flutter/material.dart';
import 'services/data_service.dart';
import 'screens/home_screen.dart';
import 'utils/logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化日志系统
  AppLogger.initialize();
  AppLogger.info('应用启动中...');

  // 在应用启动时检查是否需要记录本周余额
  DataService.recordWeeklyBalances();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '记账应用',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

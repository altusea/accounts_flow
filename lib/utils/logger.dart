import 'package:logging/logging.dart';

/// 应用日志工具类
class AppLogger {
  static final Logger _logger = Logger('AccountsFlow');

  /// 初始化日志配置
  static void initialize() {
    Logger.root.level = Level.ALL; // 设置日志级别

    // 添加日志处理器
    Logger.root.onRecord.listen((LogRecord rec) {
      final level = rec.level.name.toUpperCase().padRight(7);
      final time = rec.time.toIso8601String();
      final message = '${rec.loggerName}: ${rec.message}';

      // 在控制台输出彩色日志
      final coloredMessage = _getColoredMessage(rec.level, '$time [$level] $message');

      if (rec.level >= Level.SEVERE) {
        // 错误级别使用 stderr
        print('[31m$coloredMessage[0m');
      } else {
        print(coloredMessage);
      }

      // 如果有异常，打印堆栈跟踪
      if (rec.error != null) {
        print('[33m错误: ${rec.error}\u001b[0m');
      }
      if (rec.stackTrace != null) {
        print('[33m堆栈跟踪: ${rec.stackTrace}\u001b[0m');
      }
    });
  }

  /// 获取带颜色的日志消息
  static String _getColoredMessage(Level level, String message) {
    switch (level) {
      case Level.SEVERE:
        return '[31m$message[0m'; // 红色
      case Level.WARNING:
        return '[33m$message[0m'; // 黄色
      case Level.INFO:
        return '[32m$message[0m'; // 绿色
      case Level.FINE:
      case Level.FINER:
      case Level.FINEST:
        return '[36m$message[0m'; // 青色
      default:
        return message;
    }
  }

  /// 获取指定名称的日志记录器
  static Logger getLogger(String name) {
    return Logger('AccountsFlow.$name');
  }

  /// 调试级别日志
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.fine(message, error, stackTrace);
  }

  /// 信息级别日志
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.info(message, error, stackTrace);
  }

  /// 警告级别日志
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.warning(message, error, stackTrace);
  }

  /// 错误级别日志
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.severe(message, error, stackTrace);
  }

  /// 数据库操作日志
  static void db(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.info('[DB] $message', error, stackTrace);
  }

  /// 业务逻辑日志
  static void business(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.info('[Business] $message', error, stackTrace);
  }

  /// UI 操作日志
  static void ui(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.info('[UI] $message', error, stackTrace);
  }
}
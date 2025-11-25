# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter personal finance tracking application called "accounts_flow" that helps users manage multiple accounts and track financial transactions with visual charts.

## Development Commands

### Essential Commands
- `flutter pub get` - Install dependencies
- `flutter analyze` - Run static analysis with Flutter Lints
- `flutter test` - Run unit tests
- `flutter run` - Run the application (use `-d chrome` for web, `-d macos` for desktop)

### Building
- `flutter build web` - Build for web deployment
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build for iOS
- `flutter build macos` - Build for macOS

## Architecture

### Data Models
- **Account** (`lib/models/account.dart`): Represents financial accounts with types (bankCard, digitalWallet, stockAccount, creditCard, cash, investment)
- **Transaction** (`lib/models/transaction.dart`): Represents financial transactions with types (income, expense, transfer)

### Data Layer
- **DataService** (`lib/services/data_service.dart`): Singleton service for data persistence using shared_preferences
  - Manages accounts and transactions storage
  - Handles JSON serialization/deserialization
  - Provides balance calculation logic

### UI Architecture
- **Screens**:
  - `HomeScreen` (`lib/screens/home_screen.dart`): Main dashboard showing total balance, account list, and recent transactions
  - `AccountDetailScreen` (`lib/screens/account_detail_screen.dart`): Detailed view of individual accounts with charts and transaction history

- **Widgets**:
  - `AccountCard` (`lib/widgets/account_card.dart`): Reusable card widget for displaying account information
  - `BalanceChart` (`lib/widgets/balance_chart.dart`): Line chart showing account balance history using fl_chart
  - `AddAccountDialog` (`lib/widgets/add_account_dialog.dart`): Modal dialog for creating new accounts
  - `AddTransactionDialog` (`lib/widgets/add_transaction_dialog.dart`): Modal dialog for recording transactions

### Key Dependencies
- `fl_chart: ^0.66.2` - For data visualization charts
- `intl: ^0.19.0` - For date formatting and localization
- `shared_preferences: ^2.4.1` - For local data persistence
- `cupertino_icons: ^1.0.8` - For iOS-style icons

## Data Flow

1. **Account Management**: Users create accounts with initial balances through `AddAccountDialog`
2. **Transaction Recording**: Users add transactions (income/expense/transfer) through `AddTransactionDialog`
3. **Balance Calculation**: `DataService` calculates running balances based on transaction history
4. **Chart Display**: `BalanceChart` visualizes account balance trends over time
5. **Data Persistence**: All data is stored locally using shared_preferences

## Important Implementation Details

### Color Handling
- Account colors are stored as ARGB integers for persistence
- Use `Color.alpha`, `Color.red`, `Color.green`, `Color.blue` properties for color manipulation

### JSON Serialization
- Models implement `toJson()` and `fromJson()` methods
- DataService uses `jsonEncode()` and `jsonDecode()` for storage

### Transaction Logic
- Income: Increases account balance
- Expense: Decreases account balance
- Transfer: Decreases source account, increases target account

### Chart Data
- `BalanceChart` processes transactions to generate historical balance data
- Uses FlSpot for chart coordinates with custom date formatting

## Code Quality
- Project uses Flutter Lints for code analysis
- Follows Material Design 3 patterns
- Implements proper state management with `setState`
- Uses async/await for data operations
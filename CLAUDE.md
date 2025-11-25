# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter personal finance tracking application called "accounts_flow" that helps users manage multiple accounts, track financial transactions, and visualize balance history with charts.

## Development Commands

### Essential Commands
- `flutter pub get` - Install dependencies
- `flutter analyze` - Run static analysis with Flutter Lints
- `flutter test` - Run unit tests
- `flutter run` - Run the application (use `-d chrome` for web, `-d macos` for desktop, `-d windows` for Windows)

### Cross-Platform Building
- `flutter build macos` - Build for macOS
- `flutter build windows` - Build for Windows
- `./build_macos.sh --all` - Complete macOS build process (clean -> build -> package DMG)
- `./build_windows.ps1 -All` - Complete Windows build process (clean -> build -> package ZIP)

## Architecture

### Data Models
- **Account** (`lib/models/account.dart`): Financial accounts with types (bankCard, digitalWallet, stockAccount, creditCard, cash, investment)
- **Transaction** (`lib/models/transaction.dart`): Financial transactions with types (income, expense, transfer)
- **BalanceHistory** (`lib/models/balance_history.dart`): Weekly balance records with automatic Saturday tracking

### Data Layer
- **DataService** (`lib/services/data_service.dart`): Singleton service using shared_preferences for local persistence
  - Manages accounts, transactions, and balance history storage
  - Automatic weekly balance recording on Saturdays
  - JSON serialization/deserialization for all data models

### UI Architecture
- **Screens**:
  - `HomeScreen` (`lib/screens/home_screen.dart`): Main dashboard with total balance, account list, and recent transactions
  - `AccountDetailScreen` (`lib/screens/account_detail_screen.dart`): Individual account view with charts and transaction history
  - `HistoryScreen` (`lib/screens/history_screen.dart`): Weekly balance history tracking and visualization

- **Widgets**:
  - `AccountCard` (`lib/widgets/account_card.dart`): Reusable card for account display
  - `BalanceChart` (`lib/widgets/balance_chart.dart`): Line chart showing account balance trends using fl_chart
  - `AddAccountDialog` (`lib/widgets/add_account_dialog.dart`): Modal dialog for account creation
  - `AddTransactionDialog` (`lib/widgets/add_transaction_dialog.dart`): Modal dialog for transaction recording

### Key Dependencies
- `fl_chart: ^1.1.1` - Data visualization charts
- `intl: ^0.20.2` - Date formatting and localization
- `shared_preferences: ^2.4.1` - Local data persistence
- `cupertino_icons: ^1.0.8` - iOS-style icons

## Data Flow

1. **Account Management**: Users create accounts through `AddAccountDialog` with initial balances
2. **Transaction Recording**: Users add transactions through `AddTransactionDialog` (income/expense/transfer)
3. **Automatic Balance Tracking**: `DataService.recordWeeklyBalances()` runs at app startup to record Saturday balances
4. **Balance Calculation**: Running balances calculated from transaction history
5. **Chart Visualization**: `BalanceChart` displays historical balance trends
6. **Data Persistence**: All data stored locally using shared_preferences

## Important Implementation Details

### Balance History System
- Automatic weekly balance recording every Saturday
- `BalanceHistory.getLastSaturday()` and `getNextSaturday()` for date calculations
- History screen allows viewing and managing recorded balances

### Color Handling
- Account colors stored as ARGB integers for persistence
- Use `Color.alpha`, `Color.red`, `Color.green`, `Color.blue` for color manipulation

### JSON Serialization
- All models implement `toJson()` and `fromJson()` methods
- DataService uses `jsonEncode()` and `jsonDecode()` for storage

### Transaction Logic
- Income: Increases account balance
- Expense: Decreases account balance
- Transfer: Decreases source account, increases target account

### Chart Data
- `BalanceChart` processes transactions to generate historical balance data
- Uses FlSpot for chart coordinates with custom date formatting

## Code Quality
- Project uses Flutter Lints for code analysis via `analysis_options.yaml`
- Follows Material Design 3 patterns
- Implements proper state management with `setState`
- Uses async/await for data operations
- All code comments are written in Chinese
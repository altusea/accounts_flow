# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## code style

You are a thoughtful and artistic programmer who writes code as if crafting literature.
Follow the principles of Wang Yin’s “The Wisdom of Programming” (2015).
Your goal is not only to make code work, but to make it *clear, elegant, and timeless*.

== PRINCIPLES OF CODE CREATION ==

1. **Programming as an Art**
   - Treat programming not merely as technical execution but as an artistic discipline refined through reflection and repetition.
   - True mastery grows from continuous practice and insight, not shortcuts.
   - Value clarity and expressiveness above clever tricks or brevity.
   - Seek the simplest structure that fully expresses the idea.

2. **Refine Relentlessly**
   - Never settle for the first version. Rewrite, simplify, and polish.
   - Delete aggressively — the best programmers delete more code than they write.
   - Each refinement should reduce complexity, duplication, and cognitive load.
   - Allow time and distance to reveal better ways; true insight often comes from returning later with new eyes.

3. **Write Elegant Structures**
   - Elegant code should look geometrically tidy — structured like nested boxes or well-pruned branches.
   - Avoid tangled control flows (“spaghetti code”). The structure should reveal the logic at a glance.
   - Every `if` statement must have an explicit `else` branch that handles the opposite condition.
   - Handle all possibilities consciously; never rely on implicit fallthroughs.
   - Be explicit with braces — never depend on indentation alone to imply logic.

4. **Modular and Functional Design**
   - A module is defined by *clear inputs and outputs*, not by files or directories.
   - A function is the most natural module — small, self-contained, and composable.
   - Prefer small, pure functions that each do one simple thing.
   - Functions should communicate via parameters and return values — not shared state or class members.
   - Avoid global variables and implicit dependencies.
   - Extract repeating logic into helper functions, no matter how small.

5. **Readable, Self-Explanatory Code**
   - Write code that needs no comments. Let names and structure tell the story.
   - Replace comments with meaningful names and helper functions — every function name is a sentence in your story.
   - Choose meaningful names: concise for local variables, descriptive for public interfaces.
   - Keep variable scope as small and as close to usage as possible.
   - Do not reuse local variables for different meanings; clarity outweighs micro-optimization.
   - Use intermediate variables to break complex expressions and reveal logic.
   - Manual line breaks should serve logic and rhythm, not IDE defaults.

6. **Simplicity Over Cleverness**
   - Never use language features just because they exist.
   - Avoid “smart” idioms that hide logic (e.g., using `&&` or `||` as control flow).
   - Simplicity is not lack of sophistication; it is the mastery of essentials.
   - Explicit and straightforward code is always preferable to tricky one-liners.
   - Clarity is more valuable than brevity.

7. **Safe and Complete Logic**
   - Always handle every logical case — your code should be exhaustive and unambiguous.
   - Prefer `return` to escape a function early rather than breaking nested loops.
   - Avoid `continue` and `break` unless absolutely necessary; make control flow explicit.
   - Never rely on “optical illusions” — visual cues that suggest logic not enforced by syntax.
   - Every conditional should state both what happens *and* what doesn’t.

8. **Error and Null Handling**
   - Handle every error condition deliberately; never ignore or swallow exceptions.
   - Catch specific exceptions, never generic ones.
   - Be explicit about all possible states — handle errors and nulls exhaustively, and fail fast when invariants are violated.
   - Do not propagate `null` values casually. Validate and handle them immediately.
   - Distinguish between “not found” and “error” — they are not the same.
   - Prefer returning exceptions or using `Optional`/`Maybe` types to make absence explicit.
   - Use static analysis, `@NotNull` annotations, or runtime checks to prevent silent null propagation.
   - If a function must reject `null`, fail immediately (e.g., `Objects.requireNonNull()`).

9. **Avoid Over-Engineering**
   - Solve today’s problem first. Reuse and abstraction can wait.
   - Do not overthink future scalability or hypothetical needs.
   - Write simple, working code before worrying about reuse or frameworks.
   - Tests are valuable, but simplicity and correctness of logic come first.
   - Strive for code that is *obviously correct*, not merely “tested enough.”

10. **Aesthetic and Mental Clarity**
    - Code should “feel” balanced and natural — indentation, structure, and logic should form a visual harmony.
    - Prefer a clear tree of logic to a flat or tangled control flow.
    - The best code reads like quiet reasoning — calm, balanced, and inevitable.

== OUTPUT STYLE ==

When generating code:

- Always prioritize readability, symmetry, and explicitness.
- Never produce ambiguous or overly clever constructs.
- Write as if the reader is an intelligent peer who values simplicity and elegance.
- Explain reasoning in clear, minimal comments *only when truly necessary.*

Remember:

> “Good programmers delete more code than they write.
> Elegance is not achieved by adding, but by removing.” — inspired by Wang Yin

Write code worthy of contemplation.

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

## Development Environment Setup

### Platform Requirements
- **Flutter SDK**: >= 3.0.0, Dart SDK >= 2.17.0
- **macOS development**: Xcode 12.5+, CocoaPods installed
- **Windows development**: Visual Studio Build Tools or Visual Studio 2019+ with C++ workload
- **iOS development**: Xcode (macOS only), iOS Simulator
- **Android development**: Android Studio with Android SDK

### Environment Verification
```bash
flutter doctor -v    # Check all dependencies
flutter devices      # List available development devices
```

## Advanced Build System

### Build Script Usage
The project includes sophisticated build scripts for production deployments:

#### macOS Build Script (`build_macos.sh`)
```bash
./build_macos.sh -c    # Clean only
./build_macos.sh -b    # Build only
./build_macos.sh -p    # Package only (create DMG)
./build_macos.sh -a    # All steps (clean -> build -> package)
./build_macos.sh --all # Same as -a
```

#### Windows Build Script (`build_windows.ps1`)
```powershell
.\build_windows.ps1 -c      # Clean only
.\build_windows.ps1 -b      # Build only
.\build_windows.ps1 -p      # Package only (create ZIP)
.\build_windows.ps1 -a      # All steps
.\build_windows.ps1 -All    # All steps (same as -a)
```

### Build Outputs
- **macOS**: Creates DMG installer in `dist/` directory
- **Windows**: Creates ZIP distribution in `dist/` directory
- **Web**: Build output in `build/web/` directory
- **Mobile**: APK/IPA files in `build/` directories

### Build Dependencies
- Scripts automatically check Flutter and platform dependencies
- Failed dependency checks will stop the build process with clear error messages
- CocoaPods integration handled automatically for macOS builds

## Platform-Specific Development

### macOS Development
- Uses CocoaPods for native dependency management
- MainFlutterWindow.swift handles window lifecycle
- Requires macOS deployment target (currently set to minimum supported version)

### Windows Development
- Uses CMake configuration for native builds
- Visual Studio Build Tools required for compilation
- flutter_window.cpp handles native window integration

### iOS Development
- Standard Flutter iOS development patterns
- Podfile configured for iOS-specific dependencies
- Requires physical device or iOS Simulator for testing

### Web Development
- Standard Flutter web deployment
- Responsive design considerations for desktop/mobile browsers
- LocalStorage used for data persistence

## Application Configuration

### App Metadata
- **Application Name**: 记账应用 (Accounting App)
- **Version**: 1.0.0+1 (semantic versioning + build number)
- **Bundle IDs**: Configured per platform in respective build files

### Theme and Design
- Material Design 3 theme implementation
- Custom color scheme for financial data visualization
- Responsive layout adapted for multiple screen sizes
- Dark/light theme support (if implemented)

### Performance Considerations
- Chart rendering optimized for large datasets
- Lazy loading patterns for transaction history
- Memory-efficient JSON serialization for local storage
- Build optimization for different platform targets

## Troubleshooting Common Issues

### Build Failures
- **macOS**: Run `pod install` in `macos/` directory if CocoaPods issues occur
- **Windows**: Ensure Visual Studio Build Tools with C++ workload is installed
- **General**: Run `flutter clean && flutter pub get` before building

### Platform-Specific Issues
- **iOS Simulator**: Ensure Xcode command line tools are properly configured
- **Android Emulator**: Check Android SDK installation and AVD configuration
- **Web Build**: Clear browser cache if issues with hot reload occur

### Performance Issues
- Large datasets in charts: Implement data pagination or sampling
- Memory usage: Monitor transaction history size and implement cleanup if needed
- Build times: Use `--release` builds for performance testing

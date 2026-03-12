## FinanceApp – iOS Banking Demo

FinanceApp is a **demo mobile banking app** for iOS.  
It shows how a modern finance app could look and work: login, onboarding, cards, accounts, sending and requesting money, notifications, and basic analytics.

The goal of this project is to **demonstrate clean app structure**, **MVVM + Coordinator architecture**, and **integration with Firebase** and a small external API (mandarin prices).

---

### What this app does

- **User accounts**
  - Sign up with email and password
  - Email verification
  - Login / logout
  - Store extra user info (name, phone, country, etc.)

- **Onboarding flow**
  - Guided onboarding screens
  - Personal info and compliance steps
  - Resume onboarding if user stops in the middle

- **Cards and accounts**
  - Create and manage virtual cards
  - Each card has its own account with balance and currency
  - Block / unblock and delete cards

- **Money transfer & requests**
  - Send money to other users
  - Request money from other users
  - Accept / reject pending requests
  - All operations stored as transactions

- **Top up and payments**
  - Top up account balance
  - Pay from account to merchants
  - See transaction history list

- **Notifications**
  - In‑app notification list
  - Unread notification count
  - Notifications for transfers, top ups, and payments

- **Mandarin prices mini‑feature**
  - Fetch live mandarin prices from an external API
  - Normalize prices per kilogram for different stores
  - Show latest price per store and average price

---

### Main screens

- **Launch / splash**
  - `LaunchScreenViewController`
  - Decides where to go next (onboarding or main app)

- **Auth**
  - `LoginViewController` / `LoginViewModel`
  - `SignupViewController` / `SignupViewModel`
  - `EmailVerificationViewController` / `EmailVerificationViewModel`
  - `PersonalInfoViewController` / `PersonalInfoViewModel`
  - `ComplianceViewController` / `ComplianceViewModel`

- **Main tab bar**
  - `MainTabBarController` – root of the main logged‑in experience

- **Dashboard (Home)**
  - `MainViewController` / `MainViewModel`
  - Shows cards, quick actions, recent transactions

- **Send / Request money**
  - `SendMoneyViewController` / `SendMoneyViewModel`
  - `RequestMoneyRecipientsViewController` / `RequestMoneyRecipientsViewModel`
  - `RequestMoneyEnterAmountViewController` / `RequestMoneyEnterAmountViewModel`
  - `AcceptTransferViewController` / `AcceptTransferViewModel`

- **Top up**
  - `TopUpViewController` / `TopUpViewModel`

- **Payments**
  - `PaymentsViewController` / `PaymentsViewModel`
  - `EnterPaymentViewController` / `EnterPaymentViewModel`

- **History**
  - `HistoryViewController` / `HistoryViewModel`
  - `HistoryTransactionCell`

- **Cards and profile**
  - `CardManagementViewController` / `CardManagementViewModel`
  - `CardDetailViewController`
  - `ProfileTabViewController`
  - `ProfilePersonalInfoViewController` / `ProfilePersonalInfoViewModel`
  - `SettingsViewController` / `SettingsViewModel`

- **Notifications**
  - `NotificationsViewController` / `NotificationsViewModel`
  - `NotificationCell`

- **Mandarin prices**
  - `MandarinPricesView` (SwiftUI)
  - `MandarinPricesHostViewController`
  - `MandarinPriceModels` for data processing

---

### Tech stack

- **Platform**: iOS
- **Language**: Swift
- **UI**: UIKit (view controllers, custom views) + small SwiftUI view (`MandarinPricesView`)
- **Architecture**:
  - **MVVM** (ViewController + ViewModel)
  - **Coordinator pattern** to handle navigation (`AppCoordinator`, `OnboardingCoordinator`, etc.)
- **Backend services**:
  - **Firebase Auth** (`AuthService`) for authentication
  - **Firebase Firestore** (`FirestoreService`) for users, accounts, cards, transactions, notifications, and transfer requests
- **Networking**:
  - `URLSession` with `async/await` for the mandarin prices API (`MandarinPricesService`)

---

### Project structure 

Inside the `FinanceApp/FinanceApp` folder:

- **`App/`**
  - `AppDelegate.swift`, `SceneDelegate.swift`
  - Setup of window and root coordinator

- **`Coordinators/`**
  - `Coordinator` protocol and concrete coordinators
  - `AppCoordinator` – decides between onboarding and main app after launch
  - `OnboardingCoordinator` and related routes
  - **Why**: keeps navigation logic out of view controllers and makes flows easier to follow and test.

- **`Features/`**
  - Split by **feature and area**:
    - `Features/Auth/...`
    - `Features/Onboarding/...`
    - `Features/Main/Dashboard/...`
    - `Features/Main/SendMoney/...`
    - `Features/Main/RequestMoney/...`
    - `Features/Main/Payments/...`
    - `Features/Main/History/...`
    - `Features/Main/Notifications/...`
    - `Features/Main/Profile/...`
    - `Features/Main/Settings/...`
    - `Features/Main/TopUp/...`
    - `Features/Main/MandarinPrices/...`
  - Each feature usually has:
    - `SomethingViewController` (UI)
    - `SomethingViewModel` (business logic, talks to services)

- **`Models/`**
  - Pure data types: `User`, `Account`, `Card`, `Transaction`, `AppNotification`, `PendingTransferRequest`, `SendMoneyRecipient`, `PaymentCategory`, etc.
  - Detached from UI, used by services and view models.

- **`Services/`**
  - `AuthService` – wraps `FirebaseAuth` APIs
  - `FirestoreService` – wraps Firestore operations for users, accounts, cards, transfers, notifications
  - `ContactsService` – contacts integration
  - `StorageService` – local storage or cache
  - `ServiceContainer` – single place where services are created and injected
  - **Why**: abstracts Firebase and other details away from the UI and view models.

- **`Components/`**
  - Reusable UI components:
    - Auth UI: `AuthTextFieldView`, `AuthPillButton`, `AuthHeaderView`, `AuthSocialIconButton`, `AuthBottomPromptView`, `AuthDividerView`, `InlineLinkButton`
    - Dashboard cells: `DashboardCardCell`, `CardFaceView`, `TransactionRowView`
  - **Why**: keep UI consistent and avoid copy–paste.

- **`Utils/`**
  - `Constants`, `CardNumberGenerator`, `CountriesData`, etc.
  - **Why**: shared helpers and configuration live here.

---

### Architecture 

- **View Controllers**:
  - Own the UIKit screens.
  - Handle user interactions (button taps, table selections).
  - Bind to a **ViewModel** for data and actions.

- **View Models**:
  - Expose simple properties and methods for the view.
  - Call **services** (Firebase, network, storage).
  - Contain most of the “business logic” (e.g. when to allow a transfer, how to format data).

- **Services**:
  - One clear job each (auth, Firestore, contacts, cache).
  - Wrap external dependencies so only this layer needs to know Firebase APIs.

- **Coordinators**:
  - Control navigation (push / present / dismiss).
  - Define flows: onboarding flow, main flow, etc.
  - View controllers ask coordinators to move to the next screen, instead of pushing directly.

This separation makes it easier to **reason about the code**, **replace dependencies**, and **test** the logic.

---

### Interesting / challenging parts

- **Safe money transfers with Firestore transactions**
  - `FirestoreService.transfer(_:)` uses `runTransaction` to:
    - Check balances
    - Update sender and recipient accounts atomically
    - Create matching transaction records
    - Create a notification for the recipient
  - Avoids race conditions and inconsistent balances.

- **Pending transfer and money request flow**
  - Separate model `PendingTransferRequest`
  - Dedicated methods to create, fetch, accept, and reject requests
  - Special handling when sender or recipient must choose an account.

- **Flexible user data decoding**
  - `FirestoreService.decodeUserDocument(...)` can map multiple possible field names (`firstName` vs `first_name`, `createdAt` vs `created_at`).
  - Makes the app more robust to legacy or slightly different schemas.

- **Mandarin prices mini‑service**
  - `MandarinPricesService.fetchPrices()` talks to a simple HTTP API.
  - `MandarinPriceModels` normalize different `mass` formats and compute a `pricePerKg`.
  - Uses two ISO8601 formatters to handle timestamps with and without fractional seconds.

- **Coordinator + onboarding resume**
  - `AppCoordinator` checks Firebase current user and Firestore user document.
  - Can resume onboarding where user left off or start fresh.

---

### How to run the app

1. **Requirements**
   - Xcode (latest stable version)
   - iOS simulator (or a physical device)
   - A Firebase project configured for:
     - Firebase Auth
     - Cloud Firestore

2. **Clone the repo**

   ```bash
   git clone <your-repo-url>
   cd FinanceAppFinalProject/FinanceApp

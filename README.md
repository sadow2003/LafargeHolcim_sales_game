# SalesQuest — LafargeHolcim Sales Game

A gamified sales performance mobile app built with Flutter and Firebase. Sales teams compete on a leaderboard, claim sales, earn rewards, and get coached by an AI assistant.

---

## Prerequisites

Before you start, make sure you have the following installed:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.11.4 or later)
- Dart SDK (comes bundled with Flutter)
- Android Studio or Xcode (for running on an emulator or physical device)
- A connected Android/iOS device or a running emulator

Verify your Flutter installation is ready:

```bash
flutter doctor
```

All checkmarks should be green before continuing.

---

## Getting Started

### 1. Clone the repository

```bash
git clone <repository-url>
cd lafargeholcim_sales_game
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run the app

```bash
flutter run
```

To target a specific device when multiple are connected:

```bash
flutter devices          # list available devices
flutter run -d <device-id>
```

---

## Creating a Test Account

The app opens on the **Login** screen. Tap **"Don't have an account? Register here"** to create one.

### Email requirement

Registration only accepts `@lafargeholcim.com` email addresses. Use a test email in that format, for example:

```
testuser@lafargeholcim.com
```

> **Note:** Firebase Authentication will create this account even if the email inbox does not exist. Email verification is currently disabled, so you can log in immediately after registering.

### Password requirements

The password must be at least 8 characters and include:
- One uppercase letter
- One lowercase letter
- One number
- One special character (e.g. `!`, `@`, `#`, `$`)

Example: `Test@1234`

---

## App Features by Role

### Salesperson
- View the live leaderboard and rankings
- Submit sale claims for manager approval
- Track personal milestones and progress
- Browse and redeem rewards from the reward store
- Chat with the AI Sales Coach

### Sales Manager
- Review and approve or reject submitted sale claims
- Manage the product catalogue
- Receive push notifications when a sale is submitted

### Market Manager
- Create time-limited sales events with custom point multipliers
- Set start/end dates and reward tiers for events

### Admin
- Create, edit, and delete user accounts
- View all registered users and their roles

---

## Project Structure

```
lib/
├── main.dart                   # App entry point and route definitions
├── firebase_options.dart       # Firebase project configuration
├── screens/
│   ├── Login.dart              # Login screen
│   ├── register.dart           # Registration screen
│   ├── salesperon/             # Salesperson screens
│   ├── sales_manager/          # Sales manager screens
│   ├── market_manager/         # Market manager screens
│   ├── admin/                  # Admin screens
│   └── broadcast/              # Company-wide broadcast feed
├── ai/                         # AI Coach screens and service
├── services/                   # Push notification service
└── widgets/                    # Shared UI components
```

---

## Environment Variables

The `.env` file is included in the repository and pre-configured with the Firebase and Groq API keys required to run the app. No additional setup is needed — `flutter run` will pick it up automatically.

---

## Troubleshooting

**`flutter pub get` fails**
Make sure your Flutter SDK version is 3.11.4 or later (`flutter --version`).

**App crashes on launch**
Ensure an emulator is running or a physical device is connected and `flutter doctor` shows no critical errors.

**"Only @lafargeholcim.com emails are allowed" error**
Use an email ending in `@lafargeholcim.com` — any value in that format works for testing.

**"Invalid admin secret key" error**
Make sure you are entering the correct secret key for the selected role (see the table above).

**Push notifications not working on emulator**
Firebase Cloud Messaging does not work on all emulators. Use a physical device for full notification support.

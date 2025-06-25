# CertiSafe: Digital Certificate Repository

A Flutter application for secure management, issuance, and verification of digital certificates.  
Supports multiple user roles: **Admin**, **Certificate Authority (CA)**, **Client**, and **Recipient**.

---

## Features

- **Google Sign-In Authentication**
- **Role-based Dashboards** (Admin, CA, Client, Recipient)
- **Certificate Issuance & Upload**
- **Certificate Verification**
- **True Copy Requests & Approval**
- **PDF Certificate Preview**
- **Shareable Certificate Links**
- **System Analytics & Logs (Admin)**

---

## Getting Started

### 1. Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-dart) (comes with Flutter)
- [Android Studio](https://developer.android.com/studio) (for Android)
- [Xcode](https://developer.apple.com/xcode/) (for iOS, macOS only)
- [Firebase Project](https://console.firebase.google.com/)
- [Node.js](https://nodejs.org/) (for FlutterFire CLI)

---

### 2. Clone the Repository

```sh
git clone <your-repo-url>
cd certificate_app
```

---

### 3. Install Dependencies

```sh
flutter pub get
```

---

### 4. Configure Firebase

1. **Install FlutterFire CLI:**

   ```sh
   dart pub global activate flutterfire_cli
   ```

2. **Login to Firebase:**

   ```sh
   firebase login
   ```

3. **Run FlutterFire Configure:**

   ```sh
   flutterfire configure
   ```

   - Select your Firebase project and platforms.
   - This generates `lib/firebase_options.dart`.

4. **Add Firebase config files:**
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from Firebase Console and place them in the respective platform folders.

---

### 5. Run the App

- **Android/iOS:**

  ```sh
  flutter run
  ```

- **Web:**
  ```sh
  flutter run -d chrome
  ```

---

### 6. Run Tests

```sh
flutter test
```

---

## User Roles & Main Screens

| Role                      | Main Features                                                               |
| ------------------------- | --------------------------------------------------------------------------- |
| **Admin**                 | System analytics, logs, user management                                     |
| **Certificate Authority** | Approve certificate requests, issue certificates, handle true copy requests |
| **Client**                | Request certificates, view request status                                   |
| **Recipient**             | View/download certificates, upload true copy requests, share certificates   |

---

## Key Screens

- **Login & Registration:** Google Sign-In, role selection, profile setup
- **Dashboard:** Role-based navigation and actions
- **Certificate Request/Approval:** Request, approve, and issue certificates
- **True Copy:** Request/upload, CA approval, certified PDF generation
- **Verification:** Public certificate authenticity check
- **PDF Preview:** In-app PDF viewer for certificates

---

## Project Structure

```
lib/
  main.dart                # App entry point, Firebase init, routing
  screens/                 # UI screens (dashboard, login, CA, client, recipient, admin, etc.)
  services/                # Business logic (auth, certificate, Firestore)
  utils/                   # Utilities (PDF, share token)
  ...
```

---

## Firebase & Packages

- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`
- `google_sign_in`
- `provider`
- `flutter_pdfview`
- `syncfusion_flutter_pdf`
- `certify_me`
- `intl`, `url_launcher`, `file_picker`, `google_ml_kit`, etc.

---

## Troubleshooting

- **Missing `gradlew.bat` or build errors:**  
  Run `flutter create .` in the project root to restore missing Android files.

- **Firebase errors:**  
  Ensure `firebase_options.dart` is generated and platform config files are present.

- **General issues:**  
  Run `flutter doctor` and resolve any reported problems.

---

## License

MIT (or your license here)

# MS Image 📱✨

[![Flutter Version](https://img.shields.io/badge/Flutter-3.1%2B-blue.svg)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.0%2B-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**MS Image** is a powerful, modern, feature-rich, and privacy-first multi-tool mobile & web application built with Flutter. It combines a robust document scanner, advanced image editor, professional-grade filters, creative collage maker, and a secure QR code scanner & generator into a single seamless experience.

---

## 🌟 Key Features

### 📄 Intelligent Document Scanner
- **Auto-Detection:** Detects document boundaries accurately in real-time.
- **Perspective Correction:** Advanced perspective transform to straighten angled document photos into clean, flat scans.
- **Enhanced Filters:** Custom scanner filters including *Magic Color*, *Grayscale*, and *Black & White*.
- **Multi-Page Support:** Create, organize, and manage multi-page scanned documents effortlessly.

### 🖼️ Advanced Image Editor & Toolbox
- **Crop & Adjust:** Precise cropping tools, aspect ratios, rotation, and perspective adjustments.
- **Drawing & Text Overlay:** Draw freely on images, add custom text overlays, and apply styling.
- **GPU Color Filters:** Apply professional presets, adjust brightness, contrast, saturation, and warmth.
- **Collage Maker:** Combine multiple photos into stunning custom layouts.

### ⚡ QR Code Suite
- **Fast QR Scanner:** High-performance scanner with built-in security guardrails against malicious links.
- **Custom QR Generator:** Generate QR codes for URLs, Wi-Fi, contacts, text, and more with customized styling.

### 🔒 Security & Privacy First
- **App Lock:** Secure sensitive scans and tools using Biometrics (Fingerprint/Face ID) or PIN code (`local_auth`, `flutter_secure_storage`).
- **Offline Storage:** Local database caching with `Hive` ensuring your documents and images remain private on your device.
- **QR Security Guard:** Inspects scanned URLs and data safety before opening.

### 🎨 Modern UI & Architecture
- **Material 3 Design:** Sleek, modern interface adhering to Material Design guidelines.
- **Dynamic Color:** Adapts system colors seamlessly across platforms.
- **Adaptive Layouts:** Responsive UI optimized for phones, tablets, and web.

---

## 🛠️ Tech Stack & Architecture

- **Framework:** [Flutter](https://flutter.dev) (Dart)
- **State Management:** [Provider](https://pub.dev/packages/provider)
- **Routing:** [GoRouter](https://pub.dev/packages/go_router)
- **Local Storage:** [Hive](https://pub.dev/packages/hive) & [SharedPreferences](https://pub.dev/packages/shared_preferences)
- **Security:** [Local Auth](https://pub.dev/packages/local_auth) & [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)
- **Image Processing:** Dart `image` package, custom perspective & filtering pipelines
- **Scanning & QR:** `mobile_scanner`, `qr_flutter`

---

## 📂 Project Structure

```tree
lib/
├── core/                # Core utilities, theme, database, routing, and security guards
│   ├── database/        # Hive & local repositories (image storage, security, recent tools)
│   ├── errors/          # Global error handling and app exceptions
│   ├── navigation/      # GoRouter configuration
│   ├── registry/        # Smart tool registry models
│   ├── security/        # App lock service, biometric guards, QR security
│   ├── services/        # Image cache manager, pipeline service, permission handler
│   ├── theme/           # App design system, theme provider, dynamic color
│   └── utils/           # File ingest, GPU color filters, image decoders, storage utils
└── features/            # Feature modules (MVVM / Clean Architecture style)
    ├── crop_tool/       # Advanced cropping and perspective adjustment
    ├── dashboard/       # Main dashboard, settings, about, privacy policy
    ├── filters/         # GPU filters and filter editor
    ├── image_tools/     # Canvas drawing, text overlay, image processing logic
    ├── qr_tools/        # QR code scanner and generator
    ├── scanner/         # Document detection, perspective transform, scanner editor
    └── toolbox/         # Collage maker and image utilities
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (`>=3.1.0 <4.0.0`)
- Android Studio / VS Code with Flutter extensions
- Connected device or emulator (Android / iOS / Web)

### Installation & Execution

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/ms-image.git
   cd ms_image
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run code generation (if modifying Hive models):**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

---

## 📄 License & Privacy

- **License:** Distributed under the MIT License. See `LICENSE` for more information.
- **Privacy Policy:** MS Image respects user privacy. All document scans and image editing take place locally on-device. See [PRIVACY_POLICY.md](PRIVACY_POLICY.md) for details.

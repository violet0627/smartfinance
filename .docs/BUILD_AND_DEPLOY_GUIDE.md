# 🏗️ SmartFinance - Build & Deployment Guide

**Version:** 1.0.0
**Last Updated:** January 10, 2026
**Target Platforms:** Android, iOS

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Development Build](#development-build)
3. [Release Build](#release-build)
4. [Android Deployment](#android-deployment)
5. [iOS Deployment](#ios-deployment)
6. [Backend Deployment](#backend-deployment)
7. [Testing](#testing)
8. [Troubleshooting](#troubleshooting)

---

## 🔧 Prerequisites

### **Required Software**

#### **For Flutter App:**
- Flutter SDK 3.8+ ([Install Guide](https://docs.flutter.dev/get-started/install))
- Dart 3.0+
- Android Studio / VS Code
- Git

#### **For Android:**
- Android SDK 21+ (Android 5.0+)
- Android Studio
- Java Development Kit (JDK) 11+
- Gradle 7.0+

#### **For iOS:**
- macOS with Xcode 14+
- CocoaPods
- Apple Developer Account ($99/year)

#### **For Backend:**
- Python 3.11+
- MySQL 8.0+
- pip package manager
- Virtual environment (venv)

### **Verify Installation**

```bash
# Check Flutter
flutter --version
flutter doctor

# Check Dart
dart --version

# Check Python
python --version

# Check MySQL
mysql --version
```

---

## 💻 Development Build

### **1. Clone Repository**

```bash
git clone https://github.com/yourusername/smartfinance.git
cd smartfinance
```

### **2. Install Flutter Dependencies**

```bash
flutter pub get
```

### **3. Run Backend Locally**

```bash
cd backend
python -m venv venv

# Windows
venv\Scripts\activate

# macOS/Linux
source venv/bin/activate

pip install -r requirements.txt

# Configure database
mysql -u root -p
CREATE DATABASE smartfinance;
exit;

# Update backend/config.py with your MySQL credentials

# Run migrations
python create_tables.py

# Start backend
python run.py
```

Backend will run on `http://localhost:5000`

### **4. Update API Endpoint**

Edit `lib/services/api_service.dart`:

```dart
// Development
static const String baseUrl = 'http://localhost:5000/api';

// Production
// static const String baseUrl = 'https://api.smartfinance.app/api';
```

### **5. Run Flutter App**

```bash
# Android
flutter run

# iOS
flutter run -d ios

# Specific device
flutter devices
flutter run -d <device-id>
```

---

## 🚀 Release Build

### **Android Release Build**

#### **Step 1: Generate Keystore**

```bash
keytool -genkey -v -keystore smartfinance-release-key.jks \
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 \
  -alias smartfinance
```

**Important:** Save the passwords securely!

#### **Step 2: Create key.properties**

Create `android/key.properties`:

```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=smartfinance
storeFile=<path-to-smartfinance-release-key.jks>
```

**⚠️ NEVER commit key.properties to Git!**

Add to `.gitignore`:
```
android/key.properties
*.jks
```

#### **Step 3: Update build.gradle.kts**

Edit `android/app/build.gradle.kts`:

```kotlin
// Add before android {
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            // Enable ProGuard/R8
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

#### **Step 4: Build APK**

```bash
# Clean build
flutter clean
flutter pub get

# Build release APK
flutter build apk --release

# Build split APKs (recommended for Play Store)
flutter build apk --split-per-abi

# Build App Bundle (AAB) - preferred for Play Store
flutter build appbundle --release
```

**Output locations:**
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- Split APKs: `build/app/outputs/flutter-apk/app-<abi>-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

#### **Step 5: Test Release Build**

```bash
# Install on connected device
flutter install --release

# Or manually
adb install build/app/outputs/flutter-apk/app-release.apk
```

### **iOS Release Build**

#### **Step 1: Apple Developer Setup**

1. Enroll in Apple Developer Program ($99/year)
2. Create App ID in Apple Developer Console
3. Create Distribution Certificate
4. Create Provisioning Profile

#### **Step 2: Configure Xcode**

```bash
cd ios
pod install
open Runner.xcworkspace
```

In Xcode:
1. Select "Runner" → "Signing & Capabilities"
2. Select your Team
3. Enable "Automatically manage signing"
4. Update Bundle Identifier: `com.yourcompany.smartfinance`

#### **Step 3: Update Info.plist**

Edit `ios/Runner/Info.plist`:

```xml
<key>CFBundleDisplayName</key>
<string>SmartFinance</string>

<key>CFBundleShortVersionString</key>
<string>1.0.0</string>

<key>CFBundleVersion</key>
<string>1</string>

<!-- Camera permission -->
<key>NSCameraUsageDescription</key>
<string>Take photos of receipts for automatic data entry</string>

<!-- Photo library permission -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Select receipt images from your photo library</string>
```

#### **Step 4: Build IPA**

```bash
# Build for release
flutter build ios --release

# Or build archive in Xcode
# Product → Archive
# Then distribute to App Store
```

---

## 📱 Android Deployment

### **Google Play Store**

#### **1. Prepare Store Listing**

**Required Assets:**
- App icon: 512x512 PNG
- Feature graphic: 1024x500 PNG
- Screenshots: At least 2 (phone), 7-inch & 10-inch tablet recommended
- Short description: 80 characters max
- Full description: 4000 characters max
- Privacy policy URL

#### **2. Create Google Play Console Account**

- One-time $25 registration fee
- https://play.google.com/console

#### **3. Create App**

1. Go to "All apps" → "Create app"
2. Enter app name: "SmartFinance"
3. Select language: English (US)
4. Choose app type: App
5. Select free or paid

#### **4. Complete Store Listing**

**App details:**
- App name: SmartFinance
- Short description: "Complete personal finance management with receipt scanning"
- Full description: [See RELEASE_NOTES_v1.0.0.md]
- App icon
- Feature graphic
- Screenshots (at least 2)

**Categorization:**
- Category: Finance
- Tags: finance, budget, expenses, receipts

**Contact details:**
- Email: support@smartfinance.app
- Phone: (Optional)
- Website: https://smartfinance.app

**Privacy policy:**
- URL: https://smartfinance.app/privacy

#### **5. Content Rating**

Complete questionnaire (typically rated 3+)

#### **6. App Content**

- Privacy policy: Required
- Ads: Select if using ads
- Target audience: All ages
- App access: Not restricted

#### **7. Upload Build**

1. Go to "Production" → "Create new release"
2. Upload app-release.aab
3. Enter release name: "1.0.0 - Initial Release"
4. Add release notes
5. Review and roll out

**Review Process:**
- Usually takes 1-7 days
- Check for policy violations
- Fix and resubmit if needed

---

## 🍎 iOS Deployment

### **App Store Connect**

#### **1. Prepare Assets**

**Required:**
- App icon: 1024x1024 PNG (no transparency)
- Screenshots:
  - 6.5" iPhone: 1242x2688 or 1284x2778
  - 5.5" iPhone: 1242x2208
  - iPad Pro (12.9"): 2048x2732
  - At least 3 screenshots per device type

#### **2. App Store Connect Setup**

1. Go to https://appstoreconnect.apple.com
2. Click "My Apps" → "+" → "New App"
3. Select platform: iOS
4. App name: SmartFinance
5. Primary language: English (U.S.)
6. Bundle ID: Select your bundle ID
7. SKU: SMARTFINANCE001

#### **3. App Information**

**Category:** Finance
**Subtitle:** "Personal finance made simple"
**Privacy Policy URL:** https://smartfinance.app/privacy
**Keywords:** finance,budget,expenses,money,tracking

#### **4. Pricing**

- Price: Free (or select tier)
- Availability: All territories

#### **5. Prepare for Submission**

**App Review Information:**
- Demo account (if needed)
- Contact information
- Notes for reviewer

**Version Information:**
- Screenshots (upload for all device types)
- Promotional text
- Description
- Keywords
- Support URL
- Marketing URL

**Build:**
- Upload via Xcode or Application Loader
- Select build for this version

#### **6. Submit for Review**

1. Complete all required fields
2. Submit for review
3. Wait for Apple review (typically 1-3 days)
4. Respond to any feedback

---

## 🖥️ Backend Deployment

### **Production Server Setup**

#### **Option 1: Cloud VPS (DigitalOcean, AWS EC2, etc.)**

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Python
sudo apt install python3.11 python3-pip python3-venv -y

# Install MySQL
sudo apt install mysql-server -y
sudo mysql_secure_installation

# Clone repository
git clone https://github.com/yourusername/smartfinance.git
cd smartfinance/backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
pip install gunicorn  # Production WSGI server

# Configure MySQL
sudo mysql
CREATE DATABASE smartfinance;
CREATE USER 'smartfinance'@'localhost' IDENTIFIED BY 'strong_password';
GRANT ALL PRIVILEGES ON smartfinance.* TO 'smartfinance'@'localhost';
FLUSH PRIVILEGES;
EXIT;

# Update config.py with production settings
nano config.py

# Run migrations
python create_tables.py

# Test locally
gunicorn -b 0.0.0.0:5000 run:app

# Set up systemd service
sudo nano /etc/systemd/system/smartfinance.service
```

**systemd service file:**
```ini
[Unit]
Description=SmartFinance Backend
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/smartfinance/backend
Environment="PATH=/home/ubuntu/smartfinance/backend/venv/bin"
ExecStart=/home/ubuntu/smartfinance/backend/venv/bin/gunicorn -b 0.0.0.0:5000 run:app

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start service
sudo systemctl enable smartfinance
sudo systemctl start smartfinance
sudo systemctl status smartfinance
```

#### **Option 2: Docker Deployment**

Create `Dockerfile`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["gunicorn", "-b", "0.0.0.0:5000", "run:app"]
```

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  backend:
    build: ./backend
    ports:
      - "5000:5000"
    environment:
      - DATABASE_URL=mysql://user:pass@db:3306/smartfinance
    depends_on:
      - db

  db:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=rootpass
      - MYSQL_DATABASE=smartfinance
      - MYSQL_USER=smartfinance
      - MYSQL_PASSWORD=password
    volumes:
      - mysql_data:/var/lib/mysql

volumes:
  mysql_data:
```

```bash
# Deploy
docker-compose up -d

# Check logs
docker-compose logs -f backend
```

#### **Configure Nginx (Reverse Proxy)**

```nginx
server {
    listen 80;
    server_name api.smartfinance.app;

    location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

#### **SSL Certificate (Let's Encrypt)**

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d api.smartfinance.app
```

---

## 🧪 Testing

### **Pre-Release Testing Checklist**

#### **Functional Testing:**
- [ ] User registration
- [ ] User login
- [ ] Email verification
- [ ] Two-factor authentication
- [ ] Add transaction manually
- [ ] Scan receipt with camera
- [ ] Edit transaction
- [ ] Delete transaction
- [ ] Search transactions
- [ ] Filter transactions
- [ ] Sort transactions
- [ ] Export to CSV
- [ ] Export to PDF
- [ ] Share exports
- [ ] Create budget
- [ ] Track budget progress
- [ ] Set financial goal
- [ ] Track goal progress
- [ ] Add recurring transaction
- [ ] Receive bill reminder
- [ ] View analytics charts
- [ ] Track investments
- [ ] Dark mode toggle
- [ ] Settings changes

#### **Performance Testing:**
- [ ] App launch time < 2s
- [ ] Transaction load time < 1s
- [ ] Receipt scan time < 5s
- [ ] Report generation < 3s
- [ ] Smooth animations (60 FPS)
- [ ] No memory leaks

#### **Platform Testing:**
- [ ] Android 10
- [ ] Android 11
- [ ] Android 12
- [ ] Android 13
- [ ] iOS 15
- [ ] iOS 16
- [ ] Different screen sizes

#### **Network Testing:**
- [ ] Offline mode (show errors)
- [ ] Slow network (loading states)
- [ ] Network interruption (retry logic)

### **Automated Testing**

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## 🐛 Troubleshooting

### **Common Build Issues**

#### **Issue: "Gradle build failed"**

**Solution:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

#### **Issue: "Pod install failed" (iOS)**

**Solution:**
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter build ios
```

#### **Issue: "App crashes on launch"**

**Checks:**
- Backend is running
- API URL is correct
- All permissions are granted
- Database is accessible

#### **Issue: "Receipt scanning not working"**

**Checks:**
- Camera permission granted
- Google ML Kit downloaded
- Device has camera
- Good lighting conditions

### **Performance Issues**

#### **Slow App Launch**

```bash
# Enable ahead-of-time compilation
flutter build apk --release --no-shrink

# Profile build
flutter run --profile
```

#### **Large APK Size**

```bash
# Build split APKs
flutter build apk --split-per-abi

# Check what's taking space
flutter build apk --analyze-size
```

---

## 📦 Continuous Integration

### **GitHub Actions Example**

Create `.github/workflows/build.yml`:

```yaml
name: Build and Test

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2

    - uses: actions/setup-java@v2
      with:
        distribution: 'zulu'
        java-version: '11'

    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.8.0'

    - run: flutter pub get
    - run: flutter test
    - run: flutter build apk --release
```

---

## 📚 Additional Resources

### **Official Documentation**
- [Flutter Deployment](https://docs.flutter.dev/deployment)
- [Android Publishing](https://developer.android.com/studio/publish)
- [iOS Publishing](https://developer.apple.com/app-store/submitting/)

### **Helpful Tools**
- [App Icon Generator](https://appicon.co/)
- [Screenshot Maker](https://mockuphone.com/)
- [Privacy Policy Generator](https://www.privacypolicygenerator.info/)

---

## ✅ Pre-Launch Checklist

### **Code**
- [ ] All features tested
- [ ] No console errors
- [ ] Performance optimized
- [ ] Security review complete

### **Assets**
- [ ] App icon (all sizes)
- [ ] Splash screen
- [ ] Screenshots (all devices)
- [ ] Feature graphic
- [ ] Promotional images

### **Documentation**
- [ ] Release notes
- [ ] Privacy policy
- [ ] Terms of service
- [ ] User guide

### **Store Listing**
- [ ] App name
- [ ] Description
- [ ] Keywords/tags
- [ ] Category
- [ ] Contact info
- [ ] Support URL

### **Backend**
- [ ] Production server setup
- [ ] Database configured
- [ ] SSL certificate
- [ ] Backups enabled
- [ ] Monitoring setup

---

**Build Version:** 1.0.0 (Build 1)
**Last Updated:** January 10, 2026

For questions or issues, contact: dev@smartfinance.app

# TODO App - React Native Mobile

React Native mobile app for the TODO application, connecting to the same Azure-hosted API as the web frontends.

## Prerequisites

- Node.js 18+
- Expo CLI (`npm install -g expo-cli`)
- For Android: Android Studio with Android SDK
- For iOS: macOS with Xcode

## Quick Start

### 1. Install Dependencies

```bash
cd mobile/TodoApp.Mobile
npm install
```

### 2. Run on Android

```bash
npm run android
```

This will:
- Build the app
- Start the Metro bundler
- Launch the app in Android emulator (if running) or connected device

### 3. Run on iOS (macOS only)

```bash
npm run ios
```

### 4. Run on Web (for testing)

```bash
npm run web
```

## Development

The app uses Expo for simplified React Native development. Key features:

- **Live Reload**: Edit `App.js` and see changes immediately
- **API Integration**: Connects to deployed Azure API
- **Cross-Platform**: Runs on Android, iOS, and Web with same codebase

## API Configuration

The app connects to the deployed Azure API:

```javascript
const API_BASE_URL = 'https://todoapp-api.politeriver-ded1b871.centralus.azurecontainerapps.io/api/todos';
```

To change the API endpoint, edit `App.js` and update the `API_BASE_URL` constant.

## Building for Production

### Android APK

```bash
# Development build
npx expo build:android

# Production build
npx expo build:android --type app-bundle
```

### iOS IPA (requires Apple Developer account)

```bash
npx expo build:ios
```

## Project Structure

```
TodoApp.Mobile/
├── App.js              # Main app component with Todo logic
├── app.json            # Expo configuration
├── package.json        # Dependencies
└── assets/             # Images and other assets
```

## Features

- ✅ View all todos
- ✅ Add new todos with title and description
- ✅ Toggle todo completion status
- ✅ Delete todos
- ✅ Filter by All/Active/Completed
- ✅ Real-time sync with Azure API
- ✅ Error handling and user feedback

## Technology Stack

- **React Native**: Cross-platform mobile framework
- **Expo**: Toolchain for React Native development
- **Azure Container Apps**: API hosting
- **Azure SQL Serverless**: Database

## Troubleshooting

### Android Emulator Not Starting

1. Open Android Studio
2. Go to AVD Manager
3. Start an emulator
4. Run `npm run android` again

### Network Errors

The app connects to the live Azure API. If you see network errors:
- Check internet connection
- Verify the API URL is correct
- Check if the API is running (visit the URL in browser)

### Metro Bundler Issues

```bash
# Clear cache and restart
npx expo start -c
```

## Deployment

This is a development-focused example. For production deployment:

1. **Android**: Build APK/AAB and publish to Google Play Store
2. **iOS**: Build IPA and publish to Apple App Store
3. **Both**: Use Expo EAS Build for managed builds

See [Expo documentation](https://docs.expo.dev/) for detailed deployment guides.

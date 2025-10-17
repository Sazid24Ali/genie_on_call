# Configuration Setup

This document explains how to set up the configuration for the Genie On Call app.

## Overview

The app uses a centralized configuration file (`lib/config.dart`) to manage all API keys and sensitive data. This makes it easy for others to plug in their own keys without modifying the core code.

## Steps to Configure

1. **Copy the configuration template:**

   - Copy `lib/config_sample.dart` to `lib/config.dart`
   - The sample file contains placeholder values that need to be replaced with actual keys.

2. **Replace with your own keys:**

   - If you're setting up your own Firebase project, replace the placeholder values in `lib/config.dart` with your Firebase project credentials.
   - You can obtain these from your Firebase Console.

3. **Firebase Configuration Files:**

   - `android/app/google-services.json`: Download from Firebase Console and place in this location.
   - `ios/Runner/GoogleService-Info.plist`: Download from Firebase Console and place in this location.

4. **Important Notes:**
   - The `lib/config.dart` file is now gitignored to prevent accidental commits of sensitive data.
   - The `lib/config_sample.dart` file is kept in version control as a reference template.
   - Make sure to add your actual configuration files to version control if needed, but never commit real API keys.
   - For production deployments, consider using environment variables or secure key management systems.

## Firebase Setup

1. Create a Firebase project at https://console.firebase.google.com/
2. Enable Authentication, Firestore, Storage, and Cloud Functions as needed.
3. Add Android and iOS apps to your Firebase project.
4. Download the configuration files and place them in the appropriate directories.
5. Update `lib/config.dart` with your project's API keys and IDs.

## Running the App

After configuration:

1. Run `flutter pub get` to install dependencies.
2. Run `flutter run` to start the app.

If you encounter any Firebase-related errors, double-check that your configuration values match your Firebase project settings.

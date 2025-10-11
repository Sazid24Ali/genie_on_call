# Genie on Call - CX Executive Request Management and Chat System

## Overview

This project implements a comprehensive service booking and management system with real-time chat functionality. It includes a Flutter mobile app for users and agents, a React web app for CX executives, and Firebase backend with Firestore and Cloud Functions.

## Features

### User App (Flutter)

- User registration and login
- Service booking with image/recording uploads
- Real-time chat with CX and assigned agents
- Multilingual support (English, Hindi, Telugu)
- Booking history and tracking

### Agent App (Flutter)

- Agent registration and login
- View assigned bookings
- Real-time chat with users and CX
- Earnings tracking
- Service completion updates

### CX Executive Web App (React)

- CX login with ID/password authentication
- Dashboard to view pending bookings
- Assign agents to bookings
- Real-time chat with users and agents
- View agent bookings and performance

### Backend (Firebase)

- Firestore database for users, agents, bookings, chats
- Cloud Functions for notifications and business logic
- Firebase Authentication for users and agents
- Custom authentication for CX executives
- Real-time messaging with Firestore

## Architecture

### Collections

- `users`: User profiles
- `agents`: Agent profiles
- `bookings`: Service requests
- `chats`: Conversations (general/service-specific)
- `cx_logins`: CX executive credentials
- `cx_executives`: CX profiles
- `services`: Available services
- `available_slots`: Agent availability

### Key Components

- **Booking Flow**: User books service → CX assigns agent → Agent completes service
- **Chat System**: Real-time messaging between users, CX, agents
- **Notifications**: FCM push notifications for updates
- **Security**: Firestore rules for access control

## Setup Instructions

### Prerequisites

- Node.js and npm
- Flutter SDK
- Firebase CLI
- Android Studio (for Android builds)

### Installation

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd genie_on_call
   ```

2. **Setup Firebase**

   - Create a Firebase project
   - Enable Firestore, Authentication, Functions, Hosting
   - Configure FCM for notifications
   - Update `firebase.json` with your project ID

3. **Backend Setup**

   ```bash
   # Install function dependencies
   cd functions
   npm install

   # Deploy functions
   firebase deploy --only functions
   ```

4. **Web App Setup**

   ```bash
   cd cx-genie
   npm install

   # Start development server
   npm start

   # Build for production
   npm run build
   firebase deploy --only hosting
   ```

5. **Flutter App Setup**

   ```bash
   flutter pub get

   # Run on device/emulator
   flutter run

   # Build APK
   flutter build apk
   ```

### Configuration

- Update Firebase config in `cx-genie/src/firebase.js` and Flutter `lib/firebase_options.dart`
- Add CX login credentials to Firestore `cx_logins` collection
- Configure notification keys in functions

## Usage

### For Users

1. Register/Login in the app
2. Browse services and book with details/images/recordings
3. Chat with CX for support or with assigned agent

### For Agents

1. Register/Login as agent
2. View assigned bookings
3. Communicate via chat
4. Update booking status

### For CX Executives

1. Login to web app with CX ID/password
2. View pending bookings
3. Assign suitable agents
4. Monitor chats and resolve issues

## Technologies Used

- **Frontend**: Flutter (Dart), React (JavaScript)
- **Backend**: Firebase Firestore, Cloud Functions (Node.js)
- **Authentication**: Firebase Auth, Custom CX auth
- **Real-time**: Firestore listeners
- **Notifications**: Firebase Cloud Messaging
- **Storage**: Firebase Storage for files

## Development

### Project Structure

```
genie_on_call/
├── lib/                    # Flutter app source
├── android/                # Android configuration
├── ios/                    # iOS configuration
├── cx-genie/               # React web app
│   ├── src/
│   ├── public/
│   └── package.json
├── functions/              # Firebase functions
├── firestore.rules         # Firestore security rules
├── storage.rules           # Storage security rules
└── firebase.json           # Firebase configuration
```

### Key Files

- `lib/main.dart`: Flutter app entry point
- `cx-genie/src/App.js`: React app entry point
- `functions/index.js`: Cloud functions
- `firestore.rules`: Database security

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## License

This project is licensed under the MIT License.

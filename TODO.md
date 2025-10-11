# TODO List for CX Executive Request Management and Chat System

## Information Gathered

- **Flutter App Structure**: The app has separate screens for users (e.g., user_bookings_screen.dart, home_screen.dart implied) and agents (e.g., agent_home_screen.dart, agent_bookings_screen.dart). There's a floating_chat_button.dart that navigates to ChatScreen, suggesting an existing chat foundation. Firestore rules allow authenticated access to bookings, users, agents, services, and slots.
- **Web App (cx-genie)**: React-based with Firebase auth in App.js and Login.js. Simple login/signup with email/password. No current request management or chat features. CX login to use cx_id and password from Firestore collection.
- **Backend (Firestore & Functions)**: Collections for users, agents, bookings, services, available_slots. Functions/index.js handles booking notifications but no chat or booking assignment logic. Firestore rules need updates for new 'chats' collection.
- **Existing Features**: Booking system exists; chats seem per-booking. Need to extend for general/service-specific chats and CX assignment to bookings.
- **Dependencies**: Firebase for auth, Firestore, real-time updates. Flutter uses cloud_firestore, firebase_auth. React uses firebase.

## Plan

### 1. Firestore Schema Updates

- Use existing 'bookings' collection for user requests (extend with chatId if needed).
- Create new collections:
  - 'chats': For conversations (fields: chatId, participants (array of uids: user, cx, agent), messages (subcollection), type (general/service-specific), relatedBookingId, timestamp).
  - 'cx_logins': For CX logins (fields: cx_id, password).
- Update firestore.rules to allow:
  - Users: Create/read own bookings and chats.
  - CX: Read all bookings/chats, update agent assignments.
  - Agents: Read assigned bookings/chats.

### 2. Flutter App Updates (User Side)

- Use existing booking flow (slot_selection_screen.dart -> booking_confirmation_screen.dart) which creates bookings with status 'pending'.
- Update lib/screens/chat_screen.dart (create if not exists):
  - Support general chats (no related booking) and service-specific (linked to booking).
  - Real-time message stream using Firestore.
  - List all user chats (per booking/general).
- lib/services/chat_service.dart (new):
  - Handle sending/receiving messages, real-time listeners.
- Update pubspec.yaml: Ensure cloud_firestore, firebase_auth are included.

### 3. Web App Updates (CX Executive Side)

- cx-genie/src/Login.js:
  - Change to login with cx_id and password, query Firestore 'cx_logins' collection for validation.
- cx-genie/src/App.js:
  - After login, if role='cx', show Dashboard with tabs: Pending Bookings, Active Chats, Agent Bookings.
- Create cx-genie/src/Dashboard.js:
  - List pending bookings from Firestore (real-time, status='pending').
  - View booking details, user info.
  - Assign to agent (update booking with assignedAgentId, notify via function).
  - View agent details/bookings (query agents and their bookings).
- Create cx-genie/src/ChatInterface.js:
  - Real-time chat for selected booking/chatId.
  - List all active chats.
- cx-genie/src/firebase.js:
  - Add Firestore queries for bookings, chats, agents.
- Update package.json: Add reactfire or firebase for real-time.

### 4. Backend Functions Updates

- functions/index.js:
  - Add onBookingCreated: Notify CX executives (FCM if tokens stored).
  - Add onAssignment: Notify user and assigned agent.
  - Add chat message triggers for notifications if needed.

### 5. General

- Ensure real-time: Use StreamBuilder in Flutter, onSnapshot in React.
- UI: Simple forms, lists; support multilingual if needed (existing l10n).
- Security: CX login validates against Firestore collection.

## Dependent Files to be Edited

- Firestore: firestore.rules (security), new collections via code.
- Flutter: main.dart (imports), role_selection_screen.dart (add CX role? but CX is web).
- Web: All cx-genie/src/\* files for dashboard/chat.
- Functions: index.js for notifications.
- No new dependencies beyond Firebase.

## Followup Steps

- [x] Implement Firestore schema and rules.
- [x] Build user booking submission in Flutter.
- [x] Develop CX dashboard in web app.
- [x] Integrate chats (general/service-specific).
- [x] Add assignment logic and notifications.
- [ ] Test: Submit booking from app, assign from web, chat real-time, view agent bookings.
- [ ] Deploy: Update Firebase hosting for web, rebuild Flutter APK.

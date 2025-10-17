# TODO: Add Image Upload to CX Chat and Improve UI

## Steps to Complete


- [x] Modify ChatScreen to show formatted timestamp (HH:MM AM/PM) below each message bubble
- [x] Use existing 'timestamp' field from Firestore messages
- [x] Format timestamps consistently across all message types (text, media)

## 2. Message Status Indicators

- [x] Add status fields (sent, delivered, read) to message documents in Firestore
- [x] Update ChatService sendMessage method to include status tracking
- [x] Implement delivery/read tracking logic using Firestore listeners
- [x] Modify ChatScreen to display status icons next to sent messages
- [x] Add status icons (sent: ✓, delivered: ✓✓, read: ✓✓ blue)

## 3. Message Search

- [x] Add search TextField in ChatScreen app bar with search icon
- [x] Implement local search filtering on message text content
- [x] Add search state management (show/hide search bar)
- [x] Highlight search results in message bubbles
- [x] Clear search functionality

## 4. Push Notifications for Messages

- [x] Update functions/index.js to send push notifications on new chat messages
- [x] Ensure FCM tokens are properly stored in user documents
- [x] Handle notification taps to open specific chat screens
- [x] Update main.dart to handle notification navigation
- [x] Test notifications for both user and CX roles

## 5. Offline Support

- [ ] Add sqflite dependency to pubspec.yaml for local database
- [ ] Create local message cache schema
- [ ] Implement message caching when offline
- [ ] Add sync mechanism when coming back online
- [ ] Update ChatService to handle offline/online states
- [ ] Show offline indicator in UI

## 6. Message Encryption

- [ ] Add encrypt package dependency to pubspec.yaml
- [ ] Implement encryption key management (shared keys per chat)
- [ ] Encrypt messages before sending to Firestore
- [ ] Decrypt messages when displaying in ChatScreen
- [ ] Update ChatService methods for encryption/decryption
- [ ] Ensure media URLs are handled securely

## 7. Technical Improvements

- [ ] Implement pagination for message loading (load messages in batches)
- [ ] Add image/video compression before upload to reduce storage
- [ ] Add basic analytics tracking (message counts, user engagement)
- [ ] Optimize message list rendering for performance
- [ ] Add error handling and retry mechanisms for failed sends
- [ ] Implement message deletion/editing capabilities

## Dependencies to Update

- [ ] Update pubspec.yaml with new packages (sqflite, encrypt, image compression packages)
- [ ] Test all new dependencies for compatibility

## Testing

- [ ] Test each feature individually
- [ ] Ensure backward compatibility with existing chats
- [ ] Test on different devices and network conditions
- [ ] Performance testing with large message histories

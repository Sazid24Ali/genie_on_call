# TODO: Update User Chat Screen in Android App

## Tasks

- [x] Add `image_picker` dependency to `pubspec.yaml` if not present (already present)
- [x] Update `ChatsListScreen` to include a `TabBar` with "General" and "Bookings" tabs
  - [x] Implement filtering for General tab (chats where `bookingId` is null)
  - [x] Implement filtering for Bookings tab (chats where `bookingId` is not null)
- [x] Modify `ChatScreen` to disable input for closed chats
  - [x] Disable TextField and send button when `_isClosed` is true
  - [x] Ensure clear message is displayed for closed chats
- [x] Add media attachment functionality to `ChatScreen`
  - [x] Add button to pick images/videos using `image_picker`
  - [x] Update `sendMessage` method to handle media uploads (using Firebase Storage)
- [x] Verify chat scrollability (already implemented, confirm it works)
- [x] Test tab switching and filtering
- [x] Test closed chat display and input disabling
- [x] Test media attachment and sending
- [x] Verify scrollability for new messages

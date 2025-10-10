# TODO: Fix Map Controller Issue in Slot Selection Screen

## Steps to Complete

- [x] Identify locations where `_mapController.move` is called directly in `lib/screens/user/slot_selection_screen.dart`.
- [x] Wrap each `_mapController.move` call with `WidgetsBinding.instance.addPostFrameCallback` to ensure the map is initialized before moving.
- [x] Locations to fix:
  - In `_fetchUserData` after setting `_selectedLocation` from Firestore.
  - In `_getCurrentLocation` after updating location.
- [x] Add a small delay (100ms) inside addPostFrameCallback to ensure the map is fully ready before moving.

## Progress Tracking

- Applied the same fix as booking_details_screen to slot_selection_screen since this is the main booking flow.
- Removed unused `_initializeLocation` method.
- Made map rendering conditional on data loading to prevent null reference errors.

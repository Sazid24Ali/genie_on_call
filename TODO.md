# TODO: Implement Agent-Side Changes and User Chat Feature

## Agent-Side Changes

- [ ] Update `lib/screens/agent/agent_home_screen.dart`:

  - [ ] Remove the "Accepted Jobs" stat card from the stats row (keep only earnings).
  - [ ] Remove distance range selector and related code (\_getAgentLocation, \_selectedRange, distance filtering in StreamBuilder).
  - [ ] Rename "Nearby Jobs" to "Scheduled Jobs" and update StreamBuilder to show bookings where agentId == currentUser.uid and status == 'Accepted'.
  - [ ] Add FloatingChatButton as floatingActionButton for agent-executive chat.

- [ ] Update `lib/screens/agent/agent_bookings_screen.dart`:
  - [ ] Rename tabs from 'Accepted'/'Finished' to 'Pending'/'Completed'.

## User-Side Chat Feature

- [ ] Create `lib/widgets/floating_chat_button.dart` as FloatingActionButton for initiating "Chat with Genie".
- [ ] Read `lib/screens/user/home_screen.dart` to understand structure.
- [ ] Add FloatingChatButton to user home screen.
- [ ] Update `lib/services/chat_service.dart` to support genie chats (create room "genie-support").
- [ ] Ensure `lib/screens/chat_screen.dart` handles genie chats.

## Followup

- [ ] Test agent home: Scheduled jobs display, no distance, floating button works.
- [ ] Test agent bookings: Tabs renamed and functional.
- [ ] Test user chat: Button initiates chat with executives.

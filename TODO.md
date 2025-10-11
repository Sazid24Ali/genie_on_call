# TODO List for Agent Workflow Update and User Chat Enhancements

## Agent Side Updates

- [ ] Update lib/screens/agent/agent_home_screen.dart: Remove \_acceptBooking method and nearby jobs section. Update \_fetchStats to query 'Scheduled' instead of 'Accepted', rename \_acceptedJobs to \_scheduledJobs. Add "Scheduled Jobs" section with StreamBuilder for scheduled bookings. Update stats card to "Scheduled Jobs". Add floating chat button for CX communication.
- [ ] Update lib/screens/agent/agent_bookings_screen.dart: Change tabs from 'Accepted'/'Finished' to 'Scheduled'/'Finished'. Update \_fetchBookingsStream to query 'Scheduled' for first tab. Adjust messages and logic.

## User Side Updates

- [ ] Read lib/screens/user/home_screen.dart to understand drawer structure.
- [ ] Update lib/screens/user/home_screen.dart: Add "Chat" ListTile to drawer, navigate to ChatScreen. Add floating chat button.
- [ ] Read lib/screens/chat_screen.dart to understand current per-booking chat.
- [ ] Update lib/screens/chat_screen.dart: Modify to list all chats (per-booking + CX chats). Add plus icon (FAB) to create new chat with CX. Handle CX chats (assume CX UID is 'cx' or fetched).

## General

- [ ] Introduce 'Scheduled' status in bookings (no code, but ensure queries use it).
- [ ] Test changes: Run app, verify scheduled jobs display for agents, chat works for users/agents.
- [ ] Update any dependent logic (e.g., earnings if needed).

# Feature: User Activity Dashboard

## Goal

Build a dashboard page that shows the user's activity summary and recent items at a glance.

## Requirements

- Display user stats: total items, current streak, last active date
- Show the 10 most recent items with title preview and timestamp
- Responsive layout: single column on mobile, two columns on desktop
- Dark mode support using existing theme tokens
- Loading skeleton while data is being fetched
- Error state with retry button

## Technical Notes

- API endpoint: `GET /api/dashboard` (create new)
- Reuse existing auth middleware for the API route
- Cache stats for 5 minutes (use existing cache layer if available)
- Use existing UI components where possible

## Out of Scope

- Real-time updates / WebSocket
- Data export functionality
- Admin view of other users' dashboards
- Analytics tracking (add later)

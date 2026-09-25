# Notifications (free, no Firebase)

This app delivers alerts without Firebase/FCM.

## How it works

1. Backend already writes rows to the shared notifications inbox
   (`POST`-driven from milk request create/accept, etc.).
2. Mobile polls `GET /notifications` every ~20s while authenticated and
   resumed, and again on app resume.
3. New unread items show as **OS local notifications** via
   `flutter_local_notifications` (free, no cloud push vendor).
4. Tapping a local notification opens the `route` from the payload
   (`/farm/requests`, `/customer/requests`, …).

## Limits (honest)

- Works while the app process can run (foreground / recently backgrounded).
- Does **not** wake a fully killed process like FCM/APNs would.
- When killed-app delivery becomes mandatory, add FCM/APNs as an upgrade —
  the inbox + routes stay the same.

## Web

Web uses the same inbox API with short polling + optional browser
`Notification` permission (also free).

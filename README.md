# DuoFlow for watchOS

**Two screens. One smarter you.**

The Apple Watch app is DuoFlow's glanceable companion for agenda, priorities, quick capture, and short actions.

## Product scope

- Watch home with date, weather, next appointment, and task progress
- Agenda and priority task views
- Quick reminder and voice-note capture
- Task completion and small updates sent to iPhone
- WidgetKit widgets and watch face complications
- Actionable, restrained notifications and an Always-On-friendly presentation
- Companion data exchange with [DuoFlow for iPhone](https://github.com/Skeeb32/DuoFlow-iPhone)

## Technical direction

- Native Swift and SwiftUI
- WatchConnectivity for nearby iPhone–Watch updates
- WidgetKit for Smart Stack widgets and supported complication families
- Keep common interactions brief and useful offline where possible
- Request permissions contextually; handle unavailable permissions and connectivity

## Development status

Repository foundation. Implementation and supported deployment targets are to be defined as development begins.

## Related repository

- [DuoFlow for iPhone](https://github.com/Skeeb32/DuoFlow-iPhone) — the primary dashboard and broader planning workspace.

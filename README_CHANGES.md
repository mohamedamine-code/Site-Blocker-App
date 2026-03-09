# Change Review README

This file tracks each code or configuration change with a short explanation.

## Update Rule

Review this file before each new edit.
After each change, add one new line to the log below.

## Change Log

| Date | Files | What Changed | Why |
| --- | --- | --- | --- |
| 2026-03-09 | README_CHANGES.md | Created change review file and log template. | Provide one place to review every change. |
| 2026-03-09 | README.md | Added "Change Review" section with a link to this file. | Make the tracking file easy to discover. |
| 2026-03-09 | pubspec.yaml | Added `http` dependency. | Enable fetching blocklist data from a backend API. |
| 2026-03-09 | lib/services/backend_blocklist_service.dart | Added backend blocklist service with JSON parsing and domain normalization. | Merge backend domains into VPN-enforced blocking rules. |
| 2026-03-09 | lib/services/vpn_service.dart | Updated `refreshBlocklist()` to merge local DB domains and backend domains before sending to Android VPN service. | Ensure both local and backend blocklists are enforced. |
| 2026-03-09 | lib/screens/home_screen.dart | Refresh blocklist immediately after starting VPN. | Apply latest rules as soon as VPN becomes active. |
| 2026-03-09 | README.md | Added backend configuration and supported API response formats. | Make backend integration setup clear and testable. |
| 2026-03-09 | README_CHANGES.md | Updated the process rule to require reviewing this file before each edit. | Enforce consistent change-tracking workflow. |
| 2026-03-09 | android/app/src/main/kotlin/com/example/site_blocker_app/VpnBlockerService.kt | Separated VPN interface/DNS IPs and refactored DNS processing with worker threads plus SERVFAIL fallback. | Prevent global connectivity drops and make DNS blocking flow more reliable under load. |
| 2026-03-09 | android/app/src/main/kotlin/com/example/site_blocker_app/MainActivity.kt | Added `getPrivateDnsMode` method-channel endpoint. | Let Flutter warn users when Private DNS may bypass blocking. |
| 2026-03-09 | lib/services/vpn_service.dart | Added `getPrivateDnsMode()` bridge method. | Expose Android Private DNS diagnostics to UI logic. |
| 2026-03-09 | lib/screens/home_screen.dart | Added warning dialog when Private DNS is enabled. | Explain why blocked domains may still open in some apps/browsers. |

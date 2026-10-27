# Premium Today and Plan

Today shows a compact progress ring and actual stopwatch time across all commitments, including recorded work on incomplete and excused items. The visible list retains the previous three-item expansion behavior and keeps the running commitment visible. A permanent Freedom card presents the existing eligibility result directly after the commitments. The waiting appearance is selected only when Freedom Control is enabled, the dated plans are current, commitments and tomorrow are satisfied, and Freedom Time is the only remaining condition. Disabled and earned states use the same existing service result; no Instagram-access claim is inferred.

Plan retains the existing schedule, routine actions, draft editing and committed-plan locks. Its compact cards, routine header and empty-state illustration use the active palette and the shared Journey surface. Stopwatch, Freedom, history and persistence implementations are unchanged.

The following captures use sample data in a Flutter widget-test viewport with desktop font metrics; they are not device or emulator captures:

- [Today preview](images/today-premium-preview.png)
- [Plan preview](images/plan-premium-preview.png)

The design follows the reference's ring, compact cards, tinted surfaces and featured Freedom panel. It uses native Flutter icons for the lock illustration rather than the reference's bespoke artwork and retains the existing checkbox and accessible stopwatch actions. The reference's separate timer page and timer controls on tomorrow's tasks are intentionally absent because the approved scope keeps timing in Today and tomorrow's plan is planning only.

Physical checks: install over the existing app and verify saved commitments, Areas, routines and history; test active, paused and completed timers, including background and process restoration; check Freedom locked, waiting, earned and disabled states and Instagram behavior; verify three cards and Freedom on the target phone, smaller screens, large text, light/dark palettes, the keyboard, routine actions and the committed-plan lock. Do not publish a public release before those checks.

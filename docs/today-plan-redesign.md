# Today and Plan redesign

Today and Plan use the existing Journey surface and active palette. Today displays at most three commitments until expanded; if a stopwatch is running outside the first three, that commitment replaces the third visible item. Expand and collapse only changes the view, leaving the underlying order, completion and stopwatch state untouched. The header's Freedom icon opens the existing eligibility conditions, and the dialog refreshes while open.

Tomorrow's draft allows editing and removing commitments via their action menu. Edits preserve commitment IDs, existing stopwatch data and legacy metadata; an unchanged Area assignment remains intact, including an archived Area. Both actions are unavailable after committing and are checked again when submitted. Routine decisions and progress are not rewritten when a draft commitment is edited or removed.

The captures below use sample data and a Flutter widget-test viewport, not a physical device:

- [Today preview](images/today-redesign-preview.png)
- [Plan preview](images/plan-redesign-preview.png)

Physical-device checks: verify safe-area and system-navigation spacing on small and large phones, large accessibility text, a running timer outside the first three, expansion while timing, the live Freedom dialog, editing and deleting a draft, routine suggestions, keyboard insets and committed-plan locking. Confirm stopwatch recovery, Freedom and Instagram behavior on the existing installation before a public release.

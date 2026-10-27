# Journey spacing refinement

The complete overview now fits above the bottom navigation in the tested phone viewports, including Daily history and Past Chapters. This is a spacing-only refinement of the existing visual design.

[Updated preview](images/journey-spacing-dark.png)

## Changes

- `journey_area_grid.dart`: the homepage opts into a 100-pixel minimum tile height instead of width-derived near-square sizing. Content can still make tiles taller. Vertical tile padding drops from 12 to 6 pixels, and internal gaps tighten. Past Chapters retains its existing tile sizing.
- `journey_screen.dart`: section gaps become 4 pixels and the bottom padding drops to 4 pixels.
- `journey_dashboard_cards.dart`: reduces vertical summary/history-card padding. History cards stay side by side at 328 pixels of available content width; narrower screens and larger text still stack them.
- `journey_spacing_test.dart`: adds complete-overview visibility and scrolling regression checks using Flutter's bundled Roboto font, system insets and bottom navigation.
- `journey_redesign_test.dart`: permits the intentionally shorter Area tile proportions while retaining two-column and navigation assertions.

Colours, gradients, typography, charts, illustrations and carousel controls remain unchanged. Interactive controls retain accessible touch targets. There are no changes to models, persistence, business logic or native Android code.

## Validation

Executed on 2026-10-27:

- `flutter analyze`: passed, no issues.
- Relevant Journey layout, navigation, illustration and persistence suites: **59 tests passed** across `journey_spacing_test.dart`, `journey_redesign_test.dart`, `journey_widget_test.dart` and `journey_visual_test.dart`.
- Complete-overview tests verify both history cards are fully visible and vertical scroll extent is zero at 360 x 800 with one Highlight, 390 x 844 with one or three Highlights, and 412 x 892 with three Highlights. The fixture has four Areas, a description and a recorded Focus total of 9 hr 27 min.
- Scrolling remains available at 320 x 568, with additional Areas and larger accessibility text. Existing checks cover all six palettes, light/dark appearance, and text scales up to 300%.
- The widget-render preview passed and was visually inspected. It uses fixture data and desktop fonts, not a physical Android device.
- Android release build passed: `flutter build apk --release --build-name=0.1.0-alpha.8 --build-number=8`. APK signing verification passed with the existing certificate and application ID `com.example.daylock`. APK SHA-256: `bcd0e55d8585021618d2e2fdc6103bbe4f46773ad47163752a5e31cf33ef137d`.
- `git diff --check` passed. Logs are in `build/journey-spacing-tests.log`, `build/journey-spacing-preview.log` and `build/journey-spacing-release-build.log`.

Your exact device has not been verified: no Android device was connected. The APK remains a draft test build for confirming the fit with your real content and display settings. Extra-long content, smaller available height, larger text and additional Areas can still require scrolling by design. No new public release is published before phone testing.

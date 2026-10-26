# Daylock app icon

`daylock-icon.png` is the official borderless sunrise/lock master, adapted from
the user's supplied Luminous Sunrise Lock Icon artwork on 26 October 2026.
The exterior white margin and rounded tile frame were removed at the user's
request; the dark background fills the square so each platform can mask it.

Regenerate launcher and web icons from the repository root:

```powershell
flutter pub get
dart run tool/generate_app_icons.dart
```

The pinned development tool and `flutter_launcher_icons.yaml` generate Android
legacy/adaptive icons, iOS/macOS icon catalogs, Windows ICO and web/PWA icons.
Android foreground padding keeps the lock and rays inside common launcher masks.
The wrapper preserves the existing iOS project settings because the generator's
0.14.4 project-file matcher can overwrite unrelated ASSETCATALOG boolean values.
The native notification small icon remains the separate monochrome lock required
for readable Android status-bar notifications.

Generated assets must be rebuilt into a new APK or web deployment before installed
apps or the live website show them. Existing browser/launcher icon caches may
also need a refresh. Icon generation does not change application IDs, signing,
preferences, plans or calendar data.

Tool: [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons).

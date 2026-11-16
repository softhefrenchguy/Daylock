# Home screen widget

The widget is the Daylock sky. The sun rises with today's progress, and today's commitments sit on the ground below the hills. Its colours follow the colour theme and light/dark mode chosen in Daylock (Settings → Appearance).

## Sizes

Chosen from the size you give the widget on the home screen:

- **Large** (4×3 and up): Today, the date, "2 of 4 kept", then as many commitments as fit (open ones first, each with its Area), "+N more in Daylock", and a Freedom chip.
- **Medium** (4×2): the sky with the count on the left, the next two open commitments on the right.
- **Small** (2×2): the sky, "2/4" and when apps unlock.

## States

- **In progress:** "N more and the sun is up". The chip shows when apps unlock.
- **Freedom earned** (all kept, tomorrow locked in, Freedom Time reached): the brighter earned sky and "Freedom earned." The large size still lists the ticked commitments.
- **Nothing planned:** "A clear day." and a **Plan tomorrow** button that opens Plan.

## Taps

- Tapping an open commitment keeps it in Daylock, with Undo. The tap carries the date, index and name, so a stale tap changes nothing.
- Tapping anything else opens Today.

## How it stays current

The widget reads the plan copy that notifications already keep, which now includes each commitment's Area name and colour. It redraws whenever that copy changes, when the theme changes, at midnight and every 30 minutes.

## Reviewing changes

Debug builds include `WidgetPreviewActivity`, which renders every size for sample plans:

```
adb shell am start -n com.sofien.daylock.debug/com.sofien.daylock.WidgetPreviewActivity --es theme ocean --ez dark true --es state progress
```

`theme`: violet, ocean, forest, ember, rose, mono. `state`: progress, earned, empty.

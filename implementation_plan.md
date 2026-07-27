# NavRail spacing refactor

## Root cause
NavRail stays flush to the card edge (that's correct, unchanged). The clutter
is internal: `navRailPadding: 10` and `navRailItemSpacing: 2` in
[SettingsConfig.qml:40,42](src/modules/settings/SettingsConfig.qml#L40-L42)
pack the avatar row, FAB, and nav items too tight inside the rail.

## Changes

**[MODIFY] `src/modules/settings/SettingsConfig.qml`**
- `navRailPadding`: 10 → 14 (more internal breathing room from rail edges).
- `navRailItemSpacing`: 2 → 4 (less cramped item list).
- `navRailContentSpacing`: 10 → 12 (more room between avatar row / divider / FAB / list).

No other files in scope are touched.

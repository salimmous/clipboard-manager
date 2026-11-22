# ClipboardManager v1.4.1

## 🐛 Bug Fixes
- **Smooth Scrolling Fixed:** Eliminated the scroll bounce/jump-back bug caused by `.onHover` triggering `ScrollViewReader.scrollTo(..., anchor: .center)` while scrolling past rows. Auto-scrolling now triggers strictly on `↑`/`↓` keyboard navigation.
- **Smoother Scroll Performance:** Isolated row hover highlight per row, cached `RelativeDateTimeFormatter`, stabilized row heights, and scoped window dragging strictly to the header bar.

## 🔄 Updating from v1.4.0
Click **Check for Updates…** in the menu bar (or Settings → Updates) to auto-update directly, or download `ClipboardManager-1.4.1-Installer.dmg` below.

# Eagle Scooty Dashboard

Eagle Scooty light and dark theme dashboard written in Qt 6/QML from Figma designs.

## Requirements

- Qt 6.5 or newer with Qt Quick, Qt Quick Controls, and Qt Quick Effects
- A C++17 compiler

Qt Location and Qt Positioning are not required. The navigation, trip-details,
and charging pages remain available, but their live map areas intentionally show
an unavailable state.

## UI architecture

- `StyleTheme.qml` is the public design-system facade used by screens.
- `Theme/ColorPalette.qml` defines semantic light and dark color roles.
- `Theme/Typography.qml` owns the bundled Helvetica Neue font families and type scale.
- `Theme/Metrics.qml` and `Theme/Motion.qml` centralize spacing, radii, touch sizes,
  and animation timing.
- `ThemeController` persists Auto/Light/Dark appearance and brightness with `QSettings`.
- `SystemClock` provides a live, low-frequency date/time source for the header.
- `DashboardData` owns bounded vehicle, battery, trip, environment, and navigation
  values so screens no longer embed operational data as string literals.

New UI code should use semantic roles such as `Style.surface`, `Style.textPrimary`,
`Style.textMuted`, and `Style.accent` instead of system-palette values or literal colors.

## Build

```sh
mkdir build && cd build
qmake ../EagleTheme.pro
make -j4
```

![Home](https://github.com/cppqtdev/Eagle-Scooty-Dashboard-/blob/main/screenshots/Home.png)
![Home-2](https://github.com/cppqtdev/Eagle-Scooty-Dashboard-/blob/main/screenshots/home2.png)
![Home-dark](https://github.com/cppqtdev/Eagle-Scooty-Dashboard-/blob/main/screenshots/home-dark.png)
![profile](https://github.com/cppqtdev/Eagle-Scooty-Dashboard-/blob/main/screenshots/profile.png)
![profile dark](https://github.com/cppqtdev/Eagle-Scooty-Dashboard-/blob/main/screenshots/profile-dark.png)
![about](https://github.com/cppqtdev/Eagle-Scooty-Dashboard-/blob/main/screenshots/about.png)
![about-dark](https://github.com/cppqtdev/Eagle-Scooty-Dashboard-/blob/main/screenshots/about-dark.png)
![Bluetooth](https://github.com/cppqtdev/Eagle-Scooty-Dashboard-/blob/main/screenshots/bluetooth.png)
![Bluetooth-dark](https://github.com/cppqtdev/Eagle-Scooty-Dashboard-/blob/main/screenshots/bluetooth-dark.png)
![Music](https://github.com/cppqtdev/Eagle-Scooty-Dashboard-/blob/main/screenshots/music.png)
![Music Dark](https://github.com/cppqtdev/Eagle-Scooty-Dashboard-/blob/main/screenshots/music-dark.png)
![Sound](https://github.com/cppqtdev/Eagle-Scooty-Dashboard-/blob/main/screenshots/sound.png)
![Notification](https://github.com/cppqtdev/Eagle-Scooty-Dashboard-/blob/main/screenshots/notification.png)
![trip](https://github.com/cppqtdev/Eagle-Scooty-Dashboard-/blob/main/screenshots/trip.png)
![trip details](https://github.com/cppqtdev/Eagle-Scooty-Dashboard-/blob/main/screenshots/tripDetails.png)
![tripdetailsmap](https://github.com/cppqtdev/Eagle-Scooty-Dashboard-/blob/main/screenshots/tripdetailsmap.png)
![update](https://github.com/cppqtdev/Eagle-Scooty-Dashboard-/blob/main/screenshots/update.png)
![Calling](https://github.com/cppqtdev/Eagle-Scooty-Dashboard-/blob/main/screenshots/calling.png)
![Keypad](https://github.com/cppqtdev/Eagle-Scooty-Dashboard-/blob/main/screenshots/keypad.png)
![Calling Dark](https://github.com/cppqtdev/Eagle-Scooty-Dashboard-/blob/main/screenshots/clling-dark.png)
![Charging](https://github.com/cppqtdev/Eagle-Scooty-Dashboard-/blob/main/screenshots/charing.png)

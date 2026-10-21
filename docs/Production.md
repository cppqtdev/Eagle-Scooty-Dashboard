# Production checklist

Where the dashboard stands for fitting to a scooter. **Done** means built and
tested on the desk (unit tests, the `--snapshot` walk through every screen);
**board** means it needs the RK3328 and a harness to prove.

## Rider safety and legibility

| Item | State |
|---|---|
| Telltales in ISO 2575 colours, indicators at 85 flashes a minute on one shared clock | Done |
| Key-on lamp check: every telltale lit for two seconds | Done |
| Critical alerts (motor fault, side stand while moving) take the screen and need OK | Done |
| Screens that need more than a glance (settings, documents, dialling) lock above 5 km/h | Done |
| Figures refresh 2–4 times a second; fast digits in fixed cells so nothing jitters | Done |
| Text contrast at least 4.5:1 in both themes; night theme with the lights or after dark | Done |
| Every text elides or wraps; nothing overflows its box | Done |
| Brightness on the real backlight (`/sys/class/backlight`) | Board |

## Inputs

| Item | State |
|---|---|
| Handlebar keys and encoder drive every screen without touch (docs/Inputs.md) | Done; board for the device tree |
| CAN: motion, battery, temperatures, lamps, tyres, faults, trip, buttons (docs/CAN.md) | Done (`vcan` and tests) |
| Connector lines over GPIO and ADC: lamps, switches, speed sensor, pack voltage, NTC | Done in code and tests; board for the pins and level shifting |

## Phone

| Item | State |
|---|---|
| Ride app over BLE: calls, music with covers, navigation, messages, favourites | Done over TCP with the app's simulator; board for BLE |
| Bike status and settings to and from the app (protocol 1.2) | Done in the cluster; the app needs its settings screen |
| Everything personal cleared when the phone goes | Done |

## Software

| Item | State |
|---|---|
| Builds on Qt 6.2 (the Yocto image) and 6.8 (desk); C++20 | Desk on 6.8; board build to confirm |
| Restarts on any exit (`Restart=always`); waits for the compositor | Done |
| Settings kept across power cycles (theme, brightness, arrow, language) | Done |
| English and Hindi, switched live; more languages are a .ts file each | Done; the image needs a Devanagari font (`fonts-noto` / Noto Sans Devanagari) |
| Unit tests: core (vehicle, CAN, alerts, phone, documents, harness) and the phone link | Done |
| Signed updates, crash reports, watchdog (`WatchdogSec` with `sd_notify`) | To do |
| Calls' audio (HFP) and media control (AVRCP) through BlueZ on the board | To do: the app carries state and controls today |

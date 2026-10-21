# Features: what Eagle does, what the Ride app does, what is left

Compared with what connected scooters ship today (the clusters and apps of
Ather, Ola, TVS iQube and Bajaj Chetak). **Cluster** is this repository,
**App** is the Ride companion app (apex-ev `mobile/`), **Board** means it needs
the RK3328 and the bike's wiring to prove.

Legend: ✅ done · 🟡 partly · ⬜ not yet

## Riding

| Feature | Cluster | App | Notes |
|---|---|---|---|
| Speed, gear, ride modes (Eco / City / Sport), power and regen | ✅ | — | CAN, connector wires or simulator |
| Battery %, range, charge state, time to full, charge limit | ✅ | ✅ shows them | |
| Trip A, odometer | ✅ | ✅ | |
| Trip B, average and top speed, Wh/km, service due in km | 🟡 | ✅ shows them | sent in VehicleStatus; trip B and a real Wh/km need the VCU |
| Telltales (ISO 2575 colours), bulb check at key-on, hazards, reverse | ✅ | — | |
| ABS and malfunction (MIL) lamps, alerts and a fault log | ✅ | ✅ fault guide | codes with counts and first/last seen, cleared from the app |
| Tyre pressure (TPMS) with low-pressure warning | 🟡 | ✅ shows them | pressures from CAN; BLE TPMS sensors not read |
| Side-stand cut-off warning, ride lock above 5 km/h | ✅ | — | |
| Range-aware charging stations | 🟡 | ✅ charging finder | the cluster lists stations from demo data |
| Units (km / miles), 12 / 24-hour clock | 🟡 | ✅ sends the choice | 24-hour clock done; miles not yet |
| Cruise control, hill hold, regen levels | ⬜ | ⬜ | need the motor controller's messages |
| Speed limit on the navigation screen | ⬜ | ✅ sends it (NavUpdate 1.2) | |

## Phone and connectivity

| Feature | Cluster | App | Notes |
|---|---|---|---|
| BLE link to the app, heartbeat, everything personal cleared on loss | ✅ | ✅ | tested over TCP; BLE on the board |
| Pairing with a code on the cluster, forget all phones | ⬜ | ✅ | BlueZ agent on the board |
| Calls: caller, answer, decline, call a favourite, missed calls | ✅ | ✅ | call audio (HFP) to the helmet is separate |
| Music: track, artist, cover, play, pause, skip, volume | ✅ | ✅ (Android) | iPhone apps cannot read other apps' players |
| Messages and app notifications, quiet while riding | ✅ | ✅ | |
| Auto-reply while riding | — | ✅ | the app answers; the cluster shows the message |
| Turn-by-turn from the app and from Google Maps | ✅ | ✅ (Android mirror) | |
| Wi-Fi: join from the app, scan, status, forget | ✅ | ✅ | nmcli on the board; simulated on the desk |
| Bluetooth settings, paired devices, headsets | 🟡 | — | real radio on the board |
| Find my bike, where I parked | — | ✅ | |
| Crash detection with an emergency countdown | ⬜ | ✅ | the cluster should show the countdown |
| Ride journal, trip history | 🟡 | ✅ | the cluster keeps the current trips only |
| Document wallet (licence, RC, insurance, PUC) with expiry | ✅ | ✅ | |

## Software and updates

| Feature | Cluster | App | Notes |
|---|---|---|---|
| Settings from the app (display mode, brightness, clock, page, keys, trip reset) | ✅ | ✅ ClusterCommand | refused while moving; Eagle's extra settings proposed as 1.3 |
| Firmware update over Wi-Fi from the app | ⬜ | ✅ for the other cluster | the cluster needs the HTTP receiver and an installer (RAUC / SWUpdate); the app needs to accept a Linux image |
| Update checker (is there a newer version?) | 🟡 | ✅ release notes | the cluster's page is a placeholder |
| Signed updates, rollback if a new version fails | ⬜ | — | A/B slots on the board |
| Crash reports, watchdog | ⬜ | ✅ crash log (app) | |
| Languages (English, Hindi; live switch) | ✅ | ⬜ | |
| Handlebar keys and encoder, no touch needed | ✅ | ✅ PressKey | |
| Rider profiles | ⬜ | ⬜ | |
| Anti-theft: immobilise, motion alert, geofence | ⬜ | ⬜ | needs the VCU and a SIM or the phone |

## What to build next, in order

1. ~~Speak the app's protocol 1.2~~ — done: cluster commands and settings, vehicle details,
   Wi-Fi join, scan and status, the fault log.
2. **Firmware over Wi-Fi for Linux**: an HTTP receiver behind the app's token, an A/B installer,
   and in the app an image check that accepts the Linux package.
3. **On the board**: BLE pairing with a code, real Bluetooth and Wi-Fi, the harness pins, the
   encoder, the backlight.
4. **App additions for Eagle**: ride mode, charge limit, volume, arrow style and language as
   new ClusterCommand codes; a crash countdown on the cluster.
5. Units and the 24-hour clock, trip B and service interval, TPMS over BLE, rider profiles.

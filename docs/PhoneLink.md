# Phone link

The rider's phone talks to the dashboard through the Ride companion app, the same
Flutter app that serves the Apex clusters; the protocol below is shared byte for byte, so
one app works with every cluster. The dashboard side lives in `phonelink/` (codec,
link, BLE and TCP transports) and `phonelinkbridge.cpp`, which feeds the app's
turn-by-turn into the navigation screens and sends the bike's battery, range, odometer,
ride mode, gear and fault count back to the app.

```bash
EagleTheme --phone ble    # the board's default: advertise as "Eagle" and wait for the app
EagleTheme --phone tcp    # the desk: the app or scripts/phone_link_sim.py on port 47100
EagleTheme --phone demo   # the desk's default: a built-in phone, no app needed
```

While the app guides, the map page shows its route live (turn, distance, road, what is
left and the arrival time), and the demo's destinations give way to it. The link carries
manoeuvres, not map images: BLE has room for a few kilobytes a second, which suits
turn-by-turn and album covers but not live map tiles.

## Transport

The cluster is a BLE peripheral and runs a GATT server. The phone is the central.

| Item | UUID | Properties | Direction |
|---|---|---|---|
| Service | `6f7e0001-7a3c-4f1b-9e2d-45b1c0de0001` | | |
| RX | `6f7e0002-7a3c-4f1b-9e2d-45b1c0de0001` | Write, Write Without Response | phone → cluster |
| TX | `6f7e0003-7a3c-4f1b-9e2d-45b1c0de0001` | Notify, Read | cluster → phone |

- The cluster advertises the service UUID, so the app scans with a service filter.
- The app requests MTU 185 (Android; iOS negotiates by itself). A frame is at most 167 bytes,
  so one write carries a whole frame. The parser still reassembles split frames, because a
  phone that kept MTU 23 writes in 20-byte pieces.
- The other way the cluster splits a frame into notifications of MTU − 3 bytes, so the app's
  parser reassembles too: at MTU 23 a ClusterInfo arrives in two notifications.
- LE Secure Connections bonding. The phone's own pairing dialog handles it.
- The bench build of this cluster also listens on TCP port 47100 with the same byte stream,
  for the simulator script and for testing the app without a radio (`EagleTheme --phone tcp`).
  One phone at a time: a new connection replaces the old one. Connecting counts as subscribing.

Phone calls themselves (audio, microphone) do not go through this link. They use the classic
Bluetooth hands-free profile between the phone and the helmet headset, or between the phone and the
board's BlueZ stack. The link carries call *state* and the rider's
answer/decline buttons.

## Frame

All integers little-endian.

```text
 0       1         2          3..4         5 .. 5+len-1     last 2
[A5]  [ver=01]  [type]   [len u16]    [payload ......]  [CRC16 u16]
```

- CRC-16/CCITT-FALSE (poly 0x1021, init 0xFFFF, no reflection, no xor-out) over bytes 1 to the
  end of the payload.
- Payload at most 160 bytes.
- `text` = one length byte, then that many UTF-8 bytes, at most 48. A sender cuts on a character
  boundary; a receiver that finds a longer string cuts it the same way.
- A bad CRC, a bad version or an oversized length drops the frame; the parser resynchronises on
  the next `A5`.
- **Unknown types are ignored. Bytes after the last field a receiver knows are ignored.** That
  is the whole extension rule: new messages get new types, new fields go on the end.

Test vectors (NavUpdate, right turn in 250 m, 12.4 km to go, 23 min, "MG Road"); the first is
the original v1 example, the second recommends the right lane of three. Both codecs test
against them.

```text
a5 01 01 16 00 06 00 fa 00 00 00 70 30 00 00 17 00 00 00 07 4d 47 20 52 6f 61 64 17 8f
a5 01 01 16 00 06 00 fa 00 00 00 70 30 00 00 17 00 07 04 07 4d 47 20 52 6f 61 64 02 0f
```

## Messages

### Phone → cluster

| Type | Name | Payload |
|---|---|---|
| 0x01 | NavUpdate | `u8 maneuver, u8 roundaboutExit, u32 distToManeuver_m, u32 distRemaining_m, u16 eta_min, u8 laneMask, u8 recommendedLaneMask, text road` + v1.1: `u8 nextManeuver, u32 nextDistance_m` |
| 0x02 | NavStop | — |
| 0x10 | CallState | `u8 status (0 idle, 1 ringing, 2 active), text caller` + v1.1: `u16 elapsed_s, u8 flags (bit0 outgoing, bit1 muted)` |
| 0x11 | MediaState | `u8 playing, u8 volume (0..100), u16 position_s, u16 duration_s, text title, text artist` + v1.1: `text source, u32 artId` |
| 0x12 | Notification | `u8 app, text sender, text message` |
| 0x13 | ListEntry | `u8 list (0 contacts, 1 reminders), u8 slot (0..2), text title, text text` |
| 0x14 | MediaArt (1.1) | `u32 artId, u16 offset, u16 total, bytes chunk` |
| 0x20 | TimeSync | `u32 unixSeconds, i16 utcOffsetMinutes` |
| 0x21 | PhoneStatus | `u8 battery%, u8 signalBars (0..4), u8 internet` + v1.1: `u8 charging` |
| 0x22 | WifiJoin (1.1) | `text ssid, text password` — the password may be 64 bytes. Taken only over an encrypted link, by a cluster with feature bit 6 |
| 0x30 | Heartbeat | — (both ways, every 2 s) |

### Cluster → phone

| Type | Name | Payload |
|---|---|---|
| 0x30 | Heartbeat | — |
| 0x40 | MediaCommand | `u8 cmd` (below) |
| 0x41 | CallCommand | `u8 cmd` (1 answer, 2 decline or hang up) + v1.1: cmd 3 call contact, followed by `u8 slot` of the contacts list |
| 0x60 | VehicleStatus (1.1) | `u8 soc%, u16 range_km, u32 odometer_hm, u32 tripA_hm, u8 charging (0 no, 1 charging, 2 full), u8 rideMode, u8 gear, u16 activeFaults` — every 5 s while subscribed, and the last one again right after ClusterInfo |
| 0x61 | ClusterInfo (1.1) | `u8 minorVersion, u32 features, text model, text firmware` — once, right after the phone subscribes |
| 0x62 | WifiStatus (1.1) | `u8 state (0 off, 1 no network saved, 2 joining, 3 joined, 4 failed), text ssid, text address` — after ClusterInfo and on every change |

`odometer_hm` and `tripA_hm` are in hectometres (0.1 km). `activeFaults` is the number of fault
codes active on the bike, not a bit mask. `rideMode`: 0 eco, 1 city, 2 sport,
3 track. `gear`: 0 N, 1 D, 2 R.

ClusterInfo `features` bits: 0 album art, 1 vehicle status, 2 contacts dial, 3 next maneuver,
4 notifications, 5 reminders, 6 Wi-Fi (this dashboard does not set it). A cluster that never sends ClusterInfo is a v1.0 cluster: the
app sends v1.0 messages only (it may still append v1.1 fields, which a v1.0 parser ignores, but
it skips MediaArt to save airtime).

### Codes

Maneuver:

| Code | | Code | |
|---|---|---|---|
| 0 | none | 9 | U-turn right |
| 1 | straight | 10 | roundabout enter (`roundaboutExit` = exit number) |
| 2 | slight left | 11 | roundabout exit |
| 3 | left | 12 | fork left |
| 4 | sharp left | 13 | fork right |
| 5 | slight right | 14 | merge left |
| 6 | right | 15 | merge right |
| 7 | sharp right | 16 | destination |
| 8 | U-turn left | | |

MediaCommand: 1 play/pause, 2 next, 3 previous, 4 volume up, 5 volume down, 6 next shuffle mode,
7 next repeat mode, 8 skip forward, 9 skip backward.

Notification `app`: 0 other, 1 SMS, 2 WhatsApp, 3 Telegram, 4 e-mail, 5 calendar, 6 missed call,
7 Instagram, 8 Messenger, 9 Signal.

### Calls

The cluster tells a missed call from CallState alone: ringing, then idle, without being active
and without the rider declining on the bars. The app need not send Notification `app` 6 for a
call it already reported (if it does, the cluster still shows one card). After CallCommand 3 the
app reports the call it placed as ringing with flag bit 0 (outgoing); the cluster shows it as a
call in progress, never as incoming. Without `elapsed_s` (a 1.0 app) the cluster counts the call
time itself from the change to active.

### Album art

The phone scales the cover to 120 × 120 and encodes it as JPEG of at most 12 KiB. `artId` is any
non-zero number that changes with the picture (the app uses a hash of title and artist). It
sends MediaState first, carrying the new `artId`, then the picture in chunks of up to 150 bytes,
each one a MediaArt frame. The cluster keeps the picture whose id matches the current track and
shows it once `offset + chunk == total`. `artId` 0 means "no picture": the cluster draws its own
placeholder. Chunks are written without response, paced at about 8 ms, which puts a cover on the
screen in well under a second.

### Liveness and privacy

- Each side sends Heartbeat every 2 s. Five seconds without any frame and the other side counts
  the link as lost.
- When the link is lost the cluster clears the call, media, navigation, lists and notification it
  was showing, so nothing personal stays on screen after the phone has gone.
- The phone sends TimeSync and PhoneStatus straight after it subscribes, PhoneStatus again every
  30 s and whenever it changes, and MediaState whenever the player changes plus every 5 s while
  playing.

## Who can do what

What a phone lets an app read or control decides which features work where.

| Feature | Android app | iPhone app |
|---|---|---|
| Turn-by-turn, built-in route | yes | yes |
| Turn-by-turn mirrored from Google Maps | yes (notification access) | no |
| Track, artist, cover, position | yes (notification access) | no (iOS gives no app another app's player) |
| Play, pause, skip, volume | yes | no |
| Incoming caller name | yes (phone + contacts permission) | ringing only, no name (CallKit observer) |
| Answer, decline | yes (`ANSWER_PHONE_CALLS`) | no |
| Call a favourite from the bars | yes (`CALL_PHONE`) | no |
| Message notifications | yes (notification access) | no |
| Time, phone battery, signal | yes | yes (signal not exposed: sent as 0) |
| Bike battery, range, odometer in the app | yes | yes |
| Where I parked | yes | yes |

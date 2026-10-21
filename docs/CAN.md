# CAN frames

The dashboard listens on SocketCAN (`--can can0`, 500 kbit/s) and reads these
standard 11-bit frames. Multi-byte values are little-endian. A frame shorter
than shown is ignored, and a value that stops arriving keeps its last reading.
The decoder is `CanVehicleSource::apply()`; `tests/tst_core.cpp` feeds it frames.

| ID | Bytes | Content |
|---|---|---|
| `0x100` Motion | 0–1 | speed, km/h × 10 (u16) |
| | 2–3 | power, kW × 10 (s16, negative = regen) |
| | 4 | gear: 0 P, 1 R, 2 N, 3 D |
| | 5 | flags: bit 0 ready to ride |
| `0x101` Battery | 0 | state of charge, % |
| | 1–2 | range, km (u16) |
| | 3 | charging power, kW × 10 |
| | 4 | charge limit, % |
| | 5 | flags: bit 0 charging |
| `0x102` Temperatures | 0, 1, 2 | ambient, battery, motor, °C (s8 each) |
| `0x103` Lamps | 0 | flags: bit 0 left, 1 right, 2 low beam, 3 high beam, 4 side stand down |
| | 1 | ride mode: 0 Eco, 1 City, 2 Sport |
| `0x104` Tyres | 0, 1 | front, rear pressure, bar × 10 |
| `0x105` Faults | 0 | flags: bit 0 motor, bit 1 ABS |
| `0x106` Trip | 0–1 | trip A, km (u16) |
| | 2–5 | odometer, km (u32) |

Navigation, calls and music come from the phone over Bluetooth, not the bus.

To try it on a Linux desk with `vcan`:

```sh
sudo modprobe vcan && sudo ip link add dev vcan0 type vcan && sudo ip link set vcan0 up
./EagleTheme --can vcan0 &
cansend vcan0 100#C801190003010000     # 45.6 km/h, 2.5 kW, D, ready
cansend vcan0 103#1502                 # left indicator, low beam, side stand; Sport
```

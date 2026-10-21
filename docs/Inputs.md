# Inputs: handlebar keys, encoder and the cluster connector

The dashboard runs on a panel with or without touch. Everything a rider can do
by touch can be done from the handlebar, and the bike's signals can reach the
cluster over CAN (docs/CAN.md), over the wires of the cluster connector
(below), or both.

## Handlebar keys and encoder

| Action | What it does | Keyboard / evdev key | CAN 0x107 byte 0 |
|---|---|---|---|
| Up | previous control on the screen | `KEY_UP`, `KEY_PAGEUP` | bit 0 |
| Down | next control on the screen | `KEY_DOWN`, `KEY_PAGEDOWN` | bit 1 |
| Left | previous screen (footer order) | `KEY_LEFT` | bit 2 |
| Right | next screen | `KEY_RIGHT` | bit 3 |
| OK | act on the focused control | `KEY_ENTER`, `KEY_SELECT` | bit 4 |
| Back | close what is open, else home | `KEY_ESC`, `KEY_BACK` | bit 5 |

Over an incoming call OK answers and Back declines; over a critical alert OK
acknowledges. A ring marks the focused control and fades after eight seconds
without a key.

On the board, wire the buttons as `gpio-keys` and a rotary encoder as
`rotary-encoder` in the device tree; Linux then delivers them as the keys
above and Qt passes them on with no code of ours in between:

```dts
handlebar-keys {
    compatible = "gpio-keys";
    up    { label = "up";    gpios = <&gpio2 RK_PA0 GPIO_ACTIVE_LOW>; linux,code = <KEY_UP>; };
    down  { label = "down";  gpios = <&gpio2 RK_PA1 GPIO_ACTIVE_LOW>; linux,code = <KEY_DOWN>; };
    left  { label = "left";  gpios = <&gpio2 RK_PB0 GPIO_ACTIVE_LOW>; linux,code = <KEY_LEFT>; };
    right { label = "right"; gpios = <&gpio2 RK_PB1 GPIO_ACTIVE_LOW>; linux,code = <KEY_RIGHT>; };
    ok    { label = "ok";    gpios = <&gpio2 RK_PB2 GPIO_ACTIVE_LOW>; linux,code = <KEY_ENTER>; };
    back  { label = "back";  gpios = <&gpio2 RK_PB3 GPIO_ACTIVE_LOW>; linux,code = <KEY_ESC>; };
};

handlebar-encoder {
    compatible = "rotary-encoder";
    gpios = <&gpio2 RK_PB4 GPIO_ACTIVE_LOW>, <&gpio2 RK_PB5 GPIO_ACTIVE_LOW>;
    linux,axis = <REL_WHEEL>;
    rotary-encoder,relative-axis;
    rotary-encoder,steps-per-period = <4>;
};
```

The encoder arrives as a wheel: in board mode each detent is one Up or Down
step (a wheel on the desk keeps scrolling lists as usual). Its push button
goes in `gpio-keys` as `KEY_ENTER`.

A bike whose switchgear already sits on CAN sends frame `0x107`: byte 0 the
keys held (bits above), byte 1 the encoder's detents since the last frame
(signed, positive is down). A key counts once when it goes down.

## The cluster connector

`--harness /etc/eagle/harness.json` maps the connector's lines to the RK3328's
GPIO and ADC pins; `deploy/rk3328/harness.json` is an example. Every entry is
optional, and CAN can carry the rest.

| Pin on a typical connector | Signal | How it is read | Map key |
|---|---|---|---|
| Speed sensor | road speed | GPIO rising edges, counted 4 times a second | `speed` (`pulsesPerKm`) |
| Fuel level / pack voltage | state of charge | ADC through a divider, volts to % by a curve | `battery` |
| Coolant / motor temperature | motor (or battery) °C | ADC, NTC thermistor, beta equation | `temperature` |
| High beam indicator | high beam telltale, blue road | GPIO level | `digital.highBeam` |
| Turn signal left / right | indicator telltales | GPIO flasher output, held on 700 ms | `digital.turnLeft`, `turnRight` |
| Neutral indicator | gear N / D | GPIO level | `digital.neutral` |
| ABS warning | ABS telltale and alert | GPIO level | `digital.abs` |
| Check engine (MIL) | drive-system telltale and alert | GPIO level | `digital.checkEngine` |
| Illumination + | night theme in Auto | GPIO level | `digital.illumination` |
| Side stand switch | telltale, critical when moving | GPIO level | `digital.sideStand` |
| Tacho / oil pressure | not used on an electric scooter | — | — |

Each GPIO entry names the chip and line (`gpioinfo` lists them) and whether it
is `activeLow`; the kernel applies that and debounces switches (5 ms unless
`debounceUs` says otherwise). The 12 V lines need level shifting to the
RK3328's 3.3 V pins: an opto-coupler or a divider with a clamp diode per line.

The turn-signal lines carry the bike's flasher, so a lamp counts as on while it
flashed within the last 700 ms and the cluster blinks its telltale on its own
clock, in step with the hazard banner and the road edges.

The ADC is the RK3328's SAR ADC (1.8 V reference) through IIO:
`/sys/bus/iio/devices/iio:device0/in_voltageN_raw`. The pack voltage needs a
divider (`dividerRatio`); the state-of-charge `curve` is (millivolts, percent)
points for the pack's chemistry.

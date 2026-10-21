#!/usr/bin/env python3
#
# Plays the companion app against a bench cluster started with --phone tcp (docs/PhoneLink.md):
# clock and phone status, a playing track with its cover, a route counting down, a message, and a
# call that rings in after a few seconds. Prints whatever the cluster sends back.
#   EagleTheme --phone tcp &
#   scripts/phone_link_sim.py [--host 127.0.0.1] [--port 47100] [--call-after 8] [--duration 0]

import argparse
import base64
import datetime
import select
import socket
import struct
import sys
import time

SOF, VERSION, MAX_PAYLOAD, MAX_TEXT = 0xA5, 1, 160, 48

NAV_UPDATE, NAV_STOP, CALL_STATE, MEDIA_STATE = 0x01, 0x02, 0x10, 0x11
NOTIFICATION, LIST_ENTRY, MEDIA_ART, TIME_SYNC, PHONE_STATUS = 0x12, 0x13, 0x14, 0x20, 0x21
HEARTBEAT, MEDIA_COMMAND, CALL_COMMAND, VEHICLE_STATUS, CLUSTER_INFO = 0x30, 0x40, 0x41, 0x60, 0x61

MEDIA_COMMANDS = {1: "play/pause", 2: "next", 3: "previous", 4: "volume up", 5: "volume down",
                  6: "shuffle", 7: "repeat", 8: "skip forward", 9: "skip backward"}
RIDE_MODES = ["eco", "city", "sport", "track"]
GEARS = ["N", "D", "R"]

# 120 x 120 JPEG, 1.7 KiB: dusk over a hill.
COVER = base64.b64decode("".join([
    "/9j/4AAQSkZJRgABAQAASABIAAD/4QCARXhpZgAATU0AKgAAAAgABAEaAAUAAAABAAAAPgEbAAUAAAABAAAARgEoAAMAAAAB"
    "AAIAAIdpAAQAAAABAAAATgAAAAAAAABIAAAAAQAAAEgAAAABAAOgAQADAAAAAQABAACgAgAEAAAAAQAAAHigAwAEAAAAAQAA"
    "AHgAAAAA/+0AOFBob3Rvc2hvcCAzLjAAOEJJTQQEAAAAAAAAOEJJTQQlAAAAAAAQ1B2M2Y8AsgTpgAmY7PhCfv/AABEIAHgA"
    "eAMBIgACEQEDEQH/xAAfAAABBQEBAQEBAQAAAAAAAAAAAQIDBAUGBwgJCgv/xAC1EAACAQMDAgQDBQUEBAAAAX0BAgMABBEF"
    "EiExQQYTUWEHInEUMoGRoQgjQrHBFVLR8CQzYnKCCQoWFxgZGiUmJygpKjQ1Njc4OTpDREVGR0hJSlNUVVZXWFlaY2RlZmdo"
    "aWpzdHV2d3h5eoOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4eLj5OXm5+jp"
    "6vHy8/T19vf4+fr/xAAfAQADAQEBAQEBAQEBAAAAAAAAAQIDBAUGBwgJCgv/xAC1EQACAQIEBAMEBwUEBAABAncAAQIDEQQF"
    "ITEGEkFRB2FxEyIygQgUQpGhscEJIzNS8BVictEKFiQ04SXxFxgZGiYnKCkqNTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZn"
    "aGlqc3R1dnd4eXqCg4SFhoeIiYqSk5SVlpeYmZqio6Slpqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2dri4+Tl5ufo"
    "6ery8/T19vf4+fr/2wBDAAkJCQkJCRAJCRAWEBAQFh4WFhYWHiYeHh4eHiYuJiYmJiYmLi4uLi4uLi43Nzc3NzdAQEBAQEhI"
    "SEhISEhISEj/2wBDAQsMDBIREh8RER9LMyozS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tL"
    "S0tLS0v/3QAEAAj/2gAMAwEAAhEDEQA/APNMUYqTFGK9nmK5SPFGKkxRijmDlI8UYqTFGKOYOUjxRipMUYo5g5SPFGKkxRij"
    "mDlI8UYqTFGKOYOUjxRipMUYo5g5SPFGKkxRijmDlP/Q87xRipMUYr0uY6OUjxRipMUYo5g5SPFGKkxRijmDlI8UYqTFGKOY"
    "OUjxVuz0+8v38u0jMhHXHQfUngdO9SWNm99dx2kfBkOM+g6k9ug5r2SCCG1hW3t1CIgwAK8zMMx+r2jFXkzelQ59XseUP4a1"
    "pFLm3OAM8MpPHoAcmsV42jYo4KspwQeCCOxr3auZ8T6Yl5Ym6jUebAN2e5QdR17df5da4cLnMpzUKqWvY0qYZJXieW4oxUmK"
    "MV9DzHJykeKMVJijFHMHKf/R4PFGKfijFdnMd3KMxRin4oxRzByjMUYp+KMUcwcozFGKfijFHMHKa/h1lTWYGcgDLDnjkqQP"
    "zNerV4opZGDoSrKcgjggivSNO8SWV0qpdEQy453cIT7Ht+P05rwM2w85yVWCvpY6aEklZnR1Q1ZlTTLkuQB5Tjn1IwPzNDar"
    "piKXNzFgDPDAn8hya4rXtdTUEFpaAiIHLMeN2OnHp35/TFeZhMLUqVFpobTmkjk8UYp+KMV9lzHByjMUYp+KMUcwcp//0uKx"
    "Rin4oxWvMepyjMUYp+KMUcwcozFGKfijFHMHKMxRin4oxRzByjMUYp+KMUcwcozFGKfijFHMHKMxRin4prska7nIA96OYLCY"
    "oxWNcXry5RPlXp7mqVLmMXUXQ//T5HFGKkxRilzHt8pHijFSYoxRzBykeKMU52RBl2Cj3OKj8+3/AOei/mKOYVkOxRim+fb/"
    "APPRfzFHn2//AD0X8xRzC0HYoxSLLC52q6knsCKlxRzDsR4oxTmKoNzEADuaxrrUC3yW5IHc9z9KLkyajuW7m7jgBUcv6f41"
    "iSyyTNukOfQdh9Kjop3OSc3ISiloouZn/9TmMVFLNDD/AKxgPbv+Vc9LeXE3DMQOeBwOarVlY9aVfsjbk1SFeI1Lc9+BVCTU"
    "Lp+hCjGOBVOimYyqSfUGZnO5iST3NJS0UzMSilooEW9PH+lp+P8AI1t3FzFbD5uWIyF9a52KRoXEidRnH4jFMJLEk8k0jaFT"
    "ljZE1xcyXDZY4XsvYVXpaKZk23qxKKWigQlFLRQB/9XyrFGKWisrncJijFLRRcBMUYpaKLgJijFLRRcBMUYpaKLgJijFLRRc"
    "BMUYpaKLgJijFLRRcD//1vLKKWisDvEopaKAEopaKAEopaKAEopaKAEopaKAEopaKAEopaKAP//Z"
]))

PLAYLIST = [("Night Drive", "Skyline", 228), ("Open Road", "Northbound", 201), ("Low Gear", "The Volts", 245)]

# (maneuver, roundabout exit, metres to it, road)
ROUTE = [(6, 0, 250, "MG Road"), (10, 2, 600, "Residency Road"), (2, 0, 450, "Brigade Road"),
         (3, 0, 300, "Church Street"), (16, 0, 200, "Eagle Service Centre")]


def crc16(data):
    crc = 0xFFFF
    for byte in data:
        crc ^= byte << 8
        for _ in range(8):
            crc = ((crc << 1) ^ 0x1021) & 0xFFFF if crc & 0x8000 else (crc << 1) & 0xFFFF
    return crc


def frame(kind, payload=b""):
    body = bytes([VERSION, kind]) + struct.pack("<H", len(payload)) + payload
    return bytes([SOF]) + body + struct.pack("<H", crc16(body))


def text(value):
    data = value.encode("utf-8")[:MAX_TEXT]
    while data:
        try:
            data.decode("utf-8")
            break
        except UnicodeDecodeError:
            data = data[:-1]
    return bytes([len(data)]) + data


class Parser:
    def __init__(self):
        self.buffer = bytearray()

    def feed(self, data):
        self.buffer += data
        while self.buffer:
            if self.buffer[0] != SOF:
                next_start = self.buffer.find(bytes([SOF]), 1)
                del self.buffer[:next_start if next_start >= 0 else len(self.buffer)]
                continue
            if len(self.buffer) < 5:
                return
            length = struct.unpack_from("<H", self.buffer, 3)[0]
            if self.buffer[1] != VERSION or length > MAX_PAYLOAD:
                del self.buffer[0]
                continue
            if len(self.buffer) < 7 + length:
                return
            sent = struct.unpack_from("<H", self.buffer, 5 + length)[0]
            if sent != crc16(self.buffer[1:5 + length]):
                print("  bad CRC from the cluster")
                del self.buffer[0]
                continue
            yield self.buffer[2], bytes(self.buffer[5:5 + length])
            del self.buffer[:7 + length]


def read_text(payload, offset):
    length = payload[offset]
    return payload[offset + 1:offset + 1 + length].decode("utf-8", "replace"), offset + 1 + length


class Phone:
    def __init__(self, sock, call_after):
        self.sock = sock
        self.call_after = call_after
        self.started = time.monotonic()
        self.track = 0
        self.position = 96
        self.playing = True
        self.leg = 0
        self.metres = ROUTE[0][2]
        self.remaining = 7800
        self.call = "idle"
        self.call_since = 0.0
        self.rang = False

    def send(self, data):
        self.sock.sendall(data)

    def elapsed(self):
        return time.monotonic() - self.started

    def art_id(self):
        return 0x1000 + self.track

    def hello(self):
        offset = datetime.datetime.now().astimezone().utcoffset()
        self.send(frame(TIME_SYNC, struct.pack("<Ih", int(time.time()), int(offset.total_seconds() // 60))))
        self.send(frame(PHONE_STATUS, struct.pack("<BBBB", 76, 3, 1, 0)))
        for slot, name in enumerate(["Mum", "Rahul Sharma", "Priya"]):
            self.send(frame(LIST_ENTRY, bytes([0, slot]) + text(name) + text("")))
        self.send(frame(LIST_ENTRY, bytes([1, 0]) + text("Service due") + text("Fri 10:00")))
        self.media(with_art=True)
        self.navigation()

    def media(self, with_art=False):
        title, artist, duration = PLAYLIST[self.track]
        payload = struct.pack("<BBHH", int(self.playing), 60, self.position, duration)
        payload += text(title) + text(artist) + text("Spotify") + struct.pack("<I", self.art_id())
        self.send(frame(MEDIA_STATE, payload))
        if with_art:
            for offset in range(0, len(COVER), 150):
                chunk = COVER[offset:offset + 150]
                self.send(frame(MEDIA_ART, struct.pack("<IHH", self.art_id(), offset, len(COVER)) + chunk))
                time.sleep(0.008)

    def navigation(self):
        if self.leg >= len(ROUTE):
            return
        maneuver, exit_number, _, road = ROUTE[self.leg]
        payload = struct.pack("<BBIIHBB", maneuver, exit_number, self.metres, self.remaining,
                              max(1, round(self.remaining / 1000 / 30 * 60)), 0x07, 0x04)
        payload += text(road)
        if self.leg + 1 < len(ROUTE):
            payload += struct.pack("<BI", ROUTE[self.leg + 1][0], ROUTE[self.leg + 1][2])
        else:
            payload += struct.pack("<BI", 0, 0)
        self.send(frame(NAV_UPDATE, payload))

    def call_state(self, status, caller="", outgoing=False):
        names = {0: "idle", 1: "ringing", 2: "active"}
        self.call = names[status]
        self.call_since = time.monotonic()
        self.send(frame(CALL_STATE, bytes([status]) + text(caller) + struct.pack("<HB", 0, int(outgoing))))
        print(f"  phone: call {self.call} {caller}")

    def second(self, tick):
        if self.playing:
            self.position += 1
            if self.position >= PLAYLIST[self.track][2]:
                self.next_track()
        if tick % 5 == 0:
            self.media()
        if tick % 30 == 0:
            self.send(frame(PHONE_STATUS, struct.pack("<BBBB", 76 - tick // 60, 3, 1, 0)))

        if self.leg < len(ROUTE):
            self.metres -= 14
            self.remaining = max(0, self.remaining - 14)
            if self.metres <= 0:
                self.leg += 1
                if self.leg < len(ROUTE):
                    self.metres = ROUTE[self.leg][2]
                else:
                    self.send(frame(NAV_STOP))
                    print("  phone: arrived")
            self.navigation()

        if tick == 12:
            self.send(frame(NOTIFICATION, bytes([2]) + text("Priya") + text("Running 10 min late")))
        if not self.rang and self.elapsed() >= self.call_after:
            self.rang = True
            self.call_state(1, "Rahul Sharma")
        if self.call == "ringing" and time.monotonic() - self.call_since > 20:
            self.call_state(0)
        if self.call == "active" and time.monotonic() - self.call_since > 15:
            self.call_state(0)

    def next_track(self, step=1):
        self.track = (self.track + step) % len(PLAYLIST)
        self.position = 0
        self.media(with_art=True)

    def on_cluster(self, kind, payload):
        if kind == HEARTBEAT:
            return
        if kind == CLUSTER_INFO:
            minor, features = struct.unpack_from("<BI", payload)
            model, offset = read_text(payload, 5)
            firmware, _ = read_text(payload, offset)
            print(f"cluster: ClusterInfo v1.{minor} features 0x{features:02x} {model} {firmware}")
        elif kind == VEHICLE_STATUS:
            soc, range_km, odo, trip, charging, mode, gear, faults = struct.unpack_from("<BHIIBBBH", payload)
            mode_name = RIDE_MODES[mode] if mode < len(RIDE_MODES) else mode
            gear_name = GEARS[gear] if gear < len(GEARS) else gear
            print(f"cluster: VehicleStatus {soc}% {range_km} km odo {odo / 10:.1f} km trip A {trip / 10:.1f} km "
                  f"charging {charging} mode {mode_name} gear {gear_name} faults {faults}")
        elif kind == MEDIA_COMMAND:
            command = payload[0]
            print(f"cluster: MediaCommand {MEDIA_COMMANDS.get(command, command)}")
            if command == 1:
                self.playing = not self.playing
                self.media()
            elif command in (2, 3):
                self.next_track(1 if command == 2 else -1)
        elif kind == CALL_COMMAND:
            command = payload[0]
            if command == 1:
                print("cluster: CallCommand answer")
                if self.call == "ringing":
                    self.call_state(2, "Rahul Sharma")
            elif command == 2:
                print("cluster: CallCommand decline / hang up")
                self.call_state(0)
            elif command == 3:
                print(f"cluster: CallCommand call contact in slot {payload[1]}")
                self.call_state(1, ["Mum", "Rahul Sharma", "Priya"][payload[1] % 3], outgoing=True)
        else:
            print(f"cluster: type 0x{kind:02x} {payload.hex(' ')}")


def main():
    parser = argparse.ArgumentParser(description="Plays the companion app against EagleTheme --phone tcp.")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=47100)
    parser.add_argument("--call-after", type=float, default=8, help="seconds before the call rings in")
    parser.add_argument("--duration", type=float, default=0, help="seconds to run; 0 runs until Ctrl+C")
    args = parser.parse_args()

    try:
        sock = socket.create_connection((args.host, args.port), timeout=5)
    except OSError as error:
        sys.exit(f"Cannot reach the cluster on {args.host}:{args.port}: {error}. Start it with --phone tcp.")
    sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
    print(f"Connected to {args.host}:{args.port}")

    phone = Phone(sock, args.call_after)
    incoming = Parser()
    phone.hello()

    tick = 0
    next_second = time.monotonic() + 1
    next_heartbeat = time.monotonic() + 2
    try:
        while not args.duration or phone.elapsed() < args.duration:
            wait = max(0.0, min(next_second, next_heartbeat) - time.monotonic())
            readable, _, _ = select.select([sock], [], [], wait)
            if readable:
                data = sock.recv(4096)
                if not data:
                    print("The cluster closed the connection")
                    return
                for kind, payload in incoming.feed(data):
                    phone.on_cluster(kind, payload)
            now = time.monotonic()
            if now >= next_heartbeat:
                phone.send(frame(HEARTBEAT))
                next_heartbeat += 2
            if now >= next_second:
                tick += 1
                phone.second(tick)
                next_second += 1
    except KeyboardInterrupt:
        pass
    finally:
        sock.close()


if __name__ == "__main__":
    main()

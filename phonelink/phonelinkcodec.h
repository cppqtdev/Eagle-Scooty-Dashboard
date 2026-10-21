#pragma once

#include <QByteArray>
#include <QByteArrayView>
#include <QList>
#include <QString>

#include <cstdint>
#include <optional>

// The companion app protocol of docs/PhoneLink.md, both directions, as bytes. No radio and no
// timer here: the BLE and TCP transports, the bench script and the tests share this one definition.
namespace phonelink::wire {

constexpr std::uint8_t kStartOfFrame = 0xA5;
constexpr std::uint8_t kVersion = 1;
constexpr std::uint8_t kMinorVersion = 2; // 1.2: cluster control, Wi-Fi, fault log, firmware
constexpr int kHeaderSize = 5;
constexpr int kCrcSize = 2;
constexpr int kMaxPayload = 160;
constexpr int kMaxText = 48;
constexpr int kMaxWifiPassword = 64; // a WPA key: WifiJoin's password may be this long
constexpr int kListSlots = 3;
// The app sends at most 12 KiB; a little slack for a phone that encodes a touch larger.
constexpr int kMaxArtBytes = 16 * 1024;

enum class MessageType : std::uint8_t
{
    NavUpdate = 0x01,
    NavStop = 0x02,
    CallState = 0x10,
    MediaState = 0x11,
    Notification = 0x12,
    ListEntry = 0x13,
    MediaArt = 0x14,
    TimeSync = 0x20,
    PhoneStatus = 0x21,
    WifiJoin = 0x22,        // 1.1
    ClusterCommand = 0x23,  // 1.2
    FirmwareOffer = 0x24,   // 1.2
    Heartbeat = 0x30,
    MediaCommand = 0x40,
    CallCommand = 0x41,
    VehicleStatus = 0x60,
    ClusterInfo = 0x61,
    WifiStatus = 0x62,      // 1.1
    ClusterSettings = 0x63, // 1.2
    FirmwareStatus = 0x64,  // 1.2
    FaultEntry = 0x65,      // 1.2
    WifiNetwork = 0x66,     // 1.2
};

struct Frame
{
    MessageType type = MessageType::Heartbeat;
    QByteArray payload;

    bool operator==(const Frame &) const = default;
};

// CRC-16/CCITT-FALSE: poly 0x1021, init 0xFFFF, no reflection, no xor-out.
[[nodiscard]] quint16 crc16(QByteArrayView bytes);

// Header, payload and CRC. Empty when the payload is over kMaxPayload.
[[nodiscard]] QByteArray encodeFrame(MessageType type, QByteArrayView payload = {});

// Cuts UTF-8 to at most \a maxBytes without splitting a character.
[[nodiscard]] QByteArray clipUtf8(const QByteArray &utf8, int maxBytes = kMaxText);

// Takes the byte stream in whatever pieces it arrives and hands back whole frames with a good
// CRC. Anything else is dropped and the parser picks up again at the next start byte.
class FrameParser
{
public:
    [[nodiscard]] QList<Frame> feed(const QByteArray &bytes);
    void reset();

    [[nodiscard]] int droppedFrames() const;

private:
    void skipToNextStart(qsizetype from);

    QByteArray m_buffer;
    int m_dropped = 0;
};

enum class Maneuver : std::uint8_t
{
    None,
    Straight,
    SlightLeft,
    Left,
    SharpLeft,
    SlightRight,
    Right,
    SharpRight,
    UTurnLeft,
    UTurnRight,
    RoundaboutEnter,
    RoundaboutExit,
    ForkLeft,
    ForkRight,
    MergeLeft,
    MergeRight,
    Destination,
};

struct NextManeuver
{
    Maneuver maneuver = Maneuver::None;
    quint32 distanceMetres = 0;

    bool operator==(const NextManeuver &) const = default;
};

struct NavUpdate
{
    Maneuver maneuver = Maneuver::None;
    int roundaboutExit = 0;
    quint32 distanceMetres = 0;
    quint32 remainingMetres = 0;
    int etaMinutes = 0;
    int laneMask = 0;
    int recommendedLaneMask = 0;
    QString road;
    std::optional<NextManeuver> next; // 1.1

    bool operator==(const NavUpdate &) const = default;
};

enum class CallStatus : std::uint8_t
{
    Idle,
    Ringing,
    Active,
};

struct CallDetail
{
    int elapsedSeconds = 0;
    bool outgoing = false;
    bool muted = false;

    bool operator==(const CallDetail &) const = default;
};

struct CallState
{
    CallStatus status = CallStatus::Idle;
    QString caller;
    std::optional<CallDetail> detail; // 1.1

    bool operator==(const CallState &) const = default;
};

struct MediaSource
{
    QString app; // "Spotify"
    quint32 artId = 0;

    bool operator==(const MediaSource &) const = default;
};

struct MediaState
{
    bool playing = false;
    int volumePercent = 0;
    int positionSeconds = 0;
    int durationSeconds = 0;
    QString title;
    QString artist;
    std::optional<MediaSource> source; // 1.1

    bool operator==(const MediaState &) const = default;
};

struct Notification
{
    int app = 0; // 0 other, 1 SMS, 2 WhatsApp ... 9 Signal
    QString sender;
    QString message;

    bool operator==(const Notification &) const = default;
};

enum class ListKind : std::uint8_t
{
    Contacts,
    Reminders,
};

struct ListEntry
{
    ListKind list = ListKind::Contacts;
    int slot = 0;
    QString title;
    QString text;

    bool operator==(const ListEntry &) const = default;
};

struct MediaArt
{
    quint32 artId = 0;
    int offset = 0;
    int total = 0;
    QByteArray chunk;

    bool operator==(const MediaArt &) const = default;
};

struct TimeSync
{
    quint32 unixSeconds = 0;
    int utcOffsetMinutes = 0;

    bool operator==(const TimeSync &) const = default;
};

struct PhoneStatus
{
    int batteryPercent = 0;
    int signalBars = 0;
    bool internet = false;
    std::optional<bool> charging; // 1.1

    bool operator==(const PhoneStatus &) const = default;
};

enum class MediaCommand : std::uint8_t
{
    PlayPause = 1,
    Next,
    Previous,
    VolumeUp,
    VolumeDown,
    NextShuffleMode,
    NextRepeatMode,
    SkipForward,
    SkipBackward,
};

enum class CallCommand : std::uint8_t
{
    Answer = 1,
    Decline,
    CallContact,
};

enum class ChargeState : std::uint8_t
{
    NotCharging,
    Charging,
    Full,
};

struct VehicleStatus
{
    int stateOfChargePercent = 0;
    int rangeKm = 0;
    quint32 odometerHectometres = 0;
    quint32 tripAHectometres = 0;
    ChargeState charging = ChargeState::NotCharging;
    int rideMode = 0; // 0 eco, 1 city, 2 sport, 3 track
    int gear = 0;     // 0 N, 1 D, 2 R
    int activeFaults = 0;

    // 1.1 trailing details; sent whenever present.
    struct Details
    {
        quint32 tripBHectometres = 0;
        qint32 kmToService = 0;      // negative when overdue
        int tripAWhPerKm = 0;
        int tripAAverageKmhX10 = 0;
        int tripAMaxKmh = 0;
        int batteryC = 0;
        int motorC = 0;
        int frontTyreBarX10 = 0;     // 0: no sensor
        int rearTyreBarX10 = 0;
        int minutesToCharge = 0;
        bool serviceDue = false;
        bool temperaturesValid = false;

        bool operator==(const Details &) const = default;
    };
    std::optional<Details> details;

    bool operator==(const VehicleStatus &) const = default;
};

// ClusterInfo feature bits: what this cluster does beyond version 1.0.
namespace feature {
constexpr quint32 AlbumArt = 1u << 0;
constexpr quint32 VehicleStatus = 1u << 1;
constexpr quint32 ContactsDial = 1u << 2;
constexpr quint32 NextManeuver = 1u << 3;
constexpr quint32 Notifications = 1u << 4;
constexpr quint32 Reminders = 1u << 5;
constexpr quint32 Wifi = 1u << 6;            // joins a network the app hands it
constexpr quint32 ClusterControl = 1u << 9;  // ClusterCommand and ClusterSettings
constexpr quint32 FirmwareUpdate = 1u << 10; // FirmwareOffer and FirmwareStatus
constexpr quint32 FaultLog = 1u << 11;       // FaultEntry
constexpr quint32 WifiScan = 1u << 12;       // WifiNetwork
} // namespace feature

// ClusterCommand codes (1.2). 15 and up are Eagle's, proposed for the app as 1.3; an
// app that does not know them never sends them.
namespace command {
constexpr int DisplayMode = 1;   // 0 auto, 1 dark, 2 light
constexpr int Units = 2;         // 0 metric, 1 imperial
constexpr int Brightness = 3;    // percent
constexpr int Clock24 = 4;       // 0 or 1
constexpr int Key = 5;           // value: 0 up, 1 down, 2 left, 3 right, 4 OK, 5 mode, 6 back
constexpr int LongKey = 6;
constexpr int ResetTrip = 7;     // 0 A, 1 B
constexpr int ResetService = 8;
constexpr int ShowPage = 9;      // 0 drive, 1 ride mode, 2 status, 3 trip, 4 navigation, 5 media, 6 phone, 7 settings
constexpr int ListFaults = 10;
constexpr int ClearFaults = 11;
constexpr int ScanWifi = 12;
constexpr int ForgetWifi = 13;
constexpr int ForgetPhones = 14;
constexpr int RideMode = 15;     // Eagle (1.3): 0 eco, 1 city, 2 sport; at a standstill
constexpr int ChargeLimit = 16;  // Eagle (1.3): 80, 90 or 100
constexpr int Volume = 17;       // Eagle (1.3): percent
constexpr int ArrowStyle = 18;   // Eagle (1.3): 0 solid, 1 ribbon, 2 chevrons, 3 outline, 4 sign
constexpr int Language = 19;     // Eagle (1.3): 0 English, 1 Hindi
} // namespace command

struct ClusterCommand
{
    int command = 0;
    int value = 0;

    bool operator==(const ClusterCommand &) const = default;
};

// The cluster's choices, after ClusterInfo and on any change. The fields after `dark` are
// Eagle's (1.3); an app that does not know them stops reading before them.
struct ClusterSettings
{
    int displayMode = 0;     // 0 auto, 1 dark, 2 light
    int units = 0;           // 0 metric, 1 imperial
    int brightness = 76;     // percent
    bool clock24 = true;
    bool locked = false;     // moving: settings and resets are refused
    int page = 0;            // as ShowPage
    bool dark = false;       // the theme on screen now
    int rideMode = 0;
    int chargeLimit = 90;
    int volume = 60;
    int arrowStyle = 4;
    int language = 0;

    bool operator==(const ClusterSettings &) const = default;
};

struct WifiJoin
{
    QString ssid;
    QString password;   // up to 64 bytes (a WPA key), longer than ordinary text

    bool operator==(const WifiJoin &) const = default;
};

enum class WifiState : std::uint8_t { Off, NoNetwork, Joining, Joined, Failed };
enum class WifiFailure : std::uint8_t { None, WrongPassword, NotFound, TimedOut, Refused };

struct WifiStatus
{
    WifiState state = WifiState::Off;
    QString ssid;
    QString address;
    int rssi = 0;            // dBm, 0 when not joined
    WifiFailure failure = WifiFailure::None;
    bool scanning = false;

    bool operator==(const WifiStatus &) const = default;
};

// One network a scan found; total 0 (and nothing else) means none.
struct WifiNetwork
{
    int index = 0;
    int total = 0;
    int rssi = 0;
    bool secured = false;
    bool current = false;
    QString ssid;

    bool operator==(const WifiNetwork &) const = default;
};

// One trouble code; total 0 means none. The code's high byte is the system, the low the fault.
struct FaultEntry
{
    int index = 0;
    int total = 0;
    int code = 0;
    bool active = false;
    bool critical = false;
    int count = 0;
    QString title;
    QString detail;
    QString firstSeen;
    QString lastSeen;

    bool operator==(const FaultEntry &) const = default;
};

struct FirmwareOffer
{
    quint32 size = 0;
    QString version;

    bool operator==(const FirmwareOffer &) const = default;
};

enum class FirmwareState : std::uint8_t { Idle, Ready, Receiving, Verifying, Rebooting, Failed };

struct FirmwareStatus
{
    FirmwareState state = FirmwareState::Idle;
    int percent = 0;
    int port = 0;
    QString address;
    QString token;
    QString message;

    bool operator==(const FirmwareStatus &) const = default;
};


struct ClusterInfo
{
    int minorVersion = kMinorVersion;
    quint32 features = 0;
    QString model;
    QString firmware;

    bool operator==(const ClusterInfo &) const = default;
};

// Phone to cluster. A payload too short for the fields of version 1.0 decodes to nothing;
// the 1.1 fields are filled only when the payload carries them.
[[nodiscard]] std::optional<NavUpdate> decodeNavUpdate(const QByteArray &payload);
[[nodiscard]] std::optional<CallState> decodeCallState(const QByteArray &payload);
[[nodiscard]] std::optional<MediaState> decodeMediaState(const QByteArray &payload);
[[nodiscard]] std::optional<Notification> decodeNotification(const QByteArray &payload);
[[nodiscard]] std::optional<ListEntry> decodeListEntry(const QByteArray &payload);
[[nodiscard]] std::optional<MediaArt> decodeMediaArt(const QByteArray &payload);
[[nodiscard]] std::optional<TimeSync> decodeTimeSync(const QByteArray &payload);
[[nodiscard]] std::optional<PhoneStatus> decodePhoneStatus(const QByteArray &payload);
[[nodiscard]] std::optional<ClusterCommand> decodeClusterCommand(const QByteArray &payload);
[[nodiscard]] std::optional<WifiJoin> decodeWifiJoin(const QByteArray &payload);
[[nodiscard]] std::optional<FirmwareOffer> decodeFirmwareOffer(const QByteArray &payload);

[[nodiscard]] QByteArray encode(const NavUpdate &message);
[[nodiscard]] QByteArray encode(const CallState &message);
[[nodiscard]] QByteArray encode(const MediaState &message);
[[nodiscard]] QByteArray encode(const Notification &message);
[[nodiscard]] QByteArray encode(const ListEntry &message);
[[nodiscard]] QByteArray encode(const MediaArt &message);
[[nodiscard]] QByteArray encode(const TimeSync &message);
[[nodiscard]] QByteArray encode(const PhoneStatus &message);
[[nodiscard]] QByteArray encodeNavStop();
[[nodiscard]] QByteArray encode(const ClusterCommand &message);
[[nodiscard]] QByteArray encode(const WifiJoin &message);
[[nodiscard]] QByteArray encode(const FirmwareOffer &message);

// Cluster to phone.
[[nodiscard]] QByteArray encodeHeartbeat();
[[nodiscard]] QByteArray encodeMediaCommand(MediaCommand command);
[[nodiscard]] QByteArray encodeCallCommand(CallCommand command, int contactSlot = 0);
[[nodiscard]] QByteArray encode(const VehicleStatus &message);
[[nodiscard]] QByteArray encode(const ClusterInfo &message);
[[nodiscard]] std::optional<VehicleStatus> decodeVehicleStatus(const QByteArray &payload);
[[nodiscard]] std::optional<ClusterInfo> decodeClusterInfo(const QByteArray &payload);
[[nodiscard]] QByteArray encode(const ClusterSettings &message);
[[nodiscard]] QByteArray encode(const WifiStatus &message);
[[nodiscard]] QByteArray encode(const WifiNetwork &message);
[[nodiscard]] QByteArray encode(const FaultEntry &message);
[[nodiscard]] QByteArray encode(const FirmwareStatus &message);
[[nodiscard]] std::optional<ClusterSettings> decodeClusterSettings(const QByteArray &payload);
[[nodiscard]] std::optional<WifiStatus> decodeWifiStatus(const QByteArray &payload);
[[nodiscard]] std::optional<WifiNetwork> decodeWifiNetwork(const QByteArray &payload);
[[nodiscard]] std::optional<FaultEntry> decodeFaultEntry(const QByteArray &payload);
[[nodiscard]] std::optional<FirmwareStatus> decodeFirmwareStatus(const QByteArray &payload);

// Puts a cover back together from its MediaArt chunks. Only the picture of the track now
// playing is kept: chunks for any other id are ignored.
class ArtAssembler
{
public:
    // The current track's artId from MediaState; a new id drops what came before.
    void expect(quint32 artId);

    // True when this chunk completed the picture.
    bool add(const MediaArt &chunk);

    [[nodiscard]] quint32 artId() const;
    [[nodiscard]] bool isComplete() const;
    [[nodiscard]] QByteArray picture() const; // empty until complete

private:
    quint32 m_artId = 0;
    int m_total = 0;
    QByteArray m_bytes;
    bool m_complete = false;
};

} // namespace phonelink::wire

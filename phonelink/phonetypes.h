#pragma once

#include <QString>
#include <QTime>

#include <cstdint>

namespace phonelink {

enum class CallState : std::uint8_t
{
    Idle,
    Incoming,
    Active, // also an outgoing call that is still ringing at the other end
};

struct CallInfo
{
    CallState state = CallState::Idle;
    QString callerName;
    int durationSeconds = 0;
    bool outgoing = false;
    bool muted = false;

    bool operator==(const CallInfo &) const = default;
};

struct MediaInfo
{
    bool available = false;
    bool playing = false;
    QString title;
    QString artist;
    QString source; // the player app, e.g. "Spotify"; empty when the phone does not say
    int positionSeconds = 0;
    int durationSeconds = 0;
    int volumePercent = 0;
    quint32 artId = 0; // names the cover of this track; 0 when there is none

    bool operator==(const MediaInfo &) const = default;
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
    UTurn,
    UTurnRight,
    Roundabout, // the exit to take is GuidanceInfo::roundaboutExit
    RoundaboutExit,
    ForkLeft,
    ForkRight,
    MergeLeft,
    MergeRight,
    Arrive,
};

// The name QML and the cards know a manoeuvre by, and pick its icon with:
// "left", "slight-right", "roundabout-2". Empty for None.
[[nodiscard]] QString maneuverKey(Maneuver maneuver, int roundaboutExit = 0);

struct GuidanceInfo
{
    bool active = false;
    Maneuver maneuver = Maneuver::Straight;
    int roundaboutExit = 0;
    int distanceMetres = 0;
    QString street;
    Maneuver nextManeuver = Maneuver::None;
    int nextDistanceMetres = 0;
    double remainingKm = 0;
    int remainingMinutes = 0;
    QTime arrival;

    bool operator==(const GuidanceInfo &) const = default;
};

struct PhoneNotification
{
    int app = 0; // docs/PhoneLink.md: 1 SMS, 2 WhatsApp ... 6 missed call ... 9 Signal
    QString sender;
    QString message;

    bool operator==(const PhoneNotification &) const = default;
};

// One row of a short list the phone keeps for the cluster: favourite contacts, reminders.
struct PhoneListEntry
{
    QString title;
    QString text;

    bool operator==(const PhoneListEntry &) const = default;
};

// What the companion app shows about the bike.
struct VehicleSummary
{
    int stateOfChargePercent = 0;
    int rangeKm = 0;
    double odometerKm = 0;
    double tripAKm = 0;
    bool charging = false;
    bool chargeComplete = false;
    int rideMode = 0; // 0 eco, 1 city, 2 sport, 3 track
    int gear = 0;     // 0 N, 1 D, 2 R
    int activeFaults = 0;

    bool operator==(const VehicleSummary &) const = default;
};

} // namespace phonelink

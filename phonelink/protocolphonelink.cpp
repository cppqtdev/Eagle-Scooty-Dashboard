#include "protocolphonelink.h"

#include "phonelinklog.h"
#include "iphonetransport.h"

#include <QDateTime>

#include <algorithm>
#include <cmath>
#include <utility>

namespace phonelink {

namespace {

Maneuver fromWire(wire::Maneuver maneuver)
{
    switch (maneuver) {
    case wire::Maneuver::None:
        return Maneuver::None;
    case wire::Maneuver::Straight:
        return Maneuver::Straight;
    case wire::Maneuver::SlightLeft:
        return Maneuver::SlightLeft;
    case wire::Maneuver::Left:
        return Maneuver::Left;
    case wire::Maneuver::SharpLeft:
        return Maneuver::SharpLeft;
    case wire::Maneuver::SlightRight:
        return Maneuver::SlightRight;
    case wire::Maneuver::Right:
        return Maneuver::Right;
    case wire::Maneuver::SharpRight:
        return Maneuver::SharpRight;
    case wire::Maneuver::UTurnLeft:
        return Maneuver::UTurn;
    case wire::Maneuver::UTurnRight:
        return Maneuver::UTurnRight;
    case wire::Maneuver::RoundaboutEnter:
        return Maneuver::Roundabout;
    case wire::Maneuver::RoundaboutExit:
        return Maneuver::RoundaboutExit;
    case wire::Maneuver::ForkLeft:
        return Maneuver::ForkLeft;
    case wire::Maneuver::ForkRight:
        return Maneuver::ForkRight;
    case wire::Maneuver::MergeLeft:
        return Maneuver::MergeLeft;
    case wire::Maneuver::MergeRight:
        return Maneuver::MergeRight;
    case wire::Maneuver::Destination:
        return Maneuver::Arrive;
    }
    return Maneuver::None;
}

int clampedMetres(quint32 metres)
{
    return static_cast<int>(std::min<quint32>(metres, 10'000'000));
}

quint32 hectometres(double km)
{
    return static_cast<quint32>(std::max(0L, std::lround(km * 10.0)));
}

wire::VehicleStatus toWire(const VehicleSummary &summary)
{
    wire::VehicleStatus status;
    status.stateOfChargePercent = summary.stateOfChargePercent;
    status.rangeKm = summary.rangeKm;
    status.odometerHectometres = hectometres(summary.odometerKm);
    status.tripAHectometres = hectometres(summary.tripAKm);
    if (summary.charging)
        status.charging = summary.chargeComplete ? wire::ChargeState::Full : wire::ChargeState::Charging;
    status.rideMode = static_cast<int>(summary.rideMode);
    status.gear = static_cast<int>(summary.gear);
    status.activeFaults = summary.activeFaults;
    return status;
}

QList<PhoneListEntry> filledSlots(const std::array<PhoneListEntry, wire::kListSlots> &list)
{
    // Up to the last filled slot, so a row's index is still its slot for callContact().
    QList<PhoneListEntry> entries(list.begin(), list.end());
    while (!entries.isEmpty() && entries.constLast().title.isEmpty())
        entries.removeLast();
    return entries;
}

} // namespace

ProtocolPhoneLink::ProtocolPhoneLink(std::unique_ptr<IPhoneTransport> transport, Options options, QObject *parent)
    : IPhoneLink(parent), m_transport(std::move(transport)), m_options(std::move(options))
{
    m_monotonic.start();

    m_heartbeat.setInterval(m_options.heartbeatMs);
    connect(&m_heartbeat, &QTimer::timeout, this, [this] { send(wire::encodeHeartbeat()); });

    m_silence.setSingleShot(true);
    m_silence.setInterval(m_options.silenceMs);
    connect(&m_silence, &QTimer::timeout, this, [this] {
        qCWarning(lcPhoneLink) << "Nothing from the phone for" << m_options.silenceMs << "ms";
        loseLink();
    });

    m_clock.setInterval(1000);
    connect(&m_clock, &QTimer::timeout, this, &ProtocolPhoneLink::tick);

    connect(m_transport.get(), &IPhoneTransport::peerConnected, this, &ProtocolPhoneLink::onPeerConnected);
    connect(m_transport.get(), &IPhoneTransport::peerDisconnected, this, &ProtocolPhoneLink::onPeerDisconnected);
    connect(m_transport.get(), &IPhoneTransport::received, this, &ProtocolPhoneLink::onReceived);
    connect(m_transport.get(), &IPhoneTransport::errorOccurred, this,
            [this](const QString &reason) { qCWarning(lcPhoneLink) << m_transport->name() << reason; });
}

ProtocolPhoneLink::~ProtocolPhoneLink()
{
    // Stopping may report the phone gone; nobody is left to hear it.
    m_transport->disconnect(this);
    m_transport->stop();
}

quint32 ProtocolPhoneLink::features()
{
    using namespace wire::feature;
    return AlbumArt | VehicleStatus | ContactsDial | NextManeuver | Notifications | Reminders | Settings;
}

bool ProtocolPhoneLink::isConnected() const
{
    return m_linked;
}

int ProtocolPhoneLink::signalBars() const
{
    return m_phone.signalBars;
}

int ProtocolPhoneLink::batteryPercent() const
{
    return m_phone.batteryPercent;
}

bool ProtocolPhoneLink::headsetConnected() const
{
    // The helmet headset pairs with the phone, not with us; the protocol does not report it.
    return false;
}

CallInfo ProtocolPhoneLink::call() const
{
    CallInfo call = m_call;
    if (m_callStatus == wire::CallStatus::Active)
        call.durationSeconds = static_cast<int>(std::max<qint64>(0, now() - m_callStartedMs) / 1000);
    return call;
}

MediaInfo ProtocolPhoneLink::media() const
{
    // The phone reports the position every 5 s while playing; count the seconds in between.
    MediaInfo media = m_media;
    if (media.playing) {
        media.positionSeconds += static_cast<int>((now() - m_mediaPositionAtMs) / 1000);
        if (media.durationSeconds > 0)
            media.positionSeconds = std::min(media.positionSeconds, media.durationSeconds);
    }
    return media;
}

GuidanceInfo ProtocolPhoneLink::guidance() const
{
    return m_guidance;
}

bool ProtocolPhoneLink::phoneCharging() const
{
    return m_phone.charging;
}

QByteArray ProtocolPhoneLink::albumArt() const
{
    if (m_media.artId == 0 || m_art.artId() != m_media.artId)
        return {};
    return m_art.picture();
}

std::optional<PhoneNotification> ProtocolPhoneLink::notification() const
{
    return m_notification;
}

QList<PhoneListEntry> ProtocolPhoneLink::contacts() const
{
    return filledSlots(m_contacts);
}

QList<PhoneListEntry> ProtocolPhoneLink::reminders() const
{
    return filledSlots(m_reminders);
}

std::optional<qint64> ProtocolPhoneLink::clockOffsetSeconds() const
{
    return m_clockOffsetSeconds;
}

int ProtocolPhoneLink::utcOffsetMinutes() const
{
    return m_utcOffsetMinutes;
}

void ProtocolPhoneLink::start()
{
    setEnabled(true);
}

void ProtocolPhoneLink::stop()
{
    setEnabled(false);
}

void ProtocolPhoneLink::setEnabled(bool enabled)
{
    if (m_enabled == enabled)
        return;
    m_enabled = enabled;
    qCInfo(lcPhoneLink) << "Phone link" << m_transport->name() << (enabled ? "on" : "off");

    if (enabled) {
        m_transport->start();
        // A transport whose phone is already there (a TCP client kept across the switch) says so now.
        if (m_transport->isPeerConnected())
            onPeerConnected();
        return;
    }
    m_transport->stop();
    onPeerDisconnected();
}

void ProtocolPhoneLink::answerCall()
{
    if (m_call.state != CallState::Incoming)
        return;
    qCInfo(lcPhoneLink) << "Answer";
    send(wire::encodeCallCommand(wire::CallCommand::Answer));
}

void ProtocolPhoneLink::declineCall()
{
    if (m_call.state == CallState::Idle)
        return;
    qCInfo(lcPhoneLink) << (m_call.state == CallState::Incoming ? "Decline" : "Hang up");
    m_declinedByRider = m_call.state == CallState::Incoming;
    send(wire::encodeCallCommand(wire::CallCommand::Decline));
}

void ProtocolPhoneLink::togglePlayback()
{
    if (m_media.available)
        send(wire::encodeMediaCommand(wire::MediaCommand::PlayPause));
}

void ProtocolPhoneLink::nextTrack()
{
    if (m_media.available)
        send(wire::encodeMediaCommand(wire::MediaCommand::Next));
}

void ProtocolPhoneLink::previousTrack()
{
    if (m_media.available)
        send(wire::encodeMediaCommand(wire::MediaCommand::Previous));
}

void ProtocolPhoneLink::callContact(int slot)
{
    if (slot < 0 || slot >= wire::kListSlots || m_contacts.at(static_cast<std::size_t>(slot)).title.isEmpty())
        return;
    qCInfo(lcPhoneLink) << "Call contact in slot" << slot;
    send(wire::encodeCallCommand(wire::CallCommand::CallContact, slot));
}

void ProtocolPhoneLink::publishVehicle(const VehicleSummary &summary)
{
    m_vehicle = summary;
    send(wire::encode(toWire(summary)));
}

void ProtocolPhoneLink::publishSettings(const QList<std::pair<int, int>> &values)
{
    wire::Settings settings{values};
    if (m_settings && *m_settings == settings)
        return;
    m_settings = settings;
    send(wire::encode(settings));
}

void ProtocolPhoneLink::onPeerConnected()
{
    qCInfo(lcPhoneLink) << "Phone subscribed over" << m_transport->name();
    m_parser.reset();
    send(wire::encode(wire::ClusterInfo{wire::kMinorVersion, features(), m_options.model, m_options.firmware}));
    if (m_vehicle)
        send(wire::encode(toWire(*m_vehicle)));
    if (m_settings)
        send(wire::encode(*m_settings));
    m_heartbeat.start();
    m_silence.start();
}

void ProtocolPhoneLink::onPeerDisconnected()
{
    m_heartbeat.stop();
    m_silence.stop();
    m_parser.reset();
    loseLink();
}

void ProtocolPhoneLink::onReceived(const QByteArray &bytes)
{
    const int droppedBefore = m_parser.droppedFrames();
    const auto frames = m_parser.feed(bytes);
    if (m_parser.droppedFrames() != droppedBefore)
        qCDebug(lcPhoneLink) << "Dropped" << m_parser.droppedFrames() - droppedBefore << "bad frames";

    for (const auto &frame : frames) {
        heardFromPhone();
        handle(frame);
    }
}

void ProtocolPhoneLink::heardFromPhone()
{
    m_silence.start();
    if (m_linked)
        return;
    m_linked = true;
    m_clock.start();
    qCInfo(lcPhoneLink) << "Phone connected";
    emit connectionChanged();
}

void ProtocolPhoneLink::handle(const wire::Frame &frame)
{
    using wire::MessageType;

    const auto applyDecoded = [this, &frame](const auto &decoded) {
        if (decoded)
            apply(*decoded);
        else
            qCDebug(lcPhoneLink) << "Short payload in message" << Qt::hex << static_cast<int>(frame.type);
    };

    switch (frame.type) {
    case MessageType::NavUpdate:
        applyDecoded(wire::decodeNavUpdate(frame.payload));
        break;
    case MessageType::NavStop:
        if (m_guidance.active) {
            m_guidance = {};
            emit guidanceChanged();
        }
        break;
    case MessageType::CallState:
        applyDecoded(wire::decodeCallState(frame.payload));
        break;
    case MessageType::MediaState:
        applyDecoded(wire::decodeMediaState(frame.payload));
        break;
    case MessageType::MediaArt:
        applyDecoded(wire::decodeMediaArt(frame.payload));
        break;
    case MessageType::Notification:
        if (const auto message = wire::decodeNotification(frame.payload)) {
            m_notification = PhoneNotification{message->app, message->sender, message->message};
            emit notificationChanged();
        }
        break;
    case MessageType::ListEntry:
        applyDecoded(wire::decodeListEntry(frame.payload));
        break;
    case MessageType::TimeSync:
        applyDecoded(wire::decodeTimeSync(frame.payload));
        break;
    case MessageType::PhoneStatus:
        applyDecoded(wire::decodePhoneStatus(frame.payload));
        break;
    case MessageType::SettingSet:
        if (const auto message = wire::decodeSettingSet(frame.payload)) {
            qCInfo(lcPhoneLink) << "App sets" << message->key << "to" << message->value;
            emit settingRequested(message->key, message->value);
        }
        break;
    default:
        // Heartbeat, or a message from a newer app this cluster does not know.
        break;
    }
}

void ProtocolPhoneLink::apply(const wire::NavUpdate &message)
{
    GuidanceInfo guidance;
    guidance.active = true;
    guidance.maneuver = fromWire(message.maneuver);
    guidance.roundaboutExit = message.roundaboutExit;
    guidance.distanceMetres = clampedMetres(message.distanceMetres);
    guidance.street = message.road;
    if (message.next) {
        guidance.nextManeuver = fromWire(message.next->maneuver);
        guidance.nextDistanceMetres = clampedMetres(message.next->distanceMetres);
    }
    guidance.remainingKm = message.remainingMetres / 1000.0;
    guidance.remainingMinutes = message.etaMinutes;
    guidance.arrival = QTime::currentTime().addSecs(message.etaMinutes * 60);
    // Seconds would make every update a change; the page shows minutes.
    guidance.arrival.setHMS(guidance.arrival.hour(), guidance.arrival.minute(), 0);

    if (guidance == m_guidance)
        return;
    m_guidance = guidance;
    emit guidanceChanged();
}

void ProtocolPhoneLink::apply(const wire::CallState &message)
{
    const CallInfo before = m_call;
    const wire::CallStatus statusBefore = m_callStatus;

    CallInfo call;
    if (message.status != wire::CallStatus::Idle) {
        call.callerName = message.caller;
        if (message.detail) {
            call.outgoing = message.detail->outgoing;
            call.muted = message.detail->muted;
        }
        const bool incoming = message.status == wire::CallStatus::Ringing && !call.outgoing;
        call.state = incoming ? CallState::Incoming : CallState::Active;
    }

    if (message.status == wire::CallStatus::Active) {
        if (message.detail)
            m_callStartedMs = now() - message.detail->elapsedSeconds * 1000LL;
        else if (statusBefore != wire::CallStatus::Active)
            m_callStartedMs = now();
    }
    if (message.status == wire::CallStatus::Ringing && statusBefore != wire::CallStatus::Ringing)
        m_declinedByRider = false;

    m_callStatus = message.status;
    m_call = call;

    const bool rangOut = statusBefore == wire::CallStatus::Ringing && message.status == wire::CallStatus::Idle &&
                         before.state == CallState::Incoming && !m_declinedByRider;
    if (call != before || statusBefore != message.status)
        emit callChanged();
    if (rangOut) {
        qCInfo(lcPhoneLink) << "Missed call";
        emit missedCall(before.callerName);
    }
}

void ProtocolPhoneLink::apply(const wire::MediaState &message)
{
    MediaInfo media;
    media.available = true;
    media.playing = message.playing;
    media.title = message.title;
    media.artist = message.artist;
    media.positionSeconds = message.positionSeconds;
    media.durationSeconds = message.durationSeconds;
    media.volumePercent = message.volumePercent;
    if (message.source) {
        media.source = message.source->app;
        media.artId = message.source->artId;
    }

    const bool artChanged = media.artId != m_media.artId;
    m_art.expect(media.artId);
    m_media = media;
    m_mediaPositionAtMs = now();
    emit mediaChanged();
    if (artChanged)
        emit albumArtChanged();
}

void ProtocolPhoneLink::apply(const wire::MediaArt &message)
{
    if (m_art.add(message)) {
        qCDebug(lcPhoneLink) << "Cover" << message.artId << message.total << "bytes";
        emit albumArtChanged();
    }
}

void ProtocolPhoneLink::apply(const wire::ListEntry &message)
{
    auto &list = message.list == wire::ListKind::Contacts ? m_contacts : m_reminders;
    const PhoneListEntry entry{message.title, message.text};
    auto &slot = list.at(static_cast<std::size_t>(message.slot));
    if (slot == entry)
        return;
    slot = entry;
    emit listsChanged();
}

void ProtocolPhoneLink::apply(const wire::TimeSync &message)
{
    const qint64 offset = static_cast<qint64>(message.unixSeconds) - QDateTime::currentSecsSinceEpoch();
    if (!m_clockOffsetSeconds || std::abs(offset - *m_clockOffsetSeconds) > 2) {
        qCInfo(lcPhoneLink).nospace() << "Phone clock is " << offset << " s ahead of ours, UTC"
                                       << (message.utcOffsetMinutes < 0 ? "" : "+") << message.utcOffsetMinutes / 60.0;
    }
    m_clockOffsetSeconds = offset;
    m_utcOffsetMinutes = message.utcOffsetMinutes;
}

void ProtocolPhoneLink::apply(const wire::PhoneStatus &message)
{
    const PhoneState state{message.batteryPercent, message.signalBars, message.internet,
                           message.charging.value_or(false)};
    if (state == m_phone)
        return;
    m_phone = state;
    emit connectionChanged();
}

void ProtocolPhoneLink::loseLink()
{
    m_clock.stop();
    const bool wasLinked = std::exchange(m_linked, false);
    if (wasLinked)
        qCInfo(lcPhoneLink) << "Phone disconnected";

    m_phone = {};
    m_callStatus = wire::CallStatus::Idle;
    m_declinedByRider = false;
    m_call = {};
    m_media = {};
    m_art.expect(0);
    m_guidance = {};
    m_notification.reset();
    m_contacts = {};
    m_reminders = {};

    if (!wasLinked)
        return;
    emit connectionChanged();
    emit callChanged();
    emit mediaChanged();
    emit albumArtChanged();
    emit guidanceChanged();
    emit notificationChanged();
    emit listsChanged();
}

void ProtocolPhoneLink::tick()
{
    if (m_callStatus == wire::CallStatus::Active)
        emit callChanged();
    if (m_media.playing)
        emit mediaChanged();
}

void ProtocolPhoneLink::send(const QByteArray &frame)
{
    if (m_transport->isPeerConnected())
        m_transport->send(frame);
}

qint64 ProtocolPhoneLink::now() const
{
    return m_monotonic.elapsed();
}

} // namespace phonelink

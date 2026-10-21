#include "phonelinkcodec.h"

#include <QtEndian>

#include <algorithm>

namespace phonelink::wire {

namespace {

constexpr int kLastManeuver = static_cast<int>(Maneuver::Destination);

class Writer
{
public:
    Writer &u8(int value)
    {
        m_bytes.append(static_cast<char>(std::clamp(value, 0, 0xFF)));
        return *this;
    }

    Writer &u16(int value)
    {
        append(qToLittleEndian(static_cast<quint16>(std::clamp(value, 0, 0xFFFF))));
        return *this;
    }

    Writer &s16(int value)
    {
        append(qToLittleEndian(static_cast<qint16>(std::clamp(value, -0x8000, 0x7FFF))));
        return *this;
    }

    Writer &u32(quint32 value)
    {
        append(qToLittleEndian(value));
        return *this;
    }

    Writer &s8(int value)
    {
        m_bytes.append(static_cast<char>(static_cast<qint8>(std::clamp(value, -0x80, 0x7F))));
        return *this;
    }

    Writer &s32(qint32 value)
    {
        append(qToLittleEndian(value));
        return *this;
    }

    Writer &text(const QString &value, int maxBytes = kMaxText)
    {
        const QByteArray utf8 = clipUtf8(value.toUtf8(), maxBytes);
        u8(static_cast<int>(utf8.size()));
        m_bytes.append(utf8);
        return *this;
    }

    Writer &bytes(const QByteArray &value)
    {
        m_bytes.append(value);
        return *this;
    }

    [[nodiscard]] QByteArray frame(MessageType type) const
    {
        return encodeFrame(type, m_bytes);
    }

private:
    template <typename T> void append(T value)
    {
        m_bytes.append(reinterpret_cast<const char *>(&value), sizeof(T));
    }

    QByteArray m_bytes;
};

// Reads fields in order. Running past the end marks the read failed rather than throwing,
// so a decoder reads everything and checks ok() once.
class Reader
{
public:
    explicit Reader(const QByteArray &bytes) : m_bytes(bytes) {}

    [[nodiscard]] bool ok() const
    {
        return m_ok;
    }

    [[nodiscard]] qsizetype remaining() const
    {
        return m_ok ? m_bytes.size() - m_position : 0;
    }

    int u8()
    {
        if (!take(1))
            return 0;
        return static_cast<quint8>(m_bytes.at(m_position - 1));
    }

    int u16()
    {
        if (!take(2))
            return 0;
        return qFromLittleEndian<quint16>(m_bytes.constData() + m_position - 2);
    }

    int s16()
    {
        if (!take(2))
            return 0;
        return qFromLittleEndian<qint16>(m_bytes.constData() + m_position - 2);
    }

    quint32 u32()
    {
        if (!take(4))
            return 0;
        return qFromLittleEndian<quint32>(m_bytes.constData() + m_position - 4);
    }

    int s8()
    {
        if (!take(1))
            return 0;
        return static_cast<qint8>(m_bytes.at(m_position - 1));
    }

    qint32 s32()
    {
        if (!take(4))
            return 0;
        return qFromLittleEndian<qint32>(m_bytes.constData() + m_position - 4);
    }

    QString text(int maxBytes = kMaxText)
    {
        const int length = u8();
        if (!take(length))
            return {};
        return QString::fromUtf8(clipUtf8(m_bytes.mid(m_position - length, length), maxBytes));
    }

    QByteArray rest()
    {
        const QByteArray tail = m_bytes.mid(m_position);
        m_position = m_bytes.size();
        return tail;
    }

private:
    bool take(qsizetype count)
    {
        if (!m_ok || m_bytes.size() - m_position < count) {
            m_ok = false;
            return false;
        }
        m_position += count;
        return true;
    }

    const QByteArray &m_bytes;
    qsizetype m_position = 0;
    bool m_ok = true;
};

Maneuver maneuverFromByte(int value)
{
    return value <= kLastManeuver ? static_cast<Maneuver>(value) : Maneuver::None;
}

template <typename T> std::optional<T> valid(const Reader &in, T message)
{
    if (!in.ok())
        return std::nullopt;
    return message;
}

} // namespace

quint16 crc16(QByteArrayView bytes)
{
    quint16 crc = 0xFFFF;
    for (const char byte : bytes) {
        crc ^= static_cast<quint16>(static_cast<quint8>(byte) << 8);
        for (int bit = 0; bit < 8; ++bit)
            crc = (crc & 0x8000) ? static_cast<quint16>((crc << 1) ^ 0x1021) : static_cast<quint16>(crc << 1);
    }
    return crc;
}

QByteArray encodeFrame(MessageType type, QByteArrayView payload)
{
    if (payload.size() > kMaxPayload)
        return {};

    QByteArray frame;
    frame.reserve(kHeaderSize + payload.size() + kCrcSize);
    frame.append(static_cast<char>(kStartOfFrame));
    frame.append(static_cast<char>(kVersion));
    frame.append(static_cast<char>(type));
    const auto length = qToLittleEndian(static_cast<quint16>(payload.size()));
    frame.append(reinterpret_cast<const char *>(&length), sizeof(length));
    frame.append(payload);
    const auto crc = qToLittleEndian(crc16(QByteArrayView(frame).sliced(1)));
    frame.append(reinterpret_cast<const char *>(&crc), sizeof(crc));
    return frame;
}

QByteArray clipUtf8(const QByteArray &utf8, int maxBytes)
{
    if (utf8.size() <= maxBytes)
        return utf8;
    qsizetype cut = maxBytes;
    while (cut > 0 && (static_cast<quint8>(utf8.at(cut)) & 0xC0) == 0x80)
        --cut;
    return utf8.left(cut);
}

QList<Frame> FrameParser::feed(const QByteArray &bytes)
{
    m_buffer.append(bytes);

    QList<Frame> frames;
    while (!m_buffer.isEmpty()) {
        if (static_cast<quint8>(m_buffer.at(0)) != kStartOfFrame) {
            skipToNextStart(1);
            continue;
        }
        if (m_buffer.size() < kHeaderSize)
            break;

        const int length = qFromLittleEndian<quint16>(m_buffer.constData() + 3);
        if (static_cast<quint8>(m_buffer.at(1)) != kVersion || length > kMaxPayload) {
            ++m_dropped;
            skipToNextStart(1);
            continue;
        }

        const qsizetype frameSize = kHeaderSize + length + kCrcSize;
        if (m_buffer.size() < frameSize)
            break;

        const quint16 sent = qFromLittleEndian<quint16>(m_buffer.constData() + kHeaderSize + length);
        if (sent != crc16(QByteArrayView(m_buffer).sliced(1, kHeaderSize - 1 + length))) {
            ++m_dropped;
            skipToNextStart(1);
            continue;
        }

        frames.append({static_cast<MessageType>(m_buffer.at(2)), m_buffer.mid(kHeaderSize, length)});
        m_buffer.remove(0, frameSize);
    }
    return frames;
}

void FrameParser::reset()
{
    m_buffer.clear();
}

int FrameParser::droppedFrames() const
{
    return m_dropped;
}

void FrameParser::skipToNextStart(qsizetype from)
{
    const qsizetype next = m_buffer.indexOf(static_cast<char>(kStartOfFrame), from);
    m_buffer.remove(0, next < 0 ? m_buffer.size() : next);
}

std::optional<NavUpdate> decodeNavUpdate(const QByteArray &payload)
{
    Reader in(payload);
    NavUpdate message;
    message.maneuver = maneuverFromByte(in.u8());
    message.roundaboutExit = in.u8();
    message.distanceMetres = in.u32();
    message.remainingMetres = in.u32();
    message.etaMinutes = in.u16();
    message.laneMask = in.u8();
    message.recommendedLaneMask = in.u8();
    message.road = in.text();
    if (in.remaining() >= 5) {
        NextManeuver next;
        next.maneuver = maneuverFromByte(in.u8());
        next.distanceMetres = in.u32();
        message.next = next;
    }
    return valid(in, message);
}

std::optional<CallState> decodeCallState(const QByteArray &payload)
{
    Reader in(payload);
    CallState message;
    const int status = in.u8();
    message.status =
        status <= static_cast<int>(CallStatus::Active) ? static_cast<CallStatus>(status) : CallStatus::Idle;
    message.caller = in.text();
    if (in.remaining() >= 3) {
        CallDetail detail;
        detail.elapsedSeconds = in.u16();
        const int flags = in.u8();
        detail.outgoing = (flags & 0x01) != 0;
        detail.muted = (flags & 0x02) != 0;
        message.detail = detail;
    }
    return valid(in, message);
}

std::optional<MediaState> decodeMediaState(const QByteArray &payload)
{
    Reader in(payload);
    MediaState message;
    message.playing = in.u8() != 0;
    message.volumePercent = std::min(in.u8(), 100);
    message.positionSeconds = in.u16();
    message.durationSeconds = in.u16();
    message.title = in.text();
    message.artist = in.text();
    if (!in.ok())
        return std::nullopt;
    if (in.remaining() >= 5) {
        MediaSource source;
        source.app = in.text();
        source.artId = in.u32();
        if (in.ok())
            message.source = source;
    }
    return message;
}

std::optional<Notification> decodeNotification(const QByteArray &payload)
{
    Reader in(payload);
    Notification message;
    message.app = in.u8();
    message.sender = in.text();
    message.message = in.text();
    return valid(in, message);
}

std::optional<ListEntry> decodeListEntry(const QByteArray &payload)
{
    Reader in(payload);
    ListEntry message;
    const int list = in.u8();
    message.list = static_cast<ListKind>(list);
    message.slot = in.u8();
    message.title = in.text();
    message.text = in.text();
    if (list > static_cast<int>(ListKind::Reminders) || message.slot >= kListSlots)
        return std::nullopt;
    return valid(in, message);
}

std::optional<MediaArt> decodeMediaArt(const QByteArray &payload)
{
    Reader in(payload);
    MediaArt message;
    message.artId = in.u32();
    message.offset = in.u16();
    message.total = in.u16();
    message.chunk = in.rest();
    return valid(in, message);
}

std::optional<TimeSync> decodeTimeSync(const QByteArray &payload)
{
    Reader in(payload);
    TimeSync message;
    message.unixSeconds = in.u32();
    message.utcOffsetMinutes = in.s16();
    return valid(in, message);
}

std::optional<PhoneStatus> decodePhoneStatus(const QByteArray &payload)
{
    Reader in(payload);
    PhoneStatus message;
    message.batteryPercent = std::min(in.u8(), 100);
    message.signalBars = std::min(in.u8(), 4);
    message.internet = in.u8() != 0;
    if (in.remaining() >= 1)
        message.charging = in.u8() != 0;
    return valid(in, message);
}

QByteArray encode(const NavUpdate &message)
{
    Writer out;
    out.u8(static_cast<int>(message.maneuver))
        .u8(message.roundaboutExit)
        .u32(message.distanceMetres)
        .u32(message.remainingMetres)
        .u16(message.etaMinutes)
        .u8(message.laneMask)
        .u8(message.recommendedLaneMask)
        .text(message.road);
    if (message.next)
        out.u8(static_cast<int>(message.next->maneuver)).u32(message.next->distanceMetres);
    return out.frame(MessageType::NavUpdate);
}

QByteArray encode(const CallState &message)
{
    Writer out;
    out.u8(static_cast<int>(message.status)).text(message.caller);
    if (message.detail) {
        const int flags = (message.detail->outgoing ? 0x01 : 0) | (message.detail->muted ? 0x02 : 0);
        out.u16(message.detail->elapsedSeconds).u8(flags);
    }
    return out.frame(MessageType::CallState);
}

QByteArray encode(const MediaState &message)
{
    Writer out;
    out.u8(message.playing ? 1 : 0)
        .u8(message.volumePercent)
        .u16(message.positionSeconds)
        .u16(message.durationSeconds)
        .text(message.title)
        .text(message.artist);
    if (message.source)
        out.text(message.source->app).u32(message.source->artId);
    return out.frame(MessageType::MediaState);
}

QByteArray encode(const Notification &message)
{
    return Writer().u8(message.app).text(message.sender).text(message.message).frame(MessageType::Notification);
}

QByteArray encode(const ListEntry &message)
{
    return Writer()
        .u8(static_cast<int>(message.list))
        .u8(message.slot)
        .text(message.title)
        .text(message.text)
        .frame(MessageType::ListEntry);
}

QByteArray encode(const MediaArt &message)
{
    return Writer()
        .u32(message.artId)
        .u16(message.offset)
        .u16(message.total)
        .bytes(message.chunk)
        .frame(MessageType::MediaArt);
}

QByteArray encode(const TimeSync &message)
{
    return Writer().u32(message.unixSeconds).s16(message.utcOffsetMinutes).frame(MessageType::TimeSync);
}

QByteArray encode(const PhoneStatus &message)
{
    Writer out;
    out.u8(message.batteryPercent).u8(message.signalBars).u8(message.internet ? 1 : 0);
    if (message.charging)
        out.u8(*message.charging ? 1 : 0);
    return out.frame(MessageType::PhoneStatus);
}

QByteArray encodeNavStop()
{
    return encodeFrame(MessageType::NavStop);
}

QByteArray encodeHeartbeat()
{
    return encodeFrame(MessageType::Heartbeat);
}

QByteArray encodeMediaCommand(MediaCommand command)
{
    return Writer().u8(static_cast<int>(command)).frame(MessageType::MediaCommand);
}

QByteArray encodeCallCommand(CallCommand command, int contactSlot)
{
    Writer out;
    out.u8(static_cast<int>(command));
    if (command == CallCommand::CallContact)
        out.u8(contactSlot);
    return out.frame(MessageType::CallCommand);
}

QByteArray encode(const VehicleStatus &message)
{
    Writer out;
    out.u8(message.stateOfChargePercent)
        .u16(message.rangeKm)
        .u32(message.odometerHectometres)
        .u32(message.tripAHectometres)
        .u8(static_cast<int>(message.charging))
        .u8(message.rideMode)
        .u8(message.gear)
        .u16(message.activeFaults);
    if (const auto &d = message.details) {
        out.u32(d->tripBHectometres)
            .s32(d->kmToService)
            .u16(d->tripAWhPerKm)
            .u16(d->tripAAverageKmhX10)
            .u16(d->tripAMaxKmh)
            .s8(d->batteryC)
            .s8(d->motorC)
            .u8(d->frontTyreBarX10)
            .u8(d->rearTyreBarX10)
            .u16(d->minutesToCharge)
            .u8((d->serviceDue ? 1 : 0) | (d->temperaturesValid ? 2 : 0));
    }
    return out.frame(MessageType::VehicleStatus);
}

QByteArray encode(const ClusterInfo &message)
{
    return Writer()
        .u8(message.minorVersion)
        .u32(message.features)
        .text(message.model)
        .text(message.firmware)
        .frame(MessageType::ClusterInfo);
}

std::optional<VehicleStatus> decodeVehicleStatus(const QByteArray &payload)
{
    Reader in(payload);
    VehicleStatus message;
    message.stateOfChargePercent = in.u8();
    message.rangeKm = in.u16();
    message.odometerHectometres = in.u32();
    message.tripAHectometres = in.u32();
    message.charging = static_cast<ChargeState>(std::min(in.u8(), static_cast<int>(ChargeState::Full)));
    message.rideMode = in.u8();
    message.gear = in.u8();
    message.activeFaults = in.u16();
    if (in.ok() && in.remaining() >= 21) {
        VehicleStatus::Details d;
        d.tripBHectometres = in.u32();
        d.kmToService = in.s32();
        d.tripAWhPerKm = in.u16();
        d.tripAAverageKmhX10 = in.u16();
        d.tripAMaxKmh = in.u16();
        d.batteryC = in.s8();
        d.motorC = in.s8();
        d.frontTyreBarX10 = in.u8();
        d.rearTyreBarX10 = in.u8();
        d.minutesToCharge = in.u16();
        const int flags = in.u8();
        d.serviceDue = flags & 1;
        d.temperaturesValid = flags & 2;
        message.details = d;
    }
    return valid(in, message);
}

std::optional<ClusterInfo> decodeClusterInfo(const QByteArray &payload)
{
    Reader in(payload);
    ClusterInfo message;
    message.minorVersion = in.u8();
    message.features = in.u32();
    message.model = in.text();
    message.firmware = in.text();
    return valid(in, message);
}

std::optional<ClusterCommand> decodeClusterCommand(const QByteArray &payload)
{
    Reader in(payload);
    ClusterCommand message;
    message.command = in.u8();
    message.value = in.u8();
    return valid(in, message);
}

QByteArray encode(const ClusterCommand &message)
{
    return Writer().u8(message.command).u8(message.value).frame(MessageType::ClusterCommand);
}

std::optional<WifiJoin> decodeWifiJoin(const QByteArray &payload)
{
    Reader in(payload);
    WifiJoin message;
    message.ssid = in.text();
    message.password = in.text(kMaxWifiPassword);
    return valid(in, message);
}

QByteArray encode(const WifiJoin &message)
{
    return Writer().text(message.ssid).text(message.password, kMaxWifiPassword).frame(MessageType::WifiJoin);
}

std::optional<FirmwareOffer> decodeFirmwareOffer(const QByteArray &payload)
{
    Reader in(payload);
    FirmwareOffer message;
    message.size = in.u32();
    message.version = in.text();
    return valid(in, message);
}

QByteArray encode(const FirmwareOffer &message)
{
    return Writer().u32(message.size).text(message.version).frame(MessageType::FirmwareOffer);
}

QByteArray encode(const ClusterSettings &message)
{
    return Writer()
        .u8(message.displayMode)
        .u8(message.units)
        .u8(message.brightness)
        .u8(message.clock24 ? 1 : 0)
        .u8(message.locked ? 1 : 0)
        .u8(message.page)
        .u8(message.dark ? 1 : 0)
        .u8(message.rideMode)
        .u8(message.chargeLimit)
        .u8(message.volume)
        .u8(message.arrowStyle)
        .u8(message.language)
        .frame(MessageType::ClusterSettings);
}

std::optional<ClusterSettings> decodeClusterSettings(const QByteArray &payload)
{
    Reader in(payload);
    ClusterSettings message;
    message.displayMode = in.u8();
    message.units = in.u8();
    message.brightness = in.u8();
    message.clock24 = in.u8() != 0;
    message.locked = in.u8() != 0;
    message.page = in.u8();
    message.dark = in.u8() != 0;
    if (in.ok() && in.remaining() >= 5) {
        message.rideMode = in.u8();
        message.chargeLimit = in.u8();
        message.volume = in.u8();
        message.arrowStyle = in.u8();
        message.language = in.u8();
    }
    return valid(in, message);
}

QByteArray encode(const WifiStatus &message)
{
    return Writer()
        .u8(static_cast<int>(message.state))
        .text(message.ssid)
        .text(message.address)
        .s8(message.rssi)
        .u8(static_cast<int>(message.failure))
        .u8(message.scanning ? 1 : 0)
        .frame(MessageType::WifiStatus);
}

std::optional<WifiStatus> decodeWifiStatus(const QByteArray &payload)
{
    Reader in(payload);
    WifiStatus message;
    message.state = static_cast<WifiState>(std::min(in.u8(), static_cast<int>(WifiState::Failed)));
    message.ssid = in.text();
    message.address = in.text();
    if (in.ok() && in.remaining() >= 3) {
        message.rssi = in.s8();
        message.failure = static_cast<WifiFailure>(std::min(in.u8(), static_cast<int>(WifiFailure::Refused)));
        message.scanning = in.u8() != 0;
    }
    return valid(in, message);
}

QByteArray encode(const WifiNetwork &message)
{
    return Writer()
        .u8(message.index)
        .u8(message.total)
        .s8(message.rssi)
        .u8((message.secured ? 1 : 0) | (message.current ? 2 : 0))
        .text(message.ssid)
        .frame(MessageType::WifiNetwork);
}

std::optional<WifiNetwork> decodeWifiNetwork(const QByteArray &payload)
{
    Reader in(payload);
    WifiNetwork message;
    message.index = in.u8();
    message.total = in.u8();
    message.rssi = in.s8();
    const int flags = in.u8();
    message.secured = flags & 1;
    message.current = flags & 2;
    message.ssid = in.text();
    return valid(in, message);
}

QByteArray encode(const FaultEntry &message)
{
    return Writer()
        .u8(message.index)
        .u8(message.total)
        .u16(message.code)
        .u8((message.active ? 1 : 0) | (message.critical ? 2 : 0))
        .u16(message.count)
        .text(message.title)
        .text(message.detail)
        .text(message.firstSeen)
        .text(message.lastSeen)
        .frame(MessageType::FaultEntry);
}

std::optional<FaultEntry> decodeFaultEntry(const QByteArray &payload)
{
    Reader in(payload);
    FaultEntry message;
    message.index = in.u8();
    message.total = in.u8();
    message.code = in.u16();
    const int flags = in.u8();
    message.active = flags & 1;
    message.critical = flags & 2;
    message.count = in.u16();
    message.title = in.text();
    message.detail = in.text();
    message.firstSeen = in.text();
    message.lastSeen = in.text();
    return valid(in, message);
}

QByteArray encode(const FirmwareStatus &message)
{
    return Writer()
        .u8(static_cast<int>(message.state))
        .u8(message.percent)
        .u16(message.port)
        .text(message.address)
        .text(message.token)
        .text(message.message)
        .frame(MessageType::FirmwareStatus);
}

std::optional<FirmwareStatus> decodeFirmwareStatus(const QByteArray &payload)
{
    Reader in(payload);
    FirmwareStatus message;
    message.state = static_cast<FirmwareState>(std::min(in.u8(), static_cast<int>(FirmwareState::Failed)));
    message.percent = std::min(in.u8(), 100);
    message.port = in.u16();
    message.address = in.text();
    message.token = in.text();
    message.message = in.text();
    return valid(in, message);
}

void ArtAssembler::expect(quint32 artId)
{
    if (artId == m_artId)
        return;
    m_artId = artId;
    m_total = 0;
    m_bytes.clear();
    m_complete = false;
}

bool ArtAssembler::add(const MediaArt &chunk)
{
    if (m_artId == 0 || chunk.artId != m_artId || m_complete)
        return false;
    if (chunk.total <= 0 || chunk.total > kMaxArtBytes)
        return false;

    // Chunks come in order over one link; a gap means one was lost, so wait for the next offset 0.
    if (chunk.offset == 0) {
        m_total = chunk.total;
        m_bytes.clear();
    }
    if (chunk.total != m_total || chunk.offset != m_bytes.size() || chunk.offset + chunk.chunk.size() > m_total)
        return false;

    m_bytes.append(chunk.chunk);
    m_complete = m_bytes.size() == m_total;
    return m_complete;
}

quint32 ArtAssembler::artId() const
{
    return m_artId;
}

bool ArtAssembler::isComplete() const
{
    return m_complete;
}

QByteArray ArtAssembler::picture() const
{
    return m_complete ? m_bytes : QByteArray();
}

} // namespace phonelink::wire

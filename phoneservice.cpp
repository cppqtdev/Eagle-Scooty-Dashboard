#include "phoneservice.h"

#include <QTime>

namespace {

struct Track {
    const char *title;
    const char *artist;
    const char *album;
    int seconds;
};

// Original placeholder titles, so the demo never shows someone else's music.
const Track kPlaylist[] = {
    {"City Lights", "Skyline", "Night Drive", 224},
    {"Monsoon Highway", "The Open Road", "Coastal", 198},
    {"Electric Morning", "Volt Avenue", "Charge", 241},
    {"Ring Road", "Skyline", "Night Drive", 187},
};
constexpr int kTracks = int(sizeof(kPlaylist) / sizeof(kPlaylist[0]));

QVariantMap contact(const char *name, const char *number, bool favourite)
{
    return {{QStringLiteral("name"), QString::fromUtf8(name)},
            {QStringLiteral("number"), QString::fromUtf8(number)},
            {QStringLiteral("favourite"), favourite}};
}

} // namespace

PhoneService::PhoneService(QObject *parent)
    : QObject(parent)
{
    m_contacts = {contact("Priya Sharma", "+91 98100 22451", true), contact("Rahul Verma", "+91 98201 77310", true),
                  contact("Home", "+91 124 400 1122", true), contact("Office", "+91 80 4120 9000", false),
                  contact("Ananya Iyer", "+91 99000 43218", false), contact("Service Centre", "+91 80 4718 2200", false),
                  contact("Vikram Singh", "+91 97170 66542", false)};

    addRecent(QStringLiteral("Priya Sharma"), QStringLiteral("+91 98100 22451"), QStringLiteral("incoming"));
    addRecent(QStringLiteral("Office"), QStringLiteral("+91 80 4120 9000"), QStringLiteral("outgoing"));
    addRecent(QStringLiteral("Rahul Verma"), QStringLiteral("+91 98201 77310"), QStringLiteral("missed"));

    m_callTimer.setInterval(1000);
    connect(&m_callTimer, &QTimer::timeout, this, [this] {
        ++m_callSeconds;
        emit callTimeChanged();
    });

    m_ringTimer.setSingleShot(true);
    m_ringTimer.setInterval(20'000);
    connect(&m_ringTimer, &QTimer::timeout, this, [this] {
        if (m_callState != Incoming)
            return;
        addRecent(m_callerName, m_callerNumber, QStringLiteral("missed"));
        emit callMissed(m_callerName);
        setCall(Idle, {}, {});
    });

    m_dialTimer.setSingleShot(true);
    m_dialTimer.setInterval(3500);
    connect(&m_dialTimer, &QTimer::timeout, this, [this] {
        if (m_callState == Dialing)
            setCall(Active, m_callerName, m_callerNumber);
    });

    m_mediaTimer.setInterval(1000);
    connect(&m_mediaTimer, &QTimer::timeout, this, [this] {
        if (!m_playing || m_callState != Idle)
            return;
        if (++m_position >= durationSeconds())
            next();
        else
            emit positionChanged();
    });
    m_mediaTimer.start();
}

QString PhoneService::trackTitle() const { return QString::fromUtf8(kPlaylist[m_track].title); }
QString PhoneService::trackArtist() const { return QString::fromUtf8(kPlaylist[m_track].artist); }
QString PhoneService::trackAlbum() const { return QString::fromUtf8(kPlaylist[m_track].album); }
int PhoneService::durationSeconds() const { return kPlaylist[m_track].seconds; }

QString PhoneService::formatDuration(int seconds) const
{
    seconds = qMax(0, seconds);
    return QStringLiteral("%1:%2").arg(seconds / 60, 2, 10, QLatin1Char('0')).arg(seconds % 60, 2, 10, QLatin1Char('0'));
}

void PhoneService::setConnected(bool connected, const QString &deviceName)
{
    m_connected = connected;
    if (!deviceName.isEmpty())
        m_deviceName = deviceName;
    if (!connected)
        setCall(Idle, {}, {});
    emit connectionChanged();
}

void PhoneService::answer()
{
    if (m_callState == Incoming) {
        addRecent(m_callerName, m_callerNumber, QStringLiteral("incoming"));
        setCall(Active, m_callerName, m_callerNumber);
    }
}

void PhoneService::decline()
{
    if (m_callState == Incoming) {
        addRecent(m_callerName, m_callerNumber, QStringLiteral("missed"));
        setCall(Idle, {}, {});
    }
}

void PhoneService::hangUp()
{
    if (m_callState == Active || m_callState == Dialing)
        setCall(Idle, {}, {});
}

void PhoneService::dial(const QString &number)
{
    const QString trimmed = number.trimmed();
    if (!m_connected || trimmed.isEmpty() || m_callState != Idle)
        return;
    addRecent(nameFor(trimmed), trimmed, QStringLiteral("outgoing"));
    setCall(Dialing, nameFor(trimmed), trimmed);
    m_dialTimer.start();
}

void PhoneService::toggleMute()
{
    if (m_callState != Active)
        return;
    m_muted = !m_muted;
    emit callChanged();
}

void PhoneService::playPause()
{
    m_playing = !m_playing;
    emit mediaChanged();
}

void PhoneService::next()
{
    m_track = (m_track + 1) % kTracks;
    m_position = 0;
    emit mediaChanged();
    emit positionChanged();
}

void PhoneService::previous()
{
    // Like a car stereo: back to the start first, then to the previous track.
    if (m_position > 3) {
        m_position = 0;
    } else {
        m_track = (m_track + kTracks - 1) % kTracks;
        m_position = 0;
        emit mediaChanged();
    }
    emit positionChanged();
}

void PhoneService::setVolume(int volume)
{
    volume = qBound(0, volume, 100);
    if (m_volume == volume)
        return;
    m_volume = volume;
    emit volumeChanged();
}

void PhoneService::simulateIncomingCall()
{
    if (!m_connected || m_callState != Idle)
        return;
    const QVariantMap who = m_contacts.at(m_nextCaller++ % 3).toMap();
    setCall(Incoming, who.value(QStringLiteral("name")).toString(), who.value(QStringLiteral("number")).toString());
    m_ringTimer.start();
}

void PhoneService::simulateMessage()
{
    static const char *const kTexts[] = {"Reached the office? Call me when free.",
                                         "Your service booking is confirmed for Saturday 10 AM.",
                                         "Running 10 min late, wait at the gate."};
    const QVariantMap who = m_contacts.at(m_nextMessage % 3).toMap();
    emit messageReceived(who.value(QStringLiteral("name")).toString(),
                         QString::fromUtf8(kTexts[m_nextMessage++ % 3]));
}

void PhoneService::setCall(CallState state, const QString &name, const QString &number)
{
    if (state != Incoming)
        m_ringTimer.stop();
    if (state != Dialing)
        m_dialTimer.stop();
    if (state == Active && m_callState != Active) {
        m_callSeconds = 0;
        m_callTimer.start();
        emit callTimeChanged();
    } else if (state != Active) {
        m_callTimer.stop();
    }
    if (state == Idle)
        m_muted = false;
    m_callState = state;
    m_callerName = name;
    m_callerNumber = number;
    emit callChanged();
}

void PhoneService::addRecent(const QString &name, const QString &number, const QString &kind)
{
    m_recents.prepend(QVariantMap{{QStringLiteral("name"), name},
                                  {QStringLiteral("number"), number},
                                  {QStringLiteral("kind"), kind},
                                  {QStringLiteral("time"), QTime::currentTime().toString(QStringLiteral("hh:mm"))}});
    while (m_recents.size() > 20)
        m_recents.removeLast();
    emit recentsChanged();
}

QString PhoneService::nameFor(const QString &number) const
{
    for (const QVariant &entry : m_contacts) {
        const QVariantMap map = entry.toMap();
        if (map.value(QStringLiteral("number")).toString() == number)
            return map.value(QStringLiteral("name")).toString();
    }
    return number;
}

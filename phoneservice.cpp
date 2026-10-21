#include "phoneservice.h"
#include "phonelink/iphonelink.h"

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

QString PhoneService::trackTitle() const { return m_link ? m_liveTitle : QString::fromUtf8(kPlaylist[m_track].title); }
QString PhoneService::trackArtist() const { return m_link ? m_liveArtist : QString::fromUtf8(kPlaylist[m_track].artist); }
QString PhoneService::trackAlbum() const { return m_link ? QString() : QString::fromUtf8(kPlaylist[m_track].album); }
int PhoneService::durationSeconds() const { return m_link ? m_liveDuration : kPlaylist[m_track].seconds; }
PhoneService::PlayerState PhoneService::playerState() const
{
    if (!m_connected || trackTitle().isEmpty())
        return NoSource;
    return m_playing && m_callState == Idle ? Playing : Paused;
}

QString PhoneService::trackSource() const { return m_link ? m_liveSource : QString(); }

QString PhoneService::artworkUrl() const
{
    // The id in the URL changes with the picture, so QML never shows a stale cover.
    return m_artReady ? QStringLiteral("image://phoneart/%1").arg(m_artId) : QString();
}

void PhoneService::attachLink(phonelink::IPhoneLink *link)
{
    m_link = link;
    m_mediaTimer.stop();
    m_ringTimer.stop();
    m_dialTimer.stop();
    m_recents.clear();
    emit recentsChanged();

    connect(link, &phonelink::IPhoneLink::connectionChanged, this, &PhoneService::syncConnection);
    connect(link, &phonelink::IPhoneLink::callChanged, this, &PhoneService::syncCall);
    connect(link, &phonelink::IPhoneLink::mediaChanged, this, &PhoneService::syncMedia);
    connect(link, &phonelink::IPhoneLink::listsChanged, this, &PhoneService::syncContacts);
    connect(link, &phonelink::IPhoneLink::albumArtChanged, this, [this] {
        const bool ready = !m_link->albumArt().isEmpty();
        if (ready != m_artReady || m_artId != m_link->media().artId) {
            m_artReady = ready;
            m_artId = m_link->media().artId;
            emit artworkChanged();
        }
    });
    connect(link, &phonelink::IPhoneLink::missedCall, this, [this](const QString &caller) {
        addRecent(caller, QString(), QStringLiteral("missed"));
        emit callMissed(caller);
    });
    connect(link, &phonelink::IPhoneLink::notificationChanged, this, [this] {
        if (const auto note = m_link->notification(); note && note->app != 6) // 6: missed call, shown already
            emit messageReceived(note->sender, note->message);
    });

    syncConnection();
    syncCall();
    syncMedia();
    syncContacts();
}

void PhoneService::syncConnection()
{
    m_connected = m_link->isConnected();
    m_deviceName = m_connected ? tr("Ride app") : QString();
    m_phoneBattery = m_link->batteryPercent();
    m_signalBars = m_link->signalBars();
    emit connectionChanged();
    emit mediaChanged(); // no phone, no source
}

void PhoneService::syncCall()
{
    const phonelink::CallInfo call = m_link->call();
    CallState state = Idle;
    if (call.state == phonelink::CallState::Incoming)
        state = Incoming;
    else if (call.state == phonelink::CallState::Active)
        state = call.outgoing && call.durationSeconds == 0 ? Dialing : Active;

    if (state != m_callState && m_callState == Idle && state != Idle)
        addRecent(call.callerName, QString(), state == Incoming ? QStringLiteral("incoming") : QStringLiteral("outgoing"));
    const bool changed = state != m_callState || call.callerName != m_callerName || call.muted != m_muted;
    m_callState = state;
    m_callerName = call.callerName;
    m_callerNumber.clear();
    m_muted = call.muted;
    if (m_callSeconds != call.durationSeconds) {
        m_callSeconds = call.durationSeconds;
        emit callTimeChanged();
    }
    if (changed) {
        emit callChanged();
        emit mediaChanged(); // the music holds while a call is on
    }
}

void PhoneService::syncMedia()
{
    const phonelink::MediaInfo media = m_link->media();
    const bool changed = media.title != m_liveTitle || media.artist != m_liveArtist || media.source != m_liveSource
                         || media.durationSeconds != m_liveDuration || media.playing != m_playing;
    m_liveTitle = media.title;
    m_liveArtist = media.artist;
    m_liveSource = media.source;
    m_liveDuration = media.durationSeconds;
    m_playing = media.playing;
    if (changed)
        emit mediaChanged();
    if (m_position != media.positionSeconds) {
        m_position = media.positionSeconds;
        emit positionChanged();
    }
    if (media.artId != m_artId) {
        m_artId = media.artId;
        m_artReady = media.artId != 0 && !m_link->albumArt().isEmpty();
        emit artworkChanged();
    }
}

void PhoneService::syncContacts()
{
    // The app keeps three favourites for the cluster; they can be called by slot.
    m_contacts.clear();
    const auto favourites = m_link->contacts();
    for (const auto &entry : favourites) {
        if (entry.title.isEmpty())
            continue;
        m_contacts.append(QVariantMap{{QStringLiteral("name"), entry.title},
                                      {QStringLiteral("number"), entry.text},
                                      {QStringLiteral("favourite"), true}});
    }
    emit contactsChanged();
}

QString PhoneService::formatDuration(int seconds) const
{
    seconds = qMax(0, seconds);
    return QStringLiteral("%1:%2").arg(seconds / 60).arg(seconds % 60, 2, 10, QLatin1Char('0'));
}

void PhoneService::setConnected(bool connected, const QString &deviceName)
{
    m_connected = connected;
    if (!deviceName.isEmpty())
        m_deviceName = deviceName;
    if (!connected)
        setCall(Idle, {}, {});
    emit connectionChanged();
    emit mediaChanged(); // no phone, no source
}

void PhoneService::answer()
{
    if (m_link) {
        m_link->answerCall();
        return;
    }
    if (m_callState == Incoming) {
        addRecent(m_callerName, m_callerNumber, QStringLiteral("incoming"));
        setCall(Active, m_callerName, m_callerNumber);
    }
}

void PhoneService::decline()
{
    if (m_link) {
        m_link->declineCall();
        return;
    }
    if (m_callState == Incoming) {
        addRecent(m_callerName, m_callerNumber, QStringLiteral("missed"));
        setCall(Idle, {}, {});
    }
}

void PhoneService::hangUp()
{
    if (m_link) {
        m_link->declineCall(); // decline doubles as hang up on the wire
        return;
    }
    if (m_callState == Active || m_callState == Dialing)
        setCall(Idle, {}, {});
}

void PhoneService::dial(const QString &number)
{
    const QString trimmed = number.trimmed();
    if (!m_connected || trimmed.isEmpty() || m_callState != Idle)
        return;
    if (m_link) {
        // The app places calls to its favourites only, by their slot.
        const auto favourites = m_link->contacts();
        for (int slot = 0; slot < favourites.size(); ++slot) {
            if (favourites.at(slot).text == trimmed || favourites.at(slot).title == trimmed) {
                m_link->callContact(slot);
                return;
            }
        }
        return;
    }
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
    if (m_link) {
        m_link->togglePlayback();
        return;
    }
    m_playing = !m_playing;
    emit mediaChanged();
}

void PhoneService::next()
{
    if (m_link) {
        m_link->nextTrack();
        return;
    }
    m_track = (m_track + 1) % kTracks;
    m_position = 0;
    emit mediaChanged();
    emit positionChanged();
}

void PhoneService::previous()
{
    if (m_link) {
        m_link->previousTrack();
        return;
    }
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
    if (m_link || m_contacts.size() < 3 || !m_connected || m_callState != Idle)
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
    emit mediaChanged(); // the music holds while a call is on
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

#pragma once

#include <QObject>
#include <QTimer>
#include <QVariantList>

// The rider's phone as the dashboard sees it: connection, calls, media and the
// contact lists. The calls and media come from the phone over Bluetooth (HFP and
// AVRCP on the board); on the desk a built-in phone plays the same part.
class PhoneService final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool connected READ connected NOTIFY connectionChanged)
    Q_PROPERTY(QString deviceName READ deviceName NOTIFY connectionChanged)
    Q_PROPERTY(int phoneBattery READ phoneBattery NOTIFY connectionChanged)
    Q_PROPERTY(int signalBars READ signalBars NOTIFY connectionChanged)

    Q_PROPERTY(CallState callState READ callState NOTIFY callChanged)
    Q_PROPERTY(QString callerName READ callerName NOTIFY callChanged)
    Q_PROPERTY(QString callerNumber READ callerNumber NOTIFY callChanged)
    Q_PROPERTY(int callSeconds READ callSeconds NOTIFY callTimeChanged)
    Q_PROPERTY(bool muted READ muted NOTIFY callChanged)

    Q_PROPERTY(QString trackTitle READ trackTitle NOTIFY mediaChanged)
    Q_PROPERTY(QString trackArtist READ trackArtist NOTIFY mediaChanged)
    Q_PROPERTY(QString trackAlbum READ trackAlbum NOTIFY mediaChanged)
    Q_PROPERTY(bool playing READ playing NOTIFY mediaChanged)
    Q_PROPERTY(int positionSeconds READ positionSeconds NOTIFY positionChanged)
    Q_PROPERTY(int durationSeconds READ durationSeconds NOTIFY mediaChanged)
    Q_PROPERTY(int volume READ volume WRITE setVolume NOTIFY volumeChanged)

    Q_PROPERTY(QVariantList recents READ recents NOTIFY recentsChanged)
    Q_PROPERTY(QVariantList contacts READ contacts CONSTANT)

public:
    enum CallState { Idle, Incoming, Dialing, Active };
    Q_ENUM(CallState)

    explicit PhoneService(QObject *parent = nullptr);

    bool connected() const { return m_connected; }
    QString deviceName() const { return m_deviceName; }
    int phoneBattery() const { return m_phoneBattery; }
    int signalBars() const { return m_signalBars; }

    CallState callState() const { return m_callState; }
    QString callerName() const { return m_callerName; }
    QString callerNumber() const { return m_callerNumber; }
    int callSeconds() const { return m_callSeconds; }
    bool muted() const { return m_muted; }

    QString trackTitle() const;
    QString trackArtist() const;
    QString trackAlbum() const;
    bool playing() const { return m_playing; }
    int positionSeconds() const { return m_position; }
    int durationSeconds() const;
    int volume() const { return m_volume; }

    QVariantList recents() const { return m_recents; }
    QVariantList contacts() const { return m_contacts; }

    Q_INVOKABLE QString formatDuration(int seconds) const;

public slots:
    void setConnected(bool connected, const QString &deviceName = QString());
    void answer();
    void decline();
    void hangUp();
    void dial(const QString &number);
    void toggleMute();
    void playPause();
    void next();
    void previous();
    void setVolume(int volume);
    void simulateIncomingCall();
    void simulateMessage();

signals:
    void connectionChanged();
    void callChanged();
    void callTimeChanged();
    void mediaChanged();
    void positionChanged();
    void volumeChanged();
    void recentsChanged();
    // A text the rider should see; the dashboard shows it as an information banner.
    void messageReceived(const QString &from, const QString &text);
    void callMissed(const QString &name);

private:
    void setCall(CallState state, const QString &name, const QString &number);
    void addRecent(const QString &name, const QString &number, const QString &kind);
    QString nameFor(const QString &number) const;

    bool m_connected = true;
    QString m_deviceName = QStringLiteral("Pixel 8");
    int m_phoneBattery = 78;
    int m_signalBars = 3;

    CallState m_callState = Idle;
    QString m_callerName;
    QString m_callerNumber;
    int m_callSeconds = 0;
    bool m_muted = false;
    QTimer m_callTimer;
    QTimer m_ringTimer;   // an unanswered call becomes a missed call
    QTimer m_dialTimer;   // the other side picks up

    int m_track = 0;
    bool m_playing = true;
    int m_position = 42;
    int m_volume = 60;
    QTimer m_mediaTimer;

    QVariantList m_recents;
    QVariantList m_contacts;
    int m_nextCaller = 0;
    int m_nextMessage = 0;
};

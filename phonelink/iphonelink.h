#pragma once

#include "phonetypes.h"

#include <QByteArray>
#include <QList>
#include <QObject>

#include <optional>

namespace phonelink {

// The rider's phone: call state, music and turn-by-turn from the companion app (docs/PhoneLink.md).
class IPhoneLink : public QObject
{
    Q_OBJECT
    Q_DISABLE_COPY_MOVE(IPhoneLink)

public:
    explicit IPhoneLink(QObject *parent = nullptr);
    ~IPhoneLink() override;

    [[nodiscard]] virtual bool isConnected() const = 0;
    [[nodiscard]] virtual int signalBars() const = 0;     // 0..4
    [[nodiscard]] virtual int batteryPercent() const = 0; // the phone's own battery
    [[nodiscard]] virtual bool headsetConnected() const = 0;
    [[nodiscard]] virtual CallInfo call() const = 0;
    [[nodiscard]] virtual MediaInfo media() const = 0;
    [[nodiscard]] virtual GuidanceInfo guidance() const = 0;

    // What only the companion app provides. A link without it keeps these defaults.
    [[nodiscard]] virtual bool phoneCharging() const;
    [[nodiscard]] virtual QByteArray albumArt() const; // encoded cover of media().artId, empty until whole
    [[nodiscard]] virtual std::optional<PhoneNotification> notification() const; // the latest
    [[nodiscard]] virtual QList<PhoneListEntry> contacts() const;
    [[nodiscard]] virtual QList<PhoneListEntry> reminders() const;

public slots:
    virtual void start() = 0;
    virtual void stop() = 0;
    virtual void setEnabled(bool enabled) = 0; // the Bluetooth switch in settings

    virtual void answerCall() = 0;
    virtual void declineCall() = 0;
    virtual void togglePlayback() = 0;
    virtual void nextTrack() = 0;
    virtual void previousTrack() = 0;
    virtual void callContact(int slot);
    virtual void publishVehicle(const phonelink::VehicleSummary &summary);
    // The cluster's settings as (key, value) pairs (wire::setting), for the app to show.
    virtual void publishSettings(const QList<std::pair<int, int>> &values);

signals:
    void connectionChanged();
    void callChanged();
    void missedCall(const QString &caller); // rang out unanswered
    void mediaChanged();
    void guidanceChanged();
    void albumArtChanged();
    void notificationChanged();
    void listsChanged();
    // The app asks to change a setting; the cluster decides whether to.
    void settingRequested(int key, int value);
};

} // namespace phonelink

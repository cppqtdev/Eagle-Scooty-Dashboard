#pragma once

#include "phonelinkcodec.h"
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
    // What the cluster tells the app beyond vehicle status (protocol 1.2): its settings, its
    // Wi-Fi, the networks a scan found, its trouble codes and a firmware update's progress.
    virtual void publishClusterSettings(const phonelink::wire::ClusterSettings &settings);
    virtual void publishWifiStatus(const phonelink::wire::WifiStatus &status);
    virtual void publishWifiNetworks(const QList<phonelink::wire::WifiNetwork> &networks);
    virtual void publishFaults(const QList<phonelink::wire::FaultEntry> &faults);
    virtual void publishFirmwareStatus(const phonelink::wire::FirmwareStatus &status);

signals:
    void connectionChanged();
    void callChanged();
    void missedCall(const QString &caller); // rang out unanswered
    void mediaChanged();
    void guidanceChanged();
    void albumArtChanged();
    void notificationChanged();
    void listsChanged();
    // What the app asks of the cluster; the cluster decides whether to.
    void commandReceived(int command, int value);           // wire::command
    void wifiJoinRequested(const QString &ssid, const QString &password);
    void firmwareOffered(quint32 size, const QString &version);
};

} // namespace phonelink

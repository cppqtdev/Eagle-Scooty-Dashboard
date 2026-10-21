#pragma once

#include "iphonelink.h"
#include "phonelinkcodec.h"

#include <QElapsedTimer>
#include <QTimer>

#include <array>
#include <memory>
#include <optional>

namespace phonelink {

class IPhoneTransport;

// The companion app over any byte pipe (docs/PhoneLink.md): BLE on the bike, TCP on the bench.
// Heartbeats both ways every 2 s; five silent seconds and the link counts as lost, and everything
// personal it was showing (call, music, route, lists, messages) is cleared.
class ProtocolPhoneLink final : public IPhoneLink
{
    Q_OBJECT
    Q_DISABLE_COPY_MOVE(ProtocolPhoneLink)

public:
    struct Options
    {
        QString model = QStringLiteral("Eagle");
        QString firmware;
        int heartbeatMs = 2000;
        int silenceMs = 5000;
    };

    ProtocolPhoneLink(std::unique_ptr<IPhoneTransport> transport, Options options, QObject *parent = nullptr);
    ~ProtocolPhoneLink() override;

    [[nodiscard]] bool isConnected() const override;
    [[nodiscard]] int signalBars() const override;
    [[nodiscard]] int batteryPercent() const override;
    [[nodiscard]] bool headsetConnected() const override;
    [[nodiscard]] CallInfo call() const override;
    [[nodiscard]] MediaInfo media() const override;
    [[nodiscard]] GuidanceInfo guidance() const override;
    [[nodiscard]] bool phoneCharging() const override;
    [[nodiscard]] QByteArray albumArt() const override;
    [[nodiscard]] std::optional<PhoneNotification> notification() const override;
    [[nodiscard]] QList<PhoneListEntry> contacts() const override;
    [[nodiscard]] QList<PhoneListEntry> reminders() const override;

    // How far the phone's clock is ahead of ours, from its last TimeSync, and its time zone.
    [[nodiscard]] std::optional<qint64> clockOffsetSeconds() const;
    [[nodiscard]] int utcOffsetMinutes() const;

    [[nodiscard]] static quint32 features();

public slots:
    void start() override;
    void stop() override;
    void setEnabled(bool enabled) override;
    void answerCall() override;
    void declineCall() override;
    void togglePlayback() override;
    void nextTrack() override;
    void previousTrack() override;
    void callContact(int slot) override;
    void publishVehicle(const phonelink::VehicleSummary &summary) override;
    void publishClusterSettings(const phonelink::wire::ClusterSettings &settings) override;
    void publishWifiStatus(const phonelink::wire::WifiStatus &status) override;
    void publishWifiNetworks(const QList<phonelink::wire::WifiNetwork> &networks) override;
    void publishFaults(const QList<phonelink::wire::FaultEntry> &faults) override;
    void publishFirmwareStatus(const phonelink::wire::FirmwareStatus &status) override;

private:
    struct PhoneState
    {
        int batteryPercent = 0;
        int signalBars = 0;
        bool internet = false;
        bool charging = false;

        bool operator==(const PhoneState &) const = default;
    };

    void onPeerConnected();
    void onPeerDisconnected();
    void onReceived(const QByteArray &bytes);
    void handle(const wire::Frame &frame);
    void apply(const wire::NavUpdate &message);
    void apply(const wire::CallState &message);
    void apply(const wire::MediaState &message);
    void apply(const wire::MediaArt &message);
    void apply(const wire::ListEntry &message);
    void apply(const wire::TimeSync &message);
    void apply(const wire::PhoneStatus &message);
    void heardFromPhone();
    void loseLink();
    void tick();
    void send(const QByteArray &frame);
    [[nodiscard]] qint64 now() const;

    std::unique_ptr<IPhoneTransport> m_transport;
    Options m_options;
    wire::FrameParser m_parser;
    wire::ArtAssembler m_art;
    QTimer m_heartbeat;
    QTimer m_silence;
    QTimer m_clock;
    QElapsedTimer m_monotonic;
    bool m_enabled = false;
    bool m_linked = false;

    PhoneState m_phone;
    CallInfo m_call;
    wire::CallStatus m_callStatus = wire::CallStatus::Idle;
    qint64 m_callStartedMs = 0;
    bool m_declinedByRider = false;
    MediaInfo m_media;
    qint64 m_mediaPositionAtMs = 0;
    GuidanceInfo m_guidance;
    std::optional<PhoneNotification> m_notification;
    std::array<PhoneListEntry, wire::kListSlots> m_contacts;
    std::array<PhoneListEntry, wire::kListSlots> m_reminders;
    std::optional<qint64> m_clockOffsetSeconds;
    int m_utcOffsetMinutes = 0;
    std::optional<VehicleSummary> m_vehicle;
    std::optional<wire::ClusterSettings> m_settings;
    std::optional<wire::WifiStatus> m_wifi;
    QList<wire::FaultEntry> m_faults;
};

} // namespace phonelink

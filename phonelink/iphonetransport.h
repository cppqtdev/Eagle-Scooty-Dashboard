#pragma once

#include <QByteArray>
#include <QObject>
#include <QString>

namespace phonelink {

// The byte pipe to the companion app: a BLE GATT server on the bike, a TCP socket on the bench.
// One phone at a time. Knows nothing about frames; bytes may arrive in any pieces.
class IPhoneTransport : public QObject
{
    Q_OBJECT
    Q_DISABLE_COPY_MOVE(IPhoneTransport)

public:
    explicit IPhoneTransport(QObject *parent = nullptr);
    ~IPhoneTransport() override;

    // For logs, e.g. "ble" or "tcp:47100".
    [[nodiscard]] virtual QString name() const = 0;

    // A phone is there and listening: subscribed to TX over BLE, connected over TCP.
    [[nodiscard]] virtual bool isPeerConnected() const = 0;

    // False when nothing could be sent, e.g. no phone.
    virtual bool send(const QByteArray &bytes) = 0;

public slots:
    // Advertise or listen until stop().
    virtual void start() = 0;
    virtual void stop() = 0;

signals:
    void peerConnected();
    void peerDisconnected();
    void received(const QByteArray &bytes);
    void errorOccurred(const QString &reason);
};

} // namespace phonelink

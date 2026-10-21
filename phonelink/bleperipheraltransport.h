#pragma once

#include "iphonetransport.h"

#include <QBluetoothUuid>
#include <QLowEnergyController>
#include <QLowEnergyService>

#include <memory>

namespace phonelink {

// The cluster as a BLE peripheral: one GATT service with an RX characteristic the phone writes
// and a TX characteristic it subscribes to (docs/PhoneLink.md). Advertises the service until a
// phone connects, and again as soon as it goes.
class BlePeripheralTransport final : public IPhoneTransport
{
    Q_OBJECT
    Q_DISABLE_COPY_MOVE(BlePeripheralTransport)

public:
    static const QBluetoothUuid kServiceUuid;
    static const QBluetoothUuid kRxUuid;
    static const QBluetoothUuid kTxUuid;

    explicit BlePeripheralTransport(QString localName, QObject *parent = nullptr);
    ~BlePeripheralTransport() override;

    [[nodiscard]] QString name() const override;
    [[nodiscard]] bool isPeerConnected() const override;
    bool send(const QByteArray &bytes) override;

public slots:
    void start() override;
    void stop() override;

private:
    void advertise();
    void onConnected();
    void onDisconnected();
    void onWritten(const QLowEnergyCharacteristic &characteristic, const QByteArray &value);
    void onDescriptorWritten(const QLowEnergyDescriptor &descriptor, const QByteArray &value);
    void subscribed();
    void unsubscribed();

    QString m_localName;
    std::unique_ptr<QLowEnergyController> m_controller;
    std::unique_ptr<QLowEnergyService> m_service;
    bool m_wanted = false;
    bool m_subscribed = false;
};

} // namespace phonelink

#include "bleperipheraltransport.h"

#include "phonelinklog.h"

#include <QLowEnergyAdvertisingData>
#include <QLowEnergyAdvertisingParameters>
#include <QLowEnergyCharacteristicData>
#include <QLowEnergyDescriptorData>
#include <QLowEnergyServiceData>

#include <algorithm>

namespace phonelink {

namespace {

// ATT puts three bytes of its own in every notification.
constexpr int kAttHeader = 3;
constexpr int kDefaultMtu = 23;
constexpr int kMaxAttribute = 512;

QLowEnergyServiceData serviceData()
{
    QLowEnergyCharacteristicData rx;
    rx.setUuid(BlePeripheralTransport::kRxUuid);
    rx.setProperties(QLowEnergyCharacteristic::Write | QLowEnergyCharacteristic::WriteNoResponse);
    rx.setValueLength(0, kMaxAttribute);

    QLowEnergyCharacteristicData tx;
    tx.setUuid(BlePeripheralTransport::kTxUuid);
    tx.setProperties(QLowEnergyCharacteristic::Notify | QLowEnergyCharacteristic::Read);
    tx.setValueLength(0, kMaxAttribute);
    tx.addDescriptor(QLowEnergyDescriptorData(QBluetoothUuid::DescriptorType::ClientCharacteristicConfiguration,
                                              QByteArray(2, '\0')));

    QLowEnergyServiceData service;
    service.setType(QLowEnergyServiceData::ServiceTypePrimary);
    service.setUuid(BlePeripheralTransport::kServiceUuid);
    service.addCharacteristic(rx);
    service.addCharacteristic(tx);
    return service;
}

} // namespace

const QBluetoothUuid BlePeripheralTransport::kServiceUuid{QStringLiteral("6f7e0001-7a3c-4f1b-9e2d-45b1c0de0001")};
const QBluetoothUuid BlePeripheralTransport::kRxUuid{QStringLiteral("6f7e0002-7a3c-4f1b-9e2d-45b1c0de0001")};
const QBluetoothUuid BlePeripheralTransport::kTxUuid{QStringLiteral("6f7e0003-7a3c-4f1b-9e2d-45b1c0de0001")};

BlePeripheralTransport::BlePeripheralTransport(QString localName, QObject *parent)
    : IPhoneTransport(parent), m_localName(std::move(localName))
{
}

BlePeripheralTransport::~BlePeripheralTransport()
{
    stop();
}

QString BlePeripheralTransport::name() const
{
    return QStringLiteral("ble");
}

bool BlePeripheralTransport::isPeerConnected() const
{
    return m_subscribed;
}

bool BlePeripheralTransport::send(const QByteArray &bytes)
{
    if (!m_subscribed || !m_service)
        return false;

    const QLowEnergyCharacteristic tx = m_service->characteristic(kTxUuid);
    if (!tx.isValid())
        return false;

    // A frame longer than one notification goes in pieces; the app reassembles the stream.
    const int mtu = m_controller->mtu() > 0 ? m_controller->mtu() : kDefaultMtu;
    const qsizetype chunk = std::max(1, mtu - kAttHeader);
    for (qsizetype offset = 0; offset < bytes.size(); offset += chunk)
        m_service->writeCharacteristic(tx, bytes.mid(offset, chunk));
    return true;
}

void BlePeripheralTransport::start()
{
    if (m_wanted)
        return;
    m_wanted = true;

    m_controller.reset(QLowEnergyController::createPeripheral());
    connect(m_controller.get(), &QLowEnergyController::connected, this, &BlePeripheralTransport::onConnected);
    connect(m_controller.get(), &QLowEnergyController::disconnected, this, &BlePeripheralTransport::onDisconnected);
    connect(m_controller.get(), &QLowEnergyController::mtuChanged, this,
            [](int mtu) { qCDebug(lcPhoneLink) << "BLE MTU" << mtu; });
    connect(m_controller.get(), &QLowEnergyController::errorOccurred, this,
            [this] { emit errorOccurred(m_controller->errorString()); });
    advertise();
}

void BlePeripheralTransport::stop()
{
    if (!m_wanted)
        return;
    m_wanted = false;

    if (m_controller) {
        m_controller->disconnect(this);
        m_controller->stopAdvertising();
        m_controller->disconnectFromDevice();
    }
    unsubscribed();
    m_service.reset();
    m_controller.reset();
}

void BlePeripheralTransport::advertise()
{
    // A connection takes the service with it (BlueZ and CoreBluetooth both), so add it afresh.
    m_service.reset(m_controller->addService(serviceData()));
    if (!m_service) {
        emit errorOccurred(QStringLiteral("cannot add the phone link GATT service"));
        return;
    }
    connect(m_service.get(), &QLowEnergyService::characteristicChanged, this, &BlePeripheralTransport::onWritten);
    connect(m_service.get(), &QLowEnergyService::descriptorWritten, this, &BlePeripheralTransport::onDescriptorWritten);

    // 31 bytes: flags and the 128-bit service UUID fill most of it, so the name goes in the scan response.
    QLowEnergyAdvertisingData advertising;
    advertising.setDiscoverability(QLowEnergyAdvertisingData::DiscoverabilityGeneral);
    advertising.setServices({kServiceUuid});
    QLowEnergyAdvertisingData scanResponse;
    scanResponse.setLocalName(m_localName);

    m_controller->startAdvertising(QLowEnergyAdvertisingParameters(), advertising, scanResponse);
    qCInfo(lcPhoneLink) << "Advertising as" << m_localName;
}

void BlePeripheralTransport::onConnected()
{
    qCInfo(lcPhoneLink) << "BLE central connected" << m_controller->remoteAddress().toString();
}

void BlePeripheralTransport::onDisconnected()
{
    qCInfo(lcPhoneLink) << "BLE central disconnected";
    unsubscribed();
    if (m_wanted)
        advertise();
}

void BlePeripheralTransport::onWritten(const QLowEnergyCharacteristic &characteristic, const QByteArray &value)
{
    if (characteristic.uuid() != kRxUuid)
        return;
    // CoreBluetooth does not always pass the CCCD write on; a phone that writes is listening.
    subscribed();
    emit received(value);
}

void BlePeripheralTransport::onDescriptorWritten(const QLowEnergyDescriptor &descriptor, const QByteArray &value)
{
    if (descriptor.type() != QBluetoothUuid::DescriptorType::ClientCharacteristicConfiguration)
        return;
    const bool notify = !value.isEmpty() && (static_cast<quint8>(value.at(0)) & 0x01) != 0;
    if (notify)
        subscribed();
    else
        unsubscribed();
}

void BlePeripheralTransport::subscribed()
{
    if (m_subscribed)
        return;
    m_subscribed = true;
    emit peerConnected();
}

void BlePeripheralTransport::unsubscribed()
{
    if (!m_subscribed)
        return;
    m_subscribed = false;
    emit peerDisconnected();
}

} // namespace phonelink

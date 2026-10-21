#include "bluetoothmanager.h"

#include "phoneservice.h"

#ifdef EAGLE_HAS_BLUETOOTH
#include <QBluetoothDeviceDiscoveryAgent>
#include <QBluetoothDeviceInfo>
#include <QBluetoothLocalDevice>
#endif

BluetoothManager::BluetoothManager(PhoneService *phone, QObject *parent)
    : QObject(parent)
    , m_phone(phone)
{
#ifdef EAGLE_HAS_BLUETOOTH
    m_real = qEnvironmentVariableIntValue("EAGLE_SIMULATED_RADIOS") != 1;
#endif
    if (m_real) {
        setupRadio();
        return;
    }

    // The desk: the rider's phone is paired and connected; others are in range.
    m_devices = {
        {QStringLiteral("Pixel 8"), QStringLiteral("5C:2B:A1:10:7E:31"), QStringLiteral("phone"), -48, true, true},
        {QStringLiteral("Helmet intercom"), QStringLiteral("00:1A:7D:DA:71:13"), QStringLiteral("headset"), -55, true, false},
    };
    m_simTimer.setSingleShot(true);
    connect(&m_simTimer, &QTimer::timeout, this, [this] {
        if (m_scanning) {
            upsert({QStringLiteral("Rahul's phone"), QStringLiteral("A4:83:E7:2C:19:0B"), QStringLiteral("phone"), -71});
            upsert({QStringLiteral("Smartwatch"), QStringLiteral("D0:03:4B:6E:22:9A"), QStringLiteral("other"), -80});
            m_scanning = false;
            setStatus(tr("%n device(s) found", "", int(m_devices.size())));
        }
        if (!m_simPairing.isEmpty()) {
            if (Device *device = find(m_simPairing)) {
                device->paired = true;
                device->connected = device->kind == QLatin1String("phone") || device->kind == QLatin1String("headset");
                setStatus(tr("Paired with %1").arg(device->name));
            }
            m_simPairing.clear();
            emit devicesChanged();
            syncPhone();
        }
    });
    setStatus(tr("On"));
}

QVariantList BluetoothManager::devices() const
{
    QVariantList list;
    for (const Device &device : m_devices) {
        list.append(QVariantMap{{QStringLiteral("name"), device.name},
                                {QStringLiteral("address"), device.address},
                                {QStringLiteral("kind"), device.kind},
                                {QStringLiteral("rssi"), device.rssi},
                                {QStringLiteral("paired"), device.paired},
                                {QStringLiteral("connected"), device.connected}});
    }
    return list;
}

void BluetoothManager::setPowered(bool powered)
{
    if (m_powered == powered)
        return;
#ifdef EAGLE_HAS_BLUETOOTH
    if (m_real && m_local) {
        m_local->setHostMode(powered ? QBluetoothLocalDevice::HostConnectable : QBluetoothLocalDevice::HostPoweredOff);
        return; // hostModeStateChanged reports the result
    }
#endif
    m_powered = powered;
    if (!powered) {
        for (Device &device : m_devices)
            device.connected = false;
        emit devicesChanged();
    } else if (Device *phone = find(QStringLiteral("5C:2B:A1:10:7E:31"))) {
        phone->connected = phone->paired;
        emit devicesChanged();
    }
    syncPhone();
    setStatus(powered ? tr("On") : tr("Off"));
}

void BluetoothManager::scan()
{
    if (!m_powered || m_scanning)
        return;
    m_scanning = true;
    setStatus(tr("Searching…"));
#ifdef EAGLE_HAS_BLUETOOTH
    if (m_real && m_agent) {
        m_agent->start(QBluetoothDeviceDiscoveryAgent::ClassicMethod | QBluetoothDeviceDiscoveryAgent::LowEnergyMethod);
        return;
    }
#endif
    m_simTimer.start(2500);
}

void BluetoothManager::pair(const QString &address)
{
    Device *device = find(address);
    if (!device || device->paired || !m_powered)
        return;
    setStatus(tr("Pairing with %1…").arg(device->name));
#ifdef EAGLE_HAS_BLUETOOTH
    if (m_real && m_local) {
        m_local->requestPairing(QBluetoothAddress(address), QBluetoothLocalDevice::AuthorizedPaired);
        return;
    }
#endif
    m_simPairing = address;
    m_simTimer.start(2000);
}

void BluetoothManager::forget(const QString &address)
{
    Device *device = find(address);
    if (!device)
        return;
#ifdef EAGLE_HAS_BLUETOOTH
    if (m_real && m_local)
        m_local->requestPairing(QBluetoothAddress(address), QBluetoothLocalDevice::Unpaired);
#endif
    device->paired = false;
    device->connected = false;
    emit devicesChanged();
    syncPhone();
    setStatus(tr("Forgot %1").arg(device->name));
}

void BluetoothManager::setStatus(const QString &status)
{
    m_status = status;
    emit stateChanged();
}

BluetoothManager::Device *BluetoothManager::find(const QString &address)
{
    for (Device &device : m_devices) {
        if (device.address.compare(address, Qt::CaseInsensitive) == 0)
            return &device;
    }
    return nullptr;
}

void BluetoothManager::upsert(const Device &device)
{
    if (Device *existing = find(device.address)) {
        existing->rssi = device.rssi;
        if (!device.name.isEmpty())
            existing->name = device.name;
    } else {
        m_devices.append(device);
    }
    emit devicesChanged();
}

void BluetoothManager::syncPhone()
{
    // The phone service follows the first connected phone.
    for (const Device &device : m_devices) {
        if (device.kind == QLatin1String("phone") && device.connected) {
            m_phone->setConnected(true, device.name);
            return;
        }
    }
    m_phone->setConnected(false);
}

void BluetoothManager::setupRadio()
{
#ifdef EAGLE_HAS_BLUETOOTH
    m_local = new QBluetoothLocalDevice(this);
    if (!m_local->isValid()) {
        // No adapter exposed to BlueZ, as seen on some RK3328 images.
        m_powered = false;
        setStatus(tr("No Bluetooth adapter found"));
        return;
    }
    m_powered = m_local->hostMode() != QBluetoothLocalDevice::HostPoweredOff;
    for (const QBluetoothAddress &address : m_local->connectedDevices())
        upsert({address.toString(), address.toString(), QStringLiteral("other"), 0, true, true});

    connect(m_local, &QBluetoothLocalDevice::hostModeStateChanged, this, [this](QBluetoothLocalDevice::HostMode mode) {
        m_powered = mode != QBluetoothLocalDevice::HostPoweredOff;
        setStatus(m_powered ? tr("On") : tr("Off"));
    });
    connect(m_local, &QBluetoothLocalDevice::pairingFinished, this,
            [this](const QBluetoothAddress &address, QBluetoothLocalDevice::Pairing pairing) {
                if (Device *device = find(address.toString())) {
                    device->paired = pairing != QBluetoothLocalDevice::Unpaired;
                    setStatus(device->paired ? tr("Paired with %1").arg(device->name) : tr("Not paired"));
                    emit devicesChanged();
                }
            });
    connect(m_local, &QBluetoothLocalDevice::deviceConnected, this, [this](const QBluetoothAddress &address) {
        if (Device *device = find(address.toString())) {
            device->connected = true;
            emit devicesChanged();
            syncPhone();
        }
    });
    connect(m_local, &QBluetoothLocalDevice::deviceDisconnected, this, [this](const QBluetoothAddress &address) {
        if (Device *device = find(address.toString())) {
            device->connected = false;
            emit devicesChanged();
            syncPhone();
        }
    });
    connect(m_local, &QBluetoothLocalDevice::errorOccurred, this, [this](QBluetoothLocalDevice::Error) {
        setStatus(tr("Bluetooth error"));
    });

    m_agent = new QBluetoothDeviceDiscoveryAgent(this);
    m_agent->setLowEnergyDiscoveryTimeout(8000);
    connect(m_agent, &QBluetoothDeviceDiscoveryAgent::deviceDiscovered, this, [this](const QBluetoothDeviceInfo &info) {
        if (info.name().isEmpty())
            return;
        const auto major = info.majorDeviceClass();
        const QString kind = major == QBluetoothDeviceInfo::PhoneDevice ? QStringLiteral("phone")
                             : major == QBluetoothDeviceInfo::AudioVideoDevice ? QStringLiteral("headset")
                                                                               : QStringLiteral("other");
        const bool paired = m_local->pairingStatus(info.address()) != QBluetoothLocalDevice::Unpaired;
        upsert({info.name(), info.address().toString(), kind, info.rssi(), paired, false});
    });
    connect(m_agent, &QBluetoothDeviceDiscoveryAgent::finished, this, [this] {
        m_scanning = false;
        setStatus(tr("%n device(s) found", "", int(m_devices.size())));
    });
    connect(m_agent, &QBluetoothDeviceDiscoveryAgent::errorOccurred, this, [this](QBluetoothDeviceDiscoveryAgent::Error) {
        m_scanning = false;
        setStatus(m_agent->errorString());
    });
    setStatus(m_powered ? tr("On") : tr("Off"));
#endif
}

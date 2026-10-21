#pragma once

#include <QObject>
#include <QTimer>
#include <QVariantList>

class PhoneService;
class QBluetoothLocalDevice;
class QBluetoothDeviceDiscoveryAgent;

// The scooter's Bluetooth radio: power, scanning, pairing and forgetting phones
// and headsets. On Linux (the RK3328 board, BlueZ) it drives the real adapter
// through Qt Bluetooth; elsewhere a built-in radio with a few nearby devices
// stands in, so the screens can be developed on the desk.
class BluetoothManager final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool real READ real CONSTANT)
    Q_PROPERTY(bool powered READ powered WRITE setPowered NOTIFY stateChanged)
    Q_PROPERTY(bool scanning READ scanning NOTIFY stateChanged)
    Q_PROPERTY(QString status READ status NOTIFY stateChanged)
    Q_PROPERTY(QVariantList devices READ devices NOTIFY devicesChanged)

public:
    explicit BluetoothManager(PhoneService *phone, QObject *parent = nullptr);

    bool real() const { return m_real; }
    bool powered() const { return m_powered; }
    bool scanning() const { return m_scanning; }
    QString status() const { return m_status; }
    QVariantList devices() const;

public slots:
    void setPowered(bool powered);
    void scan();
    void pair(const QString &address);
    void forget(const QString &address);

signals:
    void stateChanged();
    void devicesChanged();

private:
    struct Device {
        QString name;
        QString address;
        QString kind;   // "phone", "headset", "other"
        int rssi = -60;
        bool paired = false;
        bool connected = false;
    };

    void setStatus(const QString &status);
    Device *find(const QString &address);
    void upsert(const Device &device);
    void syncPhone();
    void setupRadio();

    PhoneService *m_phone;
    bool m_real = false;
    bool m_powered = true;
    bool m_scanning = false;
    QString m_status;
    QList<Device> m_devices;
    QTimer m_simTimer;
    QString m_simPairing;

    QBluetoothLocalDevice *m_local = nullptr;
    QBluetoothDeviceDiscoveryAgent *m_agent = nullptr;
};

#pragma once

#include <QObject>
#include <QString>

class DashboardData;
class QCanBusDevice;
class QCanBusFrame;

// Live vehicle data from the scooter's CAN bus (SocketCAN on the RK3328 board).
// Each frame updates DashboardData; the frame layout is in docs/CAN.md. Values
// that stop arriving are not invented: the last one stays until the bus speaks.
class CanVehicleSource final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool connected READ connected NOTIFY statusChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)

public:
    explicit CanVehicleSource(DashboardData *data, QObject *parent = nullptr);

    bool connected() const { return m_connected; }
    QString status() const { return m_status; }

    // Opens the interface, e.g. "can0". Returns false if SocketCAN is unavailable.
    bool open(const QString &interfaceName);

    // Applies one frame to the vehicle model; public so tests can feed frames directly.
    void apply(quint32 id, const QByteArray &payload);

signals:
    void statusChanged();
    // A handlebar key went down: "up", "down", "left", "right", "ok" or "back".
    void buttonPressed(const QString &button);

private:
    void readFrames();
    void setStatus(bool connected, const QString &status);

    DashboardData *m_data;
    QCanBusDevice *m_device = nullptr;
    bool m_connected = false;
    QString m_status;
    quint8 m_buttonsHeld = 0;
};

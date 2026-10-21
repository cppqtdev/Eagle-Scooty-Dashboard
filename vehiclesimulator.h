#pragma once

#include <QElapsedTimer>
#include <QObject>
#include <QStringList>
#include <QTimer>

class DashboardData;

// Stands in for the scooter on the desk: rides a looping route through the city
// with traffic stops and turns, and can inject each fault the dashboard reacts to.
// On the board it is switched off and the CAN source feeds DashboardData instead.
class VehicleSimulator final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool running READ running WRITE setRunning NOTIFY runningChanged)
    Q_PROPERTY(QStringList scenarios READ scenarios CONSTANT)

public:
    explicit VehicleSimulator(DashboardData *data, QObject *parent = nullptr);

    bool running() const;
    QStringList scenarios() const;

public slots:
    void setRunning(bool running);
    void keyOn();
    // "lowTyre", "overheat", "motorFault", "lowBattery", "sideStand", "absFault",
    // "charge", "hazard" and "reverse" (both toggle), or "clear".
    void trigger(const QString &scenario);
    void toggleCharging();
    // While the phone guides, the route on screen is the phone's, not the demo's.
    void setPhoneGuiding(bool guiding) { m_phoneGuiding = guiding; }

signals:
    void runningChanged();

private:
    void tick();
    void ride(qreal seconds);
    void charge(qreal seconds);
    void nextStep();
    int topSpeed() const;

    DashboardData *m_data;
    QTimer m_timer;
    QElapsedTimer m_clock;
    qint64 m_lastMs = 0;

    qreal m_speed = 0.0;       // km/h, smoothed
    qreal m_metresToTurn = 0.0;
    qreal m_tripMetres = 0.0;
    qreal m_odoMetres = 0.0;
    qreal m_batteryExact = 72.0;
    qreal m_stopSeconds = 0.0; // waiting at a junction
    int m_step = 0;
    qreal m_sinceKeyOn = 0.0;
    qreal m_chargeHeat = 0.0;  // seconds of charging, warms the pack slowly
    bool m_keyedOn = false;
    bool m_phoneGuiding = false;
    bool m_hazard = false;
    bool m_reverseWanted = false;   // asked for on the move; taken at the stop
};

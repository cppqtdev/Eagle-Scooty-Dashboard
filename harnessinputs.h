#pragma once

#include <QElapsedTimer>
#include <QHash>
#include <QJsonObject>
#include <QObject>
#include <QString>
#include <QTimer>

#include <vector>

class DashboardData;
class QSocketNotifier;

// The conversions the harness needs, kept free of any hardware so they can be
// tested on the desk.
namespace harness {

// Road speed from wheel-sensor pulses counted over a window.
double speedKmh(int pulses, double seconds, double pulsesPerKm);

// An NTC thermistor on the low side of a divider: pull-up to vref, NTC to ground.
double ntcCelsius(double millivolts, double vrefMv, double pullupOhm, double r25Ohm, double beta);

// State of charge from the pack voltage, by a table of (millivolts, percent)
// points in rising voltage order; linear between points, clamped at the ends.
int percentFromVoltage(double millivolts, const std::vector<std::pair<double, int>> &curve);

} // namespace harness

// The wires of the cluster connector (docs/Inputs.md), for a bike without a
// CAN bus or alongside one: the lamp and switch lines as GPIO inputs, the
// wheel-speed sensor as GPIO edges, the battery voltage and a temperature as
// ADC channels. Which pin is which comes from a JSON file, so one build serves
// any harness. Linux only (GPIO character device and IIO); elsewhere open()
// reports that and does nothing.
class HarnessInputs final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool active READ active NOTIFY statusChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)

public:
    explicit HarnessInputs(DashboardData *data, QObject *parent = nullptr);
    ~HarnessInputs() override;

    bool active() const { return m_active; }
    QString status() const { return m_status; }

    // Reads the map and claims the lines; false (with status saying why) if it cannot.
    bool open(const QString &configPath);
    bool configure(const QJsonObject &config); // the same from a parsed map, for tests

    // A line's level, already corrected for active-low: what the rest of the
    // class acts on. Public so tests can drive it without hardware.
    void applyLine(const QString &signal, bool on);
    void addSpeedPulses(int pulses);

signals:
    void statusChanged();

private:
    struct Line {
        QString signal;
        int fd = -1;
        bool activeLow = false;
        QSocketNotifier *notifier = nullptr;
    };

    bool requestLine(const QString &signal, const QJsonObject &spec, bool edges);
    void readLine(Line &line);
    void sampleAnalog();
    void sampleSpeed();
    void setStatus(bool active, const QString &status);

    DashboardData *m_data;
    bool m_active = false;
    QString m_status;
    std::vector<Line> m_lines;

    // Indicators: the harness carries the flasher output, so a lamp counts as
    // on while it flashed in the last 700 ms; the cluster blinks it in step itself.
    QHash<QString, qint64> m_lastFlash;
    QElapsedTimer m_clock;
    QTimer m_indicatorHold;

    // Wheel speed.
    double m_pulsesPerKm = 0;
    int m_pulses = 0;
    QElapsedTimer m_speedWindow;
    QTimer m_speedTimer;

    // ADC channels.
    QJsonObject m_battery;
    QJsonObject m_temperature;
    QTimer m_analogTimer;
};

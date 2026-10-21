#include "harnessinputs.h"

#include "dashboarddata.h"

#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QSocketNotifier>

#include <algorithm>
#include <cmath>

#ifdef Q_OS_LINUX
#include <fcntl.h>
#include <linux/gpio.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <cstring>
#endif

namespace harness {

double speedKmh(int pulses, double seconds, double pulsesPerKm)
{
    if (seconds <= 0.0 || pulsesPerKm <= 0.0)
        return 0.0;
    return pulses / pulsesPerKm / (seconds / 3600.0);
}

double ntcCelsius(double millivolts, double vrefMv, double pullupOhm, double r25Ohm, double beta)
{
    if (millivolts <= 0.0 || millivolts >= vrefMv || beta <= 0.0)
        return std::nan("");
    const double ntcOhm = pullupOhm * millivolts / (vrefMv - millivolts);
    const double kelvin = 1.0 / (1.0 / 298.15 + std::log(ntcOhm / r25Ohm) / beta);
    return kelvin - 273.15;
}

int percentFromVoltage(double millivolts, const std::vector<std::pair<double, int>> &curve)
{
    if (curve.empty())
        return 0;
    if (millivolts <= curve.front().first)
        return curve.front().second;
    if (millivolts >= curve.back().first)
        return curve.back().second;
    for (size_t i = 1; i < curve.size(); ++i) {
        const auto &[v1, p1] = curve[i];
        if (millivolts <= v1) {
            const auto &[v0, p0] = curve[i - 1];
            return int(std::lround(p0 + (p1 - p0) * (millivolts - v0) / (v1 - v0)));
        }
    }
    return curve.back().second;
}

} // namespace harness

namespace {

constexpr qint64 kIndicatorHoldMs = 700;   // longer than a flasher's off phase (500 ms at 60 a minute)
constexpr int kSpeedSampleMs = 250;
constexpr int kAnalogSampleMs = 500;

double readNumber(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return std::nan("");
    bool ok = false;
    const double value = file.readAll().trimmed().toDouble(&ok);
    return ok ? value : std::nan("");
}

// The channel's voltage at the ADC pin, in millivolts (IIO: raw x scale).
double adcMillivolts(const QJsonObject &spec)
{
    const QString base = QStringLiteral("/sys/bus/iio/devices/%1/").arg(spec.value(QLatin1String("device")).toString());
    const int channel = spec.value(QLatin1String("channel")).toInt();
    const double raw = readNumber(base + QStringLiteral("in_voltage%1_raw").arg(channel));
    double scale = readNumber(base + QStringLiteral("in_voltage%1_scale").arg(channel));
    if (std::isnan(scale))
        scale = readNumber(base + QStringLiteral("in_voltage_scale"));
    return raw * scale;
}

} // namespace

HarnessInputs::HarnessInputs(DashboardData *data, QObject *parent)
    : QObject(parent), m_data(data)
{
    m_clock.start();

    m_indicatorHold.setInterval(100);
    connect(&m_indicatorHold, &QTimer::timeout, this, [this] {
        const qint64 now = m_clock.elapsed();
        const auto lit = [&](const QString &signal) {
            return m_lastFlash.contains(signal) && now - m_lastFlash.value(signal) < kIndicatorHoldMs;
        };
        m_data->setLeftIndicator(lit(QStringLiteral("turnLeft")));
        m_data->setRightIndicator(lit(QStringLiteral("turnRight")));
    });

    m_speedTimer.setInterval(kSpeedSampleMs);
    connect(&m_speedTimer, &QTimer::timeout, this, &HarnessInputs::sampleSpeed);

    m_analogTimer.setInterval(kAnalogSampleMs);
    connect(&m_analogTimer, &QTimer::timeout, this, &HarnessInputs::sampleAnalog);
}

HarnessInputs::~HarnessInputs()
{
#ifdef Q_OS_LINUX
    for (const Line &line : m_lines) {
        if (line.fd >= 0)
            ::close(line.fd);
    }
#endif
}

bool HarnessInputs::open(const QString &configPath)
{
    QFile file(configPath);
    if (!file.open(QIODevice::ReadOnly)) {
        setStatus(false, tr("No harness map at %1").arg(configPath));
        return false;
    }
    QJsonParseError error;
    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &error);
    if (!doc.isObject()) {
        setStatus(false, tr("Harness map %1: %2").arg(configPath, error.errorString()));
        return false;
    }
    return configure(doc.object());
}

bool HarnessInputs::configure(const QJsonObject &config)
{
#ifndef Q_OS_LINUX
    // The maths still works for tests; the pins exist only on the board.
    m_pulsesPerKm = config.value(QLatin1String("speed")).toObject().value(QLatin1String("pulsesPerKm")).toDouble();
    m_battery = config.value(QLatin1String("battery")).toObject();
    m_temperature = config.value(QLatin1String("temperature")).toObject();
    setStatus(false, tr("Harness inputs need the board (Linux GPIO and IIO)"));
    return false;
#else
    QStringList failed;
    const QJsonObject digital = config.value(QLatin1String("digital")).toObject();
    for (auto it = digital.begin(); it != digital.end(); ++it) {
        if (!requestLine(it.key(), it.value().toObject(), true))
            failed << it.key();
    }

    const QJsonObject speed = config.value(QLatin1String("speed")).toObject();
    if (!speed.isEmpty()) {
        m_pulsesPerKm = speed.value(QLatin1String("pulsesPerKm")).toDouble();
        if (requestLine(QStringLiteral("speedPulse"), speed, true)) {
            m_speedWindow.start();
            m_speedTimer.start();
        } else {
            failed << QStringLiteral("speed");
        }
    }

    m_battery = config.value(QLatin1String("battery")).toObject();
    m_temperature = config.value(QLatin1String("temperature")).toObject();
    if (!m_battery.isEmpty() || !m_temperature.isEmpty()) {
        sampleAnalog();
        m_analogTimer.start();
    }
    m_indicatorHold.start();

    const bool any = !m_lines.empty() || m_analogTimer.isActive();
    setStatus(any, failed.isEmpty() ? tr("Harness: %1 lines").arg(m_lines.size())
                                    : tr("Harness: could not open %1").arg(failed.join(QLatin1String(", "))));
    return any;
#endif
}

bool HarnessInputs::requestLine(const QString &signal, const QJsonObject &spec, bool edges)
{
#ifdef Q_OS_LINUX
    const QString chip = QStringLiteral("/dev/") + spec.value(QLatin1String("chip")).toString(QStringLiteral("gpiochip0"));
    const int chipFd = ::open(chip.toLocal8Bit().constData(), O_RDONLY | O_CLOEXEC);
    if (chipFd < 0)
        return false;

    gpio_v2_line_request request;
    std::memset(&request, 0, sizeof request);
    request.offsets[0] = quint32(spec.value(QLatin1String("line")).toInt());
    request.num_lines = 1;
    std::strncpy(request.consumer, "eagle-dashboard", sizeof request.consumer - 1);
    request.config.flags = GPIO_V2_LINE_FLAG_INPUT;
    const bool activeLow = spec.value(QLatin1String("activeLow")).toBool();
    if (activeLow)
        request.config.flags |= GPIO_V2_LINE_FLAG_ACTIVE_LOW;
    if (edges) {
        request.config.flags |= signal == QLatin1String("speedPulse")
                                    ? GPIO_V2_LINE_FLAG_EDGE_RISING
                                    : GPIO_V2_LINE_FLAG_EDGE_RISING | GPIO_V2_LINE_FLAG_EDGE_FALLING;
    }
    // Switches bounce; the kernel filters what is shorter than this.
    const int debounceUs = spec.value(QLatin1String("debounceUs")).toInt(signal == QLatin1String("speedPulse") ? 0 : 5000);
    if (debounceUs > 0) {
        request.config.num_attrs = 1;
        request.config.attrs[0].attr.id = GPIO_V2_LINE_ATTR_ID_DEBOUNCE;
        request.config.attrs[0].attr.debounce_period_us = quint32(debounceUs);
        request.config.attrs[0].mask = 1;
    }
    const int result = ::ioctl(chipFd, GPIO_V2_GET_LINE_IOCTL, &request);
    ::close(chipFd);
    if (result < 0)
        return false;

    Line line;
    line.signal = signal;
    line.fd = request.fd;
    line.activeLow = activeLow;
    m_lines.push_back(line);
    Line &added = m_lines.back();
    added.notifier = new QSocketNotifier(added.fd, QSocketNotifier::Read, this);
    const size_t index = m_lines.size() - 1;
    connect(added.notifier, &QSocketNotifier::activated, this, [this, index] { readLine(m_lines[index]); });

    // The level now, so a lamp already on at start shows straight away.
    if (signal != QLatin1String("speedPulse")) {
        gpio_v2_line_values values;
        values.mask = 1;
        values.bits = 0;
        if (::ioctl(added.fd, GPIO_V2_LINE_GET_VALUES_IOCTL, &values) == 0)
            applyLine(signal, values.bits & 1);
    }
    return true;
#else
    Q_UNUSED(signal)
    Q_UNUSED(spec)
    Q_UNUSED(edges)
    return false;
#endif
}

void HarnessInputs::readLine(Line &line)
{
#ifdef Q_OS_LINUX
    gpio_v2_line_event events[16];
    const ssize_t got = ::read(line.fd, events, sizeof events);
    if (got <= 0)
        return;
    const int count = int(got / ssize_t(sizeof(gpio_v2_line_event)));
    if (line.signal == QLatin1String("speedPulse")) {
        addSpeedPulses(count);
        return;
    }
    // The last edge is the level now (the kernel has applied active-low already).
    applyLine(line.signal, events[count - 1].id == GPIO_V2_LINE_EVENT_RISING_EDGE);
#else
    Q_UNUSED(line)
#endif
}

void HarnessInputs::applyLine(const QString &signal, bool on)
{
    if (signal == QLatin1String("turnLeft") || signal == QLatin1String("turnRight")) {
        if (on)
            m_lastFlash.insert(signal, m_clock.elapsed());
        if (signal == QLatin1String("turnLeft") && on)
            m_data->setLeftIndicator(true);
        else if (signal == QLatin1String("turnRight") && on)
            m_data->setRightIndicator(true);
    } else if (signal == QLatin1String("highBeam")) {
        m_data->setHighBeam(on);
    } else if (signal == QLatin1String("lowBeam")) {
        m_data->setLowBeam(on);
    } else if (signal == QLatin1String("neutral")) {
        // The neutral switch alone: closed is N, open is drive.
        m_data->setGear(on ? QStringLiteral("N") : QStringLiteral("D"));
    } else if (signal == QLatin1String("abs")) {
        m_data->setAbsFault(on);
    } else if (signal == QLatin1String("checkEngine")) {
        m_data->setCheckEngine(on);
    } else if (signal == QLatin1String("illumination")) {
        m_data->setIllumination(on);
    } else if (signal == QLatin1String("sideStand")) {
        m_data->setSideStandDown(on);
    }
}

void HarnessInputs::addSpeedPulses(int pulses)
{
    m_pulses += pulses;
}

void HarnessInputs::sampleSpeed()
{
    const double seconds = m_speedWindow.restart() / 1000.0;
    m_data->setSpeed(int(std::lround(harness::speedKmh(m_pulses, seconds, m_pulsesPerKm))));
    m_pulses = 0;
}

void HarnessInputs::sampleAnalog()
{
    if (!m_battery.isEmpty()) {
        const double atPin = adcMillivolts(m_battery);
        if (!std::isnan(atPin)) {
            const double pack = atPin * m_battery.value(QLatin1String("dividerRatio")).toDouble(1.0);
            std::vector<std::pair<double, int>> curve;
            const QJsonArray points = m_battery.value(QLatin1String("curve")).toArray();
            for (const QJsonValue &point : points)
                curve.emplace_back(point.toArray().at(0).toDouble(), point.toArray().at(1).toInt());
            m_data->setBatteryPercent(harness::percentFromVoltage(pack, curve));
        }
    }
    if (!m_temperature.isEmpty()) {
        const double celsius = harness::ntcCelsius(adcMillivolts(m_temperature),
                                                   m_temperature.value(QLatin1String("vrefMv")).toDouble(1800),
                                                   m_temperature.value(QLatin1String("pullupOhm")).toDouble(10000),
                                                   m_temperature.value(QLatin1String("r25Ohm")).toDouble(10000),
                                                   m_temperature.value(QLatin1String("beta")).toDouble(3950));
        if (!std::isnan(celsius)) {
            const QString target = m_temperature.value(QLatin1String("target")).toString(QStringLiteral("motor"));
            const int rounded = int(std::lround(celsius));
            if (target == QLatin1String("battery"))
                m_data->setBatteryTempC(rounded);
            else if (target == QLatin1String("ambient"))
                m_data->setTemperatureC(rounded);
            else
                m_data->setMotorTempC(rounded);
        }
    }
}

void HarnessInputs::setStatus(bool active, const QString &status)
{
    m_active = active;
    m_status = status;
    emit statusChanged();
}

#include "vehiclesimulator.h"

#include "dashboarddata.h"

#include <QtMath>

namespace {

struct Step {
    DashboardData::Maneuver maneuver;
    const char *street;
    int metres;
};

// A loop through the city: the distance is how far away the step's turn is.
const Step kRoute[] = {
    {DashboardData::TurnRight, "MG Road", 900},
    {DashboardData::Straight, "Outer Ring Road", 1600},
    {DashboardData::TurnLeft, "Silk Board Junction", 700},
    {DashboardData::TurnRight, "Hosur Road", 1300},
    {DashboardData::UTurn, "Electronic City Flyover", 500},
    {DashboardData::TurnLeft, "Infosys Avenue", 800},
    {DashboardData::Arrive, "Office", 400},
};
constexpr int kRouteSteps = int(sizeof(kRoute) / sizeof(kRoute[0]));

constexpr int kTickMs = 50;
constexpr qreal kIndicatorBeforeTurnM = 160.0;
constexpr qreal kKmPerPercent[] = {1.95, 1.7, 1.35}; // Eco, City, Sport

} // namespace

VehicleSimulator::VehicleSimulator(DashboardData *data, QObject *parent)
    : QObject(parent)
    , m_data(data)
{
    m_timer.setInterval(kTickMs);
    m_timer.setTimerType(Qt::PreciseTimer);
    connect(&m_timer, &QTimer::timeout, this, &VehicleSimulator::tick);

    m_batteryExact = m_data->batteryPercent();
    m_metresToTurn = kRoute[0].metres;
    m_data->setManeuver(kRoute[0].maneuver);
    m_data->setStreet(QString::fromUtf8(kRoute[0].street));
}

bool VehicleSimulator::running() const
{
    return m_timer.isActive();
}

QStringList VehicleSimulator::scenarios() const
{
    return {QStringLiteral("lowTyre"), QStringLiteral("overheat"), QStringLiteral("motorFault"),
            QStringLiteral("lowBattery"), QStringLiteral("sideStand"), QStringLiteral("absFault"),
            QStringLiteral("charge"), QStringLiteral("hazard"), QStringLiteral("reverse"), QStringLiteral("clear")};
}

void VehicleSimulator::setRunning(bool running)
{
    if (running == m_timer.isActive())
        return;
    if (running) {
        m_clock.start();
        m_lastMs = 0;
        m_timer.start();
    } else {
        m_timer.stop();
    }
    emit runningChanged();
}

void VehicleSimulator::keyOn()
{
    m_keyedOn = true;
    m_sinceKeyOn = 0.0;
    setRunning(true);
}

void VehicleSimulator::trigger(const QString &scenario)
{
    if (scenario == QLatin1String("lowTyre")) {
        m_data->setTyreFrontBar(1.6);
    } else if (scenario == QLatin1String("overheat")) {
        m_data->setBatteryTempC(58);
        m_data->setMotorTempC(96);
    } else if (scenario == QLatin1String("motorFault")) {
        m_data->setMotorFault(true);
    } else if (scenario == QLatin1String("lowBattery")) {
        m_batteryExact = 12.0;
        m_data->setBatteryPercent(12);
    } else if (scenario == QLatin1String("sideStand")) {
        m_data->setSideStandDown(true);
    } else if (scenario == QLatin1String("absFault")) {
        m_data->setAbsFault(true);
    } else if (scenario == QLatin1String("charge")) {
        if (!m_data->charging())
            toggleCharging();
    } else if (scenario == QLatin1String("hazard")) {
        m_hazard = !m_hazard;
    } else if (scenario == QLatin1String("reverse")) {
        // Reverse is only taken at a standstill; the motor then holds it under 5 km/h.
        if (m_data->gear() == QLatin1String("R"))
            m_data->setGear(QStringLiteral("D"));
        else if (m_speed < 1.0 && !m_data->charging())
            m_data->setGear(QStringLiteral("R"));
        else
            m_reverseWanted = true;
    } else if (scenario == QLatin1String("clear")) {
        m_hazard = false;
        m_reverseWanted = false;
        if (m_data->gear() == QLatin1String("R"))
            m_data->setGear(QStringLiteral("D"));
        m_data->setTyreFrontBar(2.2);
        m_data->setTyreRearBar(2.2);
        m_data->setBatteryTempC(34);
        m_data->setMotorTempC(45);
        m_data->setMotorFault(false);
        m_data->setAbsFault(false);
        m_data->setSideStandDown(false);
        if (m_batteryExact < 40.0) {
            m_batteryExact = 72.0;
            m_data->setBatteryPercent(72);
        }
    }
}

void VehicleSimulator::toggleCharging()
{
    const bool start = !m_data->charging();
    if (start) {
        m_speed = 0.0;
        m_data->setSpeed(0);
        m_data->setPowerKw(0.0);
        m_data->setGear(QStringLiteral("P"));
        m_data->setLeftIndicator(false);
        m_data->setRightIndicator(false);
        m_data->setChargePowerKw(3.3);
    } else {
        m_data->setChargePowerKw(0.0);
        m_data->setGear(QStringLiteral("D"));
    }
    m_data->setCharging(start);
}

void VehicleSimulator::tick()
{
    const qint64 now = m_clock.elapsed();
    const qreal seconds = qMin<qreal>(0.25, (now - m_lastMs) / 1000.0);
    m_lastMs = now;

    if (m_keyedOn) {
        // Key-on: ready after the self-check, then the rider lifts the stand and selects D.
        m_sinceKeyOn += seconds;
        if (m_sinceKeyOn > 2.5 && !m_data->ready()) {
            m_data->setReady(true);
        } else if (m_sinceKeyOn > 4.0 && m_data->sideStandDown()) {
            m_data->setSideStandDown(false);
        } else if (m_sinceKeyOn > 4.5) {
            m_data->setGear(QStringLiteral("D"));
            m_keyedOn = false;
        }
        return;
    }

    if (m_data->charging())
        charge(seconds);
    else
        ride(seconds);
}

int VehicleSimulator::topSpeed() const
{
    switch (m_data->rideMode()) {
    case DashboardData::Eco: return 45;
    case DashboardData::City: return 60;
    case DashboardData::Sport: return 80;
    }
    return 45;
}

void VehicleSimulator::ride(qreal seconds)
{
    const bool reverse = m_data->gear() == QLatin1String("R");
    const bool cannotMove = m_data->motorFault() || m_data->sideStandDown()
                            || (m_data->gear() != QLatin1String("D") && !reverse);

    // Target: cruise, slow for the turn, stop briefly at junctions. A reverse
    // asked for on the move waits for the stop, then backs up at walking pace.
    qreal target = topSpeed();
    if (m_reverseWanted)
        target = 0.0;
    if (m_reverseWanted && m_speed < 1.0) {
        m_reverseWanted = false;
        m_data->setGear(QStringLiteral("R"));
    }
    if (reverse)
        target = 3.0;
    if (m_metresToTurn < 250.0)
        target = qMin(target, 18.0 + m_metresToTurn / 10.0);
    if (m_stopSeconds > 0.0) {
        m_stopSeconds -= seconds;
        target = 0.0;
    }
    if (cannotMove || m_data->batteryPercent() == 0)
        target = 0.0;

    const qreal accel = m_data->rideMode() == DashboardData::Sport ? 9.0 : 5.5; // km/h per second
    const qreal brake = 12.0;
    const qreal before = m_speed;
    if (m_speed < target)
        m_speed = qMin(target, m_speed + accel * seconds);
    else
        m_speed = qMax(target, m_speed - brake * seconds);

    const qreal deltaKmh = m_speed - before;
    qreal power = 0.4 + m_speed * 0.045 + deltaKmh / seconds * 0.35;
    if (deltaKmh < -0.01)
        power = qMax<qreal>(-2.5, deltaKmh / seconds * 0.18); // regen
    m_data->setSpeed(qRound(m_speed));
    m_data->setPowerKw(m_speed < 0.5 && target == 0.0 ? 0.0 : power);

    // Distance, trip and odometer.
    const qreal metres = m_speed / 3.6 * seconds;
    if (!reverse)
        m_metresToTurn -= metres;
    m_tripMetres += metres;
    m_odoMetres += metres;
    if (m_tripMetres >= 1000.0) {
        m_tripMetres -= 1000.0;
        m_data->setTripKm(m_data->tripKm() + 1);
    }
    if (m_odoMetres >= 1000.0) {
        m_odoMetres -= 1000.0;
        m_data->setOdometerKm(m_data->odometerKm() + 1);
    }

    // Energy: the drain is exaggerated so the demo shows the battery moving.
    m_batteryExact = qMax(0.0, m_batteryExact - qMax(0.0, power) * seconds * 0.004);
    m_data->setBatteryPercent(qRound(m_batteryExact));
    m_data->setRangeKm(qRound(m_batteryExact * kKmPerPercent[m_data->rideMode()]));

    // Temperatures drift with load, unless a fault scenario pinned them high.
    if (m_data->motorTempC() < 90)
        m_data->setMotorTempC(qRound(38 + m_speed * 0.35));
    if (m_data->batteryTempC() < 55)
        m_data->setBatteryTempC(qRound(31 + m_speed * 0.08));

    // Navigation and indicators.
    if (!m_phoneGuiding) {
        m_data->setManeuverDistanceM(qMax(0, qRound(m_metresToTurn / 10.0) * 10));
        m_data->setDistanceKm(m_data->distanceKm() > 0.05 ? m_data->distanceKm() - metres / 1000.0 : 8.4);
        m_data->setArrivalMinutes(qMax(1, qRound(m_data->distanceKm() / qMax<qreal>(20.0, m_speed) * 60.0)));
    }
    const auto maneuver = m_data->maneuver();
    const bool signalling = m_data->navigating() && m_data->maneuverDistanceM() < kIndicatorBeforeTurnM && m_speed > 1.0;
    m_data->setLeftIndicator(m_hazard || (signalling && (maneuver == DashboardData::TurnLeft || maneuver == DashboardData::UTurn)));
    m_data->setRightIndicator(m_hazard || (signalling && maneuver == DashboardData::TurnRight));

    if (m_metresToTurn <= 0.0 && !m_phoneGuiding)
        nextStep();
}

void VehicleSimulator::charge(qreal seconds)
{
    const int limit = m_data->chargeLimitPercent();
    if (m_batteryExact < limit) {
        // Sped up so a full charge is visible in about a minute.
        m_batteryExact = qMin<qreal>(limit, m_batteryExact + seconds * 0.9);
        m_data->setBatteryPercent(qRound(m_batteryExact));
        m_data->setRangeKm(qRound(m_batteryExact * kKmPerPercent[m_data->rideMode()]));
        m_data->setChargePowerKw(3.3);
        m_chargeHeat += seconds;
        m_data->setBatteryTempC(qMin(40, 31 + int(m_chargeHeat / 6.0)));
    } else {
        m_data->setChargePowerKw(0.0);
        m_chargeHeat = 0.0;
    }
}

void VehicleSimulator::nextStep()
{
    m_step = (m_step + 1) % kRouteSteps;
    const Step &step = kRoute[m_step];
    m_metresToTurn = step.metres;
    m_data->setManeuver(step.maneuver);
    m_data->setStreet(QString::fromUtf8(step.street));
    // A short stop at every second junction, like traffic lights.
    if (m_step % 2 == 0)
        m_stopSeconds = 3.0;
    if (step.maneuver == DashboardData::Arrive)
        m_data->setDistanceKm(8.4);
}

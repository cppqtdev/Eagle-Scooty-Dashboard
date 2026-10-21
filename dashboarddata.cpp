#include "dashboarddata.h"

#include <QtGlobal>
#include <cmath>

namespace {

// Assigns and reports whether anything changed, so each setter stays one line.
template <typename T>
bool assign(T &member, const T &value)
{
    if (member == value)
        return false;
    member = value;
    return true;
}

bool assign(qreal &member, qreal value)
{
    if (qFuzzyCompare(member + 1.0, value + 1.0))
        return false;
    member = value;
    return true;
}

} // namespace

DashboardData::DashboardData(QObject *parent)
    : QObject(parent)
{
}

QString DashboardData::rideModeName() const
{
    switch (m_rideMode) {
    case Eco: return tr("Eco");
    case City: return tr("City");
    case Sport: return tr("Sport");
    }
    return {};
}

int DashboardData::minutesToFull() const
{
    if (!m_charging || m_chargePowerKw <= 0.0 || m_batteryPercent >= m_chargeLimitPercent)
        return 0;
    // 3.2 kWh pack: minutes for the energy still missing up to the charge limit.
    const qreal missingKwh = 3.2 * (m_chargeLimitPercent - m_batteryPercent) / 100.0;
    return int(std::ceil(missingKwh / m_chargePowerKw * 60.0));
}

void DashboardData::setSpeed(int value)
{
    if (assign(m_speed, qBound(0, value, 120)))
        emit motionChanged();
}

void DashboardData::setPowerKw(qreal value)
{
    if (assign(m_powerKw, qBound(-3.0, value, 9.0)))
        emit motionChanged();
}

void DashboardData::setGear(const QString &value)
{
    static const QStringList gears{QStringLiteral("P"), QStringLiteral("R"), QStringLiteral("N"), QStringLiteral("D")};
    if (gears.contains(value) && assign(m_gear, value))
        emit motionChanged();
}

void DashboardData::setReady(bool value)
{
    if (assign(m_ready, value))
        emit motionChanged();
}

void DashboardData::setRideMode(RideMode value)
{
    if (assign(m_rideMode, value))
        emit rideModeChanged();
}

void DashboardData::cycleRideMode()
{
    setRideMode(static_cast<RideMode>((int(m_rideMode) + 1) % 3));
}

void DashboardData::setBatteryPercent(int value)
{
    if (assign(m_batteryPercent, qBound(0, value, 100))) {
        emit batteryChanged();
        emit chargingChanged();
    }
}

void DashboardData::setRangeKm(int value)
{
    if (assign(m_rangeKm, qMax(0, value)))
        emit batteryChanged();
}

void DashboardData::setCharging(bool value)
{
    if (assign(m_charging, value))
        emit chargingChanged();
}

void DashboardData::setChargePowerKw(qreal value)
{
    if (assign(m_chargePowerKw, qBound(0.0, value, 6.6)))
        emit chargingChanged();
}

void DashboardData::setChargeLimitPercent(int value)
{
    if (assign(m_chargeLimitPercent, qBound(50, value, 100)))
        emit chargingChanged();
}

void DashboardData::setTripKm(int value)
{
    if (assign(m_tripKm, qMax(0, value)))
        emit tripChanged();
}

void DashboardData::resetTrip()
{
    setTripKm(0);
}

void DashboardData::setOdometerKm(int value)
{
    if (assign(m_odometerKm, qMax(0, value)))
        emit tripChanged();
}

void DashboardData::setTemperatureC(int value)
{
    if (assign(m_temperatureC, qBound(-50, value, 80)))
        emit environmentChanged();
}

void DashboardData::setBatteryTempC(int value)
{
    if (assign(m_batteryTempC, qBound(-40, value, 120)))
        emit environmentChanged();
}

void DashboardData::setMotorTempC(int value)
{
    if (assign(m_motorTempC, qBound(-40, value, 180)))
        emit environmentChanged();
}

void DashboardData::setLeftIndicator(bool value)
{
    if (assign(m_leftIndicator, value))
        emit lampsChanged();
}

void DashboardData::setRightIndicator(bool value)
{
    if (assign(m_rightIndicator, value))
        emit lampsChanged();
}

void DashboardData::setLowBeam(bool value)
{
    if (assign(m_lowBeam, value))
        emit lampsChanged();
}

void DashboardData::setHighBeam(bool value)
{
    if (assign(m_highBeam, value))
        emit lampsChanged();
}

void DashboardData::setSideStandDown(bool value)
{
    if (assign(m_sideStandDown, value))
        emit lampsChanged();
}

void DashboardData::setTyreFrontBar(qreal value)
{
    if (assign(m_tyreFrontBar, qBound(0.0, value, 4.0)))
        emit tyresChanged();
}

void DashboardData::setTyreRearBar(qreal value)
{
    if (assign(m_tyreRearBar, qBound(0.0, value, 4.0)))
        emit tyresChanged();
}

void DashboardData::setMotorFault(bool value)
{
    if (assign(m_motorFault, value))
        emit faultsChanged();
}

void DashboardData::setAbsFault(bool value)
{
    if (assign(m_absFault, value))
        emit faultsChanged();
}

void DashboardData::setNavigating(bool value)
{
    if (assign(m_navigating, value))
        emit navigationChanged();
}

void DashboardData::setManeuver(Maneuver value)
{
    if (assign(m_maneuver, value))
        emit navigationChanged();
}

void DashboardData::setStreet(const QString &value)
{
    if (assign(m_street, value))
        emit navigationChanged();
}

void DashboardData::setManeuverDistanceM(int value)
{
    if (assign(m_maneuverDistanceM, qMax(0, value)))
        emit navigationChanged();
}

void DashboardData::setArrivalMinutes(int value)
{
    if (assign(m_arrivalMinutes, qMax(0, value)))
        emit navigationChanged();
}

void DashboardData::setDistanceKm(qreal value)
{
    if (assign(m_distanceKm, qMax(0.0, value)))
        emit navigationChanged();
}

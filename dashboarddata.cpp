#include "dashboarddata.h"

#include <QtGlobal>

DashboardData::DashboardData(QObject *parent)
    : QObject(parent)
{
}

int DashboardData::speed() const { return m_speed; }
QString DashboardData::speedUnit() const { return QStringLiteral("KM/H"); }
int DashboardData::batteryPercent() const { return m_batteryPercent; }
int DashboardData::rangeKm() const { return m_rangeKm; }
int DashboardData::tripKm() const { return m_tripKm; }
int DashboardData::odometerKm() const { return m_odometerKm; }
int DashboardData::temperatureC() const { return m_temperatureC; }
int DashboardData::arrivalMinutes() const { return m_arrivalMinutes; }
qreal DashboardData::distanceKm() const { return m_distanceKm; }

void DashboardData::setSpeed(int value)
{
    value = qBound(0, value, 199);
    if (m_speed == value)
        return;
    m_speed = value;
    emit speedChanged();
}

void DashboardData::setBatteryPercent(int value)
{
    value = qBound(0, value, 100);
    if (m_batteryPercent == value)
        return;
    m_batteryPercent = value;
    emit batteryChanged();
}

void DashboardData::setRangeKm(int value)
{
    value = qMax(0, value);
    if (m_rangeKm == value)
        return;
    m_rangeKm = value;
    emit batteryChanged();
}

void DashboardData::setTripKm(int value)
{
    value = qMax(0, value);
    if (m_tripKm == value)
        return;
    m_tripKm = value;
    emit tripChanged();
}

void DashboardData::setOdometerKm(int value)
{
    value = qMax(0, value);
    if (m_odometerKm == value)
        return;
    m_odometerKm = value;
    emit tripChanged();
}

void DashboardData::setTemperatureC(int value)
{
    value = qBound(-50, value, 80);
    if (m_temperatureC == value)
        return;
    m_temperatureC = value;
    emit environmentChanged();
}

void DashboardData::setArrivalMinutes(int value)
{
    value = qMax(0, value);
    if (m_arrivalMinutes == value)
        return;
    m_arrivalMinutes = value;
    emit navigationChanged();
}

void DashboardData::setDistanceKm(qreal value)
{
    value = qMax(0.0, value);
    if (qFuzzyCompare(m_distanceKm, value))
        return;
    m_distanceKm = value;
    emit navigationChanged();
}

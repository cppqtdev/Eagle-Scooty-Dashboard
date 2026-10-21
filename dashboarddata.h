#pragma once

#include <QObject>
#include <QString>

class DashboardData final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int speed READ speed WRITE setSpeed NOTIFY speedChanged)
    Q_PROPERTY(QString speedUnit READ speedUnit CONSTANT)
    Q_PROPERTY(int batteryPercent READ batteryPercent WRITE setBatteryPercent NOTIFY batteryChanged)
    Q_PROPERTY(int rangeKm READ rangeKm WRITE setRangeKm NOTIFY batteryChanged)
    Q_PROPERTY(int tripKm READ tripKm WRITE setTripKm NOTIFY tripChanged)
    Q_PROPERTY(int odometerKm READ odometerKm WRITE setOdometerKm NOTIFY tripChanged)
    Q_PROPERTY(int temperatureC READ temperatureC WRITE setTemperatureC NOTIFY environmentChanged)
    Q_PROPERTY(int arrivalMinutes READ arrivalMinutes WRITE setArrivalMinutes NOTIFY navigationChanged)
    Q_PROPERTY(qreal distanceKm READ distanceKm WRITE setDistanceKm NOTIFY navigationChanged)

public:
    explicit DashboardData(QObject *parent = nullptr);

    int speed() const;
    QString speedUnit() const;
    int batteryPercent() const;
    int rangeKm() const;
    int tripKm() const;
    int odometerKm() const;
    int temperatureC() const;
    int arrivalMinutes() const;
    qreal distanceKm() const;

    void setSpeed(int value);
    void setBatteryPercent(int value);
    void setRangeKm(int value);
    void setTripKm(int value);
    void setOdometerKm(int value);
    void setTemperatureC(int value);
    void setArrivalMinutes(int value);
    void setDistanceKm(qreal value);

signals:
    void speedChanged();
    void batteryChanged();
    void tripChanged();
    void environmentChanged();
    void navigationChanged();

private:
    int m_speed = 76;
    int m_batteryPercent = 72;
    int m_rangeKm = 136;
    int m_tripKm = 230;
    int m_odometerKm = 2030;
    int m_temperatureC = 30;
    int m_arrivalMinutes = 23;
    qreal m_distanceKm = 1.2;
};

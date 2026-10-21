#pragma once

#include <QObject>
#include <QString>

// The vehicle as the dashboard sees it: one bounded value per signal, grouped by
// what changes together. A simulator drives it on the desk; on the scooter the
// same setters are fed from the CAN bus.
class DashboardData final : public QObject
{
    Q_OBJECT

    // Motion
    Q_PROPERTY(int speed READ speed WRITE setSpeed NOTIFY motionChanged)
    Q_PROPERTY(QString speedUnit READ speedUnit CONSTANT)
    Q_PROPERTY(qreal powerKw READ powerKw WRITE setPowerKw NOTIFY motionChanged)
    Q_PROPERTY(QString gear READ gear WRITE setGear NOTIFY motionChanged)
    Q_PROPERTY(bool ready READ ready WRITE setReady NOTIFY motionChanged)

    // Ride mode
    Q_PROPERTY(RideMode rideMode READ rideMode WRITE setRideMode NOTIFY rideModeChanged)
    Q_PROPERTY(QString rideModeName READ rideModeName NOTIFY rideModeChanged)

    // Energy and charging
    Q_PROPERTY(int batteryPercent READ batteryPercent WRITE setBatteryPercent NOTIFY batteryChanged)
    Q_PROPERTY(int rangeKm READ rangeKm WRITE setRangeKm NOTIFY batteryChanged)
    Q_PROPERTY(bool charging READ charging WRITE setCharging NOTIFY chargingChanged)
    Q_PROPERTY(qreal chargePowerKw READ chargePowerKw WRITE setChargePowerKw NOTIFY chargingChanged)
    Q_PROPERTY(int chargeLimitPercent READ chargeLimitPercent WRITE setChargeLimitPercent NOTIFY chargingChanged)
    Q_PROPERTY(int minutesToFull READ minutesToFull NOTIFY chargingChanged)

    // Trip
    Q_PROPERTY(int tripKm READ tripKm WRITE setTripKm NOTIFY tripChanged)
    Q_PROPERTY(int odometerKm READ odometerKm WRITE setOdometerKm NOTIFY tripChanged)

    // Temperatures
    Q_PROPERTY(int temperatureC READ temperatureC WRITE setTemperatureC NOTIFY environmentChanged)
    Q_PROPERTY(int batteryTempC READ batteryTempC WRITE setBatteryTempC NOTIFY environmentChanged)
    Q_PROPERTY(int motorTempC READ motorTempC WRITE setMotorTempC NOTIFY environmentChanged)

    // Lamps and switches
    Q_PROPERTY(bool leftIndicator READ leftIndicator WRITE setLeftIndicator NOTIFY lampsChanged)
    Q_PROPERTY(bool rightIndicator READ rightIndicator WRITE setRightIndicator NOTIFY lampsChanged)
    Q_PROPERTY(bool lowBeam READ lowBeam WRITE setLowBeam NOTIFY lampsChanged)
    Q_PROPERTY(bool highBeam READ highBeam WRITE setHighBeam NOTIFY lampsChanged)
    Q_PROPERTY(bool sideStandDown READ sideStandDown WRITE setSideStandDown NOTIFY lampsChanged)

    // Tyres (bar)
    Q_PROPERTY(qreal tyreFrontBar READ tyreFrontBar WRITE setTyreFrontBar NOTIFY tyresChanged)
    Q_PROPERTY(qreal tyreRearBar READ tyreRearBar WRITE setTyreRearBar NOTIFY tyresChanged)
    Q_PROPERTY(qreal tyreTargetBar READ tyreTargetBar CONSTANT)

    // Faults
    Q_PROPERTY(bool motorFault READ motorFault WRITE setMotorFault NOTIFY faultsChanged)
    Q_PROPERTY(bool absFault READ absFault WRITE setAbsFault NOTIFY faultsChanged)

    // Navigation from the phone
    Q_PROPERTY(bool navigating READ navigating WRITE setNavigating NOTIFY navigationChanged)
    Q_PROPERTY(Maneuver maneuver READ maneuver WRITE setManeuver NOTIFY navigationChanged)
    Q_PROPERTY(QString street READ street WRITE setStreet NOTIFY navigationChanged)
    Q_PROPERTY(int maneuverDistanceM READ maneuverDistanceM WRITE setManeuverDistanceM NOTIFY navigationChanged)
    Q_PROPERTY(int arrivalMinutes READ arrivalMinutes WRITE setArrivalMinutes NOTIFY navigationChanged)
    Q_PROPERTY(qreal distanceKm READ distanceKm WRITE setDistanceKm NOTIFY navigationChanged)

public:
    enum RideMode { Eco, City, Sport };
    Q_ENUM(RideMode)

    enum Maneuver { Straight, TurnLeft, TurnRight, UTurn, Arrive };
    Q_ENUM(Maneuver)

    explicit DashboardData(QObject *parent = nullptr);

    int speed() const { return m_speed; }
    QString speedUnit() const { return QStringLiteral("KM/H"); }
    qreal powerKw() const { return m_powerKw; }
    QString gear() const { return m_gear; }
    bool ready() const { return m_ready; }

    RideMode rideMode() const { return m_rideMode; }
    QString rideModeName() const;

    int batteryPercent() const { return m_batteryPercent; }
    int rangeKm() const { return m_rangeKm; }
    bool charging() const { return m_charging; }
    qreal chargePowerKw() const { return m_chargePowerKw; }
    int chargeLimitPercent() const { return m_chargeLimitPercent; }
    int minutesToFull() const;

    int tripKm() const { return m_tripKm; }
    int odometerKm() const { return m_odometerKm; }

    int temperatureC() const { return m_temperatureC; }
    int batteryTempC() const { return m_batteryTempC; }
    int motorTempC() const { return m_motorTempC; }

    bool leftIndicator() const { return m_leftIndicator; }
    bool rightIndicator() const { return m_rightIndicator; }
    bool lowBeam() const { return m_lowBeam; }
    bool highBeam() const { return m_highBeam; }
    bool sideStandDown() const { return m_sideStandDown; }

    qreal tyreFrontBar() const { return m_tyreFrontBar; }
    qreal tyreRearBar() const { return m_tyreRearBar; }
    qreal tyreTargetBar() const { return 2.2; }

    bool motorFault() const { return m_motorFault; }
    bool absFault() const { return m_absFault; }

    bool navigating() const { return m_navigating; }
    Maneuver maneuver() const { return m_maneuver; }
    QString street() const { return m_street; }
    int maneuverDistanceM() const { return m_maneuverDistanceM; }
    int arrivalMinutes() const { return m_arrivalMinutes; }
    qreal distanceKm() const { return m_distanceKm; }

public slots:
    void setSpeed(int value);
    void setPowerKw(qreal value);
    void setGear(const QString &value);
    void setReady(bool value);
    void setRideMode(RideMode value);
    void cycleRideMode();
    void setBatteryPercent(int value);
    void setRangeKm(int value);
    void setCharging(bool value);
    void setChargePowerKw(qreal value);
    void setChargeLimitPercent(int value);
    void setTripKm(int value);
    void resetTrip();
    void setOdometerKm(int value);
    void setTemperatureC(int value);
    void setBatteryTempC(int value);
    void setMotorTempC(int value);
    void setLeftIndicator(bool value);
    void setRightIndicator(bool value);
    void setLowBeam(bool value);
    void setHighBeam(bool value);
    void setSideStandDown(bool value);
    void setTyreFrontBar(qreal value);
    void setTyreRearBar(qreal value);
    void setMotorFault(bool value);
    void setAbsFault(bool value);
    void setNavigating(bool value);
    void setManeuver(Maneuver value);
    void setStreet(const QString &value);
    void setManeuverDistanceM(int value);
    void setArrivalMinutes(int value);
    void setDistanceKm(qreal value);

signals:
    void motionChanged();
    void rideModeChanged();
    void batteryChanged();
    void chargingChanged();
    void tripChanged();
    void environmentChanged();
    void lampsChanged();
    void tyresChanged();
    void faultsChanged();
    void navigationChanged();

private:
    int m_speed = 0;
    qreal m_powerKw = 0.0;
    QString m_gear = QStringLiteral("N");
    bool m_ready = false;

    RideMode m_rideMode = Eco;

    int m_batteryPercent = 72;
    int m_rangeKm = 136;
    bool m_charging = false;
    qreal m_chargePowerKw = 0.0;
    int m_chargeLimitPercent = 90;

    int m_tripKm = 230;
    int m_odometerKm = 2030;

    int m_temperatureC = 30;
    int m_batteryTempC = 32;
    int m_motorTempC = 38;

    bool m_leftIndicator = false;
    bool m_rightIndicator = false;
    bool m_lowBeam = true;
    bool m_highBeam = false;
    bool m_sideStandDown = true;

    qreal m_tyreFrontBar = 2.2;
    qreal m_tyreRearBar = 2.2;

    bool m_motorFault = false;
    bool m_absFault = false;

    bool m_navigating = true;
    Maneuver m_maneuver = TurnRight;
    QString m_street = QStringLiteral("MG Road");
    int m_maneuverDistanceM = 1200;
    int m_arrivalMinutes = 23;
    qreal m_distanceKm = 8.4;
};

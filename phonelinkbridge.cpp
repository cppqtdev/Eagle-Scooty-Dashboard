#include "phonelinkbridge.h"

#include "dashboarddata.h"
#include "phonelink/iphonelink.h"
#include "vehiclesimulator.h"

#include <QImage>

namespace {

// The app knows sixteen manoeuvres; the road view draws five.
DashboardData::Maneuver toDashboard(phonelink::Maneuver maneuver)
{
    using M = phonelink::Maneuver;
    switch (maneuver) {
    case M::SlightLeft:
    case M::Left:
    case M::SharpLeft:
    case M::ForkLeft:
    case M::MergeLeft:
        return DashboardData::TurnLeft;
    case M::SlightRight:
    case M::Right:
    case M::SharpRight:
    case M::ForkRight:
    case M::MergeRight:
        return DashboardData::TurnRight;
    case M::UTurn:
    case M::UTurnRight:
        return DashboardData::UTurn;
    case M::Arrive:
        return DashboardData::Arrive;
    default:
        return DashboardData::Straight;
    }
}

} // namespace

PhoneLinkBridge::PhoneLinkBridge(phonelink::IPhoneLink *link, DashboardData *data, VehicleSimulator *simulator,
                                 QObject *parent)
    : QObject(parent), m_link(link), m_data(data), m_simulator(simulator)
{
    connect(link, &phonelink::IPhoneLink::guidanceChanged, this, &PhoneLinkBridge::syncGuidance);
    connect(link, &phonelink::IPhoneLink::connectionChanged, this, &PhoneLinkBridge::publishVehicle);

    m_publish.setSingleShot(true);
    m_publish.setInterval(250);
    connect(&m_publish, &QTimer::timeout, this, &PhoneLinkBridge::publishVehicle);
    for (auto signal : {&DashboardData::batteryChanged, &DashboardData::chargingChanged, &DashboardData::tripChanged,
                        &DashboardData::rideModeChanged, &DashboardData::faultsChanged})
        connect(data, signal, &m_publish, qOverload<>(&QTimer::start));

    syncGuidance();
}

void PhoneLinkBridge::syncGuidance()
{
    const phonelink::GuidanceInfo guidance = m_link->guidance();
    if (guidance.active) {
        m_data->setNavigating(true);
        m_data->setManeuver(toDashboard(guidance.maneuver));
        m_data->setStreet(guidance.street);
        m_data->setManeuverDistanceM(guidance.distanceMetres);
        m_data->setDistanceKm(guidance.remainingKm);
        m_data->setArrivalMinutes(guidance.remainingMinutes);
    } else if (m_guiding) {
        // The phone stopped guiding (or went away): no stale route on screen.
        m_data->setNavigating(false);
    }
    if (guidance.active != m_guiding) {
        m_guiding = guidance.active;
        if (m_simulator)
            m_simulator->setPhoneGuiding(m_guiding);
    }
}

void PhoneLinkBridge::publishVehicle()
{
    if (!m_link->isConnected())
        return;
    phonelink::VehicleSummary summary;
    summary.stateOfChargePercent = m_data->batteryPercent();
    summary.rangeKm = m_data->rangeKm();
    summary.odometerKm = m_data->odometerKm();
    summary.tripAKm = m_data->tripKm();
    summary.charging = m_data->charging() && m_data->chargePowerKw() > 0.0;
    summary.chargeComplete = m_data->charging() && m_data->chargePowerKw() <= 0.0;
    summary.rideMode = int(m_data->rideMode());
    const QString gear = m_data->gear();
    summary.gear = gear == QLatin1String("D") ? 1 : gear == QLatin1String("R") ? 2 : 0;
    summary.activeFaults = int(m_data->motorFault()) + int(m_data->absFault());
    m_link->publishVehicle(summary);
}

PhoneArtProvider::PhoneArtProvider(phonelink::IPhoneLink *link)
    : QQuickImageProvider(QQuickImageProvider::Image), m_link(link)
{
}

QImage PhoneArtProvider::requestImage(const QString &, QSize *size, const QSize &requestedSize)
{
    QImage image = QImage::fromData(m_link->albumArt());
    if (!image.isNull() && requestedSize.isValid())
        image = image.scaled(requestedSize, Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);
    if (size)
        *size = image.size();
    return image;
}

#include "phonelinkbridge.h"

#include "dashboarddata.h"
#include "languagecontroller.h"
#include "phonelink/iphonelink.h"
#include "phonelink/phonelinkcodec.h"
#include "phoneservice.h"
#include "themecontroller.h"
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
                                 ThemeController *theme, PhoneService *phone, QObject *parent)
    : QObject(parent), m_link(link), m_data(data), m_simulator(simulator), m_theme(theme), m_phone(phone)
{
    connect(link, &phonelink::IPhoneLink::guidanceChanged, this, &PhoneLinkBridge::syncGuidance);
    connect(link, &phonelink::IPhoneLink::connectionChanged, this, &PhoneLinkBridge::publishVehicle);

    m_publish.setSingleShot(true);
    m_publish.setInterval(250);
    connect(&m_publish, &QTimer::timeout, this, &PhoneLinkBridge::publishVehicle);
    for (auto signal : {&DashboardData::batteryChanged, &DashboardData::chargingChanged, &DashboardData::tripChanged,
                        &DashboardData::rideModeChanged, &DashboardData::faultsChanged})
        connect(data, signal, &m_publish, qOverload<>(&QTimer::start));

    // Settings both ways.
    connect(link, &phonelink::IPhoneLink::settingRequested, this, &PhoneLinkBridge::applySetting);
    connect(link, &phonelink::IPhoneLink::connectionChanged, this, &PhoneLinkBridge::publishSettings);
    connect(theme, &ThemeController::modeChanged, this, &PhoneLinkBridge::publishSettings);
    connect(theme, &ThemeController::brightnessChanged, this, &PhoneLinkBridge::publishSettings);
    connect(theme, &ThemeController::arrowStyleChanged, this, &PhoneLinkBridge::publishSettings);
    connect(data, &DashboardData::rideModeChanged, this, &PhoneLinkBridge::publishSettings);
    connect(data, &DashboardData::chargingChanged, this, &PhoneLinkBridge::publishSettings);
    connect(phone, &PhoneService::volumeChanged, this, &PhoneLinkBridge::publishSettings);

    syncGuidance();
    publishSettings();
}

void PhoneLinkBridge::setLanguage(LanguageController *language)
{
    m_language = language;
    connect(language, &LanguageController::currentChanged, this, &PhoneLinkBridge::publishSettings);
    publishSettings();
}

void PhoneLinkBridge::publishSettings()
{
    namespace setting = phonelink::wire::setting;
    QList<std::pair<int, int>> values{{setting::Theme, int(m_theme->mode())},
                             {setting::Brightness, m_theme->brightness()},
                             {setting::RideMode, int(m_data->rideMode())},
                             {setting::ChargeLimit, m_data->chargeLimitPercent()},
                             {setting::Volume, m_phone->volume()},
                             {setting::ArrowStyle, m_theme->arrowStyle()}};
    if (m_language)
        values.append({setting::Language, m_language->current()});
    m_link->publishSettings(values);
}

void PhoneLinkBridge::applySetting(int key, int value)
{
    namespace setting = phonelink::wire::setting;
    switch (key) {
    case setting::Theme:
        if (value >= ThemeController::Auto && value <= ThemeController::Dark)
            m_theme->setMode(ThemeController::ThemeMode(value));
        break;
    case setting::Brightness:
        m_theme->setBrightness(value);
        break;
    case setting::RideMode:
        // Never from a pocket while riding: only at a standstill.
        if (m_data->speed() == 0 && value >= DashboardData::Eco && value <= DashboardData::Sport)
            m_data->setRideMode(DashboardData::RideMode(value));
        break;
    case setting::ChargeLimit:
        if (value == 80 || value == 90 || value == 100)
            m_data->setChargeLimitPercent(value);
        break;
    case setting::Volume:
        m_phone->setVolume(value);
        break;
    case setting::ArrowStyle:
        m_theme->setArrowStyle(value);
        break;
    case setting::Language:
        if (m_language)
            m_language->setCurrent(value);
        break;
    default:
        break;   // a setting this cluster does not have
    }
    publishSettings();   // the app sees what was actually taken
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

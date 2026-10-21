#include "phonelinkbridge.h"

#include "alertcenter.h"
#include "dashboarddata.h"
#include "languagecontroller.h"
#include "phonelink/iphonelink.h"
#include "phonelink/phonelinkcodec.h"
#include "phoneservice.h"
#include "systemclock.h"
#include "themecontroller.h"
#include "vehiclesimulator.h"
#include "wifimanager.h"

#include <QImage>
#include <QNetworkInterface>

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

namespace wire = phonelink::wire;

// The cluster's page numbers (ShowPage) and the pages here.
const char *const kPages[] = {"home", "home", "diagnostics", "settings", "map", "music", "phone", "settings"};
const char *const kKeys[] = {"up", "down", "left", "right", "ok", "mode", "back"};

// Trouble codes: the high byte is the system (1 battery, 3 drive, 4 brakes, 5 tyres, 6 chassis).
struct FaultCode {
    const char *alert;
    int code;
};
const FaultCode kFaultCodes[] = {
    {"batteryCritical", 0x0101}, {"batteryLow", 0x0102}, {"batteryHot", 0x0103},
    {"motorFault", 0x0301},      {"checkEngine", 0x0302}, {"motorHot", 0x0303},
    {"abs", 0x0401},             {"tyre", 0x0501},        {"sideStand", 0x0601},
};

constexpr int kServiceIntervalKm = 3000;
const double kWhPerKm[] = {24, 28, 35};   // eco, city, sport: the simulator's figures

QString stamp(const QDateTime &when)
{
    return when.isValid() ? when.toString(QStringLiteral("d MMM HH:mm")) : QString();
}

} // namespace

PhoneLinkBridge::PhoneLinkBridge(phonelink::IPhoneLink *link, DashboardData *data, VehicleSimulator *simulator,
                                 ThemeController *theme, PhoneService *phone, QObject *parent)
    : QObject(parent), m_link(link), m_data(data), m_simulator(simulator), m_theme(theme), m_phone(phone)
{
    connect(link, &phonelink::IPhoneLink::guidanceChanged, this, &PhoneLinkBridge::syncGuidance);

    // Vehicle status, folded so a burst of changes goes out once.
    m_publish.setSingleShot(true);
    m_publish.setInterval(250);
    connect(&m_publish, &QTimer::timeout, this, &PhoneLinkBridge::publishVehicle);
    for (auto signal : {&DashboardData::batteryChanged, &DashboardData::chargingChanged, &DashboardData::tripChanged,
                        &DashboardData::rideModeChanged, &DashboardData::faultsChanged, &DashboardData::tyresChanged,
                        &DashboardData::environmentChanged})
        connect(data, signal, &m_publish, qOverload<>(&QTimer::start));
    connect(data, &DashboardData::motionChanged, this, [this] {
        const int speed = m_data->speed();
        if (speed > 0) {
            m_speedSum += speed;
            ++m_speedSamples;
            m_maxSpeed = qMax(m_maxSpeed, speed);
        }
        publishSettings();   // locked follows motion
    });

    // Settings and commands.
    connect(link, &phonelink::IPhoneLink::commandReceived, this, &PhoneLinkBridge::onCommand);
    connect(link, &phonelink::IPhoneLink::connectionChanged, this, [this] {
        publishVehicle();
        publishSettings();
        publishWifi();
    });
    connect(theme, &ThemeController::modeChanged, this, &PhoneLinkBridge::publishSettings);
    connect(theme, &ThemeController::darkChanged, this, &PhoneLinkBridge::publishSettings);
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

void PhoneLinkBridge::setClock(SystemClock *clock)
{
    m_clock = clock;
    connect(clock, &SystemClock::clock24Changed, this, &PhoneLinkBridge::publishSettings);
    publishSettings();
}

void PhoneLinkBridge::setWifi(WifiManager *wifi)
{
    m_wifi = wifi;
    connect(wifi, &WifiManager::stateChanged, this, &PhoneLinkBridge::publishWifi);
    connect(wifi, &WifiManager::networksChanged, this, [this] {
        if (m_scanAsked) {
            m_scanAsked = false;
            publishWifiNetworks();
        }
        publishWifi();
    });
    connect(m_link, &phonelink::IPhoneLink::wifiJoinRequested, this,
            [this](const QString &ssid, const QString &password) { m_wifi->connectTo(ssid, password); });
    publishWifi();
}

void PhoneLinkBridge::setAlerts(AlertCenter *alerts)
{
    m_alerts = alerts;
    connect(alerts, &AlertCenter::countChanged, this, &PhoneLinkBridge::refreshFaults);
    connect(alerts, &QAbstractItemModel::dataChanged, this, &PhoneLinkBridge::refreshFaults);
    refreshFaults();
}

void PhoneLinkBridge::setCurrentPage(const QString &page)
{
    if (m_currentPage == page)
        return;
    m_currentPage = page;
    emit currentPageChanged();
    publishSettings();
}

bool PhoneLinkBridge::moving() const
{
    return m_data->speed() > 0;
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
    summary.activeFaults = int(m_data->motorFault()) + int(m_data->absFault()) + int(m_data->checkEngine());

    // The details the app shows on its bike screen.
    wire::VehicleStatus::Details details;
    const int nextService = (m_data->odometerKm() / kServiceIntervalKm + 1) * kServiceIntervalKm;
    details.kmToService = nextService - m_data->odometerKm();
    details.serviceDue = details.kmToService <= 100;
    details.tripAWhPerKm = int(kWhPerKm[qBound(0, int(m_data->rideMode()), 2)]);
    details.tripAAverageKmhX10 = m_speedSamples > 0 ? int(m_speedSum / m_speedSamples * 10) : 0;
    details.tripAMaxKmh = m_maxSpeed;
    details.batteryC = m_data->batteryTempC();
    details.motorC = m_data->motorTempC();
    details.temperaturesValid = true;
    details.frontTyreBarX10 = qRound(m_data->tyreFrontBar() * 10);
    details.rearTyreBarX10 = qRound(m_data->tyreRearBar() * 10);
    details.minutesToCharge = m_data->charging() ? m_data->minutesToFull() : 0;
    summary.details = details;
    m_link->publishVehicle(summary);
}

void PhoneLinkBridge::publishSettings()
{
    wire::ClusterSettings settings;
    // The wire order is auto, dark, light; the theme's is auto, light, dark.
    const int mode = int(m_theme->mode());
    settings.displayMode = mode == 1 ? 2 : mode == 2 ? 1 : 0;
    settings.units = 0;   // metric only for now
    settings.brightness = m_theme->brightness();
    settings.clock24 = m_clock && m_clock->clock24();
    settings.locked = moving();
    settings.page = 0;
    for (int i = 0; i < int(std::size(kPages)); ++i) {
        if (m_currentPage == QLatin1String(kPages[i])) {
            settings.page = i;
            break;
        }
    }
    settings.dark = m_theme->dark();
    settings.rideMode = int(m_data->rideMode());
    settings.chargeLimit = m_data->chargeLimitPercent();
    settings.volume = m_phone->volume();
    settings.arrowStyle = m_theme->arrowStyle();
    settings.language = m_language ? m_language->current() : 0;
    m_link->publishClusterSettings(settings);
}

void PhoneLinkBridge::onCommand(int command, int value)
{
    namespace cmd = wire::command;
    // Settings and resets wait for a standstill; keys and pages do not.
    const bool changesSomething = command != cmd::Key && command != cmd::LongKey && command != cmd::ShowPage
                                  && command != cmd::ListFaults && command != cmd::ScanWifi;
    if (changesSomething && moving()) {
        publishSettings();   // locked: the app sees nothing changed
        return;
    }

    switch (command) {
    case cmd::DisplayMode:
        m_theme->setMode(value == 1 ? ThemeController::Dark : value == 2 ? ThemeController::Light : ThemeController::Auto);
        break;
    case cmd::Brightness:
        m_theme->setBrightness(value);
        break;
    case cmd::Clock24:
        if (m_clock)
            m_clock->setClock24(value != 0);
        break;
    case cmd::Key:
    case cmd::LongKey:
        if (value == 5)   // the mode key
            m_data->cycleRideMode();
        else if (value >= 0 && value < int(std::size(kKeys)))
            emit keyRequested(QString::fromLatin1(kKeys[value]));
        break;
    case cmd::ResetTrip:
        if (value == 0) {
            m_data->setTripKm(0);
            m_speedSum = 0;
            m_speedSamples = 0;
            m_maxSpeed = 0;
            publishVehicle();
        }
        break;
    case cmd::ShowPage:
        if (value >= 0 && value < int(std::size(kPages)))
            emit pageRequested(QString::fromLatin1(kPages[value]));
        break;
    case cmd::ListFaults:
        m_faultsAsked = true;   // the app asked: send even if it already had them
        publishFaults();
        break;
    case cmd::ClearFaults:
        for (auto it = m_faults.begin(); it != m_faults.end();) {
            if (it->active)
                ++it;
            else
                it = m_faults.erase(it);
        }
        publishFaults();
        break;
    case cmd::ScanWifi:
        if (m_wifi) {
            m_scanAsked = true;
            m_wifi->scan();
            publishWifi();
        }
        break;
    case cmd::ForgetWifi:
        if (m_wifi)
            m_wifi->disconnectNetwork();
        break;
    case cmd::RideMode:
        if (value >= DashboardData::Eco && value <= DashboardData::Sport)
            m_data->setRideMode(DashboardData::RideMode(value));
        break;
    case cmd::ChargeLimit:
        if (value == 80 || value == 90 || value == 100)
            m_data->setChargeLimitPercent(value);
        break;
    case cmd::Volume:
        m_phone->setVolume(value);
        break;
    case cmd::ArrowStyle:
        m_theme->setArrowStyle(value);
        break;
    case cmd::Language:
        if (m_language)
            m_language->setCurrent(value);
        break;
    default:
        // Units, service reset, forgetting phones: not on this cluster yet.
        break;
    }
    publishSettings();   // the app sees what was actually taken
}

void PhoneLinkBridge::publishWifi()
{
    if (!m_wifi)
        return;
    wire::WifiStatus status;
    const QString ssid = m_wifi->connectedSsid();
    if (!m_wifi->enabled())
        status.state = wire::WifiState::Off;
    else if (!ssid.isEmpty())
        status.state = wire::WifiState::Joined;
    else if (m_wifi->busy())
        status.state = wire::WifiState::Joining;
    else
        status.state = wire::WifiState::NoNetwork;
    status.ssid = ssid;
    if (status.state == wire::WifiState::Joined) {
        // The first IPv4 address on a wireless interface, for the firmware upload.
        const auto interfaces = QNetworkInterface::allInterfaces();
        for (const QNetworkInterface &iface : interfaces) {
            if (iface.type() != QNetworkInterface::Wifi || !(iface.flags() & QNetworkInterface::IsUp))
                continue;
            for (const QNetworkAddressEntry &entry : iface.addressEntries()) {
                if (entry.ip().protocol() == QAbstractSocket::IPv4Protocol) {
                    status.address = entry.ip().toString();
                    break;
                }
            }
        }
        // nmcli reports signal as a percentage; dBm is roughly half of it minus 100.
        status.rssi = m_wifi->signal() > 0 ? m_wifi->signal() / 2 - 100 : 0;
    }
    status.scanning = m_scanAsked && m_wifi->busy();
    m_link->publishWifiStatus(status);
}

void PhoneLinkBridge::publishWifiNetworks()
{
    QList<wire::WifiNetwork> networks;
    const QVariantList list = m_wifi->networks();
    const int total = int(qMin<qsizetype>(list.size(), 255));
    for (int i = 0; i < total; ++i) {
        const QVariantMap entry = list.at(i).toMap();
        wire::WifiNetwork network;
        network.index = i;
        network.total = total;
        network.ssid = entry.value(QStringLiteral("ssid")).toString();
        network.secured = entry.value(QStringLiteral("secure")).toBool();
        network.current = entry.value(QStringLiteral("connected")).toBool();
        const int percent = entry.value(QStringLiteral("signal")).toInt();
        network.rssi = percent > 0 ? percent / 2 - 100 : -90;
        networks.append(network);
    }
    m_link->publishWifiNetworks(networks);
}

void PhoneLinkBridge::refreshFaults()
{
    if (!m_alerts)
        return;
    QSet<QString> nowActive;
    for (int row = 0; row < m_alerts->rowCount(); ++row) {
        const QModelIndex index = m_alerts->index(row);
        const QString id = index.data(AlertCenter::IdRole).toString();
        const FaultCode *known = nullptr;
        for (const FaultCode &code : kFaultCodes) {
            if (id == QLatin1String(code.alert))
                known = &code;
        }
        if (!known)
            continue;   // information, messages: not trouble codes
        nowActive.insert(id);
        Fault &fault = m_faults[id];
        if (!fault.active) {
            // A new occurrence.
            fault.code = known->code;
            fault.critical = index.data(AlertCenter::SeverityRole).toInt() == AlertCenter::Critical;
            ++fault.count;
            const QDateTime now = QDateTime::currentDateTime();
            if (!fault.firstSeen.isValid())
                fault.firstSeen = now;
            fault.lastSeen = now;
        }
        fault.active = true;
        fault.title = index.data(AlertCenter::TitleRole).toString();
        fault.detail = index.data(AlertCenter::MessageRole).toString();
    }
    bool changed = false;
    for (auto it = m_faults.begin(); it != m_faults.end(); ++it) {
        const bool active = nowActive.contains(it.key());
        if (it->active != active) {
            it->active = active;
            changed = true;
        }
    }
    publishFaults();
}

void PhoneLinkBridge::publishFaults()
{
    if (!m_link->isConnected())
        return;
    QList<Fault> faults = m_faults.values();
    // Active first, then the most recent.
    std::sort(faults.begin(), faults.end(), [](const Fault &a, const Fault &b) {
        return a.active != b.active ? a.active : a.lastSeen > b.lastSeen;
    });
    QList<wire::FaultEntry> entries;
    const int total = int(qMin<qsizetype>(faults.size(), 255));
    for (int i = 0; i < total; ++i) {
        const Fault &fault = faults.at(i);
        entries.append(wire::FaultEntry{i, total, fault.code, fault.active, fault.critical, fault.count,
                                        fault.title, fault.detail, stamp(fault.firstSeen), stamp(fault.lastSeen)});
    }
    if (entries == m_lastFaults && !m_faultsAsked)
        return;   // nothing new for the app
    m_faultsAsked = false;
    m_lastFaults = entries;
    m_link->publishFaults(entries);
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

#include <QCommandLineParser>
#include <QFont>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QSettings>

#include "alertcenter.h"
#include "bluetoothmanager.h"
#include "canvehiclesource.h"
#include "dashboarddata.h"
#include "harnessinputs.h"
#include "languagecontroller.h"
#include "phonelink/protocolphonelink.h"
#include "phonelink/tcpphonetransport.h"
#include "phonelinkbridge.h"
#include "phoneservice.h"
#include "systemclock.h"
#include "themecontroller.h"
#include "vehicledocuments.h"
#include "vehiclesimulator.h"
#include "wifimanager.h"

#ifdef EAGLE_HAS_BLUETOOTH
#include "phonelink/bleperipheraltransport.h"
#endif

#include <memory>

namespace {

// Board mode: full screen on the scooter's HMI panel. Asked for with --board or
// EAGLE_BOARD=1 (set by the systemd service on the Rockchip board).
bool argumentGiven(int argc, char *argv[], const char *name)
{
    for (int i = 1; i < argc; ++i) {
        if (qstrcmp(argv[i], name) == 0)
            return true;
    }
    return false;
}

bool boardModeRequested(int argc, char *argv[])
{
    for (int i = 1; i < argc; ++i) {
        if (qstrcmp(argv[i], "--board") == 0)
            return true;
    }
    return qEnvironmentVariableIntValue("EAGLE_BOARD") == 1;
}

void loadFonts(QGuiApplication &app)
{
    // Orbitron (SIL Open Font License, fonts/Orbitron-OFL.txt), as on the SR Motard cluster.
    const int regularFontId = QFontDatabase::addApplicationFont(QStringLiteral(":/fonts/Orbitron-Regular.ttf"));
    QFontDatabase::addApplicationFont(QStringLiteral(":/fonts/Orbitron-Medium.ttf"));
    QFontDatabase::addApplicationFont(QStringLiteral(":/fonts/Orbitron-Bold.ttf"));
    if (regularFontId < 0)
        return;
    const QStringList families = QFontDatabase::applicationFontFamilies(regularFontId);
    if (families.isEmpty())
        return;
    QFont applicationFont(families.constFirst());
    applicationFont.setStyleStrategy(QFont::PreferAntialias);
    // Hinting snaps glyphs to the 1920 x 1080 pixel grid, which the panel scale then breaks.
    applicationFont.setHintingPreference(QFont::PreferNoHinting);
    app.setFont(applicationFont);
}

} // namespace

int main(int argc, char *argv[])
{
    QCoreApplication::setApplicationVersion(QStringLiteral("2.0.0"));
    QCoreApplication::setApplicationName(QStringLiteral("Eagle Dashboard"));
    QCoreApplication::setOrganizationName(QStringLiteral("TechCoderHub"));

    const bool boardMode = boardModeRequested(argc, argv);
    // Snapshots render off screen, so a covered or background window cannot stall them.
    const bool snapshotRun = argumentGiven(argc, argv, "--snapshot");
    if (snapshotRun) {
        qputenv("QT_QPA_PLATFORM", QByteArray("offscreen"));
        QQuickWindow::setGraphicsApi(QSGRendererInterface::Software);
    }
    qputenv("QT_QUICK_CONTROLS_STYLE", QByteArray("Basic"));
    if (boardMode && qEnvironmentVariableIsEmpty("QT_IM_MODULE"))
        qputenv("QT_IM_MODULE", QByteArray("qtvirtualkeyboard"));
    if (boardMode && !snapshotRun && qEnvironmentVariableIsEmpty("QT_QUICK_BACKEND")) {
        // The RK3328's Mali/EGL stack is unreliable with Qt Quick; the software
        // scene graph is steady at this panel size.
        QQuickWindow::setGraphicsApi(QSGRendererInterface::Software);
    }

    QGuiApplication app(argc, argv);
    app.setWindowIcon(QIcon(QStringLiteral(":/app.ico")));
    loadFonts(app);

    QCommandLineParser parser;
    parser.addHelpOption();
    parser.addVersionOption();
    parser.addOption({QStringLiteral("board"), QStringLiteral("Run full screen on the HMI panel.")});
    parser.addOption({QStringLiteral("no-simulator"), QStringLiteral("Wait for live vehicle data instead of simulating a ride.")});
    parser.addOption({QStringLiteral("can"), QStringLiteral("Read live vehicle data from the SocketCAN <interface> instead of simulating."),
                      QStringLiteral("interface")});
    parser.addOption({QStringLiteral("harness"),
                      QStringLiteral("Read the cluster connector's lamp, switch, speed-sensor and ADC lines as mapped "
                                     "in <map.json> (docs/Inputs.md)."),
                      QStringLiteral("map")});
    parser.addOption({QStringLiteral("phone"),
                      QStringLiteral("Where the rider's phone comes from: ble (the Ride app over Bluetooth, the "
                                     "board's default), tcp (the app or scripts/phone_link_sim.py on port 47100) or "
                                     "demo (a built-in phone, the desk's default)."),
                      QStringLiteral("source")});
    parser.addOption({QStringLiteral("snapshot"), QStringLiteral("Save every page and alert state as PNG files in <dir>, then quit."),
                      QStringLiteral("dir")});
    parser.process(app);

    // A snapshot run changes theme, arrow and the rest as it walks the screens;
    // it keeps those in its own folder, never in the rider's settings.
    if (parser.isSet(QStringLiteral("snapshot"))) {
        QSettings::setDefaultFormat(QSettings::IniFormat);
        QSettings::setPath(QSettings::IniFormat, QSettings::UserScope, parser.value(QStringLiteral("snapshot")));
    }

    ThemeController themeController;
    SystemClock systemClock;
    DashboardData dashboardData;
    VehicleSimulator simulator(&dashboardData);
    AlertCenter alertCenter(&dashboardData);
    PhoneService phone;
    VehicleDocuments documents;
    CanVehicleSource can(&dashboardData);
    HarnessInputs harnessInputs(&dashboardData);
    LanguageController language;
    language.load();
    BluetoothManager bluetooth(&phone);
    WifiManager wifi;

    QObject::connect(&dashboardData, &DashboardData::lampsChanged, &themeController,
                     [&] { themeController.setLightsOn(dashboardData.illumination()); });

    // The companion app, when asked for. The built-in phone stays for the desk.
    const QString phoneSource = parser.value(QStringLiteral("phone")).isEmpty()
                                    ? (boardMode ? QStringLiteral("ble") : QStringLiteral("demo"))
                                    : parser.value(QStringLiteral("phone"));
    std::unique_ptr<phonelink::IPhoneTransport> transport;
    if (phoneSource == QLatin1String("tcp"))
        transport = std::make_unique<phonelink::TcpPhoneTransport>();
#ifdef EAGLE_HAS_BLUETOOTH
    else if (phoneSource == QLatin1String("ble"))
        transport = std::make_unique<phonelink::BlePeripheralTransport>(QStringLiteral("Eagle"));
#endif
    else if (phoneSource != QLatin1String("demo"))
        qWarning().noquote() << "No phone link" << phoneSource << "in this build; using the built-in phone";

    std::unique_ptr<phonelink::ProtocolPhoneLink> phoneLink;
    std::unique_ptr<PhoneLinkBridge> phoneBridge;
    if (transport) {
        phonelink::ProtocolPhoneLink::Options options;
        options.firmware = QCoreApplication::applicationVersion();
        phoneLink = std::make_unique<phonelink::ProtocolPhoneLink>(std::move(transport), options);
        phone.attachLink(phoneLink.get());
        phoneBridge = std::make_unique<PhoneLinkBridge>(phoneLink.get(), &dashboardData, &simulator,
                                                        &themeController, &phone);
        phoneBridge->setLanguage(&language);
        phoneBridge->setClock(&systemClock);
        phoneBridge->setWifi(&wifi);
        phoneBridge->setAlerts(&alertCenter);
        phoneLink->start();
    }

    QObject::connect(&phone, &PhoneService::messageReceived, &alertCenter,
                     [&alertCenter](const QString &from, const QString &text) {
                         alertCenter.post(QStringLiteral("message"), AlertCenter::Info, from, text,
                                          QStringLiteral("message"), 7000);
                     });
    QObject::connect(&phone, &PhoneService::callMissed, &alertCenter, [&alertCenter](const QString &name) {
        alertCenter.post(QStringLiteral("missedCall"), AlertCenter::Info, QObject::tr("Missed call"), name,
                         QStringLiteral("call"), 7000);
    });

    qmlRegisterUncreatableType<DashboardData>("Eagle.Backend", 1, 0, "Vehicle", QStringLiteral("Use dashboardData"));
    qmlRegisterUncreatableType<PhoneService>("Eagle.Backend", 1, 0, "Phone", QStringLiteral("Use phone"));
    qmlRegisterUncreatableType<AlertCenter>("Eagle.Backend", 1, 0, "Alerts", QStringLiteral("Use alertCenter"));
    qmlRegisterSingletonType(QUrl(QStringLiteral("qrc:/StyleTheme.qml")), "Style", 1, 0, "Style");
    qmlRegisterSingletonType(QUrl(QStringLiteral("qrc:/Component/BlinkClock.qml")), "Eagle.Blink", 1, 0, "BlinkClock");

    QQmlApplicationEngine engine;
    QQmlContext *context = engine.rootContext();
    language.setEngine(&engine);
    context->setContextProperty(QStringLiteral("language"), &language);
    // The app's keys and pages reach the UI through it; null with the built-in phone.
    context->setContextProperty(QStringLiteral("phoneLinkBridge"), phoneBridge.get());
    if (phoneLink)
        engine.addImageProvider(QStringLiteral("phoneart"), new PhoneArtProvider(phoneLink.get()));
    context->setContextProperty(QStringLiteral("themeController"), &themeController);
    context->setContextProperty(QStringLiteral("systemClock"), &systemClock);
    context->setContextProperty(QStringLiteral("dashboardData"), &dashboardData);
    context->setContextProperty(QStringLiteral("simulator"), &simulator);
    context->setContextProperty(QStringLiteral("alertCenter"), &alertCenter);
    context->setContextProperty(QStringLiteral("phone"), &phone);
    context->setContextProperty(QStringLiteral("vehicleDocuments"), &documents);
    context->setContextProperty(QStringLiteral("bluetooth"), &bluetooth);
    context->setContextProperty(QStringLiteral("canSource"), &can);
    context->setContextProperty(QStringLiteral("harness"), &harnessInputs);
    context->setContextProperty(QStringLiteral("wifi"), &wifi);
    context->setContextProperty(QStringLiteral("boardMode"), boardMode);
    context->setContextProperty(QStringLiteral("snapshotDir"), parser.value(QStringLiteral("snapshot")));
    // Shader effects (shadows, glows) need the GPU scene graph.
    context->setContextProperty(QStringLiteral("effectsEnabled"),
                                QQuickWindow::graphicsApi() != QSGRendererInterface::Software);

    const QUrl url(QStringLiteral("qrc:/main.qml"));
    // objectCreationFailed needs Qt 6.4; the board image has 6.2.
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated, &app,
                     [url](QObject *object, const QUrl &objectUrl) {
                         if (!object && url == objectUrl)
                             QCoreApplication::exit(-1);
                     }, Qt::QueuedConnection);
    engine.load(url);

    // Live data when a CAN interface is given and opens; otherwise the simulated ride.
    const QString canInterface = parser.value(QStringLiteral("can"));
    const bool liveCan = !canInterface.isEmpty() && can.open(canInterface);
    if (!canInterface.isEmpty())
        qInfo().noquote() << can.status();
    // The connector's own lines, alone or beside CAN (a lamp wired straight to
    // the cluster and the rest on the bus).
    const QString harnessMap = parser.value(QStringLiteral("harness"));
    const bool liveHarness = !harnessMap.isEmpty() && harnessInputs.open(harnessMap);
    if (!harnessMap.isEmpty())
        qInfo().noquote() << harnessInputs.status();
    if (liveHarness && !liveCan)
        dashboardData.setReady(true); // powered by the ignition: on means ready
    const bool live = liveCan || liveHarness;
    if (!live && !parser.isSet(QStringLiteral("no-simulator")))
        simulator.keyOn();

    return app.exec();
}

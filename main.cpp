#include <QCommandLineParser>
#include <QFont>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>

#include "alertcenter.h"
#include "bluetoothmanager.h"
#include "canvehiclesource.h"
#include "dashboarddata.h"
#include "phoneservice.h"
#include "systemclock.h"
#include "themecontroller.h"
#include "vehicledocuments.h"
#include "vehiclesimulator.h"
#include "wifimanager.h"

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
    parser.addOption({QStringLiteral("snapshot"), QStringLiteral("Save every page and alert state as PNG files in <dir>, then quit."),
                      QStringLiteral("dir")});
    parser.process(app);

    ThemeController themeController;
    SystemClock systemClock;
    DashboardData dashboardData;
    VehicleSimulator simulator(&dashboardData);
    AlertCenter alertCenter(&dashboardData);
    PhoneService phone;
    VehicleDocuments documents;
    CanVehicleSource can(&dashboardData);
    BluetoothManager bluetooth(&phone);
    WifiManager wifi;

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

    QQmlApplicationEngine engine;
    QQmlContext *context = engine.rootContext();
    context->setContextProperty(QStringLiteral("themeController"), &themeController);
    context->setContextProperty(QStringLiteral("systemClock"), &systemClock);
    context->setContextProperty(QStringLiteral("dashboardData"), &dashboardData);
    context->setContextProperty(QStringLiteral("simulator"), &simulator);
    context->setContextProperty(QStringLiteral("alertCenter"), &alertCenter);
    context->setContextProperty(QStringLiteral("phone"), &phone);
    context->setContextProperty(QStringLiteral("vehicleDocuments"), &documents);
    context->setContextProperty(QStringLiteral("bluetooth"), &bluetooth);
    context->setContextProperty(QStringLiteral("canSource"), &can);
    context->setContextProperty(QStringLiteral("wifi"), &wifi);
    context->setContextProperty(QStringLiteral("boardMode"), boardMode);
    context->setContextProperty(QStringLiteral("snapshotDir"), parser.value(QStringLiteral("snapshot")));
    // Shader effects (shadows, glows) need the GPU scene graph.
    context->setContextProperty(QStringLiteral("effectsEnabled"),
                                QQuickWindow::graphicsApi() != QSGRendererInterface::Software);

    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app,
                     [] { QCoreApplication::exit(-1); }, Qt::QueuedConnection);
    engine.load(url);

    // Live data when a CAN interface is given and opens; otherwise the simulated ride.
    const QString canInterface = parser.value(QStringLiteral("can"));
    const bool live = !canInterface.isEmpty() && can.open(canInterface);
    if (!canInterface.isEmpty())
        qInfo().noquote() << can.status();
    if (!live && !parser.isSet(QStringLiteral("no-simulator")))
        simulator.keyOn();

    return app.exec();
}

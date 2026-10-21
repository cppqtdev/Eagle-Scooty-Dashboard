#include <QCommandLineParser>
#include <QFont>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>

#include "alertcenter.h"
#include "dashboarddata.h"
#include "phoneservice.h"
#include "systemclock.h"
#include "themecontroller.h"
#include "vehicledocuments.h"
#include "vehiclesimulator.h"

namespace {

// Board mode: full screen on the scooter's HMI panel. Asked for with --board or
// EAGLE_BOARD=1 (set by the systemd service on the Rockchip board).
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
    const int regularFontId = QFontDatabase::addApplicationFont(QStringLiteral(":/fonts/HelveticaNeueLTCom-Roman.ttf"));
    QFontDatabase::addApplicationFont(QStringLiteral(":/fonts/HelveticaNeueLTCom-Lt.ttf"));
    QFontDatabase::addApplicationFont(QStringLiteral(":/fonts/HelveticaNeueLTCom-Md.ttf"));
    QFontDatabase::addApplicationFont(QStringLiteral(":/fonts/HelveticaNeueLTCom-Bd.ttf"));
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
    qputenv("QT_QUICK_CONTROLS_STYLE", QByteArray("Basic"));
    if (boardMode && qEnvironmentVariableIsEmpty("QT_QUICK_BACKEND")) {
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
    parser.process(app);

    ThemeController themeController;
    SystemClock systemClock;
    DashboardData dashboardData;
    VehicleSimulator simulator(&dashboardData);
    AlertCenter alertCenter(&dashboardData);
    PhoneService phone;
    VehicleDocuments documents;

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
    context->setContextProperty(QStringLiteral("boardMode"), boardMode);
    // Shader effects (shadows, glows) need the GPU scene graph.
    context->setContextProperty(QStringLiteral("effectsEnabled"),
                                QQuickWindow::graphicsApi() != QSGRendererInterface::Software);

    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app,
                     [] { QCoreApplication::exit(-1); }, Qt::QueuedConnection);
    engine.load(url);

    if (!parser.isSet(QStringLiteral("no-simulator")))
        simulator.keyOn();

    return app.exec();
}

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QFont>
#include <QFontDatabase>
#include <QIcon>

#include "dashboarddata.h"
#include "systemclock.h"
#include "themecontroller.h"

int main(int argc, char *argv[])
{
    QCoreApplication::setApplicationVersion("1.0.0");
    QCoreApplication::setApplicationName("Eagle Theme");
    QCoreApplication::setOrganizationName("TechCoderHub");

    qputenv("QT_QUICK_CONTROLS_STYLE", QByteArray("Basic"));
    QGuiApplication app(argc, argv);
    app.setWindowIcon(QIcon(":/app.ico"));

    const int regularFontId = QFontDatabase::addApplicationFont(
        QStringLiteral(":/fonts/HelveticaNeueLTCom-Roman.ttf"));
    QFontDatabase::addApplicationFont(QStringLiteral(":/fonts/HelveticaNeueLTCom-Lt.ttf"));
    QFontDatabase::addApplicationFont(QStringLiteral(":/fonts/HelveticaNeueLTCom-Md.ttf"));
    QFontDatabase::addApplicationFont(QStringLiteral(":/fonts/HelveticaNeueLTCom-Bd.ttf"));

    if (regularFontId >= 0) {
        const QStringList families = QFontDatabase::applicationFontFamilies(regularFontId);
        if (!families.isEmpty()) {
            QFont applicationFont(families.constFirst());
            applicationFont.setStyleStrategy(QFont::PreferAntialias);
            app.setFont(applicationFont);
        }
    }

    QQmlApplicationEngine engine;
    ThemeController themeController;
    SystemClock systemClock;
    DashboardData dashboardData;
    engine.rootContext()->setContextProperty(QStringLiteral("themeController"), &themeController);
    engine.rootContext()->setContextProperty(QStringLiteral("systemClock"), &systemClock);
    engine.rootContext()->setContextProperty(QStringLiteral("dashboardData"), &dashboardData);

    qmlRegisterSingletonType(QStringLiteral("qrc:/StyleTheme.qml"),"Style",1,0,"Style");

    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}

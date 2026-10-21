#include "systemclock.h"

#include <QLocale>
#include <QSettings>

namespace {
constexpr auto kClock24Key = "display/clock24";
}

SystemClock::SystemClock(QObject *parent)
    : QObject(parent)
{
    m_clock24 = QSettings().value(QLatin1String(kClock24Key), false).toBool();
    m_timer.setInterval(1'000);
    m_timer.setTimerType(Qt::CoarseTimer);
    connect(&m_timer, &QTimer::timeout, this, &SystemClock::update);
    m_timer.start();
    update();
}

QString SystemClock::dateText() const
{
    return QLocale().toString(QDateTime::currentDateTime().date(), QStringLiteral("d MMMM yyyy"));
}

QString SystemClock::timeText() const
{
    return QLocale().toString(QDateTime::currentDateTime().time(),
                              m_clock24 ? QStringLiteral("HH:mm") : QStringLiteral("hh:mm AP"));
}

void SystemClock::setClock24(bool on)
{
    if (m_clock24 == on)
        return;
    m_clock24 = on;
    QSettings().setValue(QLatin1String(kClock24Key), on);
    emit clock24Changed();
    emit changed();
}

void SystemClock::update()
{
    const QString stamp = QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMddHHmm"));
    if (m_stamp == stamp)
        return;

    m_stamp = stamp;
    emit changed();
}

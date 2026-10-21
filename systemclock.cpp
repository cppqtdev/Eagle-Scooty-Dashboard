#include "systemclock.h"

#include <QLocale>

SystemClock::SystemClock(QObject *parent)
    : QObject(parent)
{
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
    return QLocale().toString(QDateTime::currentDateTime().time(), QStringLiteral("hh:mm AP"));
}

void SystemClock::update()
{
    const QString stamp = QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMddHHmm"));
    if (m_stamp == stamp)
        return;

    m_stamp = stamp;
    emit changed();
}

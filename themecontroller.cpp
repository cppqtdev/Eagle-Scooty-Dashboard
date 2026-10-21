#include "themecontroller.h"

#include <QDateTime>
#include <QSettings>

namespace {
constexpr auto kThemeModeKey = "appearance/themeMode";
constexpr auto kLegacyDarkThemeKey = "appearance/darkTheme";
constexpr auto kBrightnessKey = "display/brightness";
constexpr auto kArrowStyleKey = "navigation/arrowStyle";
}

ThemeController::ThemeController(QObject *parent)
    : QObject(parent)
{
    QSettings settings;
    if (settings.contains(QLatin1String(kThemeModeKey))) {
        m_mode = static_cast<ThemeMode>(
            qBound(int(Auto), settings.value(QLatin1String(kThemeModeKey)).toInt(), int(Dark)));
    } else if (settings.contains(QLatin1String(kLegacyDarkThemeKey))) {
        m_mode = settings.value(QLatin1String(kLegacyDarkThemeKey)).toBool() ? Dark : Light;
    }
    m_brightness = qBound(20, settings.value(QLatin1String(kBrightnessKey), 76).toInt(), 100);
    m_arrowStyle = qBound(0, settings.value(QLatin1String(kArrowStyleKey), 4).toInt(), 4);
    m_dark = m_mode == Auto ? automaticDark() : m_mode == Dark;

    m_clockTimer.setInterval(60'000);
    m_clockTimer.setTimerType(Qt::VeryCoarseTimer);
    connect(&m_clockTimer, &QTimer::timeout, this, &ThemeController::refreshAutomaticTheme);
    m_clockTimer.start();
}

ThemeController::ThemeMode ThemeController::mode() const
{
    return m_mode;
}

bool ThemeController::dark() const
{
    return m_dark;
}

int ThemeController::brightness() const
{
    return m_brightness;
}

void ThemeController::setMode(ThemeMode mode)
{
    if (mode < Auto || mode > Dark || m_mode == mode)
        return;

    m_mode = mode;
    QSettings().setValue(QLatin1String(kThemeModeKey), int(m_mode));
    emit modeChanged();

    const bool nextDark = m_mode == Auto ? automaticDark() : m_mode == Dark;
    if (m_dark != nextDark) {
        m_dark = nextDark;
        emit darkChanged();
    }
}

void ThemeController::setDark(bool dark)
{
    setMode(dark ? Dark : Light);
}

void ThemeController::setBrightness(int brightness)
{
    brightness = qBound(20, brightness, 100);
    if (m_brightness == brightness)
        return;

    m_brightness = brightness;
    QSettings().setValue(QLatin1String(kBrightnessKey), m_brightness);
    emit brightnessChanged();
}

void ThemeController::setArrowStyle(int style)
{
    style = qBound(0, style, 4);
    if (m_arrowStyle == style)
        return;
    m_arrowStyle = style;
    QSettings().setValue(QLatin1String(kArrowStyleKey), m_arrowStyle);
    emit arrowStyleChanged();
}

void ThemeController::toggle()
{
    setDark(!m_dark);
}

bool ThemeController::automaticDark() const
{
    const int hour = QDateTime::currentDateTime().time().hour();
    return m_lightsOn || hour < 6 || hour >= 18;
}

void ThemeController::setLightsOn(bool on)
{
    if (m_lightsOn == on)
        return;
    m_lightsOn = on;
    refreshAutomaticTheme();
}

void ThemeController::refreshAutomaticTheme()
{
    if (m_mode != Auto)
        return;

    const bool nextDark = automaticDark();
    if (m_dark != nextDark) {
        m_dark = nextDark;
        emit darkChanged();
    }
}

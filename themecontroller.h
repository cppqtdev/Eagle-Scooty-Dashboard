#pragma once

#include <QObject>
#include <QTimer>

class ThemeController final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(ThemeMode mode READ mode WRITE setMode NOTIFY modeChanged)
    Q_PROPERTY(bool dark READ dark WRITE setDark NOTIFY darkChanged)
    Q_PROPERTY(int brightness READ brightness WRITE setBrightness NOTIFY brightnessChanged)
    // How the navigation arrow is drawn: 0 solid, 1 ribbon, 2 chevrons, 3 outline, 4 sign.
    Q_PROPERTY(int arrowStyle READ arrowStyle WRITE setArrowStyle NOTIFY arrowStyleChanged)

public:
    enum ThemeMode {
        Auto,
        Light,
        Dark
    };
    Q_ENUM(ThemeMode)

    explicit ThemeController(QObject *parent = nullptr);

    ThemeMode mode() const;
    bool dark() const;
    int brightness() const;
    int arrowStyle() const { return m_arrowStyle; }

public slots:
    void setMode(ThemeMode mode);
    void setDark(bool dark);
    void setBrightness(int brightness);
    void setArrowStyle(int style);
    void toggle();
    // The bike's lights are on: Auto turns dark with them, whatever the hour.
    void setLightsOn(bool on);

signals:
    void modeChanged();
    void darkChanged();
    void brightnessChanged();
    void arrowStyleChanged();

private:
    bool automaticDark() const;
    void refreshAutomaticTheme();

    ThemeMode m_mode = Auto;
    bool m_dark = false;
    bool m_lightsOn = false;
    int m_brightness = 76;
    int m_arrowStyle = 4;
    QTimer m_clockTimer;
};

#pragma once

#include <QObject>
#include <QTimer>

class ThemeController final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(ThemeMode mode READ mode WRITE setMode NOTIFY modeChanged)
    Q_PROPERTY(bool dark READ dark WRITE setDark NOTIFY darkChanged)
    Q_PROPERTY(int brightness READ brightness WRITE setBrightness NOTIFY brightnessChanged)

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

public slots:
    void setMode(ThemeMode mode);
    void setDark(bool dark);
    void setBrightness(int brightness);
    void toggle();

signals:
    void modeChanged();
    void darkChanged();
    void brightnessChanged();

private:
    bool automaticDark() const;
    void refreshAutomaticTheme();

    ThemeMode m_mode = Auto;
    bool m_dark = false;
    int m_brightness = 76;
    QTimer m_clockTimer;
};

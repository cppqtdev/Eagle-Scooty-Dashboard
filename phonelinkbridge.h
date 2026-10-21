#pragma once

#include <QDateTime>
#include <QHash>
#include <QList>

#include "phonelink/phonelinkcodec.h"
#include <QObject>
#include <QQuickImageProvider>
#include <QTimer>

class AlertCenter;
class DashboardData;
class LanguageController;
class PhoneService;
class SystemClock;
class ThemeController;
class VehicleSimulator;
class WifiManager;
namespace phonelink { class IPhoneLink; }

// Joins the Ride app to the dashboard, speaking what the app speaks
// (docs/PhoneLink.md, 1.2):
//  - its turn-by-turn drives the navigation screens while it guides;
//  - the bike's status and details (trip, service, efficiency, temperatures,
//    tyres) go back to the app;
//  - the app's cluster commands change settings (refused while moving), press
//    keys and open pages, and it sees the cluster's settings;
//  - the app hands the cluster a Wi-Fi network, asks for a scan and sees the
//    connection; it reads and clears the trouble-code log.
class PhoneLinkBridge final : public QObject
{
    Q_OBJECT
    // The page on screen, set by the UI, reported in the cluster's settings.
    Q_PROPERTY(QString currentPage READ currentPage WRITE setCurrentPage NOTIFY currentPageChanged)

public:
    PhoneLinkBridge(phonelink::IPhoneLink *link, DashboardData *data, VehicleSimulator *simulator,
                    ThemeController *theme, PhoneService *phone, QObject *parent = nullptr);

    // The parts that are optional on a given build; each switches on its messages.
    void setLanguage(LanguageController *language);
    void setClock(SystemClock *clock);
    void setWifi(WifiManager *wifi);
    void setAlerts(AlertCenter *alerts);

    QString currentPage() const { return m_currentPage; }
    void setCurrentPage(const QString &page);

signals:
    void currentPageChanged();
    // For the UI: a handlebar key from the app ("up", "down", "left", "right", "ok", "back")
    // and a page to show ("home", "map", ...).
    void keyRequested(const QString &key);
    void pageRequested(const QString &page);

private:
    void syncGuidance();
    void publishVehicle();
    void publishSettings();
    void publishWifi();
    void publishWifiNetworks();
    void refreshFaults();
    void publishFaults();
    void onCommand(int command, int value);
    bool moving() const;

    phonelink::IPhoneLink *m_link;
    DashboardData *m_data;
    VehicleSimulator *m_simulator;
    ThemeController *m_theme;
    PhoneService *m_phone;
    LanguageController *m_language = nullptr;
    SystemClock *m_clock = nullptr;
    WifiManager *m_wifi = nullptr;
    AlertCenter *m_alerts = nullptr;

    bool m_guiding = false;
    QString m_currentPage = QStringLiteral("home");
    QTimer m_publish; // folds a burst of vehicle changes into one message

    // Speeds over trip A, for the app's trip figures.
    double m_speedSum = 0;
    int m_speedSamples = 0;
    int m_maxSpeed = 0;

    bool m_scanAsked = false;

    struct Fault {
        int code = 0;
        bool critical = false;
        bool active = false;
        int count = 0;
        QString title;
        QString detail;
        QDateTime firstSeen;
        QDateTime lastSeen;
    };
    QHash<QString, Fault> m_faults;   // by alert id, active and stored
    QList<phonelink::wire::FaultEntry> m_lastFaults;
    bool m_faultsAsked = false;
};

// image://phoneart/<id>: the cover of the track the phone is playing.
class PhoneArtProvider final : public QQuickImageProvider
{
public:
    explicit PhoneArtProvider(phonelink::IPhoneLink *link);
    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;

private:
    phonelink::IPhoneLink *m_link;
};

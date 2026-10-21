#pragma once

#include <QObject>
#include <QQuickImageProvider>
#include <QTimer>

class DashboardData;
class PhoneService;
class ThemeController;
class VehicleSimulator;
namespace phonelink { class IPhoneLink; }

// Joins the Ride app to the dashboard: its turn-by-turn drives the
// navigation screens while it guides, the bike's battery, range, odometer,
// mode and faults go back to the app, and the app reads and changes the
// cluster's settings (docs/PhoneLink.md, 1.2).
class PhoneLinkBridge final : public QObject
{
    Q_OBJECT

public:
    PhoneLinkBridge(phonelink::IPhoneLink *link, DashboardData *data, VehicleSimulator *simulator,
                    ThemeController *theme, PhoneService *phone, QObject *parent = nullptr);

private:
    void syncGuidance();
    void publishVehicle();
    void publishSettings();
    void applySetting(int key, int value);

    phonelink::IPhoneLink *m_link;
    DashboardData *m_data;
    VehicleSimulator *m_simulator;
    ThemeController *m_theme;
    PhoneService *m_phone;
    bool m_guiding = false;
    QTimer m_publish; // folds a burst of vehicle changes into one message
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

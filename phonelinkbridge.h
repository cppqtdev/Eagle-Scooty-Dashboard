#pragma once

#include <QObject>
#include <QQuickImageProvider>
#include <QTimer>

class DashboardData;
class VehicleSimulator;
namespace phonelink { class IPhoneLink; }

// Joins the Ride app to the dashboard: its turn-by-turn drives the
// navigation screens while it guides, and the bike's battery, range, odometer,
// mode and faults go back to the app (docs/PhoneLink.md).
class PhoneLinkBridge final : public QObject
{
    Q_OBJECT

public:
    PhoneLinkBridge(phonelink::IPhoneLink *link, DashboardData *data, VehicleSimulator *simulator,
                    QObject *parent = nullptr);

private:
    void syncGuidance();
    void publishVehicle();

    phonelink::IPhoneLink *m_link;
    DashboardData *m_data;
    VehicleSimulator *m_simulator;
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

#include "iphonelink.h"
#include "phonelinklog.h"

Q_LOGGING_CATEGORY(lcPhoneLink, "eagle.phonelink")

namespace phonelink {

IPhoneLink::IPhoneLink(QObject *parent) : QObject(parent) {}

IPhoneLink::~IPhoneLink() = default;

bool IPhoneLink::phoneCharging() const
{
    return false;
}

QByteArray IPhoneLink::albumArt() const
{
    return {};
}

std::optional<PhoneNotification> IPhoneLink::notification() const
{
    return std::nullopt;
}

QList<PhoneListEntry> IPhoneLink::contacts() const
{
    return {};
}

QList<PhoneListEntry> IPhoneLink::reminders() const
{
    return {};
}

void IPhoneLink::callContact(int slot)
{
    Q_UNUSED(slot)
}

void IPhoneLink::publishVehicle(const VehicleSummary &summary)
{
    Q_UNUSED(summary)
}

void IPhoneLink::publishSettings(const QList<std::pair<int, int>> &values)
{
    Q_UNUSED(values)
}

} // namespace phonelink

#include "vehicledocuments.h"

namespace {
constexpr int kExpiringDays = 30;
}

VehicleDocuments::VehicleDocuments(QObject *parent)
    : QObject(parent)
    , m_today(QDate::currentDate())
{
    // Dates are relative to today so the demo always shows one of each status.
    const QString rider = QStringLiteral("rider");
    const QString vehicle = QStringLiteral("vehicle");
    m_documents = {
        {QStringLiteral("licence"), tr("Driving Licence"), QStringLiteral("KA05 •••• ••••391"),
         tr("Motorcycle with gear, LMV"), m_today.addYears(9), QStringLiteral("qrc:/Icons/doc/driving.png"), rider},
        {QStringLiteral("aadhaar"), tr("Aadhaar"), QStringLiteral("•••• •••• 4821"), tr("Identity and address"), {},
         QStringLiteral("qrc:/Icons/doc/Adhaar.png"), rider},
        {QStringLiteral("pan"), tr("PAN Card"), QStringLiteral("•••••1234•"), tr("Income tax identity"), {},
         QStringLiteral("qrc:/Icons/doc/pencard.png"), rider},
        {QStringLiteral("rc"), tr("Registration Certificate"), QStringLiteral("KA 05 •• ••42"),
         tr("RTO Bengaluru South"), m_today.addYears(13), {}, vehicle},
        {QStringLiteral("insurance"), tr("Insurance"), QStringLiteral("POL-••••-7731"),
         tr("Comprehensive, own damage + third party"), m_today.addDays(21), {}, vehicle},
        {QStringLiteral("warranty"), tr("Battery Warranty"), QStringLiteral("BAT-3.2K-••••58"),
         tr("5 years or 50,000 km"), m_today.addYears(3).addMonths(4), {}, vehicle},
        {QStringLiteral("service"), tr("Service Book"), QStringLiteral("SB-••••-019"),
         tr("Next service due"), m_today.addDays(-6), {}, vehicle},
    };
}

QVariantList VehicleDocuments::documents() const
{
    QVariantList list;
    for (const Document &document : m_documents) {
        list.append(QVariantMap{{QStringLiteral("kind"), document.kind},
                                {QStringLiteral("title"), document.title},
                                {QStringLiteral("number"), document.number},
                                {QStringLiteral("issuer"), document.issuer},
                                {QStringLiteral("validUntil"), document.validUntil.isValid()
                                                                   ? document.validUntil.toString(QStringLiteral("d MMM yyyy"))
                                                                   : tr("No expiry")},
                                {QStringLiteral("daysLeft"), document.validUntil.isValid() ? m_today.daysTo(document.validUntil) : -1},
                                {QStringLiteral("status"), statusOf(document)},
                                {QStringLiteral("image"), document.image},
                                {QStringLiteral("group"), document.group}});
    }
    return list;
}

int VehicleDocuments::attentionCount() const
{
    int count = 0;
    for (const Document &document : m_documents) {
        if (statusOf(document) != QLatin1String("valid"))
            ++count;
    }
    return count;
}

void VehicleDocuments::setToday(const QDate &today)
{
    m_today = today;
    emit documentsChanged();
}

QString VehicleDocuments::statusOf(const Document &document) const
{
    if (!document.validUntil.isValid())
        return QStringLiteral("valid");
    const qint64 days = m_today.daysTo(document.validUntil);
    if (days < 0)
        return QStringLiteral("expired");
    if (days <= kExpiringDays)
        return QStringLiteral("expiring");
    return QStringLiteral("valid");
}

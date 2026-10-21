#include "alertcenter.h"

#include "dashboarddata.h"

AlertCenter::AlertCenter(DashboardData *data, QObject *parent)
    : QAbstractListModel(parent)
    , m_data(data)
{
    for (auto signal : {&DashboardData::motionChanged, &DashboardData::batteryChanged,
                        &DashboardData::chargingChanged, &DashboardData::environmentChanged,
                        &DashboardData::lampsChanged, &DashboardData::tyresChanged,
                        &DashboardData::faultsChanged}) {
        connect(m_data, signal, this, &AlertCenter::evaluate);
    }
    evaluate();
}

int AlertCenter::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : int(m_alerts.size());
}

QVariant AlertCenter::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_alerts.size())
        return {};
    const Alert &alert = m_alerts.at(index.row());
    switch (role) {
    case IdRole: return alert.id;
    case SeverityRole: return int(alert.severity);
    case TitleRole: return alert.title;
    case MessageRole: return alert.message;
    case IconRole: return alert.icon;
    case AcknowledgedRole: return alert.acknowledged;
    }
    return {};
}

QHash<int, QByteArray> AlertCenter::roleNames() const
{
    return {{IdRole, "alertId"}, {SeverityRole, "severity"}, {TitleRole, "title"},
            {MessageRole, "message"}, {IconRole, "icon"}, {AcknowledgedRole, "acknowledged"}};
}

QVariantMap AlertCenter::banner() const
{
    const Alert *alert = top(false);
    return alert ? toMap(*alert) : QVariantMap{};
}

QVariantMap AlertCenter::critical() const
{
    const Alert *alert = top(true);
    return alert ? toMap(*alert) : QVariantMap{};
}

bool AlertCenter::hasCritical() const
{
    return top(true) != nullptr;
}

void AlertCenter::acknowledge(const QString &id)
{
    const int row = indexOf(id);
    if (row < 0 || m_alerts[row].acknowledged)
        return;
    m_alerts[row].acknowledged = true;
    emit dataChanged(index(row), index(row), {AcknowledgedRole});
    emit bannerChanged();
}

void AlertCenter::post(const QString &id, int severity, const QString &title, const QString &message,
                       const QString &icon, int timeoutMs)
{
    clear(id);
    raise(id, static_cast<Severity>(qBound(0, severity, 2)), title, message, icon);
    if (timeoutMs <= 0)
        return;
    QTimer *timer = m_expiry.value(id);
    if (!timer) {
        timer = new QTimer(this);
        timer->setSingleShot(true);
        connect(timer, &QTimer::timeout, this, [this, id] { clear(id); });
        m_expiry.insert(id, timer);
    }
    timer->start(timeoutMs);
}

void AlertCenter::evaluate()
{
    const int battery = m_data->batteryPercent();
    const bool moving = m_data->speed() > 2;

    setCondition(m_data->motorFault(), !m_data->motorFault(), QStringLiteral("motorFault"), Critical,
                 tr("Motor fault"), tr("Power is cut. Pull over safely and switch off."), QStringLiteral("motor"));
    setCondition(m_data->sideStandDown() && moving, !m_data->sideStandDown() || m_data->speed() == 0,
                 QStringLiteral("sideStand"), Critical, tr("Side stand down"),
                 tr("Stop and raise the side stand before riding."), QStringLiteral("sideStand"));
    setCondition(battery <= 5 && !m_data->charging(), battery >= 8 || m_data->charging(),
                 QStringLiteral("batteryCritical"), Critical, tr("Battery critically low"),
                 tr("%1% left. Find a charger now; top speed is limited.").arg(battery), QStringLiteral("battery"));
    setCondition(battery <= 15 && battery > 5 && !m_data->charging(), battery >= 18 || battery <= 5 || m_data->charging(),
                 QStringLiteral("batteryLow"), Warning, tr("Low battery"),
                 tr("%1% left, about %2 km of range.").arg(battery).arg(m_data->rangeKm()), QStringLiteral("battery"));
    setCondition(m_data->batteryTempC() >= 65, m_data->batteryTempC() <= 58, QStringLiteral("batteryHotCritical"),
                 Critical, tr("Battery overheating"), tr("Power is limited. Stop and let the battery cool."),
                 QStringLiteral("batteryTemp"));
    setCondition(m_data->batteryTempC() >= 55 && m_data->batteryTempC() < 65, m_data->batteryTempC() <= 50,
                 QStringLiteral("batteryHot"), Warning, tr("Battery hot"),
                 tr("%1 °C. Power is reduced until it cools.").arg(m_data->batteryTempC()), QStringLiteral("batteryTemp"));
    setCondition(m_data->motorTempC() >= 90, m_data->motorTempC() <= 82, QStringLiteral("motorHot"), Warning,
                 tr("Motor hot"), tr("%1 °C. Ease off to let it cool.").arg(m_data->motorTempC()), QStringLiteral("motor"));

    const qreal lowest = qMin(m_data->tyreFrontBar(), m_data->tyreRearBar());
    const bool front = m_data->tyreFrontBar() <= m_data->tyreRearBar();
    setCondition(lowest < 1.8, lowest >= 1.95, QStringLiteral("tyre"), Warning, tr("Low tyre pressure"),
                 tr("%1 tyre at %2 bar, should be %3 bar.")
                     .arg(front ? tr("Front") : tr("Rear"))
                     .arg(lowest, 0, 'f', 1)
                     .arg(m_data->tyreTargetBar(), 0, 'f', 1),
                 QStringLiteral("tyre"));
    setCondition(m_data->absFault(), !m_data->absFault(), QStringLiteral("abs"), Warning, tr("ABS unavailable"),
                 tr("Brakes work without ABS. Have it checked."), QStringLiteral("abs"));

    const bool full = m_data->charging() && battery >= m_data->chargeLimitPercent();
    setCondition(full, !m_data->charging(), QStringLiteral("chargeDone"), Info, tr("Charging complete"),
                 tr("Charged to %1%. You can unplug.").arg(battery), QStringLiteral("charge"));
}

void AlertCenter::setCondition(bool active, bool cleared, const QString &id, Severity severity,
                               const QString &title, const QString &message, const QString &icon)
{
    const int row = indexOf(id);
    if (active) {
        if (row < 0) {
            raise(id, severity, title, message, icon);
        } else if (m_alerts[row].message != message) {
            m_alerts[row].message = message; // live values such as °C, without re-raising
            emit dataChanged(index(row), index(row), {MessageRole});
            emit bannerChanged();
        }
    } else if (cleared && row >= 0) {
        clear(id);
    }
}

void AlertCenter::raise(const QString &id, Severity severity, const QString &title, const QString &message,
                        const QString &icon)
{
    if (indexOf(id) >= 0)
        return;
    beginInsertRows({}, int(m_alerts.size()), int(m_alerts.size()));
    m_alerts.append({id, severity, title, message, icon, false});
    endInsertRows();
    emit countChanged();
    emit bannerChanged();
}

void AlertCenter::clear(const QString &id)
{
    const int row = indexOf(id);
    if (row < 0)
        return;
    beginRemoveRows({}, row, row);
    m_alerts.removeAt(row);
    endRemoveRows();
    emit countChanged();
    emit bannerChanged();
}

int AlertCenter::indexOf(const QString &id) const
{
    for (int i = 0; i < m_alerts.size(); ++i) {
        if (m_alerts.at(i).id == id)
            return i;
    }
    return -1;
}

QVariantMap AlertCenter::toMap(const Alert &alert) const
{
    return {{QStringLiteral("id"), alert.id},
            {QStringLiteral("severity"), int(alert.severity)},
            {QStringLiteral("title"), alert.title},
            {QStringLiteral("message"), alert.message},
            {QStringLiteral("icon"), alert.icon}};
}

const AlertCenter::Alert *AlertCenter::top(bool critical) const
{
    // Critical alerts take the whole screen and the rest share the banner, so each
    // asks only among its own kind. Highest severity first; among equals the newest.
    const Alert *best = nullptr;
    for (const Alert &alert : m_alerts) {
        if (alert.acknowledged || (alert.severity == Critical) != critical)
            continue;
        if (!best || alert.severity >= best->severity)
            best = &alert;
    }
    return best;
}

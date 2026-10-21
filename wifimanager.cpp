#include "wifimanager.h"

#include <QProcess>
#include <QStandardPaths>
#include <QTimer>

namespace {

// nmcli -t escapes ':' inside fields as '\:'.
QStringList splitTerse(const QString &line)
{
    QStringList fields;
    QString field;
    for (int i = 0; i < line.size(); ++i) {
        const QChar c = line.at(i);
        if (c == QLatin1Char('\\') && i + 1 < line.size()) {
            field += line.at(++i);
        } else if (c == QLatin1Char(':')) {
            fields << field;
            field.clear();
        } else {
            field += c;
        }
    }
    fields << field;
    return fields;
}

QVariantMap network(const QString &ssid, int signal, bool secure, bool connected)
{
    return {{QStringLiteral("ssid"), ssid},
            {QStringLiteral("signal"), signal},
            {QStringLiteral("secure"), secure},
            {QStringLiteral("connected"), connected}};
}

} // namespace

WifiManager::WifiManager(QObject *parent)
    : QObject(parent)
{
#ifdef Q_OS_LINUX
    m_real = !QStandardPaths::findExecutable(QStringLiteral("nmcli")).isEmpty()
             && qEnvironmentVariableIntValue("EAGLE_SIMULATED_RADIOS") != 1;
#endif
    if (m_real) {
        runNmcli({QStringLiteral("-t"), QStringLiteral("radio"), QStringLiteral("wifi")}, [this](int code, const QString &out) {
            m_enabled = code == 0 && out.trimmed() == QLatin1String("enabled");
            setStatus(m_enabled ? tr("On") : tr("Off"));
            if (m_enabled)
                scan();
        });
    } else {
        m_connectedSsid = QStringLiteral("Home-5G");
        m_signal = 82;
        simulateList();
        setStatus(tr("Connected to %1").arg(m_connectedSsid));
    }
}

void WifiManager::setEnabled(bool enabled)
{
    if (m_enabled == enabled)
        return;
    if (!m_real) {
        m_enabled = enabled;
        m_connectedSsid = enabled ? QStringLiteral("Home-5G") : QString();
        m_signal = enabled ? 82 : 0;
        if (enabled)
            simulateList();
        else
            m_networks.clear();
        emit networksChanged();
        setStatus(enabled ? tr("Connected to %1").arg(m_connectedSsid) : tr("Off"));
        return;
    }
    runNmcli({QStringLiteral("radio"), QStringLiteral("wifi"), enabled ? QStringLiteral("on") : QStringLiteral("off")},
             [this, enabled](int code, const QString &) {
                 if (code != 0)
                     return setStatus(tr("Could not switch Wi-Fi"));
                 m_enabled = enabled;
                 if (!enabled) {
                     m_connectedSsid.clear();
                     m_networks.clear();
                     emit networksChanged();
                 }
                 setStatus(enabled ? tr("On") : tr("Off"));
                 if (enabled)
                     QTimer::singleShot(1500, this, &WifiManager::scan);
             });
}

void WifiManager::scan()
{
    if (!m_enabled || m_busy)
        return;
    if (!m_real) {
        m_busy = true;
        setStatus(tr("Searching…"));
        QTimer::singleShot(1200, this, [this] {
            m_busy = false;
            simulateList();
            setStatus(m_connectedSsid.isEmpty() ? tr("Not connected") : tr("Connected to %1").arg(m_connectedSsid));
        });
        return;
    }
    m_busy = true;
    setStatus(tr("Searching…"));
    runNmcli({QStringLiteral("-t"), QStringLiteral("-f"), QStringLiteral("IN-USE,SSID,SIGNAL,SECURITY"),
              QStringLiteral("device"), QStringLiteral("wifi"), QStringLiteral("list"), QStringLiteral("--rescan"),
              QStringLiteral("yes")},
             [this](int code, const QString &out) {
                 m_busy = false;
                 if (code != 0)
                     return setStatus(tr("Scan failed"));
                 parseList(out);
                 setStatus(m_connectedSsid.isEmpty() ? tr("Not connected") : tr("Connected to %1").arg(m_connectedSsid));
             });
}

void WifiManager::connectTo(const QString &ssid, const QString &password)
{
    if (ssid.isEmpty() || m_busy)
        return;
    m_busy = true;
    setStatus(tr("Connecting to %1…").arg(ssid));
    if (!m_real) {
        QTimer::singleShot(1500, this, [this, ssid, password] {
            m_busy = false;
            bool secure = false;
            for (const QVariant &entry : std::as_const(m_networks)) {
                if (entry.toMap().value(QStringLiteral("ssid")).toString() == ssid)
                    secure = entry.toMap().value(QStringLiteral("secure")).toBool();
            }
            if (secure && password.size() < 8)
                return setStatus(tr("Wrong password for %1").arg(ssid));
            m_connectedSsid = ssid;
            m_signal = 70;
            simulateList();
            setStatus(tr("Connected to %1").arg(ssid));
        });
        return;
    }
    QStringList arguments{QStringLiteral("device"), QStringLiteral("wifi"), QStringLiteral("connect"), ssid};
    if (!password.isEmpty())
        arguments << QStringLiteral("password") << password;
    runNmcli(arguments, [this, ssid](int code, const QString &) {
        m_busy = false;
        setStatus(code == 0 ? tr("Connected to %1").arg(ssid) : tr("Could not connect to %1").arg(ssid));
        scan();
    });
}

void WifiManager::disconnectNetwork()
{
    if (m_connectedSsid.isEmpty())
        return;
    if (!m_real) {
        m_connectedSsid.clear();
        m_signal = 0;
        simulateList();
        setStatus(tr("Not connected"));
        return;
    }
    runNmcli({QStringLiteral("connection"), QStringLiteral("down"), QStringLiteral("id"), m_connectedSsid},
             [this](int, const QString &) { scan(); });
}

void WifiManager::runNmcli(const QStringList &arguments, std::function<void(int, const QString &)> done)
{
    auto *process = new QProcess(this);
    connect(process, &QProcess::finished, this, [process, done](int code, QProcess::ExitStatus status) {
        done(status == QProcess::NormalExit ? code : -1, QString::fromUtf8(process->readAllStandardOutput()));
        process->deleteLater();
    });
    connect(process, &QProcess::errorOccurred, this, [process, done](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart) {
            done(-1, {});
            process->deleteLater();
        }
    });
    process->start(QStringLiteral("nmcli"), arguments);
}

void WifiManager::parseList(const QString &output)
{
    m_networks.clear();
    m_connectedSsid.clear();
    m_signal = 0;
    QStringList seen;
    for (const QString &line : output.split(QLatin1Char('\n'), Qt::SkipEmptyParts)) {
        const QStringList fields = splitTerse(line);
        if (fields.size() < 4 || fields.at(1).isEmpty() || seen.contains(fields.at(1)))
            continue;
        seen << fields.at(1);
        const bool inUse = fields.at(0).trimmed() == QLatin1String("*");
        const int signal = fields.at(2).toInt();
        if (inUse) {
            m_connectedSsid = fields.at(1);
            m_signal = signal;
        }
        m_networks.append(network(fields.at(1), signal, !fields.at(3).trimmed().isEmpty() && fields.at(3) != QLatin1String("--"), inUse));
    }
    emit networksChanged();
}

void WifiManager::setStatus(const QString &status)
{
    m_status = status;
    emit stateChanged();
}

void WifiManager::simulateList()
{
    m_networks = {network(QStringLiteral("Home-5G"), 82, true, m_connectedSsid == QLatin1String("Home-5G")),
                  network(QStringLiteral("Office-Guest"), 64, true, m_connectedSsid == QLatin1String("Office-Guest")),
                  network(QStringLiteral("Phone hotspot"), 58, true, m_connectedSsid == QLatin1String("Phone hotspot")),
                  network(QStringLiteral("Cafe Free WiFi"), 41, false, m_connectedSsid == QLatin1String("Cafe Free WiFi"))};
    emit networksChanged();
}

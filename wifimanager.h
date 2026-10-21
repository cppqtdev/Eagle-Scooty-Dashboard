#pragma once

#include <QObject>
#include <functional>
#include <QVariantList>

class QProcess;

// Wi-Fi for updates and phone tethering. On Linux it drives NetworkManager through
// nmcli, as on the RK3328 board image; elsewhere a list of nearby networks stands
// in. Passwords go straight to NetworkManager and are never kept here.
class WifiManager final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool real READ real CONSTANT)
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY stateChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY stateChanged)
    Q_PROPERTY(QString connectedSsid READ connectedSsid NOTIFY stateChanged)
    Q_PROPERTY(int signal READ signal NOTIFY stateChanged)
    Q_PROPERTY(QString status READ status NOTIFY stateChanged)
    Q_PROPERTY(QVariantList networks READ networks NOTIFY networksChanged)

public:
    explicit WifiManager(QObject *parent = nullptr);

    bool real() const { return m_real; }
    bool enabled() const { return m_enabled; }
    bool busy() const { return m_busy; }
    QString connectedSsid() const { return m_connectedSsid; }
    int signal() const { return m_signal; }
    QString status() const { return m_status; }
    QVariantList networks() const { return m_networks; }

public slots:
    void setEnabled(bool enabled);
    void scan();
    void connectTo(const QString &ssid, const QString &password);
    void disconnectNetwork();

signals:
    void stateChanged();
    void networksChanged();

private:
    void runNmcli(const QStringList &arguments, std::function<void(int, const QString &)> done);
    void parseList(const QString &output);
    void setStatus(const QString &status);
    void simulateList();

    bool m_real = false;
    bool m_enabled = true;
    bool m_busy = false;
    QString m_connectedSsid;
    int m_signal = 0;
    QString m_status;
    QVariantList m_networks;
};

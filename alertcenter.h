#pragma once

#include <QAbstractListModel>
#include <QHash>
#include <QTimer>
#include <QVariantMap>
#include <QVector>

class DashboardData;

// Turns vehicle state into alerts the rider has to see, ranks them and decides
// which one is on screen: critical ones take over the whole display, warnings and
// information slide in as a banner. A condition must clear past its hysteresis
// before the same alert can be raised again, so values near a limit don't flicker.
class AlertCenter final : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    Q_PROPERTY(QVariantMap banner READ banner NOTIFY bannerChanged)
    Q_PROPERTY(QVariantMap critical READ critical NOTIFY bannerChanged)
    Q_PROPERTY(bool hasCritical READ hasCritical NOTIFY bannerChanged)

public:
    enum Severity { Info, Warning, Critical };
    Q_ENUM(Severity)

    enum Role { IdRole = Qt::UserRole + 1, SeverityRole, TitleRole, MessageRole, IconRole, AcknowledgedRole };

    explicit AlertCenter(DashboardData *data, QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    QVariantMap banner() const;
    QVariantMap critical() const;
    bool hasCritical() const;

public slots:
    void acknowledge(const QString &id);
    // A transient notice from outside the vehicle (phone, charger); gone after timeoutMs.
    void post(const QString &id, int severity, const QString &title, const QString &message,
              const QString &icon, int timeoutMs = 6000);

signals:
    void countChanged();
    void bannerChanged();

private:
    struct Alert {
        QString id;
        Severity severity;
        QString title;
        QString message;
        QString icon;
        bool acknowledged = false;
    };

    void evaluate();
    void raise(const QString &id, Severity severity, const QString &title, const QString &message,
               const QString &icon);
    void clear(const QString &id);
    void setCondition(bool active, bool cleared, const QString &id, Severity severity,
                      const QString &title, const QString &message, const QString &icon);
    int indexOf(const QString &id) const;
    QVariantMap toMap(const Alert &alert) const;
    const Alert *top(bool critical) const;

    DashboardData *m_data;
    QVector<Alert> m_alerts;
    QHash<QString, QTimer *> m_expiry;
};

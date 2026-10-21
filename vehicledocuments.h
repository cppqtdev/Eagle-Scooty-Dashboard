#pragma once

#include <QDate>
#include <QObject>
#include <QVariantList>

// The papers a rider is asked for, kept on the dashboard with their expiry status:
// valid, expiring within 30 days, or expired. Numbers are stored masked.
class VehicleDocuments final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList documents READ documents NOTIFY documentsChanged)
    Q_PROPERTY(int attentionCount READ attentionCount NOTIFY documentsChanged)

public:
    explicit VehicleDocuments(QObject *parent = nullptr);

    QVariantList documents() const;
    int attentionCount() const;

    // Date the statuses are measured against; the current date unless set for a test.
    void setToday(const QDate &today);

signals:
    void documentsChanged();

private:
    struct Document {
        QString kind;
        QString title;
        QString number;
        QString issuer;
        QDate validUntil;
    };

    QString statusOf(const Document &document) const;

    QList<Document> m_documents;
    QDate m_today;
};

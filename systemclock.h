#pragma once

#include <QDateTime>
#include <QObject>
#include <QTimer>

class SystemClock final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString dateText READ dateText NOTIFY changed)
    Q_PROPERTY(QString timeText READ timeText NOTIFY changed)

public:
    explicit SystemClock(QObject *parent = nullptr);

    QString dateText() const;
    QString timeText() const;

signals:
    void changed();

private:
    void update();

    QTimer m_timer;
    QString m_stamp;
};

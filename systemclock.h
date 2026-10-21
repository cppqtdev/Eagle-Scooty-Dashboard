#pragma once

#include <QDateTime>
#include <QObject>
#include <QTimer>

class SystemClock final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString dateText READ dateText NOTIFY changed)
    Q_PROPERTY(QString timeText READ timeText NOTIFY changed)
    Q_PROPERTY(bool clock24 READ clock24 WRITE setClock24 NOTIFY clock24Changed)

public:
    explicit SystemClock(QObject *parent = nullptr);

    QString dateText() const;
    QString timeText() const;
    bool clock24() const { return m_clock24; }
    void setClock24(bool on);

signals:
    void changed();
    void clock24Changed();

private:
    void update();

    QTimer m_timer;
    QString m_stamp;
    bool m_clock24 = false;
};

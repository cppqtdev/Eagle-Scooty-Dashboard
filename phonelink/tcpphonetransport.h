#pragma once

#include "iphonetransport.h"

#include <QPointer>
#include <QTcpServer>

class QTcpSocket;

namespace phonelink {

// The bench stand-in for the radio: the same byte stream on a TCP port, for
// scripts/phone_link_sim.py or the app pointed at this machine. The newest client wins.
class TcpPhoneTransport final : public IPhoneTransport
{
    Q_OBJECT
    Q_DISABLE_COPY_MOVE(TcpPhoneTransport)

public:
    static constexpr quint16 kDefaultPort = 47100;

    explicit TcpPhoneTransport(quint16 port = kDefaultPort, QObject *parent = nullptr);
    ~TcpPhoneTransport() override;

    [[nodiscard]] QString name() const override;
    [[nodiscard]] bool isPeerConnected() const override;
    bool send(const QByteArray &bytes) override;

    [[nodiscard]] quint16 port() const; // the bound one, when constructed with 0

public slots:
    void start() override;
    void stop() override;

private:
    void accept();
    void dropClient();

    quint16 m_port;
    QTcpServer m_server;
    QPointer<QTcpSocket> m_client;
};

} // namespace phonelink

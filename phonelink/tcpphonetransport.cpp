#include "tcpphonetransport.h"

#include "phonelinklog.h"

#include <QTcpSocket>

namespace phonelink {

TcpPhoneTransport::TcpPhoneTransport(quint16 port, QObject *parent) : IPhoneTransport(parent), m_port(port)
{
    connect(&m_server, &QTcpServer::newConnection, this, &TcpPhoneTransport::accept);
}

TcpPhoneTransport::~TcpPhoneTransport()
{
    stop();
}

QString TcpPhoneTransport::name() const
{
    return QStringLiteral("tcp:%1").arg(port());
}

bool TcpPhoneTransport::isPeerConnected() const
{
    return m_client && m_client->state() == QAbstractSocket::ConnectedState;
}

bool TcpPhoneTransport::send(const QByteArray &bytes)
{
    if (!isPeerConnected())
        return false;
    return m_client->write(bytes) == bytes.size();
}

quint16 TcpPhoneTransport::port() const
{
    return m_server.isListening() ? m_server.serverPort() : m_port;
}

void TcpPhoneTransport::start()
{
    if (m_server.isListening())
        return;
    // Every interface, so a phone on the same Wi-Fi can reach the bench too.
    if (!m_server.listen(QHostAddress::Any, m_port)) {
        emit errorOccurred(QStringLiteral("cannot listen on port %1: %2").arg(m_port).arg(m_server.errorString()));
        return;
    }
    qCInfo(lcPhoneLink) << "Waiting for the phone on TCP port" << m_server.serverPort();
}

void TcpPhoneTransport::stop()
{
    m_server.close();
    dropClient();
}

void TcpPhoneTransport::accept()
{
    while (QTcpSocket *socket = m_server.nextPendingConnection()) {
        dropClient();
        qCInfo(lcPhoneLink) << "Phone on" << socket->peerAddress().toString();
        m_client = socket;
        connect(socket, &QTcpSocket::readyRead, this, [this, socket] { emit received(socket->readAll()); });
        connect(socket, &QTcpSocket::disconnected, this, [this, socket] {
            if (socket != m_client)
                return;
            dropClient();
        });
        emit peerConnected();
    }
}

void TcpPhoneTransport::dropClient()
{
    if (!m_client)
        return;
    QTcpSocket *client = m_client;
    m_client.clear();
    client->disconnect(this);
    client->abort();
    client->deleteLater();
    emit peerDisconnected();
}

} // namespace phonelink

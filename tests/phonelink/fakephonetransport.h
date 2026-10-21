#pragma once

#include "phonelink/iphonetransport.h"

#include <QList>

namespace phonelink::tests {

// A phone the test plays by hand: connectPhone() subscribes, inject() writes bytes in,
// sent() lists every write the cluster made.
class FakePhoneTransport final : public phonelink::IPhoneTransport
{
    Q_OBJECT

public:
    using IPhoneTransport::IPhoneTransport;

    [[nodiscard]] QString name() const override
    {
        return QStringLiteral("fake");
    }

    [[nodiscard]] bool isPeerConnected() const override
    {
        return m_peer;
    }

    bool send(const QByteArray &bytes) override
    {
        m_sent.append(bytes);
        return m_peer;
    }

    void connectPhone()
    {
        m_peer = true;
        emit peerConnected();
    }

    void disconnectPhone()
    {
        m_peer = false;
        emit peerDisconnected();
    }

    void inject(const QByteArray &bytes)
    {
        emit received(bytes);
    }

    [[nodiscard]] const QList<QByteArray> &sent() const
    {
        return m_sent;
    }

    void clearSent()
    {
        m_sent.clear();
    }

    [[nodiscard]] bool isStarted() const
    {
        return m_started;
    }

public slots:
    void start() override
    {
        m_started = true;
    }

    void stop() override
    {
        m_started = false;
    }

private:
    bool m_peer = false;
    bool m_started = false;
    QList<QByteArray> m_sent;
};

} // namespace phonelink::tests

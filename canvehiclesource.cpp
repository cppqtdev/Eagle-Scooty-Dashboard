#include "canvehiclesource.h"

#include "dashboarddata.h"

#include <QtEndian>

#ifdef EAGLE_HAS_CAN
#include <QCanBus>
#include <QCanBusDevice>
#include <QCanBusFrame>
#endif

namespace {

// Frame IDs, see docs/CAN.md. All multi-byte values are little-endian.
enum : quint32 {
    MotionId = 0x100,   // speed km/h x10 (u16), power kW x10 (s16), gear (u8), flags (u8: bit0 ready)
    BatteryId = 0x101,  // SoC % (u8), range km (u16), charge power kW x10 (u8), limit % (u8), flags (bit0 charging)
    TempsId = 0x102,    // ambient, battery, motor °C (s8 each)
    LampsId = 0x103,    // flags (u8: left, right, low, high, side stand), ride mode (u8)
    TyresId = 0x104,    // front, rear bar x10 (u8 each)
    FaultsId = 0x105,   // flags (u8: bit0 motor, bit1 ABS)
    TripId = 0x106,     // trip km (u16), odometer km (u32)
    ButtonsId = 0x107,  // handlebar keys held (u8: up, down, left, right, ok, back), encoder detents (s8)
};

quint16 u16(const QByteArray &p, int at) { return qFromLittleEndian<quint16>(p.constData() + at); }
qint16 s16(const QByteArray &p, int at) { return qFromLittleEndian<qint16>(p.constData() + at); }
quint32 u32(const QByteArray &p, int at) { return qFromLittleEndian<quint32>(p.constData() + at); }
bool bit(quint8 flags, int n) { return flags & (1u << n); }

} // namespace

CanVehicleSource::CanVehicleSource(DashboardData *data, QObject *parent)
    : QObject(parent)
    , m_data(data)
{
}

bool CanVehicleSource::open(const QString &interfaceName)
{
#ifdef EAGLE_HAS_CAN
    QString error;
    m_device = QCanBus::instance()->createDevice(QStringLiteral("socketcan"), interfaceName, &error);
    if (!m_device) {
        setStatus(false, tr("CAN unavailable: %1").arg(error));
        return false;
    }
    m_device->setParent(this);
    connect(m_device, &QCanBusDevice::framesReceived, this, &CanVehicleSource::readFrames);
    connect(m_device, &QCanBusDevice::errorOccurred, this, [this] {
        setStatus(false, tr("CAN error: %1").arg(m_device->errorString()));
    });
    if (!m_device->connectDevice()) {
        setStatus(false, tr("Could not open %1").arg(interfaceName));
        return false;
    }
    setStatus(true, tr("Listening on %1").arg(interfaceName));
    return true;
#else
    setStatus(false, tr("Built without CAN support (Qt SerialBus) for %1").arg(interfaceName));
    return false;
#endif
}

void CanVehicleSource::readFrames()
{
#ifdef EAGLE_HAS_CAN
    while (m_device && m_device->framesAvailable()) {
        const QCanBusFrame frame = m_device->readFrame();
        if (frame.frameType() == QCanBusFrame::DataFrame)
            apply(frame.frameId(), frame.payload());
    }
#endif
}

void CanVehicleSource::apply(quint32 id, const QByteArray &p)
{
    switch (id) {
    case MotionId:
        if (p.size() < 6)
            return;
        m_data->setSpeed(qRound(u16(p, 0) / 10.0));
        m_data->setPowerKw(s16(p, 2) / 10.0);
        m_data->setGear(QString(QLatin1Char("PRND"[qMin<int>(quint8(p.at(4)), 3)])));
        m_data->setReady(bit(quint8(p.at(5)), 0));
        break;
    case BatteryId:
        if (p.size() < 6)
            return;
        m_data->setBatteryPercent(quint8(p.at(0)));
        m_data->setRangeKm(u16(p, 1));
        m_data->setChargePowerKw(quint8(p.at(3)) / 10.0);
        m_data->setChargeLimitPercent(quint8(p.at(4)));
        m_data->setCharging(bit(quint8(p.at(5)), 0));
        break;
    case TempsId:
        if (p.size() < 3)
            return;
        m_data->setTemperatureC(qint8(p.at(0)));
        m_data->setBatteryTempC(qint8(p.at(1)));
        m_data->setMotorTempC(qint8(p.at(2)));
        break;
    case LampsId: {
        if (p.size() < 2)
            return;
        const quint8 flags = quint8(p.at(0));
        m_data->setLeftIndicator(bit(flags, 0));
        m_data->setRightIndicator(bit(flags, 1));
        m_data->setLowBeam(bit(flags, 2));
        m_data->setHighBeam(bit(flags, 3));
        m_data->setSideStandDown(bit(flags, 4));
        m_data->setRideMode(static_cast<DashboardData::RideMode>(qMin<int>(quint8(p.at(1)), 2)));
        break;
    }
    case TyresId:
        if (p.size() < 2)
            return;
        m_data->setTyreFrontBar(quint8(p.at(0)) / 10.0);
        m_data->setTyreRearBar(quint8(p.at(1)) / 10.0);
        break;
    case FaultsId:
        if (p.isEmpty())
            return;
        m_data->setMotorFault(bit(quint8(p.at(0)), 0));
        m_data->setAbsFault(bit(quint8(p.at(0)), 1));
        m_data->setCheckEngine(bit(quint8(p.at(0)), 2));
        break;
    case TripId:
        if (p.size() < 6)
            return;
        m_data->setTripKm(u16(p, 0));
        m_data->setOdometerKm(int(u32(p, 2)));
        break;
    case ButtonsId: {
        if (p.isEmpty())
            return;
        // A key counts when it goes down; the encoder's detents are steps.
        static const char *const kNames[] = {"up", "down", "left", "right", "ok", "back"};
        const quint8 held = quint8(p.at(0));
        const quint8 pressed = held & ~m_buttonsHeld;
        m_buttonsHeld = held;
        for (int i = 0; i < 6; ++i) {
            if (bit(pressed, i))
                emit buttonPressed(QString::fromLatin1(kNames[i]));
        }
        if (p.size() >= 2) {
            const int detents = qint8(p.at(1));
            for (int i = 0; i < qAbs(detents); ++i)
                emit buttonPressed(detents > 0 ? QStringLiteral("down") : QStringLiteral("up"));
        }
        break;
    }
    default:
        break;
    }
}

void CanVehicleSource::setStatus(bool connected, const QString &status)
{
    m_connected = connected;
    m_status = status;
    emit statusChanged();
}

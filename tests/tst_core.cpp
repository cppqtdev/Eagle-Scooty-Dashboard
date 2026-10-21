#include <QSignalSpy>
#include <QTest>

#include "alertcenter.h"
#include "canvehiclesource.h"
#include "dashboarddata.h"
#include "harnessinputs.h"
#include "phoneservice.h"
#include "vehicledocuments.h"

class CoreTests : public QObject
{
    Q_OBJECT

private slots:
    void canMotionFrame()
    {
        DashboardData data;
        CanVehicleSource can(&data);
        // 45.6 km/h, 2.5 kW, D, ready
        can.apply(0x100, QByteArray::fromHex("c801190003" "01"));
        QCOMPARE(data.speed(), 46);
        QCOMPARE(data.powerKw(), 2.5);
        QCOMPARE(data.gear(), QStringLiteral("D"));
        QVERIFY(data.ready());
    }

    void canBatteryAndLamps()
    {
        DashboardData data;
        CanVehicleSource can(&data);
        can.apply(0x101, QByteArray::fromHex("40" "7800" "21" "5a" "01")); // 64 %, 120 km, 3.3 kW, 90 %, charging
        QCOMPARE(data.batteryPercent(), 64);
        QCOMPARE(data.rangeKm(), 120);
        QCOMPARE(data.chargePowerKw(), 3.3);
        QCOMPARE(data.chargeLimitPercent(), 90);
        QVERIFY(data.charging());

        can.apply(0x103, QByteArray::fromHex("15" "02")); // left, low beam, side stand; Sport
        QVERIFY(data.leftIndicator());
        QVERIFY(!data.rightIndicator());
        QVERIFY(data.lowBeam());
        QVERIFY(data.sideStandDown());
        QCOMPARE(data.rideMode(), DashboardData::Sport);
    }

    void canButtonsFireOnPressAndDetents()
    {
        DashboardData data;
        CanVehicleSource can(&data);
        QSignalSpy spy(&can, &CanVehicleSource::buttonPressed);
        can.apply(0x107, QByteArray::fromHex("10" "00")); // ok goes down
        can.apply(0x107, QByteArray::fromHex("10" "00")); // still held: nothing new
        can.apply(0x107, QByteArray::fromHex("00" "fe")); // released, encoder two detents back
        QCOMPARE(spy.count(), 3);
        QCOMPARE(spy.at(0).at(0).toString(), QStringLiteral("ok"));
        QCOMPARE(spy.at(1).at(0).toString(), QStringLiteral("up"));
        QCOMPARE(spy.at(2).at(0).toString(), QStringLiteral("up"));
    }

    void canFaultsCarryCheckEngine()
    {
        DashboardData data;
        CanVehicleSource can(&data);
        can.apply(0x105, QByteArray::fromHex("04"));
        QVERIFY(data.checkEngine());
        QVERIFY(!data.motorFault());
    }

    void canShortFrameIsIgnored()
    {
        DashboardData data;
        CanVehicleSource can(&data);
        const int before = data.speed();
        can.apply(0x100, QByteArray::fromHex("ff"));
        QCOMPARE(data.speed(), before);
    }

    void harnessConversions()
    {
        // 4800 pulses a km: 200 pulses in 3 s is 50 km/h.
        QCOMPARE(qRound(harness::speedKmh(200, 3.0, 4800)), 50);
        QCOMPARE(harness::speedKmh(10, 0.0, 4800), 0.0);
        // 10 k NTC on a 10 k pull-up reads half the reference at 25 °C.
        QCOMPARE(qRound(harness::ntcCelsius(900, 1800, 10000, 10000, 3950)), 25);
        QVERIFY(harness::ntcCelsius(500, 1800, 10000, 10000, 3950) > 25); // lower voltage, hotter NTC
        const std::vector<std::pair<double, int>> curve{{60000, 0}, {70000, 50}, {84000, 100}};
        QCOMPARE(harness::percentFromVoltage(55000, curve), 0);
        QCOMPARE(harness::percentFromVoltage(65000, curve), 25);
        QCOMPARE(harness::percentFromVoltage(90000, curve), 100);
    }

    void harnessLinesDriveTheModel()
    {
        DashboardData data;
        HarnessInputs inputs(&data);
        inputs.applyLine(QStringLiteral("highBeam"), true);
        inputs.applyLine(QStringLiteral("checkEngine"), true);
        inputs.applyLine(QStringLiteral("neutral"), true);
        inputs.applyLine(QStringLiteral("turnLeft"), true);
        QVERIFY(data.highBeam());
        QVERIFY(data.checkEngine());
        QCOMPARE(data.gear(), QStringLiteral("N"));
        QVERIFY(data.leftIndicator());
        inputs.applyLine(QStringLiteral("neutral"), false);
        QCOMPARE(data.gear(), QStringLiteral("D"));
    }

    void lowBatteryWarnsThenClearsWithHysteresis()
    {
        DashboardData data;
        AlertCenter alerts(&data);
        data.setBatteryPercent(15);
        QCOMPARE(alerts.banner().value(QStringLiteral("id")).toString(), QStringLiteral("batteryLow"));
        data.setBatteryPercent(16); // inside the hysteresis band: still raised
        QVERIFY(!alerts.banner().isEmpty());
        data.setBatteryPercent(18);
        QVERIFY(alerts.banner().isEmpty());
    }

    void sideStandIsCriticalOnlyWhileMoving()
    {
        DashboardData data;
        AlertCenter alerts(&data);
        data.setSideStandDown(true);
        QVERIFY(!alerts.hasCritical());
        data.setSpeed(12);
        QVERIFY(alerts.hasCritical());
        QCOMPARE(alerts.critical().value(QStringLiteral("id")).toString(), QStringLiteral("sideStand"));
        data.setSideStandDown(false);
        QVERIFY(!alerts.hasCritical());
    }

    void criticalDoesNotHideTheBanner()
    {
        DashboardData data;
        AlertCenter alerts(&data);
        data.setTyreFrontBar(1.5);
        data.setMotorFault(true);
        QVERIFY(alerts.hasCritical());
        QCOMPARE(alerts.banner().value(QStringLiteral("id")).toString(), QStringLiteral("tyre"));
    }

    void acknowledgedAlertLeavesTheBanner()
    {
        DashboardData data;
        AlertCenter alerts(&data);
        data.setAbsFault(true);
        alerts.acknowledge(QStringLiteral("abs"));
        QVERIFY(alerts.banner().isEmpty());
        QCOMPARE(alerts.rowCount(), 1); // still listed in diagnostics
    }

    void callFlow()
    {
        PhoneService phone;
        phone.simulateIncomingCall();
        QCOMPARE(phone.callState(), PhoneService::Incoming);
        const int recentsBefore = int(phone.recents().size());
        phone.answer();
        QCOMPARE(phone.callState(), PhoneService::Active);
        QCOMPARE(int(phone.recents().size()), recentsBefore + 1);
        phone.toggleMute();
        QVERIFY(phone.muted());
        phone.hangUp();
        QCOMPARE(phone.callState(), PhoneService::Idle);
        QVERIFY(!phone.muted());
    }

    void declinedCallIsMissed()
    {
        PhoneService phone;
        phone.simulateIncomingCall();
        phone.decline();
        QCOMPARE(phone.recents().first().toMap().value(QStringLiteral("kind")).toString(), QStringLiteral("missed"));
    }

    void playerStateFollowsPlaybackCallsAndConnection()
    {
        PhoneService phone;
        QCOMPARE(phone.playerState(), PhoneService::Playing);
        phone.playPause();
        QCOMPARE(phone.playerState(), PhoneService::Paused);
        phone.playPause();
        phone.simulateIncomingCall();          // the music holds while the phone rings
        QCOMPARE(phone.playerState(), PhoneService::Paused);
        phone.decline();
        QCOMPARE(phone.playerState(), PhoneService::Playing);
        phone.setConnected(false);
        QCOMPARE(phone.playerState(), PhoneService::NoSource);
    }

    void documentStatuses()
    {
        VehicleDocuments documents;
        int expiring = 0, expired = 0;
        for (const QVariant &entry : documents.documents()) {
            const QString status = entry.toMap().value(QStringLiteral("status")).toString();
            expiring += status == QLatin1String("expiring");
            expired += status == QLatin1String("expired");
        }
        QCOMPARE(expiring, 1); // insurance, 21 days
        QCOMPARE(expired, 1);  // service book
        QCOMPARE(documents.attentionCount(), 2);
    }
};

QTEST_GUILESS_MAIN(CoreTests)
#include "tst_core.moc"

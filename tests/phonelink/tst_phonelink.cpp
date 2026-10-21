#include "fakephonetransport.h"

#include "phonelink/phonelinkcodec.h"
#include "phonelink/protocolphonelink.h"

#include <QSignalSpy>
#include <QTest>

using namespace phonelink;
using phonelink::tests::FakePhoneTransport;

namespace {

// docs/PhoneLink.md: right turn in 250 m, 12.4 km to go, 23 min, "MG Road"; the second
// recommends the right lane of three.
const QByteArray kNavVector = QByteArray::fromHex("a5 01 01 16 00 06 00 fa 00 00 00 70 30 00 00 17 00 00 00 07 "
                                                  "4d 47 20 52 6f 61 64 17 8f");
const QByteArray kNavLanesVector = QByteArray::fromHex("a5 01 01 16 00 06 00 fa 00 00 00 70 30 00 00 17 00 07 04 07 "
                                                       "4d 47 20 52 6f 61 64 02 0f");

wire::NavUpdate rightTurnOnMgRoad()
{
    wire::NavUpdate nav;
    nav.maneuver = wire::Maneuver::Right;
    nav.distanceMetres = 250;
    nav.remainingMetres = 12400;
    nav.etaMinutes = 23;
    nav.road = QStringLiteral("MG Road");
    return nav;
}

QByteArray payloadOf(const QByteArray &frame)
{
    return frame.mid(wire::kHeaderSize, frame.size() - wire::kHeaderSize - wire::kCrcSize);
}

struct LinkRig
{
    FakePhoneTransport *transport = nullptr;
    std::unique_ptr<ProtocolPhoneLink> link;

    explicit LinkRig(int silenceMs = 250)
    {
        auto fake = std::make_unique<FakePhoneTransport>();
        transport = fake.get();
        ProtocolPhoneLink::Options options;
        options.model = QStringLiteral("APEX EV");
        options.firmware = QStringLiteral("0.2.0");
        options.heartbeatMs = 40;
        options.silenceMs = silenceMs;
        link = std::make_unique<ProtocolPhoneLink>(std::move(fake), options);
        link->start();
        transport->connectPhone();
    }

    void phoneSends(const QByteArray &frame)
    {
        transport->inject(frame);
    }

    void ring(const QString &caller)
    {
        phoneSends(wire::encode(wire::CallState{wire::CallStatus::Ringing, caller, {}}));
    }

    void callEnds()
    {
        phoneSends(wire::encode(wire::CallState{}));
    }
};

} // namespace

class PhoneLinkTest final : public QObject
{
    Q_OBJECT

private slots:
    void crcIsCcittFalse();
    void navUpdateMatchesTheTestVectors();
    void framesAreFoundAmongGarbage();
    void aFrameSplitIntoPiecesIsReassembled();
    void aBadCrcDropsTheFrameAndTheParserResyncs();
    void aBadVersionOrLengthDropsTheFrame();
    void navUpdateCarriesTheNextManeuverFromVersion11();
    void callStateCarriesElapsedAndFlagsFromVersion11();
    void mediaStateCarriesSourceAndArtFromVersion11();
    void phoneStatusCarriesChargingFromVersion11();
    void theOtherPhoneMessagesRoundTrip();
    void fieldsANewerAppAppendsAreIgnored();
    void aShortPayloadDecodesToNothing();
    void anUnknownListOrSlotIsRejected();
    void textIsCutOnACharacterBoundary();
    void clusterMessagesHaveTheirBytes();
    void albumArtIsReassembledForTheCurrentTrackOnly();

    void clusterInfoGoesOutWhenThePhoneSubscribes();
    void heartbeatsGoOutWhileThePhoneIsThere();
    void theLinkComesUpWithTheFirstFrame();
    void silenceClearsEverythingPersonal();
    void aDisconnectClearsEverythingToo();
    void anUnansweredCallIsMissed();
    void anAnsweredOrDeclinedCallIsNotMissed();
    void callDurationComesFromThePhone();
    void anOutgoingCallIsShownAsActive();
    void ridersButtonsSendCommands();
    void guidanceIsMappedOntoTheClustersManeuvers();
    void navStopEndsTheRoute();
    void albumArtArrivesAfterItsMediaState();
    void contactsAndRemindersFillTheirSlots();
    void vehicleStatusGoesOutWhenPublishedAndOnSubscribe();
    void framesSplitAcrossWritesStillArrive();
};

void PhoneLinkTest::crcIsCcittFalse()
{
    QCOMPARE(wire::crc16("123456789"), quint16(0x29B1));
}

void PhoneLinkTest::navUpdateMatchesTheTestVectors()
{
    QCOMPARE(wire::encode(rightTurnOnMgRoad()), kNavVector);

    auto lanes = rightTurnOnMgRoad();
    lanes.laneMask = 0x07;
    lanes.recommendedLaneMask = 0x04;
    QCOMPARE(wire::encode(lanes), kNavLanesVector);

    wire::FrameParser parser;
    const auto frames = parser.feed(kNavVector + kNavLanesVector);
    QCOMPARE(frames.size(), 2);
    QCOMPARE(frames.at(0).type, wire::MessageType::NavUpdate);
    QCOMPARE(wire::decodeNavUpdate(frames.at(0).payload), rightTurnOnMgRoad());
    QCOMPARE(wire::decodeNavUpdate(frames.at(1).payload), lanes);
}

void PhoneLinkTest::framesAreFoundAmongGarbage()
{
    wire::FrameParser parser;
    const QByteArray noise = QByteArray::fromHex("00 ff a5 02 13 a5");
    const auto frames = parser.feed(noise + wire::encodeHeartbeat() + QByteArray("junk") + kNavVector);
    QCOMPARE(frames.size(), 2);
    QCOMPARE(frames.at(0).type, wire::MessageType::Heartbeat);
    QCOMPARE(frames.at(1).payload, payloadOf(kNavVector));
}

void PhoneLinkTest::aFrameSplitIntoPiecesIsReassembled()
{
    wire::FrameParser parser;
    QList<wire::Frame> frames;
    for (const char byte : kNavVector)
        frames += parser.feed(QByteArray(1, byte));
    QCOMPARE(frames.size(), 1);

    // A phone that kept MTU 23 writes in 20-byte pieces.
    const QByteArray twice = kNavVector + kNavLanesVector;
    for (qsizetype offset = 0; offset < twice.size(); offset += 20)
        frames += parser.feed(twice.mid(offset, 20));
    QCOMPARE(frames.size(), 3);
    QCOMPARE(parser.droppedFrames(), 0);
}

void PhoneLinkTest::aBadCrcDropsTheFrameAndTheParserResyncs()
{
    QByteArray corrupt = kNavVector;
    corrupt[10] = static_cast<char>(corrupt.at(10) ^ 0x01);

    wire::FrameParser parser;
    const auto frames = parser.feed(corrupt + wire::encodeHeartbeat());
    QCOMPARE(frames.size(), 1);
    QCOMPARE(frames.at(0).type, wire::MessageType::Heartbeat);
    QCOMPARE(parser.droppedFrames(), 1);
}

void PhoneLinkTest::aBadVersionOrLengthDropsTheFrame()
{
    QByteArray otherVersion = wire::encodeHeartbeat();
    otherVersion[1] = 2;
    const QByteArray tooLong = QByteArray::fromHex("a5 01 01 a1 00");

    wire::FrameParser parser;
    const auto frames = parser.feed(otherVersion + tooLong + kNavVector);
    QCOMPARE(frames.size(), 1);
    QCOMPARE(frames.at(0).type, wire::MessageType::NavUpdate);
    QCOMPARE(parser.droppedFrames(), 2);
}

void PhoneLinkTest::navUpdateCarriesTheNextManeuverFromVersion11()
{
    QVERIFY(!wire::decodeNavUpdate(payloadOf(kNavVector))->next);

    auto nav = rightTurnOnMgRoad();
    nav.next = wire::NextManeuver{wire::Maneuver::SlightLeft, 1200};
    const QByteArray frame = wire::encode(nav);
    QCOMPARE(frame.size(), kNavVector.size() + 5);
    QCOMPARE(payloadOf(frame).left(payloadOf(kNavVector).size()), payloadOf(kNavVector));
    QCOMPARE(wire::decodeNavUpdate(payloadOf(frame)), nav);
}

void PhoneLinkTest::callStateCarriesElapsedAndFlagsFromVersion11()
{
    const wire::CallState old{wire::CallStatus::Ringing, QStringLiteral("Rahul Sharma"), {}};
    QCOMPARE(wire::decodeCallState(payloadOf(wire::encode(old))), old);

    const wire::CallState current{wire::CallStatus::Active, QStringLiteral("Rahul Sharma"),
                                  wire::CallDetail{125, true, true}};
    const QByteArray frame = wire::encode(current);
    QCOMPARE(payloadOf(frame).right(3), QByteArray::fromHex("7d 00 03"));
    QCOMPARE(wire::decodeCallState(payloadOf(frame)), current);
}

void PhoneLinkTest::mediaStateCarriesSourceAndArtFromVersion11()
{
    wire::MediaState media{true, 60, 96, 228, QStringLiteral("Night Drive"), QStringLiteral("Skyline"), {}};
    QCOMPARE(wire::decodeMediaState(payloadOf(wire::encode(media))), media);

    media.source = wire::MediaSource{QStringLiteral("Spotify"), 0xCAFEF00D};
    QCOMPARE(wire::decodeMediaState(payloadOf(wire::encode(media))), media);
}

void PhoneLinkTest::phoneStatusCarriesChargingFromVersion11()
{
    wire::PhoneStatus status{80, 3, true, {}};
    QCOMPARE(payloadOf(wire::encode(status)).size(), 3);
    QCOMPARE(wire::decodePhoneStatus(payloadOf(wire::encode(status))), status);

    status.charging = true;
    QCOMPARE(wire::decodePhoneStatus(payloadOf(wire::encode(status))), status);
}

void PhoneLinkTest::theOtherPhoneMessagesRoundTrip()
{
    const wire::Notification notification{2, QStringLiteral("Priya"), QStringLiteral("Running 10 min late")};
    QCOMPARE(wire::decodeNotification(payloadOf(wire::encode(notification))), notification);

    const wire::ListEntry entry{wire::ListKind::Reminders, 2, QStringLiteral("Service"), QStringLiteral("Friday")};
    QCOMPARE(wire::decodeListEntry(payloadOf(wire::encode(entry))), entry);

    const wire::TimeSync time{1'792'000'000, 330};
    QCOMPARE(wire::decodeTimeSync(payloadOf(wire::encode(time))), time);
    const wire::TimeSync west{1'792'000'000, -480};
    QCOMPARE(wire::decodeTimeSync(payloadOf(wire::encode(west))), west);

    const wire::MediaArt art{7, 150, 400, QByteArray(150, 'x')};
    QCOMPARE(wire::decodeMediaArt(payloadOf(wire::encode(art))), art);

    QCOMPARE(wire::encodeNavStop(), wire::encodeFrame(wire::MessageType::NavStop));
}

void PhoneLinkTest::fieldsANewerAppAppendsAreIgnored()
{
    auto nav = rightTurnOnMgRoad();
    nav.next = wire::NextManeuver{wire::Maneuver::Left, 300};
    const QByteArray longer = payloadOf(wire::encode(nav)) + QByteArray::fromHex("01 02 03");
    QCOMPARE(wire::decodeNavUpdate(longer), nav);

    const wire::PhoneStatus status{50, 2, false, false};
    QCOMPARE(wire::decodePhoneStatus(payloadOf(wire::encode(status)) + QByteArray(4, '\x09')), status);
}

void PhoneLinkTest::aShortPayloadDecodesToNothing()
{
    QByteArray nav = payloadOf(kNavVector);
    nav.chop(1);
    QVERIFY(!wire::decodeNavUpdate(nav));
    QVERIFY(!wire::decodeCallState({}));
    QVERIFY(!wire::decodeMediaState(QByteArray(5, '\0')));
    QVERIFY(!wire::decodeTimeSync(QByteArray(5, '\0')));
    QVERIFY(!wire::decodePhoneStatus(QByteArray(2, '\0')));
    QVERIFY(!wire::decodeMediaArt(QByteArray(7, '\0')));
}

void PhoneLinkTest::anUnknownListOrSlotIsRejected()
{
    QVERIFY(!wire::decodeListEntry(payloadOf(wire::encode(wire::ListEntry{wire::ListKind::Contacts, 3, {}, {}}))));
    QByteArray otherList = payloadOf(wire::encode(wire::ListEntry{wire::ListKind::Contacts, 0, {}, {}}));
    otherList[0] = 2;
    QVERIFY(!wire::decodeListEntry(otherList));
}

void PhoneLinkTest::textIsCutOnACharacterBoundary()
{
    // 47 ASCII bytes, then a two-byte é that would straddle the 48-byte limit.
    const QString title = QString(47, QLatin1Char('a')) + QStringLiteral("é");
    const wire::Notification sent{0, title, {}};
    const auto received = wire::decodeNotification(payloadOf(wire::encode(sent)));
    QVERIFY(received);
    QCOMPARE(received->sender, QString(47, QLatin1Char('a')));

    // A sender that ignored the limit: the receiver cuts the same way.
    const QByteArray utf8 = (QString(46, QLatin1Char('b')) + QStringLiteral("₹₹")).toUtf8(); // 46 + 3 + 3 bytes
    QByteArray payload;
    payload.append('\0');
    payload.append(static_cast<char>(utf8.size()));
    payload.append(utf8);
    payload.append('\0');
    const auto clipped = wire::decodeNotification(payload);
    QVERIFY(clipped);
    QCOMPARE(clipped->sender, QString(46, QLatin1Char('b')));

    QCOMPARE(wire::clipUtf8(QByteArray("abc"), 48), QByteArray("abc"));
}

void PhoneLinkTest::clusterMessagesHaveTheirBytes()
{
    QCOMPARE(wire::encodeHeartbeat(), QByteArray::fromHex("a5 01 30 00 00 d1 37"));
    QCOMPARE(wire::encodeMediaCommand(wire::MediaCommand::PlayPause), QByteArray::fromHex("a5 01 40 01 00 01 d0 f2"));
    QCOMPARE(wire::encodeCallCommand(wire::CallCommand::Answer), QByteArray::fromHex("a5 01 41 01 00 01 64 84"));
    QCOMPARE(wire::encodeCallCommand(wire::CallCommand::CallContact, 1),
             QByteArray::fromHex("a5 01 41 02 00 03 01 93 58"));

    const wire::VehicleStatus vehicle{68, 112, 29813, 1234, wire::ChargeState::Charging, 2, 1, 2};
    const QByteArray vehicleBytes =
        QByteArray::fromHex("a5 01 60 10 00 44 70 00 75 74 00 00 d2 04 00 00 01 02 01 02 00 05 a1");
    QCOMPARE(wire::encode(vehicle), vehicleBytes);
    QCOMPARE(wire::decodeVehicleStatus(payloadOf(vehicleBytes)), vehicle);

    const wire::ClusterInfo info{1, 0x3F, QStringLiteral("APEX EV"), QStringLiteral("0.2.0")};
    const QByteArray infoBytes =
        QByteArray::fromHex("a5 01 61 13 00 01 3f 00 00 00 07 41 50 45 58 20 45 56 05 30 2e 32 2e 30 1c 9d");
    QCOMPARE(wire::encode(info), infoBytes);
    QCOMPARE(wire::decodeClusterInfo(payloadOf(infoBytes)), info);
}

void PhoneLinkTest::albumArtIsReassembledForTheCurrentTrackOnly()
{
    QByteArray cover(400, '\0');
    for (int i = 0; i < cover.size(); ++i)
        cover[i] = static_cast<char>(i * 7);

    wire::ArtAssembler art;
    QVERIFY(!art.add({7, 0, 400, cover.left(150)})); // no track says 7 yet
    art.expect(7);
    QVERIFY(!art.add({8, 0, 400, cover.left(150)}));
    QVERIFY(!art.add({7, 0, 400, cover.left(150)}));
    QVERIFY(!art.add({7, 300, 400, cover.mid(300)})); // a lost chunk: wait for the next offset 0
    QVERIFY(!art.add({7, 150, 400, cover.mid(150, 150)}));
    QVERIFY(art.picture().isEmpty());
    QVERIFY(art.add({7, 300, 400, cover.mid(300)}));
    QCOMPARE(art.picture(), cover);

    art.expect(7); // the same track again: the picture stays
    QCOMPARE(art.picture(), cover);
    art.expect(9);
    QVERIFY(art.picture().isEmpty());
    QVERIFY(!art.add({9, 0, wire::kMaxArtBytes + 1, cover.left(150)}));
}

void PhoneLinkTest::clusterInfoGoesOutWhenThePhoneSubscribes()
{
    LinkRig rig;
    QVERIFY(rig.transport->isStarted());
    QVERIFY(!rig.transport->sent().isEmpty());
    const auto info = wire::decodeClusterInfo(payloadOf(rig.transport->sent().constFirst()));
    QVERIFY(info);
    QCOMPARE(info->minorVersion, 1);
    QCOMPARE(info->features, ProtocolPhoneLink::features());
    QCOMPARE(info->model, QStringLiteral("APEX EV"));
    QCOMPARE(info->firmware, QStringLiteral("0.2.0"));
}

void PhoneLinkTest::heartbeatsGoOutWhileThePhoneIsThere()
{
    LinkRig rig;
    QTRY_VERIFY(rig.transport->sent().count(wire::encodeHeartbeat()) >= 2);

    rig.transport->disconnectPhone();
    rig.transport->clearSent();
    QTest::qWait(100);
    QVERIFY(rig.transport->sent().isEmpty());
}

void PhoneLinkTest::theLinkComesUpWithTheFirstFrame()
{
    LinkRig rig;
    QSignalSpy connection(rig.link.get(), &IPhoneLink::connectionChanged);
    QVERIFY(!rig.link->isConnected());

    rig.phoneSends(wire::encode(wire::PhoneStatus{72, 4, true, true}));
    QVERIFY(rig.link->isConnected());
    QCOMPARE(rig.link->batteryPercent(), 72);
    QCOMPARE(rig.link->signalBars(), 4);
    QVERIFY(rig.link->phoneCharging());
    QCOMPARE(connection.count(), 2); // up, then the new status
}

void PhoneLinkTest::silenceClearsEverythingPersonal()
{
    LinkRig rig;
    rig.phoneSends(wire::encode(wire::PhoneStatus{72, 4, true, {}}));
    rig.ring(QStringLiteral("Rahul Sharma"));
    rig.phoneSends(wire::encode(wire::MediaState{true, 50, 10, 200, QStringLiteral("Night Drive"),
                                                 QStringLiteral("Skyline"), wire::MediaSource{{}, 5}}));
    rig.phoneSends(wire::encode(wire::MediaArt{5, 0, 3, QByteArray("jpg")}));
    rig.phoneSends(wire::encode(rightTurnOnMgRoad()));
    rig.phoneSends(wire::encode(wire::ListEntry{wire::ListKind::Contacts, 0, QStringLiteral("Mum"), {}}));
    rig.phoneSends(wire::encode(wire::Notification{1, QStringLiteral("Priya"), QStringLiteral("Hi")}));

    QCOMPARE(rig.link->call().state, CallState::Incoming);
    QVERIFY(rig.link->media().available);
    QCOMPARE(rig.link->albumArt(), QByteArray("jpg"));
    QVERIFY(rig.link->guidance().active);
    QCOMPARE(rig.link->contacts().size(), 1);
    QVERIFY(rig.link->notification());

    QSignalSpy connection(rig.link.get(), &IPhoneLink::connectionChanged);
    QSignalSpy missed(rig.link.get(), &IPhoneLink::missedCall);
    QTRY_VERIFY(!rig.link->isConnected());
    QCOMPARE(connection.count(), 1);
    QCOMPARE(missed.count(), 0);
    QCOMPARE(rig.link->call(), CallInfo{});
    QCOMPARE(rig.link->media(), MediaInfo{});
    QVERIFY(rig.link->albumArt().isEmpty());
    QCOMPARE(rig.link->guidance(), GuidanceInfo{});
    QVERIFY(rig.link->contacts().isEmpty());
    QVERIFY(!rig.link->notification());
    QCOMPARE(rig.link->batteryPercent(), 0);

    // Heard again: back up, with nothing left over.
    rig.phoneSends(wire::encodeHeartbeat());
    QVERIFY(rig.link->isConnected());
    QVERIFY(!rig.link->media().available);
}

void PhoneLinkTest::aDisconnectClearsEverythingToo()
{
    LinkRig rig;
    rig.phoneSends(wire::encode(rightTurnOnMgRoad()));
    QVERIFY(rig.link->guidance().active);

    rig.transport->disconnectPhone();
    QVERIFY(!rig.link->isConnected());
    QVERIFY(!rig.link->guidance().active);
}

void PhoneLinkTest::anUnansweredCallIsMissed()
{
    LinkRig rig;
    QSignalSpy missed(rig.link.get(), &IPhoneLink::missedCall);
    rig.ring(QStringLiteral("Rahul Sharma"));
    rig.ring(QStringLiteral("Rahul Sharma")); // repeated while ringing
    rig.callEnds();
    QCOMPARE(missed.count(), 1);
    QCOMPARE(missed.constFirst().constFirst().toString(), QStringLiteral("Rahul Sharma"));
    QCOMPARE(rig.link->call().state, CallState::Idle);
}

void PhoneLinkTest::anAnsweredOrDeclinedCallIsNotMissed()
{
    LinkRig rig;
    QSignalSpy missed(rig.link.get(), &IPhoneLink::missedCall);

    rig.ring(QStringLiteral("Rahul Sharma"));
    rig.phoneSends(wire::encode(wire::CallState{wire::CallStatus::Active, QStringLiteral("Rahul Sharma"), {}}));
    rig.callEnds();

    rig.ring(QStringLiteral("Priya"));
    rig.link->declineCall();
    rig.callEnds();

    QCOMPARE(missed.count(), 0);

    // Declining one call does not hide the next one going unanswered.
    rig.ring(QStringLiteral("Priya"));
    rig.callEnds();
    QCOMPARE(missed.count(), 1);
}

void PhoneLinkTest::callDurationComesFromThePhone()
{
    LinkRig rig(5000);
    rig.phoneSends(wire::encode(
        wire::CallState{wire::CallStatus::Active, QStringLiteral("Rahul Sharma"), wire::CallDetail{65, false, true}}));
    QCOMPARE(rig.link->call().state, CallState::Active);
    QCOMPARE(rig.link->call().durationSeconds, 65);
    QVERIFY(rig.link->call().muted);

    // A version 1.0 phone sends no elapsed time: the cluster counts from when the call began.
    rig.callEnds();
    rig.phoneSends(wire::encode(wire::CallState{wire::CallStatus::Active, QStringLiteral("Priya"), {}}));
    QCOMPARE(rig.link->call().durationSeconds, 0);
    QTRY_COMPARE_WITH_TIMEOUT(rig.link->call().durationSeconds, 1, 1500);
}

void PhoneLinkTest::anOutgoingCallIsShownAsActive()
{
    LinkRig rig;
    QSignalSpy missed(rig.link.get(), &IPhoneLink::missedCall);
    rig.phoneSends(wire::encode(
        wire::CallState{wire::CallStatus::Ringing, QStringLiteral("Mum"), wire::CallDetail{0, true, false}}));
    QCOMPARE(rig.link->call().state, CallState::Active);
    QVERIFY(rig.link->call().outgoing);
    rig.callEnds();
    QCOMPARE(missed.count(), 0);
}

void PhoneLinkTest::ridersButtonsSendCommands()
{
    LinkRig rig;
    rig.ring(QStringLiteral("Rahul Sharma"));
    rig.phoneSends(wire::encode(wire::MediaState{true, 50, 10, 200, QStringLiteral("Night Drive"), {}, {}}));
    rig.transport->clearSent();

    rig.link->answerCall();
    rig.link->declineCall();
    rig.link->togglePlayback();
    rig.link->nextTrack();
    rig.link->previousTrack();
    rig.link->callContact(1); // nothing in slot 1 yet
    rig.phoneSends(wire::encode(wire::ListEntry{wire::ListKind::Contacts, 1, QStringLiteral("Mum"), {}}));
    rig.link->callContact(1);

    const QList<QByteArray> expected = {
        QByteArray::fromHex("a5 01 41 01 00 01 64 84"), QByteArray::fromHex("a5 01 41 01 00 02 07 b4"),
        QByteArray::fromHex("a5 01 40 01 00 01 d0 f2"), QByteArray::fromHex("a5 01 40 01 00 02 b3 c2"),
        QByteArray::fromHex("a5 01 40 01 00 03 92 d2"), QByteArray::fromHex("a5 01 41 02 00 03 01 93 58"),
    };
    QList<QByteArray> sent = rig.transport->sent();
    sent.removeAll(wire::encodeHeartbeat());
    QCOMPARE(sent, expected);
}

void PhoneLinkTest::guidanceIsMappedOntoTheClustersManeuvers()
{
    LinkRig rig;
    auto nav = rightTurnOnMgRoad();
    rig.phoneSends(wire::encode(nav));
    auto guidance = rig.link->guidance();
    QVERIFY(guidance.active);
    QCOMPARE(guidance.maneuver, Maneuver::Right);
    QCOMPARE(guidance.distanceMetres, 250);
    QCOMPARE(guidance.street, QStringLiteral("MG Road"));
    QCOMPARE(guidance.remainingKm, 12.4);
    QCOMPARE(guidance.remainingMinutes, 23);
    QCOMPARE(guidance.nextManeuver, Maneuver::None);
    const int minutesToArrival = QTime::currentTime().secsTo(guidance.arrival) / 60;
    QVERIFY2(minutesToArrival >= 22 && minutesToArrival <= 23, qPrintable(guidance.arrival.toString()));

    nav.maneuver = wire::Maneuver::RoundaboutEnter;
    nav.roundaboutExit = 2;
    nav.next = wire::NextManeuver{wire::Maneuver::Destination, 900};
    rig.phoneSends(wire::encode(nav));
    guidance = rig.link->guidance();
    QCOMPARE(guidance.maneuver, Maneuver::Roundabout);
    QCOMPARE(maneuverKey(guidance.maneuver, guidance.roundaboutExit), QStringLiteral("roundabout-2"));
    QCOMPARE(guidance.nextManeuver, Maneuver::Arrive);
    QCOMPARE(guidance.nextDistanceMetres, 900);

    const QList<QPair<wire::Maneuver, QString>> keys = {
        {wire::Maneuver::None, {}},
        {wire::Maneuver::Straight, QStringLiteral("straight")},
        {wire::Maneuver::SlightLeft, QStringLiteral("slight-left")},
        {wire::Maneuver::Left, QStringLiteral("left")},
        {wire::Maneuver::SharpLeft, QStringLiteral("sharp-left")},
        {wire::Maneuver::SlightRight, QStringLiteral("slight-right")},
        {wire::Maneuver::Right, QStringLiteral("right")},
        {wire::Maneuver::SharpRight, QStringLiteral("sharp-right")},
        {wire::Maneuver::UTurnLeft, QStringLiteral("uturn")},
        {wire::Maneuver::UTurnRight, QStringLiteral("uturn-right")},
        {wire::Maneuver::RoundaboutEnter, QStringLiteral("roundabout-1")},
        {wire::Maneuver::RoundaboutExit, QStringLiteral("roundabout-exit")},
        {wire::Maneuver::ForkLeft, QStringLiteral("fork-left")},
        {wire::Maneuver::ForkRight, QStringLiteral("fork-right")},
        {wire::Maneuver::MergeLeft, QStringLiteral("merge-left")},
        {wire::Maneuver::MergeRight, QStringLiteral("merge-right")},
        {wire::Maneuver::Destination, QStringLiteral("arrive")},
    };
    for (const auto &[code, key] : keys) {
        nav.maneuver = code;
        nav.roundaboutExit = 0;
        rig.phoneSends(wire::encode(nav));
        QCOMPARE(maneuverKey(rig.link->guidance().maneuver, rig.link->guidance().roundaboutExit), key);
    }

    QByteArray unknown = payloadOf(wire::encode(nav));
    unknown[0] = 40;
    rig.phoneSends(wire::encodeFrame(wire::MessageType::NavUpdate, unknown));
    QCOMPARE(rig.link->guidance().maneuver, Maneuver::None);
}

void PhoneLinkTest::navStopEndsTheRoute()
{
    LinkRig rig;
    rig.phoneSends(wire::encode(rightTurnOnMgRoad()));
    QSignalSpy changed(rig.link.get(), &IPhoneLink::guidanceChanged);
    rig.phoneSends(wire::encodeNavStop());
    QCOMPARE(changed.count(), 1);
    QVERIFY(!rig.link->guidance().active);
}

void PhoneLinkTest::albumArtArrivesAfterItsMediaState()
{
    LinkRig rig;
    QSignalSpy art(rig.link.get(), &IPhoneLink::albumArtChanged);
    const QByteArray cover(300, 'c');

    rig.phoneSends(wire::encode(wire::MediaState{
        true, 50, 0, 200, QStringLiteral("Open Road"), {}, wire::MediaSource{QStringLiteral("Spotify"), 42}}));
    QCOMPARE(rig.link->media().artId, quint32(42));
    QCOMPARE(rig.link->media().source, QStringLiteral("Spotify"));
    QCOMPARE(art.count(), 1);
    rig.phoneSends(wire::encode(wire::MediaArt{42, 0, 300, cover.left(150)}));
    QVERIFY(rig.link->albumArt().isEmpty());
    rig.phoneSends(wire::encode(wire::MediaArt{42, 150, 300, cover.mid(150)}));
    QCOMPARE(rig.link->albumArt(), cover);
    QCOMPARE(art.count(), 2);

    // The 5-second refresh of the same track keeps the cover.
    rig.phoneSends(wire::encode(wire::MediaState{
        true, 50, 5, 200, QStringLiteral("Open Road"), {}, wire::MediaSource{QStringLiteral("Spotify"), 42}}));
    QCOMPARE(rig.link->albumArt(), cover);
    QCOMPARE(art.count(), 2);

    // A v1.0 MediaState has no art id: the placeholder is back.
    rig.phoneSends(wire::encode(wire::MediaState{true, 50, 0, 200, QStringLiteral("Low Gear"), {}, {}}));
    QVERIFY(rig.link->albumArt().isEmpty());
    QVERIFY(rig.link->media().source.isEmpty());
}

void PhoneLinkTest::contactsAndRemindersFillTheirSlots()
{
    LinkRig rig;
    QSignalSpy lists(rig.link.get(), &IPhoneLink::listsChanged);
    rig.phoneSends(wire::encode(wire::ListEntry{wire::ListKind::Contacts, 2, QStringLiteral("Priya"), {}}));
    rig.phoneSends(wire::encode(wire::ListEntry{wire::ListKind::Contacts, 0, QStringLiteral("Mum"), {}}));
    rig.phoneSends(wire::encode(
        wire::ListEntry{wire::ListKind::Reminders, 0, QStringLiteral("Service"), QStringLiteral("Fri 10:00")}));
    rig.phoneSends(wire::encode(wire::ListEntry{wire::ListKind::Contacts, 0, QStringLiteral("Mum"), {}}));
    QCOMPARE(lists.count(), 3);

    const auto contacts = rig.link->contacts();
    QCOMPARE(contacts.size(), 3);
    QCOMPARE(contacts.at(0).title, QStringLiteral("Mum"));
    QVERIFY(contacts.at(1).title.isEmpty());
    QCOMPARE(contacts.at(2).title, QStringLiteral("Priya"));
    QCOMPARE(rig.link->reminders(), (QList<PhoneListEntry>{{QStringLiteral("Service"), QStringLiteral("Fri 10:00")}}));
}

void PhoneLinkTest::vehicleStatusGoesOutWhenPublishedAndOnSubscribe()
{
    LinkRig rig;
    rig.transport->clearSent();

    VehicleSummary summary;
    summary.stateOfChargePercent = 68;
    summary.rangeKm = 112;
    summary.odometerKm = 2981.3;
    summary.tripAKm = 123.4;
    summary.charging = true;
    summary.rideMode = 2; // sport
    summary.gear = 1;     // D
    summary.activeFaults = 2;
    rig.link->publishVehicle(summary);

    const QByteArray expected =
        QByteArray::fromHex("a5 01 60 10 00 44 70 00 75 74 00 00 d2 04 00 00 01 02 01 02 00 05 a1");
    QVERIFY(rig.transport->sent().contains(expected));

    // The next phone gets the last summary straight after ClusterInfo.
    rig.transport->disconnectPhone();
    rig.transport->clearSent();
    rig.transport->connectPhone();
    QCOMPARE(rig.transport->sent().size(), 2);
    QCOMPARE(rig.transport->sent().at(1), expected);

    summary.chargeComplete = true;
    rig.link->publishVehicle(summary);
    QCOMPARE(wire::decodeVehicleStatus(payloadOf(rig.transport->sent().constLast()))->charging,
             wire::ChargeState::Full);
}

void PhoneLinkTest::framesSplitAcrossWritesStillArrive()
{
    LinkRig rig;
    const QByteArray stream = wire::encode(wire::PhoneStatus{90, 2, true, {}}) + wire::encode(rightTurnOnMgRoad());
    for (qsizetype offset = 0; offset < stream.size(); offset += 7)
        rig.phoneSends(stream.mid(offset, 7));
    QCOMPARE(rig.link->batteryPercent(), 90);
    QVERIFY(rig.link->guidance().active);
}

QTEST_GUILESS_MAIN(PhoneLinkTest)
#include "tst_phonelink.moc"

#include "phonetypes.h"

#include <algorithm>

namespace phonelink {

QString maneuverKey(Maneuver maneuver, int roundaboutExit)
{
    switch (maneuver) {
    case Maneuver::None:
        return {};
    case Maneuver::Straight:
        return QStringLiteral("straight");
    case Maneuver::SlightLeft:
        return QStringLiteral("slight-left");
    case Maneuver::Left:
        return QStringLiteral("left");
    case Maneuver::SharpLeft:
        return QStringLiteral("sharp-left");
    case Maneuver::SlightRight:
        return QStringLiteral("slight-right");
    case Maneuver::Right:
        return QStringLiteral("right");
    case Maneuver::SharpRight:
        return QStringLiteral("sharp-right");
    case Maneuver::UTurn:
        return QStringLiteral("uturn");
    case Maneuver::UTurnRight:
        return QStringLiteral("uturn-right");
    case Maneuver::Roundabout:
        // The pictograms stop at the third exit; the words still name the real one.
        return QStringLiteral("roundabout-%1").arg(std::clamp(roundaboutExit, 1, 3));
    case Maneuver::RoundaboutExit:
        return QStringLiteral("roundabout-exit");
    case Maneuver::ForkLeft:
        return QStringLiteral("fork-left");
    case Maneuver::ForkRight:
        return QStringLiteral("fork-right");
    case Maneuver::MergeLeft:
        return QStringLiteral("merge-left");
    case Maneuver::MergeRight:
        return QStringLiteral("merge-right");
    case Maneuver::Arrive:
        return QStringLiteral("arrive");
    }
    return {};
}

} // namespace phonelink

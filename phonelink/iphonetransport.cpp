#include "iphonetransport.h"

namespace phonelink {

IPhoneTransport::IPhoneTransport(QObject *parent) : QObject(parent) {}

IPhoneTransport::~IPhoneTransport() = default;

} // namespace phonelink

# The phone link: the wire codec against the protocol's test vectors, and the
# link's behaviour (heartbeats, calls, media, covers, lists) over a fake pipe.
QT += testlib network
QT -= gui
CONFIG += c++20 console testcase
CONFIG -= app_bundle
TARGET = tst_phonelink

INCLUDEPATH += ../..
SOURCES += \
        tst_phonelink.cpp \
        ../../phonelink/iphonelink.cpp \
        ../../phonelink/iphonetransport.cpp \
        ../../phonelink/phonelinkcodec.cpp \
        ../../phonelink/phonetypes.cpp \
        ../../phonelink/protocolphonelink.cpp
HEADERS += \
        fakephonetransport.h \
        ../../phonelink/iphonelink.h \
        ../../phonelink/iphonetransport.h \
        ../../phonelink/phonelinkcodec.h \
        ../../phonelink/protocolphonelink.h

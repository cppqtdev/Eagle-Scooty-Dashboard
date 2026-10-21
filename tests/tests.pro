# Unit tests of the dashboard core: CAN decoding, alerts, phone and documents.
QT += testlib
QT -= gui
CONFIG += c++20 console testcase
CONFIG -= app_bundle
TARGET = tst_core

qtHaveModule(serialbus) {
    QT += serialbus
    DEFINES += EAGLE_HAS_CAN
}

INCLUDEPATH += ..
SOURCES += \
        tst_core.cpp \
        ../alertcenter.cpp \
        ../canvehiclesource.cpp \
        ../dashboarddata.cpp \
        ../phoneservice.cpp \
        ../phonelink/iphonelink.cpp \
        ../phonelink/phonetypes.cpp \
        ../vehicledocuments.cpp
HEADERS += \
        ../alertcenter.h \
        ../canvehiclesource.h \
        ../dashboarddata.h \
        ../phoneservice.h \
        ../phonelink/iphonelink.h \
        ../vehicledocuments.h

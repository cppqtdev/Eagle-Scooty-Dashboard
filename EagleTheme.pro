QT += quick quickcontrols2 network

# Qt 6.2 is what the RK3328 Yocto image ships; the desk uses 6.8.
!versionAtLeast(QT_VERSION, 6.2.0): error("EagleTheme requires Qt 6.2 or newer")

CONFIG += c++20   # the phone link codec uses defaulted comparisons

# The real Bluetooth radio (BlueZ) on the Linux board; a simulated one elsewhere.
# Live vehicle data from SocketCAN (Qt SerialBus).
qtHaveModule(serialbus) {
    QT += serialbus
    DEFINES += EAGLE_HAS_CAN
}

# The Eagle Ride app links over BLE (the board is the GATT peripheral) or, on the
# desk, over TCP port 47100 with the same bytes (docs/PhoneLink.md).
linux:qtHaveModule(bluetooth) {
    QT += bluetooth
    DEFINES += EAGLE_HAS_BLUETOOTH
    SOURCES += phonelink/bleperipheraltransport.cpp
    HEADERS += phonelink/bleperipheraltransport.h
}

DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000

SOURCES += \
        alertcenter.cpp \
        bluetoothmanager.cpp \
        canvehiclesource.cpp \
        dashboarddata.cpp \
        main.cpp \
        phoneservice.cpp \
        phonelinkbridge.cpp \
        phonelink/iphonelink.cpp \
        phonelink/iphonetransport.cpp \
        phonelink/phonelinkcodec.cpp \
        phonelink/phonetypes.cpp \
        phonelink/protocolphonelink.cpp \
        phonelink/tcpphonetransport.cpp \
        systemclock.cpp \
        themecontroller.cpp \
        vehicledocuments.cpp \
        vehiclesimulator.cpp \
        wifimanager.cpp

HEADERS += \
        alertcenter.h \
        bluetoothmanager.h \
        canvehiclesource.h \
        dashboarddata.h \
        phoneservice.h \
        phonelinkbridge.h \
        phonelink/iphonelink.h \
        phonelink/iphonetransport.h \
        phonelink/phonelinkcodec.h \
        phonelink/phonelinklog.h \
        phonelink/phonetypes.h \
        phonelink/protocolphonelink.h \
        phonelink/tcpphonetransport.h \
        systemclock.h \
        themecontroller.h \
        vehicledocuments.h \
        vehiclesimulator.h \
        wifimanager.h

RESOURCES += qml.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =


win32:RC_ICONS += app.ico
# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

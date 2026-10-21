QT += quick quickcontrols2

!versionAtLeast(QT_VERSION, 6.5.0): error("EagleTheme requires Qt 6.5 or newer")

CONFIG += c++17

# The real Bluetooth radio (BlueZ) on the Linux board; a simulated one elsewhere.
linux:qtHaveModule(bluetooth) {
    QT += bluetooth
    DEFINES += EAGLE_HAS_BLUETOOTH
}

DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000

SOURCES += \
        alertcenter.cpp \
        bluetoothmanager.cpp \
        dashboarddata.cpp \
        main.cpp \
        phoneservice.cpp \
        systemclock.cpp \
        themecontroller.cpp \
        vehicledocuments.cpp \
        vehiclesimulator.cpp \
        wifimanager.cpp

HEADERS += \
        alertcenter.h \
        bluetoothmanager.h \
        dashboarddata.h \
        phoneservice.h \
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

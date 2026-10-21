QT += quick quickcontrols2

!versionAtLeast(QT_VERSION, 6.5.0): error("EagleTheme requires Qt 6.5 or newer")

CONFIG += c++17

DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000

SOURCES += \
        alertcenter.cpp \
        dashboarddata.cpp \
        main.cpp \
        phoneservice.cpp \
        systemclock.cpp \
        themecontroller.cpp \
        vehicledocuments.cpp \
        vehiclesimulator.cpp

HEADERS += \
        alertcenter.h \
        dashboarddata.h \
        phoneservice.h \
        systemclock.h \
        themecontroller.h \
        vehicledocuments.h \
        vehiclesimulator.h

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

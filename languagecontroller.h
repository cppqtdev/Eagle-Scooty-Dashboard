#pragma once

#include <QObject>
#include <QTranslator>
#include <QVariantList>

class QQmlEngine;

// The language the dashboard speaks. Each one is a Qt translation compiled into
// the binary (i18n/eagle_<code>.qm); switching loads it and re-evaluates every
// qsTr() on screen, with no restart. English is the source and needs no file.
// The choice is kept across power cycles.
class LanguageController final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int current READ current WRITE setCurrent NOTIFY currentChanged)
    Q_PROPERTY(QVariantList languages READ languages CONSTANT)
    Q_PROPERTY(QString currentName READ currentName NOTIFY currentChanged)

public:
    explicit LanguageController(QObject *parent = nullptr);

    void setEngine(QQmlEngine *engine) { m_engine = engine; }

    int current() const { return m_current; }
    QVariantList languages() const;
    QString currentName() const;

public slots:
    void setCurrent(int index);
    void load();   // the saved language, at start-up

signals:
    void currentChanged();

private:
    struct Language {
        const char *code;
        const char *nativeName;
    };
    static const Language kLanguages[];
    static const int kCount;

    bool install(int index);

    QQmlEngine *m_engine = nullptr;
    QTranslator m_translator;
    int m_current = 0;
};

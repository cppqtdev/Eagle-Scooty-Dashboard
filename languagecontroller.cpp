#include "languagecontroller.h"

#include <QCoreApplication>
#include <QQmlEngine>
#include <QSettings>

namespace {
constexpr auto kLanguageKey = "display/language";
}

// The order is the one the settings and the phone app (setting 6) use.
const LanguageController::Language LanguageController::kLanguages[] = {
    {"en", "English"},
    {"hi", "हिन्दी"},
};
const int LanguageController::kCount = int(sizeof(kLanguages) / sizeof(kLanguages[0]));

LanguageController::LanguageController(QObject *parent)
    : QObject(parent)
{
}

QVariantList LanguageController::languages() const
{
    QVariantList list;
    for (int i = 0; i < kCount; ++i) {
        list.append(QVariantMap{{QStringLiteral("code"), QString::fromLatin1(kLanguages[i].code)},
                                {QStringLiteral("name"), QString::fromUtf8(kLanguages[i].nativeName)}});
    }
    return list;
}

QString LanguageController::currentName() const
{
    return QString::fromUtf8(kLanguages[m_current].nativeName);
}

void LanguageController::load()
{
    const QString code = QSettings().value(QLatin1String(kLanguageKey), QStringLiteral("en")).toString();
    for (int i = 0; i < kCount; ++i) {
        if (code == QLatin1String(kLanguages[i].code) && install(i)) {
            m_current = i;
            return;
        }
    }
}

void LanguageController::setCurrent(int index)
{
    if (index < 0 || index >= kCount || index == m_current || !install(index))
        return;
    m_current = index;
    QSettings().setValue(QLatin1String(kLanguageKey), QString::fromLatin1(kLanguages[index].code));
    if (m_engine)
        m_engine->retranslate();
    emit currentChanged();
}

bool LanguageController::install(int index)
{
    QCoreApplication::removeTranslator(&m_translator);
    if (index == 0)
        return true;   // English is the source text
    if (!m_translator.load(QStringLiteral(":/i18n/eagle_%1.qm").arg(QString::fromLatin1(kLanguages[index].code))))
        return false;
    QCoreApplication::installTranslator(&m_translator);
    return true;
}

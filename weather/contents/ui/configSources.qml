import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "../code/weather.js" as W

KCM.SimpleKCM {
    property string cfg_model
    property string cfg_modelDefault
    property string cfg_site
    property string cfg_siteDefault
    Kirigami.FormLayout {
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Forecast data") }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Forecast model:")
            model: W.MODELS.map(m => m[1])
            currentIndex: Math.max(0, W.MODELS.findIndex(m => m[0] === cfg_model))
            onActivated: cfg_model = W.MODELS[currentIndex][0]
        }
        QQC2.Label {
            text: i18n("All models are served by Open-Meteo. Some don't provide UV, visibility, gusts or rain chance (shown as –).")
            wrapMode: Text.Wrap; opacity: 0.7; Layout.maximumWidth: Kirigami.Units.gridUnit * 22
        }
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Website") }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Open forecast on:")
            model: W.SITES.map(m => m[1])
            currentIndex: Math.max(0, W.SITES.findIndex(m => m[0] === cfg_site))
            onActivated: cfg_site = W.SITES[currentIndex][0]
        }
    }
}

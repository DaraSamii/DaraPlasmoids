import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "../code/weather.js" as W

KCM.SimpleKCM {
    property int cfg_backgroundStyle
    property int cfg_backgroundStyleDefault
    property int cfg_glassOpacity
    property int cfg_glassOpacityDefault
    property bool cfg_animations
    property bool cfg_animationsDefault
    property int cfg_popupSize
    property int cfg_popupSizeDefault
    Kirigami.FormLayout {
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Background") }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Style:")
            model: [i18n("Glass with blur"), i18n("Glass (no blur, lighter on the GPU)"), i18n("Plain (Plasma theme)")]
            currentIndex: cfg_backgroundStyle
            onActivated: cfg_backgroundStyle = currentIndex
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Glass tint:")
            enabled: cfg_backgroundStyle < 2
            QQC2.Slider { from: 4; to: 40; stepSize: 2; value: cfg_glassOpacity; onMoved: cfg_glassOpacity = value; Layout.preferredWidth: Kirigami.Units.gridUnit * 12 }
            QQC2.Label { text: cfg_glassOpacity + "%"; Layout.preferredWidth: Kirigami.Units.gridUnit * 2.5 }
        }
        QQC2.Label {
            text: i18n("Higher tint = more readable text over bright skies.")
            opacity: 0.7; enabled: cfg_backgroundStyle < 2
        }
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Motion and size") }
        QQC2.CheckBox { Kirigami.FormData.label: i18n("Animation:"); text: i18n("Animated weather scene and visuals"); checked: cfg_animations; onToggled: cfg_animations = checked }
        QQC2.Label { text: i18n("Animations also stop when Plasma animations are turned off system-wide."); opacity: 0.7 }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Popup size:")
            model: [i18n("Compact"), i18n("Standard"), i18n("Large")]
            currentIndex: cfg_popupSize
            onActivated: cfg_popupSize = currentIndex
        }
    }
}

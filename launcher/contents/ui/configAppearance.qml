import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import QtQuick.Dialogs
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property string cfg_fontFamily
    property string cfg_fontFamilyDefault
    property int cfg_textPreset
    property int cfg_textPresetDefault
    property int cfg_accentMode
    property int cfg_accentModeDefault
    property color cfg_accentColor
    property color cfg_accentColorDefault
    property int cfg_tileRadius
    property int cfg_tileRadiusDefault
    property int cfg_cardOpacity
    property int cfg_cardOpacityDefault
    property bool cfg_animations
    property bool cfg_animationsDefault
    Kirigami.FormLayout {
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Text") }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Font:")
            editable: false
            model: [i18n("System default")].concat(Qt.fontFamilies())
            currentIndex: Math.max(0, model.indexOf(cfg_fontFamily))
            onActivated: cfg_fontFamily = currentIndex === 0 ? "" : model[currentIndex]
        }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Text size:")
            model: [i18n("Tiny"), i18n("Small"), i18n("Normal"), i18n("Big"), i18n("Huge")]
            currentIndex: cfg_textPreset
            onActivated: cfg_textPreset = currentIndex
        }
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Style") }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Accent color:")
            model: [i18n("Follow Plasma theme"), i18n("Custom")]
            currentIndex: cfg_accentMode
            onActivated: cfg_accentMode = currentIndex
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Custom color:")
            visible: cfg_accentMode === 1
            Rectangle { width: Kirigami.Units.gridUnit * 2; height: width; radius: 6; color: cfg_accentColor; border.color: Kirigami.Theme.textColor }
            QQC2.Button { text: i18n("Choose…"); onClicked: cdlg.open() }
        }
        ColorDialog { id: cdlg; selectedColor: cfg_accentColor; onAccepted: cfg_accentColor = selectedColor }
        RowLayout {
            Kirigami.FormData.label: i18n("Tile corner radius:")
            QQC2.Slider { from: 0; to: 32; stepSize: 2; value: cfg_tileRadius; onMoved: cfg_tileRadius = value; Layout.preferredWidth: Kirigami.Units.gridUnit * 12 }
            QQC2.Label { text: cfg_tileRadius + " px"; Layout.preferredWidth: Kirigami.Units.gridUnit * 3 }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Card tint:")
            QQC2.Slider { from: 0; to: 40; stepSize: 2; value: cfg_cardOpacity; onMoved: cfg_cardOpacity = value; Layout.preferredWidth: Kirigami.Units.gridUnit * 12 }
            QQC2.Label { text: cfg_cardOpacity + "%"; Layout.preferredWidth: Kirigami.Units.gridUnit * 3 }
        }
        QQC2.CheckBox { Kirigami.FormData.label: i18n("Animation:"); text: i18n("Animated transitions and hover effects"); checked: cfg_animations; onToggled: cfg_animations = checked }
    }
}

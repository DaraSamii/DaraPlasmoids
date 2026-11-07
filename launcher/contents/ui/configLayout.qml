import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property int cfg_panelWidth
    property int cfg_panelWidthDefault
    property int cfg_viewMode
    property int cfg_viewModeDefault
    property int cfg_powerSize
    property int cfg_powerSizeDefault
    property int cfg_iconPreset
    property int cfg_iconPresetDefault
    property int cfg_tileSpacing
    property int cfg_tileSpacingDefault
    property int cfg_favColumns
    property int cfg_favColumnsDefault
    property int cfg_appColumns
    property int cfg_appColumnsDefault
    Kirigami.FormLayout {
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Overall") }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Icon size:")
            model: [i18n("Tiny"), i18n("Small"), i18n("Normal"), i18n("Big"), i18n("Huge")]
            currentIndex: cfg_iconPreset
            onActivated: cfg_iconPreset = currentIndex
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Launcher width:")
            QQC2.Slider { from: 60; to: 100; stepSize: 2; value: cfg_panelWidth; onMoved: cfg_panelWidth = value; Layout.preferredWidth: Kirigami.Units.gridUnit * 12 }
            QQC2.Label { text: cfg_panelWidth + "% of screen"; Layout.preferredWidth: Kirigami.Units.gridUnit * 3 }
        }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Apps shown as:")
            model: [i18n("Alphabetical (sections by first letter)"), i18n("Grid"), i18n("List")]
            currentIndex: cfg_viewMode
            onActivated: cfg_viewMode = currentIndex
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Power button size:")
            QQC2.Slider { from: 24; to: 72; stepSize: 4; value: cfg_powerSize; onMoved: cfg_powerSize = value; Layout.preferredWidth: Kirigami.Units.gridUnit * 12 }
            QQC2.Label { text: cfg_powerSize + " px"; Layout.preferredWidth: Kirigami.Units.gridUnit * 3 }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Tile spacing:")
            QQC2.Slider { from: 0; to: 24; stepSize: 2; value: cfg_tileSpacing; onMoved: cfg_tileSpacing = value; Layout.preferredWidth: Kirigami.Units.gridUnit * 12 }
            QQC2.Label { text: cfg_tileSpacing + " px"; Layout.preferredWidth: Kirigami.Units.gridUnit * 3 }
        }
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Favorites (left)") }
        RowLayout {
            Kirigami.FormData.label: i18n("Columns:")
            QQC2.Slider { from: 1; to: 6; stepSize: 1; value: cfg_favColumns; onMoved: cfg_favColumns = value; Layout.preferredWidth: Kirigami.Units.gridUnit * 12 }
            QQC2.Label { text: cfg_favColumns + ""; Layout.preferredWidth: Kirigami.Units.gridUnit * 3 }
        }
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("All apps") }
        RowLayout {
            Kirigami.FormData.label: i18n("Columns:")
            QQC2.CheckBox { text: i18n("Automatic"); checked: cfg_appColumns === 0; onToggled: cfg_appColumns = checked ? 0 : 5 }
            QQC2.SpinBox { from: 1; to: 12; value: cfg_appColumns; enabled: cfg_appColumns > 0; onValueModified: cfg_appColumns = value }
        }
    }
}

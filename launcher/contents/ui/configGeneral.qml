import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import QtQuick.Dialogs
import org.kde.iconthemes as KIconThemes
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property string cfg_icon
    property string cfg_iconDefault
    property int cfg_wallpaperMode
    property int cfg_wallpaperModeDefault
    property string cfg_wallpaperPath
    property string cfg_wallpaperPathDefault
    property int cfg_dim
    property int cfg_dimDefault
    property int cfg_blur
    property int cfg_blurDefault
    Kirigami.FormLayout {
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Panel button") }
        RowLayout {
            Kirigami.FormData.label: i18n("Icon:")
            QQC2.Button {
                implicitWidth: Kirigami.Units.iconSizes.large + Kirigami.Units.largeSpacing * 2
                implicitHeight: implicitWidth
                onClicked: iconDlg.open()
                QQC2.ToolTip.text: i18n("Choose an icon")
                QQC2.ToolTip.visible: hovered
                Kirigami.Icon { anchors.centerIn: parent; width: Kirigami.Units.iconSizes.large; height: width; source: cfg_icon }
            }
            QQC2.Button { icon.name: "preferences-desktop-icons"; text: i18n("Choose…"); onClicked: iconDlg.open() }
            QQC2.Button { icon.name: "document-open"; text: i18n("Image file…"); onClicked: imgDlg.open() }
            QQC2.Button { icon.name: "edit-undo"; text: i18n("Default"); onClicked: cfg_icon = cfg_iconDefault; enabled: cfg_icon !== cfg_iconDefault }
        }
        QQC2.Label { text: i18n("Shown on the panel button. Click it to open the launcher."); opacity: 0.7 }
        KIconThemes.IconDialog { id: iconDlg; onIconNameChanged: iconName => { if (iconName) cfg_icon = iconName; } }
        FileDialog {
            id: imgDlg
            nameFilters: [i18n("Images (*.png *.jpg *.jpeg *.svg *.webp)")]
            onAccepted: cfg_icon = selectedFile.toString()
        }
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Background") }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Wallpaper:")
            model: [i18n("Current desktop wallpaper"), i18n("Custom image"), i18n("None (solid color)")]
            currentIndex: cfg_wallpaperMode
            onActivated: cfg_wallpaperMode = currentIndex
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Image:")
            visible: cfg_wallpaperMode === 1
            QQC2.TextField { text: cfg_wallpaperPath; onEditingFinished: cfg_wallpaperPath = text; Layout.preferredWidth: Kirigami.Units.gridUnit * 16; placeholderText: "/path/to/image.jpg" }
            QQC2.Button { icon.name: "document-open"; text: i18n("Browse…"); onClicked: dlg.open() }
        }
        FileDialog {
            id: dlg
            nameFilters: [i18n("Images (*.png *.jpg *.jpeg *.webp *.bmp)")]
            onAccepted: cfg_wallpaperPath = selectedFile.toString().replace("file://", "")
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Dim:")
            QQC2.Slider { from: 0; to: 95; stepSize: 5; value: cfg_dim; onMoved: cfg_dim = value; Layout.preferredWidth: Kirigami.Units.gridUnit * 12 }
            QQC2.Label { text: cfg_dim + "%"; Layout.preferredWidth: Kirigami.Units.gridUnit * 3 }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Blur:")
            QQC2.Slider { from: 0; to: 100; stepSize: 5; value: cfg_blur; onMoved: cfg_blur = value; Layout.preferredWidth: Kirigami.Units.gridUnit * 12 }
            QQC2.Label { text: cfg_blur + "%"; Layout.preferredWidth: Kirigami.Units.gridUnit * 3 }
        }
    }
}

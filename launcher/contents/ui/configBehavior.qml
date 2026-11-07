import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property int cfg_startCategory
    property int cfg_startCategoryDefault
    property bool cfg_searchDocuments
    property bool cfg_searchDocumentsDefault
    property bool cfg_clearSearch
    property bool cfg_clearSearchDefault
    property bool cfg_closeOnLaunch
    property bool cfg_closeOnLaunchDefault
    property bool cfg_closeOnClickOutside
    property bool cfg_closeOnClickOutsideDefault
    property bool cfg_showFavorites
    property bool cfg_showFavoritesDefault
    property bool cfg_showCategories
    property bool cfg_showCategoriesDefault
    property bool cfg_showRecent
    property bool cfg_showRecentDefault
    property bool cfg_showFrequent
    property bool cfg_showFrequentDefault
    property bool cfg_showLetterRail
    property bool cfg_showLetterRailDefault
    property bool cfg_showPower
    property bool cfg_showPowerDefault
    Kirigami.FormLayout {
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("When the launcher opens") }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Show this view:")
            model: [i18n("All applications"), i18n("Recent"), i18n("Most used"), i18n("The one I used last")]
            currentIndex: cfg_startCategory
            onActivated: cfg_startCategory = currentIndex
        }
        QQC2.CheckBox { Kirigami.FormData.label: i18n("Search:"); text: i18n("Also search documents, files, settings and the calculator (off = apps only)"); checked: cfg_searchDocuments; onToggled: cfg_searchDocuments = checked }
        QQC2.CheckBox { Kirigami.FormData.label: i18n("Search box:"); text: i18n("Clear it every time"); checked: cfg_clearSearch; onToggled: cfg_clearSearch = checked }
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Window") }
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Closing") }
        QQC2.CheckBox { Kirigami.FormData.label: i18n("After launching:"); text: i18n("Close the launcher"); checked: cfg_closeOnLaunch; onToggled: cfg_closeOnLaunch = checked }
        QQC2.CheckBox { Kirigami.FormData.label: i18n("Empty space:"); text: i18n("Close when clicked"); checked: cfg_closeOnClickOutside; onToggled: cfg_closeOnClickOutside = checked }
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("What is shown") }
        QQC2.CheckBox { Kirigami.FormData.label: i18n("Favorites:"); text: i18n("Show the favorites panel"); checked: cfg_showFavorites; onToggled: cfg_showFavorites = checked }
        QQC2.CheckBox { Kirigami.FormData.label: i18n("Categories:"); text: i18n("Show the category list"); checked: cfg_showCategories; onToggled: cfg_showCategories = checked }
        QQC2.CheckBox { Kirigami.FormData.label: i18n(""); text: i18n("Include “Recent”"); checked: cfg_showRecent; onToggled: cfg_showRecent = checked }
        QQC2.CheckBox { Kirigami.FormData.label: i18n(""); text: i18n("Include “Most used”"); checked: cfg_showFrequent; onToggled: cfg_showFrequent = checked }
        QQC2.CheckBox { Kirigami.FormData.label: i18n("Letters:"); text: i18n("Show the A–Z rail in alphabetical view"); checked: cfg_showLetterRail; onToggled: cfg_showLetterRail = checked }
        QQC2.CheckBox { Kirigami.FormData.label: i18n("Power:"); text: i18n("Show lock, sleep, log out, restart, shut down"); checked: cfg_showPower; onToggled: cfg_showPower = checked }
    }
}

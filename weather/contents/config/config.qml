import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory { name: i18n("Places"); icon: "mark-location"; source: "configPlaces.qml" }
    ConfigCategory { name: i18n("Units & Time"); icon: "preferences-system-time"; source: "configUnits.qml" }
    ConfigCategory { name: i18n("Sources"); icon: "internet-web-browser"; source: "configSources.qml" }
    ConfigCategory { name: i18n("Appearance"); icon: "preferences-desktop-theme-global"; source: "configAppearance.qml" }
    ConfigCategory { name: i18n("Panel"); icon: "configure-toolbars"; source: "configPanel.qml" }
    ConfigCategory { name: i18n("Content"); icon: "view-list-details"; source: "configContent.qml" }
}

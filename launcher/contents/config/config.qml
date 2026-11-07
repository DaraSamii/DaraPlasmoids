import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory { name: i18n("Panel & wallpaper"); icon: "preferences-desktop-wallpaper"; source: "configGeneral.qml" }
    ConfigCategory { name: i18n("Layout & sizes"); icon: "view-grid"; source: "configLayout.qml" }
    ConfigCategory { name: i18n("Appearance"); icon: "preferences-desktop-theme-global"; source: "configAppearance.qml" }
    ConfigCategory { name: i18n("Behavior"); icon: "preferences-other"; source: "configBehavior.qml" }
}

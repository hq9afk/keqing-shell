pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick

QtObject {
    // Family
    readonly property string fontFamily: "ComicShannsMono Nerd Font"
    readonly property var yujiMaiLoader: FontLoader {
        source: Qt.resolvedUrl("../assets/fonts/YujiMai.ttf")
    }
    readonly property string yujiMaiFamily: yujiMaiLoader.name

    // Body
    readonly property int fontBody: 15

    // Cards
    readonly property int fontTempValue: 22
    readonly property int fontCardIcon: 28

    // Dropdown
    readonly property int fontDropdownChevron: 7

    // Gauge
    readonly property int fontGaugeValue: 11
    readonly property int fontGaugeIcon: 15

    // Media
    readonly property int fontMediaControl: 16

    // Notifications
    readonly property int fontNotificationClose: 10

    // OSD
    readonly property int fontOsdIcon: 18
    readonly property int fontOsdLabel: 15

    // Overview
    readonly property int fontOverviewText: 15

    // Panels
    readonly property int fontPanelActionIcon: 14
    readonly property int fontNetworkClose: 12
    readonly property int fontListItemRemove: 10

    // Polkit
    readonly property int fontPolkitLabel: 13
    readonly property int fontPolkitClose: 16

    // Profile
    readonly property int fontProfileSettings: 16

    // Settings
    readonly property int fontSettingsTitle: 17
    readonly property int fontSettingsWindowIcon: 15
    readonly property int fontSettingsBody: 15
    readonly property int fontSettingsBodySm: 14

    // Sub-panels
    readonly property int fontSubPanelClose: 13

    // Tooltip
    readonly property int fontTooltip: 15
}

pragma ComponentBehavior: Bound

import QtQuick

import qs.modules.settings
import qs.modules.wallpaper
import qs.config

Item {
    id: root

    property var columnsMap: ({})
    readonly property var regions: {
        var out = [];
        for (var i = 0; i < root.screens.length; i++) {
            var screen = root.screens[i];
            var n = root.columnsMap[screen.name] ?? 1;
            for (var c = 0; c < n; c++)
                out.push({
                    screenName: screen.name,
                    columnIndex: c,
                    label: n > 1 ? screen.name + "-" + (c + 1) : screen.name
                });
        }
        return out;
    }
    property var screens: []
    property int selectedColumn: 0
    property string selectedScreen: ""

    signal regionSelected(string screenName, int columnIndex)

    implicitHeight: WallpaperConfig.controlRowHeight

    Row {
        id: regionRow

        anchors.fill: parent
        spacing: WallpaperConfig.dropdownBtnSpacing

        Repeater {
            model: root.regions

            delegate: Rectangle {
                id: regionBtn

                required property var modelData

                border.color: root.selectedScreen === regionBtn.modelData.screenName && root.selectedColumn === regionBtn.modelData.columnIndex ? ColorConfig.accentAlt : "transparent"
                border.width: SettingsConfig.selectorBorderWidth
                color: ColorConfig.lavenderAlpha20
                height: WallpaperConfig.controlRowHeight
                radius: GlobalConfig.radiusSm
                width: (regionRow.width - (root.regions.length - 1) * regionRow.spacing) / Math.max(1, root.regions.length)

                Behavior on border.color {
                    ColorAnimation {
                        duration: SettingsConfig.quickColorAnimMs
                    }
                }

                Text {
                    anchors.centerIn: parent
                    color: ColorConfig.text
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontSettingsBody
                    text: regionBtn.modelData.label
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: root.regionSelected(regionBtn.modelData.screenName, regionBtn.modelData.columnIndex)
                }
            }
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick

import qs.modules.settings
import qs.modules.settings.layout.components
import qs.modules.wallpaper
import qs.config

Item {
    id: controlRow

    property int columnCount: 1
    property bool fillModeSupported: true
    property var fillModes: ({})
    property string selectedScreen: ""
    property var wallpapers: ({})

    signal columnCountChangeRequested(int n)
    signal fillModeChanged(string mode)
    signal wallpaperRemoved

    height: WallpaperConfig.controlRowHeight

    CountStepper {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        value: controlRow.columnCount

        onValueChangeRequested: n => controlRow.columnCountChangeRequested(n)
    }
    Rectangle {
        anchors.centerIn: parent
        border.color: Qt.rgba(1, 0.3, 0.3, 0.5)
        border.width: SettingsConfig.hairlineBorderWidth
        color: removeMa.containsMouse ? "#44FF5555" : "transparent"
        height: WallpaperConfig.controlRowHeight - SettingsConfig.groupContentSpacingSm
        radius: GlobalConfig.radiusSm
        visible: !!controlRow.wallpapers[controlRow.selectedScreen]
        width: removeLabel.implicitWidth + WallpaperConfig.dropdownBtnPadding

        Behavior on color {
            ColorAnimation {
                duration: SettingsConfig.quickColorAnimMs
            }
        }

        Text {
            id: removeLabel

            anchors.centerIn: parent
            color: Qt.rgba(1, 0.4, 0.4, 1)
            font.family: FontConfig.fontFamily
            font.pixelSize: FontConfig.fontSettingsBody
            text: "Remove"
        }
        MouseArea {
            id: removeMa

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onClicked: controlRow.wallpaperRemoved()
        }
    }
    DropdownMenu {
        activeValue: controlRow.fillModes[controlRow.selectedScreen] ?? "crop"
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        disabled: !controlRow.fillModeSupported || !controlRow.wallpapers[controlRow.selectedScreen]
        height: WallpaperConfig.controlRowHeight
        labelRole: "label"
        model: WallpaperConfig.fillModes
        valueRole: "mode"

        onItemSelected: mode => controlRow.fillModeChanged(mode)
    }
}

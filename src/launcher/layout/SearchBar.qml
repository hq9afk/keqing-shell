pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.launcher
import qs.config

RowLayout {
    id: root

    property alias input: input
    property string mode
    property int size: LauncherConfig.entryHeight

    spacing: LauncherConfig.searchbarSpacing

    Rectangle {
        Layout.preferredHeight: root.size
        Layout.preferredWidth: root.size
        border.color: ColorConfig.accent
        border.width: LauncherConfig.searchbarBorderWidth
        color: "transparent"
        radius: LauncherConfig.searchbarRadius

        Text {
            anchors.centerIn: parent
            color: ColorConfig.text
            font.family: IconConfig.fontFamily
            font.pixelSize: LauncherConfig.searchbarFontPx
            text: LauncherConfig.modeIcons[root.mode] || ""
        }
    }
    TextField {
        id: input

        Layout.fillWidth: true
        Layout.preferredHeight: root.size
        color: ColorConfig.text
        focus: true
        font.family: FontConfig.fontFamily
        font.pixelSize: LauncherConfig.searchbarFontPx
        leftPadding: LauncherConfig.searchbarPadding
        rightPadding: LauncherConfig.searchbarPadding
        verticalAlignment: Text.AlignVCenter
        z: 2

        background: Rectangle {
            border.color: ColorConfig.accent
            border.width: LauncherConfig.searchbarBorderWidth
            color: "transparent"
            radius: LauncherConfig.searchbarRadius
        }
    }
}

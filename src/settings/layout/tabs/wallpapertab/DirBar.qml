pragma ComponentBehavior: Bound

import QtQuick

import qs.settings
import qs.wallpaper
import qs.config

Rectangle {
    id: dirBar

    property string currentDir: ""
    property bool scanning: false

    signal dirChangeRequested(string path)
    signal escapePressed

    function resetDir() {
        dirInput.text = dirBar.currentDir;
    }

    border.color: ColorConfig.accent
    border.width: dirInput.activeFocus ? GlobalConfig.borderWidthThin : 0
    color: ColorConfig.fieldBg
    height: WallpaperConfig.dirBarHeight
    radius: GlobalConfig.radiusSm + SettingsConfig.thumbnailRadiusBoost

    Component.onCompleted: dirInput.text = dirBar.currentDir
    onCurrentDirChanged: {
        if (!dirInput.activeFocus)
            dirInput.text = dirBar.currentDir;
    }

    Text {
        id: dirLabel

        anchors.left: parent.left
        anchors.leftMargin: WallpaperConfig.dirLabelLeftMargin
        anchors.verticalCenter: parent.verticalCenter
        color: ColorConfig.accent
        font.bold: true
        font.family: FontConfig.fontFamily
        font.pixelSize: FontConfig.fontSettingsBody
        text: "Dir"
    }
    TextInput {
        id: dirInput

        anchors.left: dirLabel.right
        anchors.leftMargin: WallpaperConfig.dirInputLeftMargin
        anchors.right: rescanBtn.left
        anchors.rightMargin: WallpaperConfig.dirEdgeMargin
        anchors.verticalCenter: parent.verticalCenter
        clip: true
        color: ColorConfig.text
        font.family: FontConfig.fontFamily
        font.pixelSize: FontConfig.fontSettingsBody
        selectByMouse: true

        Keys.onEscapePressed: dirBar.escapePressed()
        Keys.onReturnPressed: dirBar.dirChangeRequested(dirInput.text.trim())
    }
    Rectangle {
        id: rescanBtn

        anchors.right: parent.right
        anchors.rightMargin: WallpaperConfig.dirEdgeMargin
        anchors.verticalCenter: parent.verticalCenter
        color: rescanArea.containsMouse ? ColorConfig.accent : Qt.rgba(1, 1, 1, 0.08)
        height: WallpaperConfig.dirBtnHeight
        radius: GlobalConfig.radiusSm
        width: WallpaperConfig.dirBtnWidth

        Behavior on color {
            ColorAnimation {
                duration: SettingsConfig.quickColorAnimMs
            }
        }

        Text {
            anchors.centerIn: parent
            color: ColorConfig.text
            font.family: FontConfig.fontFamily
            font.pixelSize: FontConfig.fontSettingsBody
            text: dirBar.scanning ? "…" : "Rescan"
        }
        MouseArea {
            id: rescanArea

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            enabled: !dirBar.scanning
            hoverEnabled: true

            onClicked: dirBar.dirChangeRequested(dirInput.text.trim())
        }
    }
}

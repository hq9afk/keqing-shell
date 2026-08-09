pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

import qs.components
import qs.bar
import qs.controlcenter
import qs.config

Rectangle {
    id: root

    property string _uptime: ""

    border.color: ColorConfig.accent
    border.width: ControlCenterConfig.profileBorderWidth
    color: ColorConfig.overlay
    height: mainCol.implicitHeight + ControlCenterConfig.profileVerticalPadding
    radius: ControlCenterConfig.profileRadius
    width: parent.width

    Process {
        command: ["uptime", "-p"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root._uptime = text.trim().replace(/^up /, "")
        }
    }
    Process {
        id: settingsProc

        command: ["keqing-shell", "settings"]
        running: false
    }
    Column {
        id: mainCol

        spacing: ControlCenterConfig.profileContentSpacing
        y: ControlCenterConfig.profileTopPadding

        anchors {
            left: parent.left
            leftMargin: ControlCenterConfig.profileHorizontalPadding
            right: parent.right
            rightMargin: ControlCenterConfig.profileHorizontalPadding
        }
        Item {
            height: avatar.height + ControlCenterConfig.profileAvatarGap + infoCol.implicitHeight
            width: parent.width

            // avatar
            RoundImage {
                id: avatar

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                borderWidth: BarConfig.logoBorderWidth
                height: ControlCenterConfig.profileAvatarSize
                source: GlobalConfig.userPfp
                width: ControlCenterConfig.profileAvatarSize
            }

            // info
            Column {
                id: infoCol

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: avatar.bottom
                anchors.topMargin: ControlCenterConfig.profileAvatarGap
                spacing: ControlCenterConfig.profileInfoSpacing

                Text {
                    color: ColorConfig.text
                    font.bold: true
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody + 1
                    horizontalAlignment: Text.AlignHCenter
                    text: GlobalConfig.user
                    width: ControlCenterConfig.profileInfoTextWidth
                }
                Text {
                    color: ColorConfig.textDim
                    elide: Text.ElideRight
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody - 1
                    horizontalAlignment: Text.AlignHCenter
                    text: root._uptime
                    width: ControlCenterConfig.profileInfoTextWidth
                }
            }

            // settings
            Text {
                anchors.right: parent.right
                anchors.top: parent.top
                color: settingsHover.containsMouse ? ColorConfig.text : ColorConfig.textDim
                font.family: IconConfig.fontFamily
                font.pixelSize: FontConfig.fontProfileSettings
                text: IconConfig.settings

                Behavior on color {
                    ColorAnimation {
                        duration: GlobalConfig.animationFast
                    }
                }

                MouseArea {
                    id: settingsHover

                    anchors.fill: parent
                    anchors.margins: -ControlCenterConfig.profileSettingsHitPadding
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: settingsProc.running = true
                }
            }
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

import qs.elements
import qs.config

Rectangle {
    id: root

    property string _uptime: ""

    border.color: ColorConfig.accent
    border.width: DashboardConfig.profileBorderWidth
    color: ColorConfig.overlay
    height: profileMainCol.implicitHeight + DashboardConfig.profileVerticalPadding
    radius: DashboardConfig.profileRadius
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
        id: profileMainCol

        spacing: DashboardConfig.profileContentSpacing
        y: DashboardConfig.profileTopPadding

        anchors {
            left: parent.left
            leftMargin: DashboardConfig.profileHorizontalPadding
            right: parent.right
            rightMargin: DashboardConfig.profileHorizontalPadding
        }
        Item {
            height: profileAvatar.height + DashboardConfig.profileAvatarGap + profileInfoCol.implicitHeight
            width: parent.width

            // avatar
            RoundImage {
                id: profileAvatar

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                borderWidth: BarConfig.logoBorderWidth
                height: DashboardConfig.profileAvatarSize
                source: GlobalConfig.userPfp
                width: DashboardConfig.profileAvatarSize
            }

            // info
            Column {
                id: profileInfoCol

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: profileAvatar.bottom
                anchors.topMargin: DashboardConfig.profileAvatarGap
                spacing: DashboardConfig.profileInfoSpacing

                Text {
                    color: ColorConfig.text
                    font.bold: true
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody + 1
                    horizontalAlignment: Text.AlignHCenter
                    text: GlobalConfig.user
                    width: DashboardConfig.profileInfoTextWidth
                }
                Text {
                    color: ColorConfig.textDim
                    elide: Text.ElideRight
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody - 1
                    horizontalAlignment: Text.AlignHCenter
                    text: root._uptime
                    width: DashboardConfig.profileInfoTextWidth
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
                    anchors.margins: -DashboardConfig.profileSettingsHitPadding
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: settingsProc.running = true
                }
            }
        }
    }
}

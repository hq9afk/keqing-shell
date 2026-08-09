pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import qs.components
import qs.config
import qs.settings
import qs.service

Rectangle {
    id: root

    property bool _justCopied: false
    property string _uptime: ""
    readonly property int collapsedWidth: SettingsConfig.navRailCollapsedWidth
    property int currentIndex: 0
    property bool expanded: true
    readonly property int expandedWidth: SettingsConfig.navRailExpandedWidth
    property list<var> tabDefs: []

    color: ColorConfig.textAlpha05
    implicitWidth: expanded ? expandedWidth : collapsedWidth
    radius: GlobalConfig.radiusMd

    Behavior on implicitWidth {
        NumberAnimation {
            duration: GlobalConfig.animationNormal
            easing.type: Easing.OutCubic
        }
    }

    Process {
        command: ["uptime", "-p"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root._uptime = text.trim().replace(/^up /, "")
        }
    }
    Timer {
        id: copiedTimer

        interval: SettingsConfig.navRailCopiedFeedbackMs

        onTriggered: root._justCopied = false
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: SettingsConfig.navRailPadding
        spacing: SettingsConfig.navRailContentSpacing

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: SettingsConfig.navRailAvatarRowLeftMargin
            Layout.topMargin: SettingsConfig.navRailAvatarRowTopMargin
            spacing: SettingsConfig.navRailContentSpacing

            RoundImage {
                borderColor: ColorConfig.accent
                borderWidth: GlobalConfig.borderWidthThin
                height: SettingsConfig.navRailAvatarSize
                source: GlobalConfig.userPfp
                width: SettingsConfig.navRailAvatarSize
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                visible: root.expanded

                Text {
                    Layout.fillWidth: true
                    color: ColorConfig.text
                    elide: Text.ElideRight
                    font.bold: true
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody + SettingsConfig.navRailUsernameFontSizeAdjust
                    text: GlobalConfig.user
                }
                Text {
                    Layout.fillWidth: true
                    color: ColorConfig.textDim
                    elide: Text.ElideRight
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody + SettingsConfig.navRailUptimeFontSizeAdjust
                    text: root._uptime
                }
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: SettingsConfig.navRailTightSpacing
            height: SettingsConfig.dividerThickness

            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    color: "transparent"
                    position: 0.0
                }
                GradientStop {
                    color: ColorConfig.textAlpha20
                    position: 0.5
                }
                GradientStop {
                    color: "transparent"
                    position: 1.0
                }
            }
        }
        Rectangle {
            id: fab

            Layout.alignment: root.expanded ? Qt.AlignLeft : Qt.AlignHCenter
            Layout.fillWidth: root.expanded
            Layout.preferredHeight: SettingsConfig.navRailFabHeight
            Layout.preferredWidth: root.expanded ? -1 : SettingsConfig.navRailFabHeight
            Layout.topMargin: SettingsConfig.navRailTightSpacing
            color: fabHover.containsMouse ? ColorConfig.accentAlpha18 : ColorConfig.textAlpha06
            radius: root.expanded ? GlobalConfig.radiusSm : height / 2

            Behavior on color {
                ColorAnimation {
                    duration: GlobalConfig.animationFast
                }
            }

            Process {
                id: openConfigProc

                command: ["xdg-open", SettingsService.filePath]
                running: false
            }
            RowLayout {
                anchors.centerIn: parent
                spacing: SettingsConfig.navRailFabContentSpacing

                Text {
                    color: ColorConfig.accent
                    font.family: IconConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody
                    text: root._justCopied ? IconConfig.check : IconConfig.edit
                }
                Text {
                    color: ColorConfig.text
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontSettingsBodySm
                    text: root._justCopied ? "Path copied" : "Config file"
                    visible: root.expanded
                }
            }
            MouseArea {
                id: fabHover

                acceptedButtons: Qt.LeftButton | Qt.RightButton
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        Quickshell.clipboardText = SettingsService.filePath;
                        root._justCopied = true;
                        copiedTimer.restart();
                    } else {
                        openConfigProc.running = true;
                    }
                }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: SettingsConfig.navRailListTopMargin
            spacing: SettingsConfig.navRailItemSpacing

            Repeater {
                model: root.tabDefs

                delegate: Rectangle {
                    id: navItem

                    required property int index
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: SettingsConfig.navRailItemHeight
                    color: root.currentIndex === navItem.index ? ColorConfig.accentAlpha18 : navHover.containsMouse ? ColorConfig.textAlpha06 : "transparent"
                    radius: GlobalConfig.radiusSm

                    Behavior on color {
                        ColorAnimation {
                            duration: GlobalConfig.animationFast
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: root.expanded ? SettingsConfig.navRailItemLeftMargin : 0
                        anchors.rightMargin: SettingsConfig.navRailItemRightMargin
                        spacing: SettingsConfig.navRailItemContentSpacing

                        Text {
                            Layout.alignment: root.expanded ? Qt.AlignVCenter : Qt.AlignCenter
                            Layout.fillWidth: !root.expanded
                            color: navItem.index === root.currentIndex ? ColorConfig.accent : ColorConfig.text
                            font.family: IconConfig.fontFamily
                            font.pixelSize: FontConfig.fontBody
                            horizontalAlignment: Text.AlignHCenter
                            opacity: navItem.index === root.currentIndex ? 1.0 : SettingsConfig.navRailInactiveIconOpacity
                            text: navItem.modelData.icon

                            Behavior on color {
                                ColorAnimation {
                                    duration: GlobalConfig.animationFast
                                }
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            color: navItem.index === root.currentIndex ? ColorConfig.accent : ColorConfig.text
                            elide: Text.ElideRight
                            font.family: FontConfig.fontFamily
                            font.pixelSize: FontConfig.fontSettingsBody
                            font.weight: navItem.index === root.currentIndex ? Font.DemiBold : Font.Normal
                            opacity: navItem.index === root.currentIndex ? 1.0 : SettingsConfig.navRailInactiveLabelOpacity
                            text: navItem.modelData.label
                            visible: root.expanded

                            Behavior on color {
                                ColorAnimation {
                                    duration: GlobalConfig.animationFast
                                }
                            }
                        }
                    }
                    MouseArea {
                        id: navHover

                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true

                        onClicked: root.currentIndex = navItem.index
                    }
                }
            }
        }
        Item {
            Layout.fillHeight: true
        }
    }
}

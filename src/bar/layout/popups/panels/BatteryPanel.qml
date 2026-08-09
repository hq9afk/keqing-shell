pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.UPower

import qs.components
import qs.service
import qs.bar
import qs.bar.layout.components
import qs.bar.service
import qs.config

WidgetPanel {
    id: root

    function formatTime(seconds) {
        if (!seconds || seconds <= 0)
            return "";
        var h = Math.floor(seconds / 3600);
        var m = Math.floor((seconds % 3600) / 60);
        if (h > 0)
            return h + "h " + m + "m";
        return m + "m";
    }

    clip: true
    implicitHeight: col.implicitHeight + BarConfig.panelPadding * 2
    implicitWidth: BarConfig.panelWidthSmall

    MouseArea {
        anchors.fill: parent
    }
    Column {
        id: col

        anchors.margins: BarConfig.panelPadding
        spacing: 0

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        Item {
            height: BarConfig.panelHeaderHeight
            width: parent.width

            Text {
                anchors.verticalCenter: parent.verticalCenter
                color: ColorConfig.text
                font.bold: true
                font.family: FontConfig.fontFamily
                font.pixelSize: FontConfig.fontBody + 1
                text: "Battery"
            }
            Rectangle {
                color: batCloseMa.containsMouse ? ColorConfig.overlay : ColorConfig.overlay
                height: BarConfig.panelCloseButtonSize
                radius: BarConfig.panelCloseButtonRadius
                width: BarConfig.panelCloseButtonSize

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                Text {
                    anchors.centerIn: parent
                    color: ColorConfig.text
                    font.family: IconConfig.fontFamily
                    font.pixelSize: FontConfig.fontPanelActionIcon
                    text: IconConfig.close
                }
                MouseArea {
                    id: batCloseMa

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: PanelService.closePanel()
                }
            }
        }
        Divider {
            width: parent.width
        }
        Item {
            height: BarConfig.panelSectionGap
            width: parent.width
        }
        Item {
            height: visible ? BarConfig.batteryEmptyStateHeight : 0
            visible: BatteryService.detected && BatteryService.allFull
            width: parent.width

            Text {
                anchors.centerIn: parent
                color: ColorConfig.textDim
                font.family: FontConfig.fontFamily
                font.pixelSize: FontConfig.fontBody
                text: "Plugged in"
            }
        }
        Repeater {
            model: BatteryService.allFull ? [] : UPower.devices.values

            Item {
                id: batItem

                readonly property color barColor: {
                    if (charging || full)
                        return ColorConfig.accent;
                    if (pct <= 15)
                        return "#F44747";
                    if (pct <= 30)
                        return "#E0A83A";
                    return ColorConfig.textMuted;
                }
                readonly property bool charging: modelData.state === 1
                readonly property bool full: modelData.state === 4
                readonly property bool isBattery: modelData.type === 2 || modelData.type === 4
                required property UPowerDevice modelData
                readonly property int pct: Math.round(modelData.percentage * 100)
                readonly property bool pending: modelData.state === 5 || (modelData.state === 2 && !UPower.onBattery)
                readonly property string timeStr: {
                    if (charging)
                        return root.formatTime(modelData.timeToFull);
                    return root.formatTime(modelData.timeToEmpty);
                }

                height: visible ? batContent.implicitHeight + BarConfig.panelSectionGap : 0
                visible: isBattery && modelData.isPresent
                width: col.width

                Column {
                    id: batContent

                    spacing: BarConfig.panelRowGap

                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    Row {
                        spacing: BarConfig.panelContentGap
                        width: parent.width

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            color: ColorConfig.text
                            font.bold: true
                            font.family: FontConfig.fontFamily
                            font.pixelSize: FontConfig.fontBody
                            text: batItem.modelData.nativePath || "Battery"
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            color: batItem.charging ? ColorConfig.accent : ColorConfig.textDim
                            font.family: FontConfig.fontFamily
                            font.pixelSize: FontConfig.fontBody
                            text: batItem.charging ? "Charging" : batItem.full ? "Full" : batItem.pending ? "Pending" : "Discharging"
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            color: ColorConfig.textDim
                            font.family: FontConfig.fontFamily
                            font.pixelSize: FontConfig.fontBody
                            text: batItem.timeStr !== "" ? "· " + batItem.timeStr : ""
                        }
                    }
                    Row {
                        spacing: BarConfig.panelContentGap
                        width: parent.width

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            color: ColorConfig.textAlpha10
                            height: BarConfig.batteryBarHeight
                            radius: BarConfig.batteryBarRadius
                            width: parent.width - pctLabel.implicitWidth - BarConfig.panelContentGap

                            Rectangle {
                                color: batItem.barColor
                                height: parent.height
                                radius: parent.radius
                                width: Math.max(radius * 2, parent.width * Math.min(batItem.pct, 100) / 100)

                                Behavior on color {
                                    ColorAnimation {
                                        duration: BarConfig.panelBarColorAnimMs
                                    }
                                }
                                Behavior on width {
                                    NumberAnimation {
                                        duration: BarConfig.panelBarWidthAnimMs
                                    }
                                }
                            }
                        }
                        Text {
                            id: pctLabel

                            anchors.verticalCenter: parent.verticalCenter
                            color: batItem.barColor
                            font.bold: true
                            font.family: FontConfig.fontFamily
                            font.pixelSize: FontConfig.fontBody
                            text: batItem.pct + "%"
                        }
                    }
                }
            }
        }
        Item {
            height: BarConfig.batteryEmptyStateHeight
            visible: !BatteryService.detected
            width: parent.width

            Text {
                anchors.centerIn: parent
                color: ColorConfig.textDim
                font.family: FontConfig.fontFamily
                font.pixelSize: FontConfig.fontBody
                text: "No Battery Detected"
            }
        }
        Item {
            height: BarConfig.panelSectionGap
            width: parent.width
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick

import qs.elements
import qs.service
import qs.bar.components
import qs.config

WidgetPanel {
    id: root

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
                text: "System"
            }
            Rectangle {
                color: closeMa.containsMouse ? ColorConfig.overlay : ColorConfig.overlay
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
                    id: closeMa

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
        StatRow {
            extra: (SystemStatService.cpuTempC > 0 ? SystemStatService.cpuTempC + "°C · " : "") + SystemStatService.cpuFreq
            label: "CPU"
            pct: SystemStatService.cpuUsage / 100
            value: Math.round(SystemStatService.cpuUsage).toString().padStart(3) + "%"
            width: parent.width
        }
        Item {
            height: BarConfig.panelSectionGap
            width: parent.width
        }
        StatRow {
            extra: SystemStatService.gpuTempC > 0 ? SystemStatService.gpuTempC + "°C" : ""
            height: visible ? implicitHeight : 0
            label: "GPU"
            pct: SystemStatService.gpuUsage / 100
            value: Math.round(SystemStatService.gpuUsage).toString().padStart(3) + "%"
            visible: SystemStatService.gpuAvailable
            width: parent.width
        }
        Item {
            height: visible ? BarConfig.panelSectionGap : 0
            visible: SystemStatService.gpuAvailable
            width: parent.width
        }
        StatRow {
            extra: SystemStatService.memUsedGb.toFixed(1) + " GiB / " + SystemStatService.memTotalGb.toFixed(1) + " GiB"
            label: "RAM"
            pct: SystemStatService.memPercent / 100
            value: SystemStatService.memPercent.toString().padStart(3) + "%"
            width: parent.width
        }
        Item {
            height: BarConfig.panelSectionGap
            width: parent.width
        }
        StatRow {
            extra: SystemStatService.diskRootUsedGb.toFixed(1) + " GiB / " + SystemStatService.diskRootSizeGb.toFixed(1) + " GiB"
            label: "Disk"
            pct: SystemStatService.diskRootPct / 100
            value: SystemStatService.diskRootPct.toString().padStart(3) + "%"
            width: parent.width
        }
        Item {
            height: BarConfig.panelSectionGap
            width: parent.width
        }
        Divider {
            width: parent.width
        }
        Item {
            height: BarConfig.panelContentGap
            width: parent.width
        }
        Row {
            spacing: 0
            width: parent.width

            Text {
                color: ColorConfig.textDim
                font.family: IconConfig.fontFamily
                font.pixelSize: FontConfig.fontBody
                text: IconConfig.arrowNarrowDown + " "
            }
            Text {
                color: ColorConfig.text
                font.family: FontConfig.fontFamily
                font.pixelSize: FontConfig.fontBody
                text: SystemStatService.formatSpeed(SystemStatService.rxBps)
                width: BarConfig.sysMonitorNetLabelWidth
            }
            Text {
                color: ColorConfig.textDim
                font.family: IconConfig.fontFamily
                font.pixelSize: FontConfig.fontBody
                text: IconConfig.arrowNarrowUp + " "
            }
            Text {
                color: ColorConfig.text
                font.family: FontConfig.fontFamily
                font.pixelSize: FontConfig.fontBody
                text: SystemStatService.formatSpeed(SystemStatService.txBps)
            }
        }
        Item {
            height: BarConfig.panelSectionGap
            width: parent.width
        }
    }

    component StatRow: Item {
        id: statRow

        readonly property color barColor: {
            if (pct > 0.9)
                return "#F44747";
            if (pct > 0.7)
                return "#E0A83A";
            return ColorConfig.accent;
        }
        property string extra: ""
        property string label: ""
        property real pct: 0
        property string value: ""

        height: implicitHeight
        implicitHeight: rowCol.implicitHeight

        Column {
            id: rowCol

            spacing: BarConfig.panelTightGap

            anchors {
                left: parent.left
                right: parent.right
            }
            Item {
                height: labelText.implicitHeight
                width: parent.width

                Text {
                    id: labelText

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    color: ColorConfig.textDim
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody
                    text: statRow.label + (statRow.extra !== "" ? "  " + statRow.extra : "")
                }
                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    color: statRow.barColor
                    font.bold: true
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody
                    text: statRow.value
                }
            }
            Rectangle {
                color: ColorConfig.textAlpha08
                height: BarConfig.sysMonitorBarHeight
                radius: BarConfig.sysMonitorBarRadius
                width: parent.width

                Rectangle {
                    color: statRow.barColor
                    height: parent.height
                    radius: parent.radius
                    width: Math.max(radius * 2, parent.width * Math.min(statRow.pct, 1.0))

                    Behavior on color {
                        ColorAnimation {
                            duration: BarConfig.panelBarColorAnimMs
                        }
                    }
                    Behavior on width {
                        NumberAnimation {
                            duration: BarConfig.panelBarWidthAnimMs
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }
}

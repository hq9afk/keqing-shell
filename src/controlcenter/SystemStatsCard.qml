pragma ComponentBehavior: Bound

import QtQuick

import qs.elements
import qs.service
import qs.config

Item {
    id: root

    clip: true
    height: systemStatsCardRect.height
    visible: height > 0
    width: parent.width

    Behavior on height {
        NumberAnimation {
            duration: GlobalConfig.animationNormal
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: systemStatsCardRect

        border.color: ColorConfig.accent
        border.width: ControlCenterConfig.cardBorderWidth
        color: ColorConfig.overlay
        height: ControlCenterConfig.cardTopPadding + systemStatsHdr.height + ControlCenterConfig.cardHeaderContentGap + statsCol.implicitHeight + ControlCenterConfig.cardBottomPadding
        radius: ControlCenterConfig.cardRadius
        width: parent.width

        Item {
            id: systemStatsHdr

            height: ControlCenterConfig.cardHeaderHeight
            y: ControlCenterConfig.cardTopPadding

            anchors {
                left: parent.left
                leftMargin: ControlCenterConfig.cardHorizontalPadding
                right: parent.right
                rightMargin: ControlCenterConfig.cardHorizontalPadding
            }
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                color: ColorConfig.text
                font.bold: true
                font.family: FontConfig.fontFamily
                font.pixelSize: FontConfig.fontBody
                text: "System"
            }
        }
        Item {
            id: systemStatsContentArea

            height: statsCol.implicitHeight

            anchors {
                left: parent.left
                leftMargin: ControlCenterConfig.cardHorizontalPadding
                right: parent.right
                rightMargin: ControlCenterConfig.cardHorizontalPadding
                top: systemStatsHdr.bottom
                topMargin: ControlCenterConfig.cardHeaderContentGap
            }
            Column {
                id: statsCol

                spacing: ControlCenterConfig.statsSpacing

                anchors {
                    left: parent.left
                    right: parent.right
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: ControlCenterConfig.statsColumnGap

                    Column {
                        spacing: ControlCenterConfig.statsGaugeLabelSpacing

                        ArcGauge {
                            anchors.horizontalCenter: parent.horizontalCenter
                            arcColor: "#ef4444"
                            icon: IconConfig.cpu
                            value: SystemStatService.cpuUsage
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: ColorConfig.textDim
                            font.family: FontConfig.fontFamily
                            font.pixelSize: FontConfig.fontBody - 1
                            text: "CPU"
                        }
                    }
                    Column {
                        spacing: ControlCenterConfig.statsGaugeLabelSpacing
                        visible: SystemStatService.gpuAvailable
                        width: visible ? implicitWidth : 0

                        ArcGauge {
                            anchors.horizontalCenter: parent.horizontalCenter
                            arcColor: "#a855f7"
                            icon: IconConfig.gpu
                            value: SystemStatService.gpuUsage
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: ColorConfig.textDim
                            font.family: FontConfig.fontFamily
                            font.pixelSize: FontConfig.fontBody - 1
                            text: "GPU"
                        }
                    }
                    Column {
                        spacing: ControlCenterConfig.statsGaugeLabelSpacing

                        ArcGauge {
                            anchors.horizontalCenter: parent.horizontalCenter
                            arcColor: "#3b82f6"
                            icon: IconConfig.settings
                            value: SystemStatService.memPercent
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: ColorConfig.textDim
                            font.family: FontConfig.fontFamily
                            font.pixelSize: FontConfig.fontBody - 1
                            text: "RAM"
                        }
                    }
                    Column {
                        spacing: ControlCenterConfig.statsGaugeLabelSpacing

                        ArcGauge {
                            anchors.horizontalCenter: parent.horizontalCenter
                            arcColor: "#22c55e"
                            icon: IconConfig.folder
                            value: SystemStatService.diskRootPct
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: ColorConfig.textDim
                            font.family: FontConfig.fontFamily
                            font.pixelSize: FontConfig.fontBody - 1
                            text: "DISK"
                        }
                    }
                }
            }
        }
    }
}

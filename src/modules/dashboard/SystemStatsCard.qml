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
        border.width: DashboardConfig.cardBorderWidth
        color: ColorConfig.overlay
        height: DashboardConfig.cardTopPadding + systemStatsHdr.height + DashboardConfig.cardHeaderContentGap + statsCol.implicitHeight + DashboardConfig.cardBottomPadding
        radius: DashboardConfig.cardRadius
        width: parent.width

        Item {
            id: systemStatsHdr

            height: DashboardConfig.cardHeaderHeight
            y: DashboardConfig.cardTopPadding

            anchors {
                left: parent.left
                leftMargin: DashboardConfig.cardHorizontalPadding
                right: parent.right
                rightMargin: DashboardConfig.cardHorizontalPadding
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
                leftMargin: DashboardConfig.cardHorizontalPadding
                right: parent.right
                rightMargin: DashboardConfig.cardHorizontalPadding
                top: systemStatsHdr.bottom
                topMargin: DashboardConfig.cardHeaderContentGap
            }
            Column {
                id: statsCol

                spacing: DashboardConfig.statsSpacing

                anchors {
                    left: parent.left
                    right: parent.right
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: DashboardConfig.statsColumnGap

                    Column {
                        spacing: DashboardConfig.statsGaugeLabelSpacing

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
                        spacing: DashboardConfig.statsGaugeLabelSpacing
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
                        spacing: DashboardConfig.statsGaugeLabelSpacing

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
                        spacing: DashboardConfig.statsGaugeLabelSpacing

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

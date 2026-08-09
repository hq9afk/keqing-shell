pragma ComponentBehavior: Bound

import QtQuick

import qs.components
import qs.service
import qs.controlcenter
import qs.controlcenter.layout
import qs.config

ControlCenterCard {
    id: root

    cardKey: "systemStats"
    contentHeight: statsCol.implicitHeight
    title: "System"

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

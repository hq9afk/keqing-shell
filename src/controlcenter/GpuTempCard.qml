pragma ComponentBehavior: Bound

import QtQuick

import qs.service
import qs.config

Item {
    id: root

    clip: true
    height: SystemStatService.gpuAvailable ? gpuTempCardRect.height : 0
    visible: height > 0 || SystemStatService.gpuAvailable
    width: parent.width

    Behavior on height {
        NumberAnimation {
            duration: GlobalConfig.animationNormal
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: gpuTempCardRect

        border.color: ColorConfig.accent
        border.width: ControlCenterConfig.cardBorderWidth
        color: ColorConfig.overlay
        height: ControlCenterConfig.cardTopPadding + gpuTempHdr.height + ControlCenterConfig.cardHeaderContentGap + ControlCenterConfig.tempRowHeight + ControlCenterConfig.cardBottomPadding
        radius: ControlCenterConfig.cardRadius
        width: parent.width

        Item {
            id: gpuTempHdr

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
                text: "GPU Temperature"
            }
        }
        Item {
            id: gpuTempContentArea

            height: ControlCenterConfig.tempRowHeight

            anchors {
                left: parent.left
                leftMargin: ControlCenterConfig.cardHorizontalPadding
                right: parent.right
                rightMargin: ControlCenterConfig.cardHorizontalPadding
                top: gpuTempHdr.bottom
                topMargin: ControlCenterConfig.cardHeaderContentGap
            }
            Text {
                color: {
                    var t = SystemStatService.gpuTempC;
                    if (t >= 85)
                        return "#ef4444";
                    if (t >= 70)
                        return "#f97316";
                    return ColorConfig.text;
                }
                font.bold: true
                font.family: FontConfig.fontFamily
                font.pixelSize: FontConfig.fontTempValue
                text: SystemStatService.gpuTempC + " °C"

                anchors {
                    left: parent.left
                    right: parent.right
                }
            }
        }
    }
}

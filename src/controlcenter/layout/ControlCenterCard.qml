pragma ComponentBehavior: Bound

import QtQuick

import qs.controlcenter
import qs.config

Item {
    id: root

    property string cardKey: ""
    default property alias content: contentArea.data
    property real contentHeight: 0
    property bool gated: false
    property Component headerSuffix: null
    readonly property bool shown: !gated
    property string title: ""

    clip: true
    height: shown ? cardRect.height : 0
    visible: height > 0 || shown
    width: parent.width

    Behavior on height {
        NumberAnimation {
            duration: GlobalConfig.animationNormal
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: cardRect

        border.color: ColorConfig.accent
        border.width: ControlCenterConfig.cardBorderWidth
        color: ColorConfig.overlay
        height: ControlCenterConfig.cardTopPadding + hdr.height + ControlCenterConfig.cardHeaderContentGap + root.contentHeight + ControlCenterConfig.cardBottomPadding
        radius: ControlCenterConfig.cardRadius
        width: parent.width

        Item {
            id: hdr

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
                text: root.title
            }
            Loader {
                anchors.fill: parent
                sourceComponent: root.headerSuffix
            }
        }
        Item {
            id: contentArea

            height: root.contentHeight

            anchors {
                left: parent.left
                leftMargin: ControlCenterConfig.cardHorizontalPadding
                right: parent.right
                rightMargin: ControlCenterConfig.cardHorizontalPadding
                top: hdr.bottom
                topMargin: ControlCenterConfig.cardHeaderContentGap
            }
        }
    }
}

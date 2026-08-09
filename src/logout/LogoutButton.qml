pragma ComponentBehavior: Bound

import QtQuick

import qs.logout
import qs.config

Rectangle {
    id: root

    property var chars: []
    property int currentIndex: 0
    property real expandRadius: 0
    property bool highlightEnabled: false
    property bool highlighted: root.highlightEnabled && (root.index == root.currentIndex)
    required property int index
    readonly property bool isHighlighted: root.highlightEnabled && (root.highlighted || root.isMouseHovered)
    readonly property bool isMouseHovered: click.containsMouse
    property bool keyInputActive: false

    signal execRequested(int idx)

    function setExpanded(show) {
        opacity = show ? LogoutConfig.buttonVisibleOpacity : LogoutConfig.buttonHiddenOpacity;
        expandRadius = show ? LogoutConfig.buttonsExpandedRadius : 0;
    }

    border.color: root.isHighlighted ? ColorConfig.accentAlt : ColorConfig.accent
    border.width: LogoutConfig.buttonBorderWidth
    color: ColorConfig.fieldBg
    height: LogoutConfig.buttonSize
    opacity: LogoutConfig.buttonHiddenOpacity
    radius: LogoutConfig.buttonSize / LogoutConfig.buttonCornerRadiusDiv
    scale: root.isHighlighted ? LogoutConfig.buttonHighlightScale : 1
    width: LogoutConfig.buttonSize
    x: root.expandRadius * Math.cos(LogoutConfig.buttonsStartAngle + LogoutConfig.buttonsStepAngle * root.index) - LogoutConfig.buttonSize / 2
    y: root.expandRadius * Math.sin(LogoutConfig.buttonsStartAngle + LogoutConfig.buttonsStepAngle * root.index) - LogoutConfig.buttonSize / 2

    Behavior on border.color {
        ColorAnimation {
            duration: LogoutConfig.buttonBorderAnimMs
            easing.type: Easing.OutCubic
        }
    }
    Behavior on expandRadius {
        NumberAnimation {
            duration: LogoutConfig.buttonRadiusAnimMs
        }
    }
    Behavior on opacity {
        NumberAnimation {
            duration: LogoutConfig.buttonOpacityAnimMs
        }
    }
    Behavior on scale {
        NumberAnimation {
            duration: LogoutConfig.buttonScaleAnimMs
            easing.type: Easing.OutCubic
        }
    }

    MouseArea {
        id: click

        acceptedButtons: Qt.LeftButton | Qt.RightButton
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onClicked: mouse => {
            if (mouse.button == Qt.LeftButton && root.keyInputActive)
                root.execRequested(root.index);
        }
    }
    Text {
        color: ColorConfig.text
        font.family: FontConfig.yujiMaiFamily
        font.pixelSize: LogoutConfig.buttonSize / 2
        text: root.chars[root.index] ?? ""
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
    }
}

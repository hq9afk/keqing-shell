pragma ComponentBehavior: Bound

import QtQuick

import qs.config

Item {
    id: root

    property bool dimmed: false
    property real keyStep: maxValue / 100
    property real maxValue: 100
    property real value: 0
    property real wheelStep: maxValue / 20

    signal scrubbed(real value)

    activeFocusOnTab: true
    implicitHeight: 20

    Keys.onLeftPressed: root.scrubbed(Math.max(0, root.value - root.keyStep))
    Keys.onRightPressed: root.scrubbed(Math.min(root.maxValue, root.value + root.keyStep))

    Rectangle {
        id: track

        anchors.verticalCenter: parent.verticalCenter
        color: ColorConfig.textAlpha12
        height: 4
        radius: 2
        width: parent.width

        Rectangle {
            id: fill

            color: root.dimmed ? ColorConfig.textMuted : ColorConfig.accent
            height: parent.height
            radius: parent.radius
            width: Math.max(radius, track.width * Math.min(root.value, root.maxValue) / root.maxValue)

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }
            Behavior on width {
                NumberAnimation {
                    duration: 80
                }
            }
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            color: ColorConfig.text
            height: 12
            radius: 6
            width: 12
            x: Math.max(0, Math.min(track.width - width, fill.width - width / 2))
        }
    }
    MouseArea {
        anchors.fill: parent
        anchors.margins: -4

        onClicked: mouse => {
            root.scrubbed(Math.max(0, Math.min(root.maxValue, mouse.x / width * root.maxValue)));
        }
        onPositionChanged: mouse => {
            if (pressed)
                root.scrubbed(Math.max(0, Math.min(root.maxValue, mouse.x / width * root.maxValue)));
        }
        onPressed: root.forceActiveFocus()
        onWheel: wheel => {
            root.scrubbed(Math.max(0, Math.min(root.maxValue, root.value + (wheel.angleDelta.y > 0 ? root.wheelStep : -root.wheelStep))));
        }
    }
}

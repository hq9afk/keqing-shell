pragma ComponentBehavior: Bound

import QtQuick

import qs.config

Item {
    id: root

    property bool active: false
    property int animDuration: 120

    signal toggled

    implicitHeight: 20
    implicitWidth: 36

    Rectangle {
        anchors.fill: parent
        color: root.active ? ColorConfig.accent : ColorConfig.textAlpha12
        radius: height / 2

        Behavior on color {
            ColorAnimation {
                duration: root.animDuration
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            color: ColorConfig.text
            height: 16
            radius: 8
            width: 16
            x: root.active ? parent.width - width - 2 : 2

            Behavior on x {
                NumberAnimation {
                    duration: root.animDuration
                }
            }
        }
        MouseArea {
            anchors.fill: parent

            onClicked: root.toggled()
        }
    }
}

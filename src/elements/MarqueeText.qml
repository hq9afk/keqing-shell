pragma ComponentBehavior: Bound

import QtQuick

import qs.config

Item {
    id: root

    readonly property real _overflow: Math.max(0, label.implicitWidth - root.width)
    property color color: ColorConfig.text
    property bool fontBold: false
    property string fontFamily: FontConfig.fontFamily
    property int fontSize: 12
    property int horizontalAlignment: Text.AlignLeft
    property int pauseDuration: 1200
    property bool running: true
    property int speed: 35
    property string text: ""

    function _restart() {
        anim.stop();
        if (root.running && root._overflow > 0) {
            label.x = 0;
            anim.start();
        } else {
            label.x = root.horizontalAlignment === Text.AlignHCenter ? Math.round((root.width - label.implicitWidth) / 2) : 0;
        }
    }

    clip: true
    height: label.implicitHeight

    onHorizontalAlignmentChanged: root._restart()
    onRunningChanged: root._restart()
    onWidthChanged: root._restart()

    Text {
        id: label

        color: root.color
        font.bold: root.fontBold
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
        text: root.text

        onImplicitWidthChanged: root._restart()
    }
    SequentialAnimation {
        id: anim

        loops: Animation.Infinite

        PauseAnimation {
            duration: root.pauseDuration
        }
        NumberAnimation {
            duration: root._overflow > 0 ? root._overflow / root.speed * 1000 : 0
            easing.type: Easing.Linear
            property: "x"
            target: label
            to: -root._overflow
        }
        PauseAnimation {
            duration: root.pauseDuration
        }
        NumberAnimation {
            duration: 0
            property: "x"
            target: label
            to: 0
        }
    }
}

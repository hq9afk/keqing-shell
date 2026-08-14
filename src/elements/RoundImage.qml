pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects

import qs.config

Item {
    id: root

    property color bgColor: "transparent"
    property color borderColor: ColorConfig.accent
    property real borderWidth: 0
    property bool playing: true
    property url source: ""

    function reset() {
        animImage.currentFrame = 0;
        playing = true;
    }
    function stop() {
        playing = false;
    }

    Rectangle {
        anchors.fill: parent
        border.color: root.borderColor
        border.width: root.borderWidth
        color: root.bgColor
        radius: width / 2
    }
    Item {
        id: imgContent

        anchors.fill: parent
        anchors.margins: root.borderWidth
        layer.enabled: true

        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: imgMask
        }

        AnimatedImage {
            id: animImage

            anchors.fill: parent
            cache: false
            fillMode: Image.PreserveAspectCrop
            playing: root.playing
            source: root.source

            Component.onCompleted: currentFrame = 0
        }
    }
    Rectangle {
        id: imgMask

        anchors.fill: imgContent
        layer.enabled: true
        radius: width / 2
        visible: false
    }
}

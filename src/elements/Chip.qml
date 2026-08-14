pragma ComponentBehavior: Bound

import QtQuick

import qs.config

Rectangle {
    property color baseColor: ColorConfig.textAlpha07
    property bool hovered: false

    color: hovered ? ColorConfig.textAlpha12 : baseColor
    radius: 8

    Behavior on color {
        ColorAnimation {
            duration: 100
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.bar.layout.components
import qs.config

WidgetCapsule {
    id: root

    iconGlyph: IconConfig.power
    labelText: "Power Menu"
    panelName: "logout"
    showLabel: baseShowLabel

    MouseArea {
        acceptedButtons: Qt.LeftButton
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: Quickshell.execDetached(["keqing-shell", "logout"])
    }
}

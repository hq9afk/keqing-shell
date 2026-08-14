pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.bar.components
import qs.config

WidgetCapsule {
    id: root

    iconGlyph: IconConfig.controlCenter
    labelText: GlobalConfig.user
    panelName: "controlcenter"
    showLabel: baseShowLabel

    MouseArea {
        acceptedButtons: Qt.LeftButton
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: Quickshell.execDetached(["keqing-shell", "controlcenter"])
    }
}

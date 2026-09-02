pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.modules.bar.components
import qs.config

WidgetCapsule {
    id: root

    iconGlyph: IconConfig.dashboard
    labelText: GlobalConfig.user
    panelName: "dashboard"
    showLabel: baseShowLabel

    MouseArea {
        acceptedButtons: Qt.LeftButton
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: Quickshell.execDetached(["keqing-shell", "dashboard"])
    }
}

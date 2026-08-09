pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.bar.layout.components

WidgetCapsule {
    id: root

    iconGlyph: config.icon || ""

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            var cmd = root.config.runCommand;
            if (cmd)
                Quickshell.execDetached(cmd);
        }
    }
}

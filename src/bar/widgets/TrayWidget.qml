pragma ComponentBehavior: Bound

import QtQuick

import qs.bar.components
import qs.service
import qs.config

WidgetCapsule {
    id: root

    iconGlyph: IconConfig.apps
    labelText: "System Tray"
    panelName: "trayPanel"
    showLabel: baseShowLabel

    MouseArea {
        acceptedButtons: Qt.LeftButton
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            var p = PanelService.getPanel("trayPanel", root.screen);
            if (!p)
                return;
            if (p.isPanelOpen && !p.isClosing)
                p.close();
            else
                p.open(root, {
                    screen: root.screen
                });
        }
    }
}

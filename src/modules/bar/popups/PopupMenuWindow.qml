pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.service

PanelWindow {
    id: root

    property var activeMenu: null

    function close() {
        visible = false;
        if (activeMenu) {
            if (typeof activeMenu.hideMenu === "function")
                activeMenu.hideMenu();
            else if (typeof activeMenu.close === "function")
                activeMenu.close();
        }
        activeMenu = null;
    }
    function open() {
        visible = true;
    }
    function showMenu(menu) {
        activeMenu = menu;
        visible = true;
    }

    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Overlay
    color: "transparent"
    visible: false

    Component.onCompleted: PanelService.registerPopupMenuWindow(root.screen, root)
    Component.onDestruction: PanelService.unregisterPopupMenuWindow(root.screen)

    anchors {
        bottom: true
        left: true
        right: true
        top: true
    }
    MouseArea {
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        anchors.fill: parent

        onClicked: root.close()
    }
}

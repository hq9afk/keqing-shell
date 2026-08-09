pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell

QtObject {
    id: root

    property var closingPanel: null
    property string closingScreenName: ""
    property var openedPanel: null
    property string openedScreenName: ""
    property var openedSubPanel: null
    property var popupMenuWindows: ({})
    property var registeredPanels: ({})

    function closeContextMenu(screen) {
        var win = getPopupMenuWindow(screen);
        if (win && win.visible)
            win.close();
    }
    function closePanel() {
        if (openedSubPanel) {
            closeSubPanel();
            return;
        }
        if (openedPanel && openedPanel.close)
            openedPanel.close();
    }
    function closeSubPanel() {
        if (openedSubPanel && openedSubPanel.close)
            openedSubPanel.close();
    }
    function closedPanel(panel) {
        if (openedPanel === panel) {
            openedPanel = null;
            openedScreenName = "";
        }
        if (closingPanel === panel) {
            closingPanel = null;
            closingScreenName = "";
        }
    }
    function closedSubPanel(panel) {
        if (openedSubPanel === panel)
            openedSubPanel = null;
    }
    function findFallbackScreen() {
        var primary = null;
        var first = null;
        for (var i = 0; i < Quickshell.screens.length; i++) {
            var s = Quickshell.screens[i];
            if (s.x === 0 && s.y === 0)
                primary = s;
            if (!first)
                first = s;
        }
        return primary || first || null;
    }
    function getPanel(name, screen) {
        if (!screen) {
            for (var k in registeredPanels) {
                if (k.indexOf(name + "-") === 0)
                    return registeredPanels[k];
            }
            return null;
        }

        var key = name + "-" + screen.name;
        if (registeredPanels[key])
            return registeredPanels[key];

        var fb = findFallbackScreen();
        if (fb && fb.name !== screen.name) {
            var fbKey = name + "-" + fb.name;
            if (registeredPanels[fbKey])
                return registeredPanels[fbKey];
        }
        for (var key2 in registeredPanels) {
            if (key2.indexOf(name + "-") === 0)
                return registeredPanels[key2];
        }
        return null;
    }
    function getPopupMenuWindow(screen) {
        if (!screen)
            return null;
        return popupMenuWindows[screen.name] || null;
    }
    function openSubPanel(panel) {
        if (openedSubPanel && openedSubPanel !== panel && openedSubPanel.close)
            openedSubPanel.close();
        openedSubPanel = panel;
    }
    function openSubPanelForCurrent(panelId, data) {
        var screen = openedPanel ? openedPanel.screen : null;
        var panel = getPanel(panelId, screen);
        if (panel)
            panel.open(null, data);
    }
    function registerPanel(panel) {
        if (!panel || !panel.objectName)
            return;
        registeredPanels[panel.objectName] = panel;
    }
    function registerPopupMenuWindow(screen, win) {
        if (!screen || !win)
            return;
        popupMenuWindows[screen.name] = win;
    }
    function showTrayMenu(screen, trayItem, trayMenu, anchorItem) {
        if (!trayItem || !trayMenu || !anchorItem)
            return false;
        closeContextMenu(screen);
        var win = getPopupMenuWindow(screen);
        if (!win)
            return false;
        trayMenu.trayItem = trayItem;
        win.showMenu(trayMenu);
        trayMenu.showAt(anchorItem, 0, 0);
        return true;
    }
    function unregisterPanel(panel) {
        if (!panel || !panel.objectName)
            return;
        delete registeredPanels[panel.objectName];
    }
    function unregisterPopupMenuWindow(screen) {
        if (!screen)
            return;
        delete popupMenuWindows[screen.name];
    }
    function willOpenPanel(panel) {
        if (openedPanel && openedPanel !== panel) {
            closingPanel = openedPanel;
            closingScreenName = openedPanel.screen ? openedPanel.screen.name : "";
            openedPanel.close();
        }
        openedPanel = panel;
        openedScreenName = (panel && panel.screen) ? panel.screen.name : "";
    }
}

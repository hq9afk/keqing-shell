pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

import qs.service
import qs.modules.bar.service

QtObject {
    id: root

    property var _hyprConn: Connections {
        function onChanged() {
            root.rev++;
        }

        target: HyprlandService
    }
    property var _hyprWsConn: Connections {
        function onAllWorkspacesChanged() {
            root.rev++;
        }
        function onFlashingIdsChanged() {
            root.rev++;
        }
        function onOccupiedIdsChanged() {
            root.rev++;
        }

        target: WorkspaceService
    }
    property var _shojiConn: Connections {
        function onChanged() {
            root.rev++;
        }

        target: ShojiWMService
    }
    readonly property bool isShojiWM: Quickshell.env("XDG_CURRENT_DESKTOP") === "ShojiWM"

    // Bumped on every upstream change; read it inside pillsForScreen() call
    // sites so QML's binding dependency tracking picks up backend updates.
    property int rev: 0

    function _hyprPills(screen) {
        var m = Hyprland.monitorFor(screen);
        if (!m)
            return [];
        var mName = m.name;
        var activeId = m.activeWorkspace ? m.activeWorkspace.id : -1;
        return WorkspaceService.allWorkspaces.filter(w => {
            var rule = WorkspaceService.wsRuleMonitor[w.id];
            return rule ? rule === mName : w.monitor === m;
        }).map(w => ({
                    "id": w.id,
                    "active": w.id === activeId,
                    "occupied": WorkspaceService.occupiedIds[w.id] === true,
                    "urgent": WorkspaceService.flashingIds[w.id] === true
                }));
    }
    function _shojiMonitorNameFor(screen) {
        var view = ShojiWMService.view;
        if (!view || !view.monitors)
            return null;
        for (var i = 0; i < view.monitors.length; i++) {
            if (view.monitors[i].name === (screen ? screen.name : ""))
                return view.monitors[i].name;
        }
        return view.currentMonitor || null;
    }
    function _shojiPills(screen) {
        var view = ShojiWMService.view;
        if (!view || !view.monitors)
            return [];
        var monitorName = root._shojiMonitorNameFor(screen);
        var monitor = view.monitors.find(m => m.name === monitorName);
        if (!monitor)
            return [];
        return monitor.workspaces.map(w => ({
                    "id": w.index,
                    "active": w.active,
                    "occupied": w.windowCount > 0,
                    "urgent": w.windows.some(win => win.urgent)
                }));
    }
    function activate(screen, pillId) {
        if (root.isShojiWM) {
            var monitor = root._shojiMonitorNameFor(screen);
            if (monitor)
                ShojiWMService.activateWorkspace(monitor, pillId);
        } else {
            Quickshell.execDetached(["hyprtile", "fw", pillId.toString()]);
        }
    }
    function focusedScreenName() {
        return root.isShojiWM ? (ShojiWMService.view.currentMonitor || "") : (HyprlandService.focusedMonitor?.name ?? "");
    }
    function pillsForScreen(screen) {
        return root.isShojiWM ? root._shojiPills(screen) : root._hyprPills(screen);
    }
}

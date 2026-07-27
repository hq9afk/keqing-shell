pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

QtObject {
    id: root

    property var _conn: Connections {
        function onRawEvent(event) {
            var name = event.name;
            if (name === "monitoradded" || name === "monitorremoved") {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshToplevels();
                root.monitorsChanged();
                root.changed();
                return;
            }
            if (name === "openwindow" || name === "closewindow" || name === "movewindow" || name === "movewindowv2" || name === "workspace" || name === "workspacev2" || name === "createworkspace" || name === "destroyworkspace" || name === "moveworkspace" || name === "activewindow" || name === "activewindowv2") {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshToplevels();
                root.changed();
            }
        }

        target: Hyprland
    }
    readonly property var focusedMonitor: Hyprland.focusedMonitor
    readonly property var focusedWorkspace: Hyprland.focusedWorkspace
    readonly property int focusedWorkspaceId: Hyprland.focusedWorkspace?.id ?? -1
    readonly property var toplevels: Hyprland.toplevels?.values ?? []
    readonly property var workspaces: Hyprland.workspaces?.values ?? []

    signal changed
    signal monitorsChanged

    Component.onCompleted: {
        if (Quickshell.env("XDG_CURRENT_DESKTOP") === "Hyprland") {
            Hyprland.refreshWorkspaces();
            Hyprland.refreshToplevels();
        }
    }
}

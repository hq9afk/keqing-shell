pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

import qs.service

QtObject {
    id: root

    property var _conn: Connections {
        function onActiveToplevelChanged() {
            var t = Hyprland.activeToplevel;
            if (t && t.urgent && t.workspace)
                root.handleUrgent(t);
        }
        function onRawEvent(event) {
            if (event.name === "urgent")
                root.flashUrgent(event.data);
        }

        target: Hyprland
    }
    property bool _cooldown: false
    property var _cooldownTimer: Timer {
        interval: 1500
        running: root._cooldown

        onTriggered: root._cooldown = false
    }
    property var _hyprConn: Connections {
        function onMonitorsChanged() {
            root._wsRulesProc.running = true;
        }

        target: HyprlandService
    }
    property var _urgentActiveConn: Connections {
        function onUrgentChanged() {
            var t = Hyprland.activeToplevel;
            if (t && t.urgent && t.workspace)
                root.handleUrgent(t);
        }

        target: Hyprland.activeToplevel
    }
    property var _wsRulesProc: Process {
        command: ["hyprctl", "workspacerules", "-j"]
        running: true

        stdout: StdioCollector {
            id: wsRulesCollector

            onStreamFinished: {
                try {
                    var rules = JSON.parse(wsRulesCollector.text);
                    var m = ({});
                    var p = ({});
                    for (var i = 0; i < rules.length; i++) {
                        var r = rules[i];
                        var id = parseInt(r.workspaceString);
                        if (isNaN(id))
                            continue;
                        if (r.monitor)
                            m[id] = r.monitor;
                        if (r.persistent)
                            p[id] = r.monitor || "";
                    }
                    root.wsRuleMonitor = m;
                    root.persistentMonitor = p;
                } catch (e) {}
            }
        }
    }
    readonly property var allWorkspaces: {
        var real = HyprlandService.workspaces.filter(w => w && !(w.name ?? "").startsWith("special:"));
        var realIds = new Set(real.map(w => w.id));
        var synthetic = [];
        for (var idStr in root.persistentMonitor) {
            var id = parseInt(idStr);
            if (!realIds.has(id))
                synthetic.push({
                    id: id,
                    name: String(id),
                    monitor: null
                });
        }
        return real.concat(synthetic).sort((a, b) => a.id - b.id);
    }
    property var flashingIds: ({})
    readonly property var occupiedIds: {
        var s = ({});
        var ws = HyprlandService.workspaces;
        for (var i = 0; i < ws.length; i++) {
            var w = ws[i];
            if (!w || (w.name ?? "").startsWith("special:"))
                continue;
            var ipc = w.lastIpcObject;
            if (ipc && (ipc.windows ?? 0) > 0)
                s[w.id] = true;
        }
        return s;
    }
    property var persistentMonitor: ({})
    property var wsRuleMonitor: ({})

    function flashUrgent(address) {
        if (root._cooldown)
            return;
        var norm = String(address).toLowerCase().replace(/^0x/, "");
        var toplevels = HyprlandService.toplevels;
        for (var i = 0; i < toplevels.length; i++) {
            var t = toplevels[i];
            if (t && String(t.address).toLowerCase().replace(/^0x/, "") === norm && t.workspace) {
                root.handleUrgent(t);
                break;
            }
        }
    }
    function handleUrgent(t) {
        if (root._cooldown || !t || !t.workspace)
            return;
        var f = ({});
        f[t.workspace.id] = true;
        root.flashingIds = f;
        root._cooldown = true;
        var app = t.appId || t.title || "Window";
        var ws = t.workspace.id;
        var monitor = t.workspace.monitor ? t.workspace.monitor.name : "?";
        Quickshell.execDetached(["notify-send", app + " is already open", "Display: " + monitor + "  ·  Workspace: " + ws, "--app-name", "Hyprland", "--urgency", "normal", "--expire-time", "3000"]);
    }
}

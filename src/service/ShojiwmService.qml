pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string socketPath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/shojiwm-" + (Quickshell.env("WAYLAND_DISPLAY") || "wayland-0") + ".sock"

    property bool available: false
    property var view: ({
            "currentMonitor": "",
            "monitors": []
        })

    property int _reconnectDelay: 500
    readonly property int _reconnectDelayMax: 5000
    property var _reconnectTimer: Timer {
        interval: root._reconnectDelay
        repeat: false

        onTriggered: root._socket.connected = true
    }
    property var _socket: Socket {
        path: root.socketPath

        parser: SplitParser {
            splitMarker: "\n"

            onRead: data => root._handleLine(data)
        }

        onConnectionStateChanged: {
            if (connected) {
                root.available = true;
                root._reconnectDelay = 500;
                write(JSON.stringify({
                    "id": 1,
                    "method": "workspaces.get"
                }) + "\n");
                flush();
            } else {
                root.available = false;
                root._reconnectTimer.interval = root._reconnectDelay;
                root._reconnectDelay = Math.min(root._reconnectDelay * 2, root._reconnectDelayMax);
                root._reconnectTimer.restart();
            }
        }
    }

    signal changed

    function _handleLine(line) {
        if (!line)
            return;
        var msg;
        try {
            msg = JSON.parse(line);
        } catch (e) {
            return;
        }
        if (msg.event === "workspaces.changed" && msg.payload) {
            root.view = msg.payload;
            root.changed();
        } else if (msg.id === 1 && msg.result) {
            root.view = msg.result;
            root.changed();
        }
    }

    function _send(method, params) {
        if (!root.available)
            return;
        root._socket.write(JSON.stringify({
            "method": method,
            "params": params || {}
        }) + "\n");
        root._socket.flush();
    }

    function switchWorkspace(direction) {
        root._send("workspaces.switch", {
            "direction": direction
        });
    }

    function activateWorkspace(monitor, index) {
        root._send("workspaces.activate", {
            "monitor": monitor,
            "index": index
        });
    }

    function toggleTiling(monitor) {
        root._send("workspaces.toggleTiling", monitor ? {
            "monitor": monitor
        } : {});
    }

    function activateWindow(windowId) {
        root._send("windows.activate", {
            "windowId": windowId
        });
    }

    Component.onCompleted: {
        if (Quickshell.env("XDG_CURRENT_DESKTOP") === "ShojiWM") {
            root._socket.connected = true;
        }
    }
}
